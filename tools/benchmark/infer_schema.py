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
    with open(path, encoding="utf-8") as f:
        text = f.read().strip()
    if not text:
        return
    try:
        doc = json.loads(text)
    except json.JSONDecodeError:
        for raw in text.splitlines():
            raw = raw.strip()
            if raw:
                yield json.loads(raw)
        return
    if isinstance(doc, dict) and isinstance(doc.get("statuses"), list):
        doc = doc["statuses"]
    if isinstance(doc, list):
        yield from doc
    else:
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
