# pg_jason_validator

Compile-time generated JSON schema validators for PostgreSQL `jsonb`.

This extension is a rethink of
[is_jsonb_valid](https://github.com/furstenheim/is_jsonb_valid). That
extension validates a `jsonb` document against a schema passed at run time,
which means every call re-inspects the schema: is `items` a tuple or a single
schema? is `additionalProperties` a boolean or an object? where does this
`$ref` point? Those conditionals depend only on the schema, and schemas are
usually static.

`pg_jason_validator` moves all of that to build time:

* `validator_macros.h` contains a **family of C macros**, one per validator
  kind (`JSV_TYPE_*`, `JSV_MINIMUM`, `JSV_PROP`, `JSV_TUPLE_ITEM`,
  `JSV_ENUM`, `JSV_CONTAINS`, ...). Each macro only performs the
  data-dependent part of a keyword's check.
* `validators.json` declares the validators you want, as an array of
  `{"name": ..., "schema": ...}` entries. `name` (matching `[a-z0-9_]+`, not
  starting with a digit) becomes the SQL function name; `schema` is a JSON
  schema (draft 4 / draft 7 keywords, see below).
* `make` runs `tools/generate_validators.py`, which **deterministically**
  compiles the schemas into C: one static node function per schema node,
  written purely with the macros, plus one SQL-callable function per entry.
  Schema-shape decisions — including resolving every `$ref` — happen in the
  generator; malformed schemas fail the build, not the query.

The resulting SQL functions take a **single parameter**, the `jsonb` value to
validate:

```sql
CREATE EXTENSION pg_jason_validator;
SELECT my_validator('{"foo": 1}');
```

## Declaring validators

```json
[
  {"name": "point", "schema": {
    "type": "object",
    "properties": {"x": {"type": "number"}, "y": {"type": "number"}},
    "required": ["x", "y"],
    "additionalProperties": false
  }}
]
```

Rebuild and reinstall after editing `validators.json`:

```sh
make && make install && make installcheck
```

## Build

```sh
make            # generates pg_jason_validator.c + the extension SQL, compiles
make install
make installcheck
```

The generator needs `python3` (standard library only) and the output is a
pure function of `validators.json` — byte-identical across runs.

## Semantics

Validation behaviour intentionally replicates `is_jsonb_valid`, quirks
included; the whole regression suite of that extension runs against this one
(each distinct schema in those tests became one generated function — tests
sharing a schema share the function). Draft 4 and draft 7 spellings are
disambiguated by value type where they conflict (e.g. a boolean
`exclusiveMinimum` is the draft 4 modifier, a number is the draft 7 bound).

Differences that follow from the compile-time model:

* The schema is not a run-time argument, so tests of `NULL`/malformed
  schemas do not translate: the generator rejects malformed schemas at build
  time instead.
* `$ref` is resolved by the generator (root-anchored references, same rule
  as `is_jsonb_valid`); recursive schemas become mutually recursive C
  functions. A reference the original implementation would only reject when
  evaluated (e.g. a remote URL) is compiled into a node that raises the same
  error if it is ever reached.

## Layout

* `validator_macros.h` — macro family + static inline runtime helpers.
* `validators.json` — validator declarations (source of truth).
* `tools/generate_validators.py` — the code generator run by `make`.
* `tools/import_tests.py` — one-time importer that produced
  `validators.json`, `sql/` and `expected/` from an `is_jsonb_valid`
  checkout.
* `sql/`, `expected/` — pg_regress suite (adapted from `is_jsonb_valid`;
  every result was cross-checked against the reference implementation's
  expected outputs).

## Benchmark

`tools/benchmark/` contains a Docker-based benchmark that validates the
[frosch twitter dataset](https://frosch.cosy.sbg.ac.at/datasets/json/twitter)
(downloaded at run time) with a generated function from this extension,
`is_jsonb_valid`, and `pg_jsonschema` in both its per-row and compiled-schema
modes. See [tools/benchmark/README.md](tools/benchmark/README.md).

## CI

Same setup as `is_jsonb_valid`: the pgxn-tools container builds and runs the
regression suite against PostgreSQL 9.6 through 19.
