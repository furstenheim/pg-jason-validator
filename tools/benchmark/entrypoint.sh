#!/usr/bin/env bash
# Container entry point (runs as root):
#   1. download the tweet dataset (unless a mounted DATASET_DIR is given)
#   2. identify the JSON schema of the dataset (unless SCHEMA_FILE is given)
#   3. compile that schema into pg_jason_validator's validate_tweet()
#   4. hand over to bench.sh as the postgres user
set -euo pipefail

DATASET_GIT_URL="${DATASET_GIT_URL:-https://frosch.cosy.sbg.ac.at/datasets/json/twitter.git}"
export DATASET_DIR="${DATASET_DIR:-}"

if [ -z "$DATASET_DIR" ]; then
    echo "== downloading dataset from $DATASET_GIT_URL =="
    # the dataset host is occasionally unreachable; retry with backoff
    attempt=1
    until git clone --depth 1 "$DATASET_GIT_URL" /bench/dataset; do
        if [ "$attempt" -ge 4 ]; then
            echo "failed to clone $DATASET_GIT_URL after $attempt attempts" >&2
            exit 1
        fi
        rm -rf /bench/dataset
        sleep $((30 * attempt))
        attempt=$((attempt + 1))
        echo "== retrying download (attempt $attempt) =="
    done
    export DATASET_DIR=/bench/dataset
fi
mapfile -t JSON_FILES < <(find "$DATASET_DIR" -name '*.json' -size +0 | sort)
if [ "${#JSON_FILES[@]}" -eq 0 ]; then
    echo "no .json files found in $DATASET_DIR" >&2
    exit 1
fi
ls -l "${JSON_FILES[@]}"

if [ -n "${SCHEMA_FILE:-}" ]; then
    echo "== using provided schema $SCHEMA_FILE =="
    cp "$SCHEMA_FILE" /bench/tweet-schema.json
else
    echo "== identifying dataset schema =="
    python3 /usr/local/bin/infer_schema.py "${JSON_FILES[@]}" > /bench/tweet-schema.json
fi

echo "== compiling validate_tweet from the schema =="
cd /opt/pg_jason_validator
python3 - <<'PY'
import json
schema = json.load(open("/bench/tweet-schema.json"))
json.dump([{"name": "validate_tweet", "schema": schema}], open("validators.json", "w"))
PY
make with_llvm=no >/dev/null
make install with_llvm=no >/dev/null

# non-recursive: DATASET_DIR may be a read-only mount
chown postgres:postgres /bench /bench/tweet-schema.json
exec gosu postgres /usr/local/bin/bench.sh
