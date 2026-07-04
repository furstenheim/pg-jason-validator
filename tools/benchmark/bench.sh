#!/usr/bin/env bash
# Benchmark entry point, run inside the Docker image as the postgres user.
#
# Downloads the twitter dataset at run time, loads it into a scratch
# PostgreSQL instance and times four ways of validating every tweet against
# the same JSON schema (tools/benchmark/tweet-schema.json):
#
#   1. pg_jason_validator  - validate_tweet(data), schema compiled to C at build time
#   2. is_jsonb_valid      - is_jsonb_valid(schema, data), schema interpreted per row
#   3. pg_jsonschema       - jsonb_matches_schema(schema, data), schema compiled per row
#   4. pg_jsonschema/comp. - jsonb_matches_compiled_schema(schema::jsonschema, data),
#                            schema compiled once per query call site
set -euo pipefail

DATASET_GIT_URL="${DATASET_GIT_URL:-https://frosch.cosy.sbg.ac.at/datasets/json/twitter.git}"
DATASET_DIR="${DATASET_DIR:-}"   # set to a mounted directory of .json files to skip the download
SCALE="${SCALE:-1}"              # total copies of the dataset to load
RUNS="${RUNS:-5}"                # timed repetitions per implementation

PGDATA=/bench/pgdata
export PGHOST=/tmp PGDATABASE=bench

# the official postgres image has the server binaries on PATH; plain Debian
# installs keep them under /usr/lib/postgresql/<major>/bin
if ! command -v initdb >/dev/null 2>&1; then
    export PATH="/usr/lib/postgresql/${PG_MAJOR:-16}/bin:$PATH"
fi

if [ -z "$DATASET_DIR" ]; then
    echo "== downloading dataset from $DATASET_GIT_URL =="
    git clone --depth 1 "$DATASET_GIT_URL" /bench/dataset
    DATASET_DIR=/bench/dataset
fi
mapfile -t JSON_FILES < <(find "$DATASET_DIR" -name '*.json' -size +0 | sort)
if [ "${#JSON_FILES[@]}" -eq 0 ]; then
    echo "no .json files found in $DATASET_DIR" >&2
    exit 1
fi
echo "== dataset files: ${JSON_FILES[*]} =="

echo "== starting scratch postgres =="
initdb -D "$PGDATA" --auth=trust --no-sync >/dev/null
pg_ctl -D "$PGDATA" -l /bench/postgres.log -w -o "\
 -c listen_addresses='' \
 -c unix_socket_directories=$PGHOST \
 -c fsync=off -c full_page_writes=off -c synchronous_commit=off \
 -c shared_buffers=1GB \
 -c jit=off \
 -c max_parallel_workers_per_gather=0" start >/dev/null

createdb bench
psql -Xq -c "CREATE EXTENSION pg_jason_validator;" \
        -c "CREATE EXTENSION is_jsonb_valid;" \
        -c "CREATE EXTENSION pg_jsonschema;" \
        -c "CREATE TABLE tweets (data jsonb);"

echo "== loading tweets =="
python3 /usr/local/bin/load_tweets.py "${JSON_FILES[@]}" \
    | psql -Xq -c "COPY tweets (data) FROM STDIN"
if [ "$SCALE" -gt 1 ]; then
    psql -Xq -c "INSERT INTO tweets
                 SELECT t.data FROM (SELECT data FROM tweets) t, generate_series(2, $SCALE)"
fi
psql -Xq -c "VACUUM ANALYZE tweets"
ROWS=$(psql -XqAt -c "SELECT count(*) FROM tweets")
echo "== $ROWS tweets loaded (scale $SCALE) =="

SCHEMA=$(cat /bench/tweet-schema.json)
Q="\$tweet_schema\$${SCHEMA}\$tweet_schema\$"

LABELS=(
    "pg_jason_validator (compile-time C)"
    "is_jsonb_valid (schema per row)"
    "pg_jsonschema (schema per row)"
    "pg_jsonschema (compiled schema)"
)
QUERIES=(
    "SELECT count(*) FILTER (WHERE validate_tweet(data)) FROM tweets"
    "SELECT count(*) FILTER (WHERE is_jsonb_valid(${Q}::jsonb, data)) FROM tweets"
    "SELECT count(*) FILTER (WHERE jsonb_matches_schema(${Q}::json, data)) FROM tweets"
    "SELECT count(*) FILTER (WHERE jsonb_matches_compiled_schema(${Q}::jsonschema, data)) FROM tweets"
)

run_ms() {
    # execution time in ms of one run of $1
    psql -XqAt -c '\timing on' -c "$1" | sed -n 's/^Time: \([0-9.]*\) ms.*/\1/p' | tail -1
}

echo
echo "== benchmark: $RUNS timed runs each, after one warmup =="
printf '%-38s %13s %12s %12s %10s\n' implementation valid/total "min ms" "median ms" rows/s
RESULTS=()
for i in "${!QUERIES[@]}"; do
    sql=${QUERIES[$i]}
    valid=$(psql -XqAt -c "$sql")   # warmup + semantics check
    times=()
    for _ in $(seq "$RUNS"); do
        times+=("$(run_ms "$sql")")
    done
    stats=$(printf '%s\n' "${times[@]}" | python3 -c '
import sys
t = sorted(float(x) for x in sys.stdin)
median = t[len(t)//2] if len(t) % 2 else (t[len(t)//2 - 1] + t[len(t)//2]) / 2
print("%.1f %.1f" % (t[0], median))')
    read -r tmin tmedian <<<"$stats"
    rate=$(python3 -c "print('%d' % ($ROWS / ($tmedian / 1000.0)))")
    printf '%-38s %13s %12s %12s %10s\n' "${LABELS[$i]}" "$valid/$ROWS" "$tmin" "$tmedian" "$rate"
done
echo
echo "(valid/total differs slightly between implementations where their"
echo " JSON-Schema semantics differ; large gaps would mean the comparison"
echo " is not validating equivalent work)"

pg_ctl -D "$PGDATA" stop >/dev/null
