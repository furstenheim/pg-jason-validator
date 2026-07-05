#!/usr/bin/env bash
# Build and run the validator benchmark. Usage, from anywhere in the repo:
#   tools/benchmark/run.sh
#
# Tunables (exported env vars, all optional):
#   RUNS=5            timed repetitions per implementation
#   SCALE=1           total copies of the dataset to load
#   DATASET_GIT_URL   where to clone the tweets from (default: the frosch
#                     datasets/json/twitter repository)
#   DATASET_CACHE     host directory with an existing checkout; mounted into
#                     the container to skip the download
#   SCHEMA_CACHE      host JSON-schema file to use instead of identifying
#                     the schema from the dataset
set -euo pipefail

cd "$(dirname "$0")/../.."

docker build -f tools/benchmark/Dockerfile -t pg_jason_validator_bench .

docker_args=(--rm --shm-size=1g -e RUNS -e SCALE -e DATASET_GIT_URL)
if [ -n "${DATASET_CACHE:-}" ]; then
    docker_args+=(-v "$(cd "$DATASET_CACHE" && pwd)":/bench/dataset:ro -e DATASET_DIR=/bench/dataset)
fi
if [ -n "${SCHEMA_CACHE:-}" ]; then
    docker_args+=(-v "$(realpath "$SCHEMA_CACHE")":/bench/schema.json:ro -e SCHEMA_FILE=/bench/schema.json)
fi

exec docker run "${docker_args[@]}" pg_jason_validator_bench
