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


def load(path):
    with open(path, encoding="utf-8") as f:
        text = f.read().strip()
    if not text:
        return 0
    try:
        doc = json.loads(text)
    except json.JSONDecodeError:
        count = 0
        for raw in text.splitlines():
            raw = raw.strip()
            if raw:
                emit(json.loads(raw))
                count += 1
        return count
    if isinstance(doc, dict) and isinstance(doc.get("statuses"), list):
        doc = doc["statuses"]
    if isinstance(doc, list):
        for tweet in doc:
            emit(tweet)
        return len(doc)
    emit(doc)
    return 1


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    total = 0
    for path in sys.argv[1:]:
        total += load(path)
    print("loaded %d documents" % total, file=sys.stderr)


if __name__ == "__main__":
    main()
