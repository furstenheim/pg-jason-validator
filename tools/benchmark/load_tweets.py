#!/usr/bin/env python3
"""Turn downloaded tweet JSON files into COPY text-format input.

Accepts any mix of layouts per file: a top-level JSON array of tweets, an
object with a "statuses" array (Twitter API search responses), a single
tweet object, or newline-delimited JSON. Emits one compact JSON document
per line, escaped for `COPY tweets (data) FROM STDIN`.
"""

import json
import sys
from decimal import Decimal


def _decimal_default(obj):
    if isinstance(obj, Decimal):
        # Preserve whole numbers exactly (tweet IDs exceed float precision).
        return int(obj) if obj % 1 == 0 else float(obj)
    raise TypeError(repr(obj) + " is not JSON serializable")


def emit(doc):
    line = json.dumps(doc, separators=(",", ":"), ensure_ascii=False, default=_decimal_default)
    # PostgreSQL text cannot store null bytes; remove them before COPY.
    line = line.replace("\\u0000", "")
    # compact JSON contains no raw newlines/tabs; only backslashes need
    # escaping for COPY text format
    sys.stdout.write(line.replace("\\", "\\\\") + "\n")


def documents(path):
    # keep in sync with infer_schema.py so both tools see the same documents
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


def load(path):
    count = 0
    for doc in documents(path):
        emit(doc)
        count += 1
    return count


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    total = 0
    for path in sys.argv[1:]:
        total += load(path)
    print("loaded %d documents" % total, file=sys.stderr)


if __name__ == "__main__":
    main()
