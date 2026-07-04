# Benchmark image: PostgreSQL 16 with the four validators installed.
# Build from the repository root:
#   docker build -f tools/benchmark/Dockerfile -t pg_jason_validator_bench .
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
    && make -C /tmp/is_jsonb_valid install \
    && rm -rf /tmp/is_jsonb_valid

# pg_jason_validator, built with a single validator (validate_tweet)
# generated from the benchmark tweet schema
COPY Makefile pg_jason_validator.control validator_macros.h /tmp/pg_jason_validator/
COPY tools/generate_validators.py /tmp/pg_jason_validator/tools/
COPY tools/benchmark/tweet-schema.json /tmp/pg_jason_validator/
RUN cd /tmp/pg_jason_validator \
    && python3 -c "import json; \
        schema = json.load(open('tweet-schema.json')); \
        json.dump([{'name': 'validate_tweet', 'schema': schema}], open('validators.json', 'w'))" \
    && make install \
    && rm -rf /tmp/pg_jason_validator

COPY tools/benchmark/load_tweets.py /usr/local/bin/load_tweets.py
COPY tools/benchmark/bench.sh /usr/local/bin/bench.sh
COPY tools/benchmark/tweet-schema.json /bench/tweet-schema.json
RUN chmod +x /usr/local/bin/bench.sh && chown -R postgres:postgres /bench

USER postgres
ENTRYPOINT ["/usr/local/bin/bench.sh"]
