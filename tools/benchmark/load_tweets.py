#!/usr/bin/env python3
"""Turn downloaded tweet JSON files into COPY text-format input.

Accepts any mix of layouts per file: a top-level JSON array of tweets, an
object with a "statuses" array (Twitter API search responses), a single
tweet object, or newline-delimited JSON. Emits one compact JSON document
per line, escaped for `COPY tweets (data) FROM STDIN`.
"""

import json
import sys


def emit(doc):
    line = json.dumps(doc, separators=(",", ":"), ensure_ascii=False)
    # compact JSON contains no raw newlines/tabs; only backslashes need
    # escaping for COPY text format
    sys.stdout.write(line.replace("\\", "\\\\") + "\n")


def documents(path):
    # keep in sync with infer_schema.py so both tools see the same documents
    with open(path, encoding="utf-8", errors="replace") as f:
        text = f.read().strip()
    if not text:
        return
    if text.startswith("version https://git-lfs"):
        sys.exit("%s is a Git LFS pointer, not the data: clone with git-lfs installed"
                 % path)
    try:
        doc = json.loads(text)
    except json.JSONDecodeError:
        # not a single document; try newline-delimited JSON
        docs = []
        for n, raw in enumerate(text.splitlines(), 1):
            raw = raw.strip()
            if not raw:
                continue
            try:
                docs.append(json.loads(raw))
            except json.JSONDecodeError:
                print("skipping %s: not JSON or NDJSON (line %d)" % (path, n),
                      file=sys.stderr)
                return
        yield from docs
        return
    if isinstance(doc, dict) and isinstance(doc.get("statuses"), list):
        doc = doc["statuses"]
    if isinstance(doc, list):
        yield from doc
    else:
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
