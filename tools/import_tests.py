#!/usr/bin/env python3
"""One-time importer of the is_jsonb_valid regression suite.

Reads the sql/ and expected/ directories of a checkout of
https://github.com/furstenheim/is_jsonb_valid and rewrites every
``SELECT is_jsonb_valid('<schema>', '<data>')`` (and the draft-v7 variant)
into ``SELECT <generated_function>('<data>')``:

  * every distinct schema becomes one entry in validators.json; tests using
    the same schema (anywhere in the suite) share the same function;
  * sql/ test files are rewritten in place relative to this repository;
  * the expected boolean outcome of every statement, taken from the
    reference expected/*.out files, is written to a manifest so the freshly
    generated expected outputs can be cross-checked against the reference
    implementation's behaviour.

Statements that cannot exist in the compile-time model are dropped:
NULL schemas (the schema is no longer a run-time argument) and schemas the
reference rejects with a run-time ERROR (malformed schemas fail at code
generation time instead).

Usage: import_tests.py <reference_checkout> [<manifest_output>]
"""

import json
import os
import re
import sys
from decimal import Decimal

# Reference REGRESS order (from the is_jsonb_valid Makefile); the first file
# is renamed since it is the one that creates the extension.
REFERENCE_TESTS = """
is_jsonb_valid_test additionalItems additionalItems.v7 additionalProperties
additionalProperties.v7 allOf allOf.v7 anyOf anyOf.v7 boolean.v7 const.v7
contains.v7 default default.v7 dependencies dependencies.v7 enum enum.v7
exclusiveMaximum.v7 exclusiveMinimum.v7 id id.v7 if.v7 infinite infinite.v7
items items.v7 maximum maximum.v7 maxItems maxItems.v7 maxLength maxLength.v7
maxProperties maxProperties.v7 minimum minimum.v7 minItems minItems.v7
minLength minLength.v7 minProperties minProperties.v7 multipleOf
multipleOf.v7 not not.v7 oneOf oneOf.v7 pattern pattern.v7 patternProperties
patternProperties.v7 properties properties.v7 propertyNames.v7 ref ref.v7
required required.v7 type type.v7 uniqueItems uniqueItems.v7
""".split()

RENAMES = {"is_jsonb_valid_test": "pg_jason_validator_test"}
PREFIXES = {"is_jsonb_valid_test": "misc"}


def snake(name):
    name = name.replace(".", "_")
    return re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower()


def json_dump(v):
    if v is None:
        return "null"
    if v is True:
        return "true"
    if v is False:
        return "false"
    if isinstance(v, (Decimal, int)):
        return str(v)
    if isinstance(v, str):
        return json.dumps(v, ensure_ascii=True)
    if isinstance(v, list):
        return "[" + ",".join(json_dump(x) for x in v) + "]"
    if isinstance(v, dict):
        return "{" + ",".join(json.dumps(k, ensure_ascii=True) + ":" + json_dump(x)
                              for k, x in v.items()) + "}"
    raise ValueError("cannot serialize %r" % (v,))


def canonical(v):
    """Dedup key: like json_dump but with sorted object keys."""
    if isinstance(v, list):
        return "[" + ",".join(canonical(x) for x in v) + "]"
    if isinstance(v, dict):
        return "{" + ",".join(json.dumps(k, ensure_ascii=True) + ":" + canonical(v[k])
                              for k in sorted(v)) + "}"
    return json_dump(v)


def parse_sql(text):
    """Split a test file into ('comment', line) and ('stmt', text) items."""
    items = []
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if c in " \t\n\r":
            i += 1
            continue
        if text.startswith("--", i):
            j = text.find("\n", i)
            j = n if j < 0 else j
            items.append(("comment", text[i:j]))
            i = j + 1
            continue
        # statement: read until ; outside single quotes
        j = i
        in_quote = False
        while j < n:
            if text[j] == "'":
                in_quote = not in_quote
            elif text[j] == ";" and not in_quote:
                break
            j += 1
        if j >= n:
            raise ValueError("unterminated statement: %r..." % text[i:i + 60])
        items.append(("stmt", text[i:j + 1]))
        i = j + 1
    return items


STMT_RE = re.compile(r"^\s*select\s+(is_jsonb_valid_draft_v7|is_jsonb_valid)\s*\(",
                     re.IGNORECASE)


def split_args(stmt, start):
    """Parse `(arg1, arg2);` from position `start` (after the open paren).
    Each arg is NULL or a single-quoted literal; returns verbatim slices."""
    args = []
    i = start
    for argno in (1, 2):
        while stmt[i] in " \t\n\r":
            i += 1
        if stmt[i] == "'":
            j = i + 1
            while True:
                j = stmt.index("'", j)
                if j + 1 < len(stmt) and stmt[j + 1] == "'":
                    j += 2
                    continue
                break
            args.append(stmt[i:j + 1])
            i = j + 1
        elif stmt[i:i + 4].upper() == "NULL":
            args.append(None)
            i += 4
        else:
            raise ValueError("unexpected argument syntax: %r" % stmt[i:i + 40])
        while stmt[i] in " \t\n\r":
            i += 1
        expected = "," if argno == 1 else ")"
        if stmt[i] != expected:
            raise ValueError("expected %r at %r" % (expected, stmt[i:i + 40]))
        i += 1
    return args


def unquote(lit):
    assert lit[0] == "'" and lit[-1] == "'"
    return lit[1:-1].replace("''", "'")


def parse_out(path):
    """Extract the ordered SELECT outcomes from an expected/*.out file:
    ('row', 't'|'f'|None) or ('error',). CREATE EXTENSION produces no
    output under pg_regress' quiet psql, so it contributes no outcome."""
    outcomes = []
    lines = open(path).read().split("\n")
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.startswith("ERROR:"):
            outcomes.append(("error",))
        elif re.fullmatch(r"-+", line):
            value = lines[i + 1].strip() if i + 1 < len(lines) else ""
            outcomes.append(("row", value if value else None))
            i += 1  # skip the value line
        i += 1
    return outcomes


def main():
    ref = sys.argv[1]
    manifest_path = sys.argv[2] if len(sys.argv) > 2 else "manifest.json"
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    os.makedirs(os.path.join(here, "sql"), exist_ok=True)
    validators = []          # entries for validators.json, in first-use order
    by_canonical = {}        # canonical schema -> function name
    manifest = {}            # new test name -> [ [function, 't'/'f'], ... ]
    dropped = []

    for test in REFERENCE_TESTS:
        new_name = RENAMES.get(test, test)
        prefix = PREFIXES.get(test, snake(test))
        counter = 0

        items = parse_sql(open(os.path.join(ref, "sql", test + ".sql")).read())
        outcomes = parse_out(os.path.join(ref, "expected", test + ".out"))
        selects = [it for it in items
                   if it[0] == "stmt"
                   and not re.match(r"^\s*CREATE EXTENSION\b", it[1], re.IGNORECASE)]
        if len(selects) != len(outcomes):
            raise ValueError("%s: %d statements vs %d outcomes"
                             % (test, len(selects), len(outcomes)))

        out_lines = []
        results = []
        stmt_idx = 0
        for kind, text in items:
            if kind == "comment":
                out_lines.append(text)
                continue
            if re.match(r"^\s*CREATE EXTENSION\b", text, re.IGNORECASE):
                out_lines.append("CREATE EXTENSION pg_jason_validator;")
                continue
            outcome = outcomes[stmt_idx]
            stmt_idx += 1
            m = STMT_RE.match(text)
            if not m:
                raise ValueError("%s: unrecognized statement %r" % (test, text[:60]))
            schema_lit, data_lit = split_args(text, m.end())
            if schema_lit is None or outcome[0] == "error":
                dropped.append((test, text.strip().replace("\n", " ")[:100]))
                continue
            assert outcome[0] == "row" and outcome[1] in ("t", "f"), \
                "%s: unexpected outcome %r" % (test, outcome)
            schema = json.loads(unquote(schema_lit), parse_float=Decimal)
            key = canonical(schema)
            fn = by_canonical.get(key)
            if fn is None:
                counter += 1
                fn = "%s_%d" % (prefix, counter)
                by_canonical[key] = fn
                validators.append((fn, schema))
            out_lines.append("SELECT %s(%s);" % (fn, data_lit))
            results.append([fn, outcome[1]])

        with open(os.path.join(here, "sql", new_name + ".sql"), "w") as f:
            f.write("\n".join(out_lines) + "\n")
        manifest[new_name] = results

    with open(os.path.join(here, "validators.json"), "w") as f:
        f.write("[\n")
        f.write(",\n".join('{"name":%s,"schema":%s}' % (json.dumps(n), json_dump(s))
                           for n, s in validators))
        f.write("\n]\n")

    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=1)

    print("imported %d test files, %d unique validators, dropped %d statements:"
          % (len(REFERENCE_TESTS), len(validators), len(dropped)))
    for test, stmt in dropped:
        print("  [%s] %s" % (test, stmt))


if __name__ == "__main__":
    main()
