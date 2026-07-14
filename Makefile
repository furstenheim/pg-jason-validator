EXTENSION = pg_jason_validator
EXTVERSION = 0.1.0
DATA = pg_jason_validator--$(EXTVERSION).sql
MODULES = pg_jason_validator
REGRESS = pg_jason_validator_tests pg_jason_validator_test additionalItems additionalItems.v7 additionalProperties additionalProperties.v7 allOf allOf.v7 anyOf anyOf.v7 boolean.v7 const.v7 contains.v7 default default.v7 dependencies dependencies.v7 enum enum.v7 exclusiveMaximum.v7 exclusiveMinimum.v7 id id.v7 if.v7 infinite infinite.v7 items items.v7 maximum maximum.v7 maxItems maxItems.v7 maxLength maxLength.v7 maxProperties maxProperties.v7 minimum minimum.v7 minItems minItems.v7 minLength minLength.v7 minProperties minProperties.v7 multipleOf multipleOf.v7 not not.v7 oneOf oneOf.v7 pattern pattern.v7 patternProperties patternProperties.v7 properties properties.v7 propertyNames.v7 ref ref.v7 required required.v7 type type.v7 uniqueItems uniqueItems.v7

GENERATED = pg_jason_validator.c pg_jason_validator--$(EXTVERSION).sql sql/pg_jason_validator_tests.sql expected/pg_jason_validator_tests.out
EXTRA_CLEAN = $(GENERATED)

PYTHON ?= python3

# postgres stuff
PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

# All validator functions are generated from validators.json before anything
# is compiled: the schemas are static, so every schema-shape decision is made
# by the generator and the C compiler, never at run time. (The generator is
# deterministic and emits both files, so running it for either target is
# idempotent.)
pg_jason_validator.c: validators.json tools/generate_validators.py validator_macros.h
	$(PYTHON) tools/generate_validators.py validators.json

pg_jason_validator--$(EXTVERSION).sql: validators.json tools/generate_validators.py validator_macros.h
	$(PYTHON) tools/generate_validators.py validators.json

sql/pg_jason_validator_tests.sql expected/pg_jason_validator_tests.out: validators.json tools/generate_validators.py validator_macros.h
	$(PYTHON) tools/generate_validators.py validators.json

all: $(GENERATED)
