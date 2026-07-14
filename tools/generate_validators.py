#!/usr/bin/env python3
"""Deterministic code generator for pg_jason_validator.

Reads a JSON file containing an array of ``{"name": ..., "schema": ...}``
entries (``name`` must match ``[a-z0-9_]+`` and not start with a digit;
``schema`` is a JSON schema) and emits:

  * ``pg_jason_validator.c``  — one static node function per schema node,
    written exclusively with the macros from ``validator_macros.h``, plus one
    SQL-callable function per validator that takes a single jsonb argument.
  * ``pg_jason_validator--<version>.sql`` — the extension script creating the
    SQL functions.

Everything that depends on the shape of the schema is decided here, at
generation time: which keywords are present, draft-4 vs draft-7 spelling of
exclusive bounds, tuple vs uniform "items", where every "$ref" points, and so
on. Unresolvable or malformed schemas are an error at generation time, not at
run time.

The output is a pure function of the input file: running the generator twice
produces byte-identical files.
"""

import json
import sys
from decimal import Decimal

VERSION = "0.1.0"
EXTENSION = "pg_jason_validator"

# Canonical JSON type names in the order is_jsonb_valid checks them. A schema
# type string T matches a canonical name C when C.startswith(T) — this
# replicates the reference implementation's strncmp(T, C, strlen(T)) quirk
# (e.g. "inte" behaves as "integer").
CANONICAL_TYPES = [
    ("object", "JSV_T_OBJECT"),
    ("array", "JSV_T_ARRAY"),
    ("null", "JSV_T_NULL"),
    ("string", "JSV_T_STRING"),
    ("number", "JSV_T_NUMBER"),
    ("integer", "JSV_T_INTEGER"),
    ("boolean", "JSV_T_BOOLEAN"),
]


class GenError(Exception):
    pass


class RefError(Exception):
    """A $ref the reference implementation rejects at evaluation time. The
    generator turns these into JSV_ERROR nodes (same message as
    is_jsonb_valid) instead of failing the build, because the branch may be
    unreachable (e.g. short-circuited by anyOf)."""
    pass


def is_num(v):
    return isinstance(v, (int, Decimal)) and not isinstance(v, bool)


def json_dump(v):
    """Compact, ASCII-only, Decimal-preserving JSON serialization."""
    if v is None:
        return "null"
    if v is True:
        return "true"
    if v is False:
        return "false"
    if isinstance(v, Decimal):
        return str(v)
    if isinstance(v, int):
        return str(v)
    if isinstance(v, str):
        return json.dumps(v, ensure_ascii=True)
    if isinstance(v, list):
        return "[" + ",".join(json_dump(x) for x in v) + "]"
    if isinstance(v, dict):
        return "{" + ",".join(json.dumps(k, ensure_ascii=True) + ":" + json_dump(x)
                              for k, x in v.items()) + "}"
    raise GenError("cannot serialize %r" % (v,))


def c_str(s):
    """C string literal for an arbitrary Python string (UTF-8 bytes)."""
    out = []
    for b in s.encode("utf-8"):
        c = chr(b)
        if c in ('"', "\\"):
            out.append("\\" + c)
        elif 0x20 <= b < 0x7F:
            out.append(c)
        else:
            out.append("\\%03o" % b)
    return '"' + "".join(out) + '"'


def utf8_len(s):
    return len(s.encode("utf-8"))


def num_lit(v):
    """C string literal holding a numeric constant for numeric_in()."""
    return c_str(str(v))


def resolve_pointer(root, ref):
    """Resolve a $ref against the root schema, like is_jsonb_valid does:
    only root-anchored JSON pointers ("#", "#/a/b", ...) are supported."""
    if not isinstance(ref, str):
        raise RefError("$ref must be a string")
    if ref == "":
        raise RefError("$ref must not be an empty string")
    parts = ref.split("/")
    if parts[0] != "#":
        raise RefError("$ref must be anchored at root")
    node = root
    for raw in parts[1:]:
        token = raw.replace("~1", "/").replace("~0", "~")
        if isinstance(node, dict):
            if token not in node:
                raise RefError("Missing references $ref")
            node = node[token]
        elif isinstance(node, list):
            try:
                idx = int(token)
            except ValueError:
                raise RefError("Missing references $ref")
            if not 0 <= idx < len(node):
                raise RefError("Missing references $ref")
            node = node[idx]
        else:
            raise RefError("$ref must point to a schema, not to a scalar")
    return node


class Generator:
    def __init__(self):
        self.decls = []          # forward declarations, by node id
        self.bodies = []         # body lines, by node id
        self.validators = []     # (name, root node id)

    # ---- node generation -------------------------------------------------

    def node(self, schema, root, memo):
        """Return the node id validating `schema`; generate it if needed.

        `memo` maps id(subschema-object) -> node id within one validator, so
        cyclic $refs terminate and repeated references share one function.
        """
        key = id(schema)
        if key in memo:
            return memo[key]
        nid = len(self.bodies)
        memo[key] = nid
        self.decls.append("JSV_NODE_DECLARE(%d);" % nid)
        self.bodies.append(None)  # reserve slot; recursion may allocate more
        self.bodies[nid] = self.gen_body(nid, schema, root, memo)
        return nid

    def fn(self, schema, root, memo):
        return "jsv_node_%d" % self.node(schema, root, memo)

    def gen_body(self, nid, schema, root, memo):
        lines = []
        lines.append("// %s" % json_dump(schema))
        lines.append("JSV_NODE_BEGIN(%d)" % nid)
        body = self.keywords(schema, root, memo)
        lines.extend("\t" + l for l in body)
        lines.append("JSV_NODE_END")
        return lines

    def keywords(self, schema, root, memo):
        if schema is True:
            return []
        if schema is False:
            return ["JSV_FAIL();"]
        if not isinstance(schema, dict):
            raise GenError("schema must be an object or boolean: %s" % json_dump(schema))

        out = []

        # $ref overrides every sibling keyword, as in is_jsonb_valid
        if "$ref" in schema:
            try:
                target = resolve_pointer(root, schema["$ref"])
            except RefError as e:
                out.append("JSV_ERROR(%s);" % c_str(str(e)))
                return out
            if isinstance(target, (dict, bool)):
                out.append("JSV_CHECK(%s);" % self.fn(target, root, memo))
            else:
                # the reference errors when the resolved schema is a scalar
                out.append('JSV_ERROR("Schema must be an object");')
            return out

        # required (draft-4/7 array form; the draft-3 boolean form is
        # handled by the enclosing "properties" loop below)
        required = schema.get("required")
        if isinstance(required, list):
            for k in required:
                if not isinstance(k, str):
                    raise GenError("required entries must be strings: %s" % json_dump(required))
                out.append("JSV_REQUIRED(%s, %d);" % (c_str(k), utf8_len(k)))

        # type
        if "type" in schema:
            t = schema["type"]
            alts = [t] if isinstance(t, str) else t
            if not isinstance(alts, list):
                raise GenError("type must be a string or an array: %s" % json_dump(t))
            out.append("JSV_TYPE_BEGIN")
            for alt in alts:
                if isinstance(alt, str):
                    for canonical, enum in CANONICAL_TYPES:
                        if canonical.startswith(alt):
                            out.append("\tJSV_TYPE_ALT(%s)" % enum)
                elif isinstance(alt, dict):
                    # draft-3 leftover supported by the reference: a schema
                    # object inside a "type" array
                    out.append("\tJSV_TYPE_ALT_SCHEMA(%s)" % self.fn(alt, root, memo))
                else:
                    raise GenError("type elements must be strings or objects: %s" % json_dump(t))
            out.append("JSV_TYPE_END")

        # properties / patternProperties / additionalProperties
        props = schema.get("properties")
        patprops = schema.get("patternProperties")
        addprops = schema.get("additionalProperties")
        if props is not None and not isinstance(props, dict):
            raise GenError("properties must be an object")
        if patprops is not None and not isinstance(patprops, dict):
            raise GenError("patternProperties must be an object")
        if addprops is not None and not isinstance(addprops, (dict, bool)):
            raise GenError("additionalProperties must be an object or boolean")

        # draft-3 boolean "required" on a property subschema; the reference
        # only enforces it when patternProperties is absent (its optimized
        # merge join visits schema properties missing from the data).
        if props and patprops is None:
            for k, sub in props.items():
                if isinstance(sub, dict) and sub.get("required") is True:
                    out.append("JSV_REQUIRED(%s, %d);" % (c_str(k), utf8_len(k)))

        need_loop = bool(props) or bool(patprops) or addprops is False \
            or isinstance(addprops, dict)
        if need_loop:
            out.append("JSV_OBJECT_BEGIN")
            for k, sub in (props or {}).items():
                out.append("\tJSV_PROP(%s, %d, %s)"
                           % (c_str(k), utf8_len(k), self.fn(sub, root, memo)))
            for rk, rsub in (patprops or {}).items():
                out.append("\tJSV_PROP_PATTERN(%s, %s)"
                           % (c_str(rk), self.fn(rsub, root, memo)))
            if addprops is False:
                out.append("\tJSV_PROP_ADDITIONAL_FALSE")
            elif isinstance(addprops, dict):
                out.append("\tJSV_PROP_ADDITIONAL(%s)" % self.fn(addprops, root, memo))
            out.append("JSV_OBJECT_END")

        # propertyNames (draft 7)
        if "propertyNames" in schema:
            pn = schema["propertyNames"]
            if not isinstance(pn, (dict, bool)):
                raise GenError("propertyNames must be a schema")
            out.append("JSV_PROPERTY_NAMES(%s)" % self.fn(pn, root, memo))

        # if / then / else (draft 7); then/else are ignored without "if"
        if "if" in schema:
            cond = schema["if"]
            if not isinstance(cond, (dict, bool)):
                raise GenError("if must be a schema")
            then = schema.get("then", True)
            els = schema.get("else", True)
            if not isinstance(then, (dict, bool)) or not isinstance(els, (dict, bool)):
                raise GenError("then/else must be schemas")
            out.append("JSV_IF_THEN_ELSE(%s, %s, %s);"
                       % (self.fn(cond, root, memo),
                          self.fn(then, root, memo),
                          self.fn(els, root, memo)))

        # items / additionalItems
        items = schema.get("items")
        additems = schema.get("additionalItems")
        if isinstance(items, dict):
            out.append("JSV_ITEMS_ALL(%s)" % self.fn(items, root, memo))
        elif items is True:
            pass
        elif items is False:
            out.append("JSV_ITEMS_EMPTY();")
        elif isinstance(items, list):
            out.append("JSV_TUPLE_BEGIN")
            for i, sub in enumerate(items):
                out.append("\tJSV_TUPLE_ITEM(%d, %s)" % (i, self.fn(sub, root, memo)))
            if additems is False:
                out.append("\tJSV_TUPLE_ADDITIONAL_FALSE")
            elif isinstance(additems, dict):
                out.append("\tJSV_TUPLE_ADDITIONAL(%s)" % self.fn(additems, root, memo))
            out.append("JSV_TUPLE_END")
        elif items is not None:
            raise GenError("items must be an object, array or boolean")

        # numeric bounds; the draft-4 boolean exclusive* modifier and the
        # draft-7 standalone numeric exclusive* are told apart by value type
        if is_num(schema.get("minimum")):
            macro = "JSV_MINIMUM_EXCLUSIVE" if schema.get("exclusiveMinimum") is True \
                else "JSV_MINIMUM"
            out.append("%s(%s);" % (macro, num_lit(schema["minimum"])))
        if is_num(schema.get("exclusiveMinimum")):
            out.append("JSV_MINIMUM_EXCLUSIVE(%s);" % num_lit(schema["exclusiveMinimum"]))
        if is_num(schema.get("maximum")):
            macro = "JSV_MAXIMUM_EXCLUSIVE" if schema.get("exclusiveMaximum") is True \
                else "JSV_MAXIMUM"
            out.append("%s(%s);" % (macro, num_lit(schema["maximum"])))
        if is_num(schema.get("exclusiveMaximum")):
            out.append("JSV_MAXIMUM_EXCLUSIVE(%s);" % num_lit(schema["exclusiveMaximum"]))

        # anyOf / allOf / oneOf
        if isinstance(schema.get("anyOf"), list):
            out.append("JSV_ANY_OF_BEGIN")
            for sub in schema["anyOf"]:
                out.append("\tJSV_ANY_OF_ALT(%s)" % self.fn(sub, root, memo))
            out.append("JSV_ANY_OF_END")
        if isinstance(schema.get("allOf"), list):
            for sub in schema["allOf"]:
                out.append("JSV_CHECK(%s);" % self.fn(sub, root, memo))
        if isinstance(schema.get("oneOf"), list):
            out.append("JSV_ONE_OF_BEGIN")
            for sub in schema["oneOf"]:
                out.append("\tJSV_ONE_OF_ALT(%s)" % self.fn(sub, root, memo))
            out.append("JSV_ONE_OF_END")

        if schema.get("uniqueItems") is True:
            out.append("JSV_UNIQUE_ITEMS();")

        # contains (draft 7)
        if "contains" in schema:
            c = schema["contains"]
            if not isinstance(c, (dict, bool)):
                raise GenError("contains must be a schema")
            out.append("JSV_CONTAINS(%s)" % self.fn(c, root, memo))

        if isinstance(schema.get("enum"), list):
            out.append("JSV_ENUM(%s);" % c_str(json_dump(schema["enum"])))

        if "const" in schema:
            out.append("JSV_CONST(%s);" % c_str(json_dump(schema["const"])))

        if is_num(schema.get("minLength")):
            out.append("JSV_MIN_LENGTH(%s);" % num_lit(schema["minLength"]))
        if is_num(schema.get("maxLength")):
            out.append("JSV_MAX_LENGTH(%s);" % num_lit(schema["maxLength"]))

        if "not" in schema and isinstance(schema["not"], (dict, bool)):
            out.append("JSV_NOT(%s);" % self.fn(schema["not"], root, memo))

        if is_num(schema.get("minProperties")):
            out.append("JSV_MIN_PROPERTIES(%s);" % num_lit(schema["minProperties"]))
        if is_num(schema.get("maxProperties")):
            out.append("JSV_MAX_PROPERTIES(%s);" % num_lit(schema["maxProperties"]))
        if is_num(schema.get("minItems")):
            out.append("JSV_MIN_ITEMS(%s);" % num_lit(schema["minItems"]))
        if is_num(schema.get("maxItems")):
            out.append("JSV_MAX_ITEMS(%s);" % num_lit(schema["maxItems"]))

        # dependencies: single key, key array, schema, or boolean schema
        deps = schema.get("dependencies")
        if isinstance(deps, dict):
            for k, dep in deps.items():
                kargs = (c_str(k), utf8_len(k))
                if isinstance(dep, str):
                    out.append("JSV_DEPENDENCY_KEY(%s, %d, %s, %d);"
                               % (kargs + (c_str(dep), utf8_len(dep))))
                elif isinstance(dep, list):
                    for d in dep:
                        if isinstance(d, str):
                            out.append("JSV_DEPENDENCY_KEY(%s, %d, %s, %d);"
                                       % (kargs + (c_str(d), utf8_len(d))))
                elif isinstance(dep, (dict, bool)):
                    out.append("JSV_DEPENDENCY_SCHEMA(%s, %d, %s);"
                               % (kargs + (self.fn(dep, root, memo),)))

        if isinstance(schema.get("pattern"), str):
            out.append("JSV_PATTERN(%s);" % c_str(schema["pattern"]))

        if is_num(schema.get("multipleOf")):
            out.append("JSV_MULTIPLE_OF(%s);" % num_lit(schema["multipleOf"]))

        return out

    # ---- validators ------------------------------------------------------

    def add_validator(self, name, schema, test=False):
        if not isinstance(name, str) or not name:
            raise GenError("validator name missing")
        if not all(c.islower() or c.isdigit() or c == "_" for c in name) \
                or not name.isascii():
            raise GenError("validator name must match [a-z0-9_]+: %r" % name)
        if name[0].isdigit():
            raise GenError("validator name must not start with a digit: %r" % name)
        if len(name) > 63:
            raise GenError("validator name too long: %r" % name)
        if any(name == n for n, _, _t in self.validators):
            raise GenError("duplicate validator name: %r" % name)
        memo = {}
        nid = self.node(schema, schema, memo)
        self.validators.append((name, nid, test))

    # ---- output ----------------------------------------------------------

    def c_source(self, source_file):
        parts = []
        parts.append("/*")
        parts.append(" * Generated by tools/generate_validators.py from %s." % source_file)
        parts.append(" * DO NOT EDIT: regenerate with `make`.")
        parts.append(" */")
        parts.append('#include "validator_macros.h"')
        parts.append("")
        parts.append("PG_MODULE_MAGIC;")
        parts.append("")
        parts.extend(self.decls)
        parts.append("")
        for body in self.bodies:
            parts.extend(body)
            parts.append("")
        for name, nid, _t in self.validators:
            parts.append("JSV_VALIDATOR(%s, jsv_node_%d)" % (name, nid))
        parts.append("")
        return "\n".join(parts)

    def sql_source(self):
        parts = []
        parts.append('\\echo Use "CREATE EXTENSION %s" to load this file. \\quit' % EXTENSION)
        parts.append("")
        for name, _, is_test in self.validators:
            if is_test:
                continue
            parts.append("CREATE FUNCTION %s (data jsonb)" % name)
            parts.append("RETURNS boolean")
            parts.append("AS 'MODULE_PATHNAME', '%s'" % name)
            parts.append("LANGUAGE C IMMUTABLE STRICT;")
            parts.append("")
        return "\n".join(parts)

    def test_sql_source(self):
        # pg_regress runs psql with -a -q: statements are echoed verbatim,
        # command tags are suppressed and blank input lines are not echoed.
        # Keeping this file free of blank lines makes the expected output
        # byte-identical to the input on every postgres version.
        parts = []
        parts.append("CREATE EXTENSION %s;" % EXTENSION)
        for name, _, is_test in self.validators:
            if not is_test:
                continue
            parts.append("CREATE FUNCTION %s (data jsonb)" % name)
            parts.append("RETURNS boolean")
            parts.append("AS '$libdir/%s', '%s'" % (EXTENSION, name))
            parts.append("LANGUAGE C IMMUTABLE STRICT;")
        return "\n".join(parts) + "\n"


def main():
    source = sys.argv[1] if len(sys.argv) > 1 else "validators.json"
    with open(source) as f:
        entries = json.load(f, parse_float=Decimal)
    if not isinstance(entries, list):
        raise GenError("%s must contain an array of {name, schema} objects" % source)

    import os
    gen = Generator()
    for entry in entries:
        if not isinstance(entry, dict) or "name" not in entry or "schema" not in entry:
            raise GenError("each entry must be an object with name and schema: %r" % (entry,))
        gen.add_validator(entry["name"], entry["schema"], test=bool(entry.get("test", False)))

    with open("%s.c" % EXTENSION, "w") as f:
        f.write(gen.c_source(source))
    with open("%s--%s.sql" % (EXTENSION, VERSION), "w") as f:
        f.write(gen.sql_source())
    test_sql = gen.test_sql_source()
    os.makedirs("sql", exist_ok=True)
    os.makedirs("expected", exist_ok=True)
    with open(os.path.join("sql", "%s_tests.sql" % EXTENSION), "w") as f:
        f.write(test_sql)
    # psql's echo of the file (no tags, no blank lines) IS the expected output
    with open(os.path.join("expected", "%s_tests.out" % EXTENSION), "w") as f:
        f.write(test_sql)
    test_count = sum(1 for _, _, t in gen.validators if t)
    print("generated %d validators (%d test), %d schema nodes"
          % (len(gen.validators), test_count, len(gen.bodies)))


if __name__ == "__main__":
    try:
        main()
    except GenError as e:
        print("generate_validators.py: error: %s" % e, file=sys.stderr)
        sys.exit(1)
