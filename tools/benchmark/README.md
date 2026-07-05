# Validator benchmark

Times four ways of validating tweets against the same JSON schema, inside
Docker, on the
[frosch twitter dataset](https://frosch.cosy.sbg.ac.at/datasets/json/twitter)
(downloaded when the benchmark runs — the data is not part of this
repository):

| implementation | what happens per row |
| --- | --- |
| `pg_jason_validator` `validate_tweet(data)` | nothing schema-related: the schema was compiled to C before the run |
| [`is_jsonb_valid`](https://github.com/furstenheim/is_jsonb_valid) `is_jsonb_valid(schema, data)` | the schema jsonb is re-interpreted on every row |
| [`pg_jsonschema`](https://github.com/supabase/pg_jsonschema) `jsonb_matches_schema(schema, data)` | the schema is re-compiled by the jsonschema crate on every row |
| `pg_jsonschema` `jsonb_matches_compiled_schema(schema::jsonschema, data)` | "compile mode": the cast compiles the schema once per query call site, rows reuse the cached validator |

## The schema is identified from the data

There is no hand-written tweet schema. After downloading the dataset, the
container runs [`infer_schema.py`](infer_schema.py), which derives a strict
draft-07 schema from the tweets themselves: every object path lists exactly
the properties observed there with **`additionalProperties: false`**,
properties present in every instance are `required`, scalar types are the
observed unions (`integer` only when no fractional value ever appeared), and
array item schemas are the merge of all observed elements.

Because the schema is exact rather than hand-relaxed, all four validators
have to do the full strict traversal — and every tweet should validate, so
the reported `valid/total` doubles as a semantics-agreement check between
the implementations.

`validate_tweet()` is then compiled from that schema *inside the container*
(the image ships the extension sources and toolchain), which is the same
`validators.json → make` flow a user of the extension would run.

## Run

Requires Docker. From anywhere in the repository:

```sh
tools/benchmark/run.sh
```

This builds the image (installing `pg_jsonschema` from its released `.deb`
and building `is_jsonb_valid` from GitHub), then runs it: clone the dataset,
identify the schema, compile `validate_tweet`, load every tweet into a
`tweets(data jsonb)` table in a scratch PostgreSQL 16, and time
`SELECT count(*) FILTER (WHERE <validate>(...)) FROM tweets` per
implementation — one warmup pass, then `RUNS` timed repetitions, reporting
min/median and rows per second.

Tunables (environment variables, see `run.sh`):

```sh
RUNS=10 SCALE=5 tools/benchmark/run.sh    # 5 copies of the dataset, 10 timed runs
DATASET_CACHE=~/twitter-checkout tools/benchmark/run.sh   # skip the download
SCHEMA_CACHE=my-schema.json tools/benchmark/run.sh        # pin a schema instead of inferring
DATASET_GIT_URL=https://... tools/benchmark/run.sh        # different dataset
```

There is also a manually triggered GitHub Action
(`.github/workflows/benchmark.yml`, "Run workflow" in the Actions tab) that
executes the same benchmark on a hosted runner.

The scratch server is tuned for benchmarking, not durability: `fsync=off`,
`jit=off` and `max_parallel_workers_per_gather=0` (single-process scans, so
row-validation cost is what dominates the timing).
