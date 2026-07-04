/*
 * validator_macros.h
 *
 * Family of compile-time specialized JSON-schema validator macros.
 *
 * The code generator (tools/generate_validators.py) reads validators.json and
 * emits one static "node" function per schema node, whose body is a straight
 * sequence of these macros. All decisions that depend on the *shape* of the
 * schema (which keywords are present, whether "items" is a tuple or a single
 * schema, whether "additionalProperties" is false, where a "$ref" points, ...)
 * are taken by the generator, so at runtime only the data-dependent work is
 * left.
 *
 * Every macro operates on the local variable `data` (a non-NULL Jsonb *), the
 * single argument of the generated node function, and either falls through
 * (keyword satisfied or not applicable to the data's type) or executes
 * `return false`.
 *
 * The runtime semantics deliberately replicate the is_jsonb_valid extension
 * (https://github.com/furstenheim/is_jsonb_valid), draft 4 and draft 7
 * behaviour combined; keywords whose meaning differs between drafts are
 * disambiguated by the generator from the JSON type of their value.
 */
#ifndef VALIDATOR_MACROS_H
#define VALIDATOR_MACROS_H

#include "postgres.h"
#include "fmgr.h"
#include <limits.h>
#include "catalog/pg_collation.h"
#include "utils/builtins.h"
#if PG_VERSION_NUM >= 100000
#include "utils/fmgrprotos.h"
#endif
#include "utils/jsonb.h"
#include "utils/memutils.h"
#include "utils/numeric.h"

/* PostgreSQL 9.6 spells DatumGetJsonbP/PG_GETARG_JSONB_P without the P */
#ifndef PG_GETARG_JSONB_P
#define DatumGetJsonbP(d) DatumGetJsonb(d)
#endif

typedef enum JsvType
{
	JSV_T_OBJECT,
	JSV_T_ARRAY,
	JSV_T_NULL,
	JSV_T_STRING,
	JSV_T_NUMBER,
	JSV_T_INTEGER,
	JSV_T_BOOLEAN
} JsvType;

/*
 * Scalar jsonb values are stored as one-element pseudo arrays, so a real
 * array is an array root that is not marked scalar.
 */
static inline bool
jsv_is_array(Jsonb *jb)
{
	return JB_ROOT_IS_ARRAY(jb) && !JB_ROOT_IS_SCALAR(jb);
}

static inline void
jsv_get_scalar(Jsonb *jb, JsonbValue *out)
{
	JsonbIterator *it = JsonbIteratorInit(&jb->root);
	JsonbValue	wrapper;

	(void) JsonbIteratorNext(&it, &wrapper, true);
	Assert(wrapper.type == jbvArray);
	(void) JsonbIteratorNext(&it, out, true);
}

static inline bool
jsv_numeric_scalar(Jsonb *jb, JsonbValue *out)
{
	if (!JB_ROOT_IS_SCALAR(jb))
		return false;
	jsv_get_scalar(jb, out);
	return out->type == jbvNumeric;
}

static inline bool
jsv_string_scalar(Jsonb *jb, JsonbValue *out)
{
	if (!JB_ROOT_IS_SCALAR(jb))
		return false;
	jsv_get_scalar(jb, out);
	return out->type == jbvString;
}

static inline bool
jsv_numeric_is_integer(Numeric n)
{
	return DatumGetBool(DirectFunctionCall2(
							numeric_eq,
							NumericGetDatum(n),
							DirectFunctionCall1(numeric_floor, NumericGetDatum(n))));
}

static inline bool
jsv_has_type(Jsonb *jb, JsvType t)
{
	JsonbValue	v;

	if (JB_ROOT_IS_OBJECT(jb))
		return t == JSV_T_OBJECT;
	if (jsv_is_array(jb))
		return t == JSV_T_ARRAY;
	jsv_get_scalar(jb, &v);
	switch (v.type)
	{
		case jbvNull:
			return t == JSV_T_NULL;
		case jbvString:
			return t == JSV_T_STRING;
		case jbvNumeric:
			if (t == JSV_T_NUMBER)
				return true;
			if (t == JSV_T_INTEGER)
				return jsv_numeric_is_integer(v.val.numeric);
			return false;
		case jbvBool:
			return t == JSV_T_BOOLEAN;
		default:
			elog(ERROR, "unknown jsonb scalar type");
			return false;
	}
}

/*
 * Constants coming from the (static) schema are parsed once per backend and
 * cached in TopMemoryContext; each macro expansion owns its cache slot
 * through a function-local static variable.
 */
static inline Numeric
jsv_static_numeric(Numeric *cache, const char *lit)
{
	if (*cache == NULL)
	{
		MemoryContext oldctx = MemoryContextSwitchTo(TopMemoryContext);

		*cache = DatumGetNumeric(DirectFunctionCall3(numeric_in,
													 CStringGetDatum(lit),
													 ObjectIdGetDatum(InvalidOid),
													 Int32GetDatum(-1)));
		MemoryContextSwitchTo(oldctx);
	}
	return *cache;
}

static inline text *
jsv_static_text(text **cache, const char *lit)
{
	if (*cache == NULL)
	{
		MemoryContext oldctx = MemoryContextSwitchTo(TopMemoryContext);

		*cache = cstring_to_text(lit);
		MemoryContextSwitchTo(oldctx);
	}
	return *cache;
}

static inline Jsonb *
jsv_static_jsonb(Jsonb **cache, const char *lit)
{
	if (*cache == NULL)
	{
		MemoryContext oldctx = MemoryContextSwitchTo(TopMemoryContext);

		*cache = DatumGetJsonbP(DirectFunctionCall1(jsonb_in, CStringGetDatum(lit)));
		MemoryContextSwitchTo(oldctx);
	}
	return *cache;
}

static inline int
jsv_num_cmp(Numeric a, Numeric b)
{
	return DatumGetInt32(DirectFunctionCall2(numeric_cmp,
											 NumericGetDatum(a),
											 NumericGetDatum(b)));
}

static inline int
jsv_int_num_cmp(int a, Numeric b)
{
	return DatumGetInt32(DirectFunctionCall2(numeric_cmp,
											 DirectFunctionCall1(int4_numeric, Int32GetDatum(a)),
											 NumericGetDatum(b)));
}

static inline bool
jsv_multiple_of(Numeric value, Numeric divisor)
{
	Datum		quotient = DirectFunctionCall2(numeric_div,
											   NumericGetDatum(value),
											   NumericGetDatum(divisor));

	return DatumGetBool(DirectFunctionCall2(
							numeric_eq,
							quotient,
							DirectFunctionCall1(numeric_floor, quotient)));
}

static inline Jsonb *
jsv_value_to_jsonb(JsonbValue *v)
{
	return JsonbValueToJsonb(v);
}

static inline bool
jsv_key_eq(JsonbValue *k, const char *key, int len)
{
	Assert(k->type == jbvString);
	return k->val.string.len == len && memcmp(k->val.string.val, key, len) == 0;
}

static inline bool
jsv_regex_match(const char *s, int len, text *regex)
{
	return DatumGetBool(DirectFunctionCall2Coll(
							textregexeq,
							DEFAULT_COLLATION_OID,
							PointerGetDatum(cstring_to_text_with_len(s, len)),
							PointerGetDatum(regex)));
}

/* Character (not byte) length of a jsonb string scalar */
static inline int
jsv_char_length(JsonbValue *str)
{
	return DatumGetInt32(DirectFunctionCall1(
							 textlen,
							 PointerGetDatum(cstring_to_text_with_len(str->val.string.val,
																	  str->val.string.len))));
}

static inline bool
jsv_has_key(Jsonb *jb, const char *key, int len)
{
	JsonbValue	k;

	k.type = jbvString;
	/* not modified by the lookup; plain cast keeps pre-12 servers happy */
	k.val.string.val = (char *) key;
	k.val.string.len = len;
	return findJsonbValueFromContainer(&jb->root, JB_FOBJECT, &k) != NULL;
}

static inline bool
jsv_jsonb_eq(Jsonb *a, Jsonb *b)
{
	return compareJsonbContainers(&a->root, &b->root) == 0;
}

static inline bool
jsv_enum_contains(Jsonb *enumJb, Jsonb *data)
{
	JsonbIterator *it;
	JsonbValue	v;
	JsonbIteratorToken r;

	it = JsonbIteratorInit(&enumJb->root);
	r = JsonbIteratorNext(&it, &v, true);
	Assert(r == WJB_BEGIN_ARRAY);
	(void) r;
	while ((r = JsonbIteratorNext(&it, &v, true)) != WJB_END_ARRAY)
	{
		if (jsv_jsonb_eq(jsv_value_to_jsonb(&v), data))
			return true;
	}
	return false;
}

static inline int
jsv_num_items(Jsonb *jb)
{
	JsonbIterator *it = JsonbIteratorInit(&jb->root);
	JsonbValue	v;
	JsonbIteratorToken r;

	r = JsonbIteratorNext(&it, &v, true);
	Assert(r == WJB_BEGIN_ARRAY);
	(void) r;
	Assert(v.type == jbvArray);
	return v.val.array.nElems;
}

static inline int
jsv_num_properties(Jsonb *jb)
{
	JsonbIterator *it = JsonbIteratorInit(&jb->root);
	JsonbValue	v;
	JsonbIteratorToken r;

	r = JsonbIteratorNext(&it, &v, true);
	Assert(r == WJB_BEGIN_OBJECT);
	(void) r;
	Assert(v.type == jbvObject);
	return v.val.object.nPairs;
}

/* Quadratic pairwise comparison, same approach as is_jsonb_valid */
static inline bool
jsv_unique_items_ok(Jsonb *jb)
{
	JsonbIterator *it;
	JsonbValue	v;
	JsonbIteratorToken r;
	int			i = 0;

	it = JsonbIteratorInit(&jb->root);
	r = JsonbIteratorNext(&it, &v, true);
	Assert(r == WJB_BEGIN_ARRAY);
	(void) r;
	while ((r = JsonbIteratorNext(&it, &v, true)) != WJB_END_ARRAY)
	{
		Jsonb	   *item = jsv_value_to_jsonb(&v);
		JsonbIterator *it2;
		JsonbValue	v2;
		JsonbIteratorToken r2;
		int			j = 0;

		i++;
		it2 = JsonbIteratorInit(&jb->root);
		r2 = JsonbIteratorNext(&it2, &v2, true);
		Assert(r2 == WJB_BEGIN_ARRAY);
		(void) r2;
		while (j < i - 1 && (r2 = JsonbIteratorNext(&it2, &v2, true)) != WJB_END_ARRAY)
		{
			j++;
			if (jsv_jsonb_eq(item, jsv_value_to_jsonb(&v2)))
				return false;
		}
	}
	return true;
}

/* ------------------------------------------------------------------------
 * Node function scaffolding
 * ------------------------------------------------------------------------ */

#define JSV_NODE_DECLARE(id) static bool jsv_node_##id(Jsonb *data)

#define JSV_NODE_BEGIN(id) \
	JSV_NODE_DECLARE(id) \
	{

#define JSV_NODE_END \
		return true; \
	}

/* Body of a `false` boolean schema */
#define JSV_FAIL() return false

/*
 * Body of a schema the reference implementation only rejects when it is
 * actually evaluated (e.g. a $ref that is not anchored at the root). The
 * generator emits this instead of failing the build so that schemas whose
 * invalid branches are unreachable keep working exactly like is_jsonb_valid.
 */
#define JSV_ERROR(msg) \
	ereport(ERROR, \
			(errcode(ERRCODE_INVALID_PARAMETER_VALUE), errmsg("%s", msg)))

/* Validate against another node (allOf members, $ref targets, ...) */
#define JSV_CHECK(fn) \
	do { \
		if (!fn(data)) \
			return false; \
	} while (0)

/* SQL-callable entry point: one jsonb argument, boolean result */
#ifdef PG_GETARG_JSONB_P
#define JSV_GETARG_JSONB(n) PG_GETARG_JSONB_P(n)
#else
#define JSV_GETARG_JSONB(n) PG_GETARG_JSONB(n)
#endif

#define JSV_VALIDATOR(name, rootfn) \
	PG_FUNCTION_INFO_V1(name); \
	Datum \
	name(PG_FUNCTION_ARGS) \
	{ \
		Jsonb	   *jsv_data = JSV_GETARG_JSONB(0); \
		PG_RETURN_BOOL(rootfn(jsv_data)); \
	}

/* ------------------------------------------------------------------------
 * "type"
 * ------------------------------------------------------------------------ */

#define JSV_TYPE_BEGIN \
	{ \
		bool		jsv_type_ok = false;

#define JSV_TYPE_ALT(t) \
		jsv_type_ok = jsv_type_ok || jsv_has_type(data, t);

/* draft-4 allows full schemas as members of a "type" array */
#define JSV_TYPE_ALT_SCHEMA(fn) \
		jsv_type_ok = jsv_type_ok || fn(data);

#define JSV_TYPE_END \
		if (!jsv_type_ok) \
			return false; \
	}

/* ------------------------------------------------------------------------
 * Numeric keywords (apply only when the data is a number)
 * ------------------------------------------------------------------------ */

#define JSV_NUMERIC_KEYWORD(lit, op) \
	do { \
		JsonbValue	jsv_num; \
		if (jsv_numeric_scalar(data, &jsv_num)) \
		{ \
			static Numeric jsv_limit = NULL; \
			if (jsv_num_cmp(jsv_num.val.numeric, jsv_static_numeric(&jsv_limit, lit)) op 0) \
				return false; \
		} \
	} while (0)

#define JSV_MINIMUM(lit)			JSV_NUMERIC_KEYWORD(lit, <)
#define JSV_MINIMUM_EXCLUSIVE(lit)	JSV_NUMERIC_KEYWORD(lit, <=)
#define JSV_MAXIMUM(lit)			JSV_NUMERIC_KEYWORD(lit, >)
#define JSV_MAXIMUM_EXCLUSIVE(lit)	JSV_NUMERIC_KEYWORD(lit, >=)

#define JSV_MULTIPLE_OF(lit) \
	do { \
		JsonbValue	jsv_num; \
		if (jsv_numeric_scalar(data, &jsv_num)) \
		{ \
			static Numeric jsv_divisor = NULL; \
			if (!jsv_multiple_of(jsv_num.val.numeric, jsv_static_numeric(&jsv_divisor, lit))) \
				return false; \
		} \
	} while (0)

/* ------------------------------------------------------------------------
 * String keywords (apply only when the data is a string)
 * ------------------------------------------------------------------------ */

#define JSV_LENGTH_KEYWORD(lit, op) \
	do { \
		JsonbValue	jsv_str; \
		if (jsv_string_scalar(data, &jsv_str)) \
		{ \
			static Numeric jsv_limit = NULL; \
			if (jsv_int_num_cmp(jsv_char_length(&jsv_str), jsv_static_numeric(&jsv_limit, lit)) op 0) \
				return false; \
		} \
	} while (0)

#define JSV_MIN_LENGTH(lit) JSV_LENGTH_KEYWORD(lit, <)
#define JSV_MAX_LENGTH(lit) JSV_LENGTH_KEYWORD(lit, >)

#define JSV_PATTERN(lit) \
	do { \
		JsonbValue	jsv_str; \
		if (jsv_string_scalar(data, &jsv_str)) \
		{ \
			static text *jsv_regex = NULL; \
			if (!jsv_regex_match(jsv_str.val.string.val, jsv_str.val.string.len, \
								 jsv_static_text(&jsv_regex, lit))) \
				return false; \
		} \
	} while (0)

/* ------------------------------------------------------------------------
 * Object keywords
 * ------------------------------------------------------------------------ */

#define JSV_REQUIRED(key, len) \
	do { \
		if (JB_ROOT_IS_OBJECT(data) && !jsv_has_key(data, key, len)) \
			return false; \
	} while (0)

#define JSV_COUNT_KEYWORD(lit, op, is_kind, count) \
	do { \
		if (is_kind) \
		{ \
			static Numeric jsv_limit = NULL; \
			if (jsv_int_num_cmp(count, jsv_static_numeric(&jsv_limit, lit)) op 0) \
				return false; \
		} \
	} while (0)

#define JSV_MIN_PROPERTIES(lit) \
	JSV_COUNT_KEYWORD(lit, <, JB_ROOT_IS_OBJECT(data), jsv_num_properties(data))
#define JSV_MAX_PROPERTIES(lit) \
	JSV_COUNT_KEYWORD(lit, >, JB_ROOT_IS_OBJECT(data), jsv_num_properties(data))
#define JSV_MIN_ITEMS(lit) \
	JSV_COUNT_KEYWORD(lit, <, jsv_is_array(data), jsv_num_items(data))
#define JSV_MAX_ITEMS(lit) \
	JSV_COUNT_KEYWORD(lit, >, jsv_is_array(data), jsv_num_items(data))

/*
 * properties / patternProperties / additionalProperties.
 *
 * The generator emits, in this order:
 *   JSV_OBJECT_BEGIN
 *       one JSV_PROP per key in "properties"
 *       one JSV_PROP_PATTERN per key in "patternProperties"
 *       at most one JSV_PROP_ADDITIONAL / JSV_PROP_ADDITIONAL_FALSE
 *   JSV_OBJECT_END
 */
#define JSV_OBJECT_BEGIN \
	if (JB_ROOT_IS_OBJECT(data)) \
	{ \
		JsonbIterator *jsv_it = JsonbIteratorInit(&data->root); \
		JsonbValue	jsv_key, \
					jsv_val; \
		JsonbIteratorToken jsv_tok = JsonbIteratorNext(&jsv_it, &jsv_key, true); \
		Assert(jsv_tok == WJB_BEGIN_OBJECT); \
		while ((jsv_tok = JsonbIteratorNext(&jsv_it, &jsv_key, true)) != WJB_END_OBJECT) \
		{ \
			bool		jsv_matched = false; \
			(void) jsv_matched; \
			jsv_tok = JsonbIteratorNext(&jsv_it, &jsv_val, true);

#define JSV_PROP(key, len, fn) \
			if (jsv_key_eq(&jsv_key, key, len)) \
			{ \
				jsv_matched = true; \
				if (!fn(jsv_value_to_jsonb(&jsv_val))) \
					return false; \
			}

#define JSV_PROP_PATTERN(regex_lit, fn) \
			{ \
				static text *jsv_regex = NULL; \
				if (jsv_regex_match(jsv_key.val.string.val, jsv_key.val.string.len, \
									jsv_static_text(&jsv_regex, regex_lit))) \
				{ \
					jsv_matched = true; \
					if (!fn(jsv_value_to_jsonb(&jsv_val))) \
						return false; \
				} \
			}

#define JSV_PROP_ADDITIONAL(fn) \
			if (!jsv_matched) \
			{ \
				if (!fn(jsv_value_to_jsonb(&jsv_val))) \
					return false; \
			}

#define JSV_PROP_ADDITIONAL_FALSE \
			if (!jsv_matched) \
				return false;

#define JSV_OBJECT_END \
		} \
	}

/* draft-7 propertyNames: every key, as a string scalar, must satisfy fn */
#define JSV_PROPERTY_NAMES(fn) \
	if (JB_ROOT_IS_OBJECT(data)) \
	{ \
		JsonbIterator *jsv_it = JsonbIteratorInit(&data->root); \
		JsonbValue	jsv_key, \
					jsv_val; \
		JsonbIteratorToken jsv_tok = JsonbIteratorNext(&jsv_it, &jsv_key, true); \
		Assert(jsv_tok == WJB_BEGIN_OBJECT); \
		while ((jsv_tok = JsonbIteratorNext(&jsv_it, &jsv_key, true)) != WJB_END_OBJECT) \
		{ \
			if (!fn(jsv_value_to_jsonb(&jsv_key))) \
				return false; \
			jsv_tok = JsonbIteratorNext(&jsv_it, &jsv_val, true); \
		} \
	}

#define JSV_DEPENDENCY_KEY(key, len, dep, deplen) \
	do { \
		if (JB_ROOT_IS_OBJECT(data) && jsv_has_key(data, key, len) && \
			!jsv_has_key(data, dep, deplen)) \
			return false; \
	} while (0)

#define JSV_DEPENDENCY_SCHEMA(key, len, fn) \
	do { \
		if (JB_ROOT_IS_OBJECT(data) && jsv_has_key(data, key, len)) \
		{ \
			if (!fn(data)) \
				return false; \
		} \
	} while (0)

/* ------------------------------------------------------------------------
 * Array keywords
 * ------------------------------------------------------------------------ */

/* "items" is a single schema: every element must satisfy it */
#define JSV_ITEMS_ALL(fn) \
	if (jsv_is_array(data)) \
	{ \
		JsonbIterator *jsv_it = JsonbIteratorInit(&data->root); \
		JsonbValue	jsv_elem; \
		JsonbIteratorToken jsv_tok = JsonbIteratorNext(&jsv_it, &jsv_elem, true); \
		Assert(jsv_tok == WJB_BEGIN_ARRAY); \
		while ((jsv_tok = JsonbIteratorNext(&jsv_it, &jsv_elem, true)) != WJB_END_ARRAY) \
		{ \
			if (!fn(jsv_value_to_jsonb(&jsv_elem))) \
				return false; \
		} \
	}

/* draft-7 "items": false — only the empty array validates */
#define JSV_ITEMS_EMPTY() \
	do { \
		if (jsv_is_array(data) && jsv_num_items(data) > 0) \
			return false; \
	} while (0)

/*
 * "items" is a tuple: positional schemas, then additionalItems. The
 * generator emits JSV_TUPLE_ITEM entries with consecutive indexes starting
 * at 0, then at most one JSV_TUPLE_ADDITIONAL / JSV_TUPLE_ADDITIONAL_FALSE.
 */
#define JSV_TUPLE_BEGIN \
	if (jsv_is_array(data)) \
	{ \
		JsonbIterator *jsv_it = JsonbIteratorInit(&data->root); \
		JsonbValue	jsv_elem; \
		JsonbIteratorToken jsv_tok = JsonbIteratorNext(&jsv_it, &jsv_elem, true); \
		int			jsv_idx = 0; \
		Assert(jsv_tok == WJB_BEGIN_ARRAY); \
		while ((jsv_tok = JsonbIteratorNext(&jsv_it, &jsv_elem, true)) != WJB_END_ARRAY) \
		{ \
			if (false) \
			{ \
			}

#define JSV_TUPLE_ITEM(i, fn) \
			else if (jsv_idx == i) \
			{ \
				if (!fn(jsv_value_to_jsonb(&jsv_elem))) \
					return false; \
			}

#define JSV_TUPLE_ADDITIONAL(fn) \
			else \
			{ \
				if (!fn(jsv_value_to_jsonb(&jsv_elem))) \
					return false; \
			}

#define JSV_TUPLE_ADDITIONAL_FALSE \
			else \
			{ \
				return false; \
			}

#define JSV_TUPLE_END \
			jsv_idx++; \
		} \
	}

#define JSV_UNIQUE_ITEMS() \
	do { \
		if (jsv_is_array(data) && !jsv_unique_items_ok(data)) \
			return false; \
	} while (0)

/* draft-7 "contains": at least one element must satisfy fn */
#define JSV_CONTAINS(fn) \
	if (jsv_is_array(data)) \
	{ \
		JsonbIterator *jsv_it = JsonbIteratorInit(&data->root); \
		JsonbValue	jsv_elem; \
		JsonbIteratorToken jsv_tok = JsonbIteratorNext(&jsv_it, &jsv_elem, true); \
		bool		jsv_found = false; \
		Assert(jsv_tok == WJB_BEGIN_ARRAY); \
		while (!jsv_found && \
			   (jsv_tok = JsonbIteratorNext(&jsv_it, &jsv_elem, true)) != WJB_END_ARRAY) \
		{ \
			jsv_found = fn(jsv_value_to_jsonb(&jsv_elem)); \
		} \
		if (!jsv_found) \
			return false; \
	}

/* ------------------------------------------------------------------------
 * Generic keywords
 * ------------------------------------------------------------------------ */

#define JSV_ENUM(lit) \
	do { \
		static Jsonb *jsv_enum_cache = NULL; \
		if (!jsv_enum_contains(jsv_static_jsonb(&jsv_enum_cache, lit), data)) \
			return false; \
	} while (0)

#define JSV_CONST(lit) \
	do { \
		static Jsonb *jsv_const_cache = NULL; \
		if (!jsv_jsonb_eq(jsv_static_jsonb(&jsv_const_cache, lit), data)) \
			return false; \
	} while (0)

#define JSV_NOT(fn) \
	do { \
		if (fn(data)) \
			return false; \
	} while (0)

#define JSV_ANY_OF_BEGIN \
	{ \
		bool		jsv_any = false;

#define JSV_ANY_OF_ALT(fn) \
		if (!jsv_any) \
			jsv_any = fn(data);

#define JSV_ANY_OF_END \
		if (!jsv_any) \
			return false; \
	}

#define JSV_ONE_OF_BEGIN \
	{ \
		int			jsv_one = 0;

#define JSV_ONE_OF_ALT(fn) \
		if (jsv_one < 2 && fn(data)) \
			jsv_one++;

#define JSV_ONE_OF_END \
		if (jsv_one != 1) \
			return false; \
	}

#define JSV_IF_THEN_ELSE(condfn, thenfn, elsefn) \
	do { \
		if (condfn(data)) \
		{ \
			if (!thenfn(data)) \
				return false; \
		} \
		else \
		{ \
			if (!elsefn(data)) \
				return false; \
		} \
	} while (0)

#endif							/* VALIDATOR_MACROS_H */
