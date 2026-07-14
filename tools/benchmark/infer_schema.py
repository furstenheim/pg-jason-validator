#!/usr/bin/env python3
"""Identify the JSON schema of a set of documents.

Reads tweet files (same layouts as load_tweets.py: JSON array, object with a
"statuses" array, single object, or NDJSON) and prints a draft-07 schema that
describes exactly what was observed:

  * objects list every property seen at that path, mark the ones present in
    every instance as required, and set "additionalProperties": false — the
    schema stays strict because it is derived from the data, instead of being
    hand-relaxed to tolerate unknown fields;
  * scalar types are the union of the types observed ("integer" only if no
    fractional number ever appeared at that path);
  * array item schemas are the merge of every element observed.

The output is deterministic: properties appear in first-seen order and type
unions in a fixed canonical order.
"""

import json
import sys
from decimal import Decimal

TYPE_ORDER = ["object", "array", "string", "integer", "number", "boolean", "null"]


class Node:
    __slots__ = ("types", "properties", "prop_counts", "object_count", "items")

    def __init__(self):
        self.types = set()
        self.properties = {}     # name -> Node, first-seen order
        self.prop_counts = {}    # name -> number of instances containing it
        self.object_count = 0
        self.items = None        # Node, once any array element is seen

    def observe(self, value):
        if isinstance(value, dict):
            self.types.add("object")
            self.object_count += 1
            for k, v in value.items():
                if k not in self.properties:
                    self.properties[k] = Node()
                    self.prop_counts[k] = 0
                self.prop_counts[k] += 1
                self.properties[k].observe(v)
        elif isinstance(value, list):
            self.types.add("array")
            for v in value:
                if self.items is None:
                    self.items = Node()
                self.items.observe(v)
        elif isinstance(value, bool):
            self.types.add("boolean")
        elif isinstance(value, int):
            self.types.add("integer")
        elif isinstance(value, float):
            self.types.add("number")
        elif isinstance(value, Decimal):
            # ijson yields Decimal for all numbers; classify by whether it is whole
            self.types.add("integer" if value % 1 == 0 else "number")
        elif isinstance(value, str):
            self.types.add("string")
        elif value is None:
            self.types.add("null")
        else:
            raise ValueError("unsupported value: %r" % (value,))

    def schema(self):
        out = {}
        types = set(self.types)
        # a path where both whole and fractional numbers appear is a number
        if "number" in types:
            types.discard("integer")
        ordered = [t for t in TYPE_ORDER if t in types]
        if ordered:
            out["type"] = ordered[0] if len(ordered) == 1 else ordered
        if "object" in types:
            out["properties"] = {k: n.schema() for k, n in self.properties.items()}
            required = [k for k in self.properties
                        if self.prop_counts[k] == self.object_count]
            if required:
                out["required"] = required
            out["additionalProperties"] = False
        if "array" in types and self.items is not None:
            out["items"] = self.items.schema()
        return out


def documents(path):
    with open(path, encoding="utf-8", errors="replace") as f:
        # Check for LFS pointer without loading the whole file
        head = f.read(512)
        if not head.strip():
            return
        if head.lstrip().startswith("version https://git-lfs"):
            sys.exit("%s is a Git LFS pointer, not the data: clone with git-lfs installed"
                     % path)

        # If the first non-empty line is valid JSON, treat the file as NDJSON and
        # stream it line-by-line to avoid loading multi-gigabyte files into memory.
        f.seek(0)
        first_raw = next((l.strip() for l in f if l.strip()), "")
        try:
            json.loads(first_raw)
            f.seek(0)
            for n, raw in enumerate(f, 1):
                raw = raw.strip()
                if not raw:
                    continue
                try:
                    yield json.loads(raw)
                except json.JSONDecodeError:
                    print("skipping %s: not JSON or NDJSON (line %d)" % (path, n),
                          file=sys.stderr)
                    return
            return
        except json.JSONDecodeError:
            pass

        # Not NDJSON — stream the JSON array/object with ijson to avoid loading
        # the whole file into memory.
        import ijson
        first_char = head.lstrip()[0]
        f.seek(0)
        if first_char == '[':
            yield from ijson.items(f, 'item')
        else:
            # {"statuses": [...]} wrapper or a single small object
            count = 0
            for item in ijson.items(f, 'statuses.item'):
                yield item
                count += 1
            if count == 0:
                f.seek(0)
                doc = json.loads(f.read())
                yield doc


def main():
    root = Node()
    count = 0
    for path in sys.argv[1:]:
        for doc in documents(path):
            root.observe(doc)
            count += 1
    if count == 0:
        print("no documents found", file=sys.stderr)
        sys.exit(1)
    schema = {"$schema": "http://json-schema.org/draft-07/schema#"}
    schema.update(root.schema())
    json.dump(schema, sys.stdout, indent=2, ensure_ascii=False)
    sys.stdout.write("\n")
    print("identified schema from %d documents" % count, file=sys.stderr)


if __name__ == "__main__":
    main()
