# Validator benchmark

Times four ways of validating tweets against the same JSON schema
([`tweet-schema.json`](tweet-schema.json)), inside Docker, on the
[frosch twitter dataset](https://frosch.cosy.sbg.ac.at/datasets/json/twitter)
(downloaded when the benchmark runs — the data is not part of this
repository):

| implementation | what happens per row |
| --- | --- |
| `pg_jason_validator` `validate_tweet(data)` | nothing schema-related: the schema was compiled to C when the image was built |
| [`is_jsonb_valid`](https://github.com/furstenheim/is_jsonb_valid) `is_jsonb_valid(schema, data)` | the schema jsonb is re-interpreted on every row |
| [`pg_jsonschema`](https://github.com/supabase/pg_jsonschema) `jsonb_matches_schema(schema, data)` | the schema is re-compiled by the jsonschema crate on every row |
| `pg_jsonschema` `jsonb_matches_compiled_schema(schema::jsonschema, data)` | "compile mode": the cast compiles the schema once per query call site, rows reuse the cached validator |

## Run

Requires Docker. From anywhere in the repository:

```sh
tools/benchmark/run.sh
```

This builds the image (installing `pg_jsonschema` from its released `.deb`,
building `is_jsonb_valid` from GitHub and `pg_jason_validator` from this
checkout with a single generated `validate_tweet` function) and then runs the
benchmark: clone the dataset, load every tweet into a `tweets(data jsonb)`
table in a scratch PostgreSQL 16, and time
`SELECT count(*) FILTER (WHERE <validate>(...)) FROM tweets` for each
implementation — one warmup pass, then `RUNS` timed repetitions, reporting
min/median and rows per second. The warmup pass also prints each
implementation's `valid/total` so you can see the four validators agree on
the dataset.

Tunables (environment variables, see `run.sh`):

```sh
RUNS=10 SCALE=5 tools/benchmark/run.sh   # 5 copies of the dataset, 10 timed runs
DATASET_CACHE=~/twitter-checkout tools/benchmark/run.sh   # skip the download
DATASET_GIT_URL=https://... tools/benchmark/run.sh        # different dataset
```

The scratch server is tuned for benchmarking, not durability: `fsync=off`,
`jit=off` and `max_parallel_workers_per_gather=0` (single-process scans, so
row-validation cost is what dominates the timing).

## The schema

`tweet-schema.json` is the
[tweet schema from is_jsonb_valid](https://github.com/furstenheim/is_jsonb_valid/blob/master/tools/tweet-schema.json)
with a light update:

* pinned to draft-07 via `$schema` (pg_jsonschema otherwise assumes the
  latest draft);
* `maxLength: 2` on the geo coordinates array was a typo for `maxItems: 2`;
* removed `additionalItems` where `items` is a single schema (meaningless in
  every draft) and the `additionalProperties: false` markers, so tweets with
  fields added to the Twitter API after the schema was written still
  validate — otherwise every implementation would short-circuit on the first
  unknown field and the benchmark would measure nothing;
* `follow_request_sent` / `following` / `notifications` accept `boolean` as
  well as `null` (they were always-null in the old streaming API).
