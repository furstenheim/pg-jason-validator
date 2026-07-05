# Benchmark image: PostgreSQL 16 with the four validators installed.
# Build from the repository root:
#   docker build -f tools/benchmark/Dockerfile -t pg_jason_validator_bench .
#
# validate_tweet() is NOT built here: the container entry point downloads
# the dataset, identifies its schema and compiles the validator from it at
# run time, so the image only carries the extension sources and toolchain.
FROM postgres:16-bookworm

ARG PG_JSONSCHEMA_VERSION=0.3.4

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        postgresql-server-dev-$PG_MAJOR \
        git \
        curl \
        ca-certificates \
        python3 \
    && rm -rf /var/lib/apt/lists/*

# pg_jsonschema: prebuilt release package
RUN arch="$(dpkg --print-architecture)" \
    && curl -fsSL -o /tmp/pg_jsonschema.deb \
        "https://github.com/supabase/pg_jsonschema/releases/download/v${PG_JSONSCHEMA_VERSION}/pg_jsonschema-v${PG_JSONSCHEMA_VERSION}-pg${PG_MAJOR}-${arch}-linux-gnu.deb" \
    && dpkg -i /tmp/pg_jsonschema.deb \
    && rm /tmp/pg_jsonschema.deb

# is_jsonb_valid: the runtime-schema reference implementation
RUN git clone --depth 1 https://github.com/furstenheim/is_jsonb_valid /tmp/is_jsonb_valid \
    && make -C /tmp/is_jsonb_valid install with_llvm=no \
    && rm -rf /tmp/is_jsonb_valid

# pg_jason_validator sources; compiled by entrypoint.sh once the schema of
# the downloaded dataset is known
COPY Makefile pg_jason_validator.control validator_macros.h /opt/pg_jason_validator/
COPY tools/generate_validators.py /opt/pg_jason_validator/tools/

COPY tools/benchmark/load_tweets.py /usr/local/bin/load_tweets.py
COPY tools/benchmark/infer_schema.py /usr/local/bin/infer_schema.py
COPY tools/benchmark/bench.sh /usr/local/bin/bench.sh
COPY tools/benchmark/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/bench.sh /usr/local/bin/entrypoint.sh \
    && mkdir -p /bench && chown postgres:postgres /bench

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
