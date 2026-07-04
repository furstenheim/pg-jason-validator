-- contains keyword validation
-- array with item matching schema (5) is valid
SELECT contains_v7_1('[3,4,5]');
-- array with item matching schema (6) is valid
SELECT contains_v7_1('[3,4,6]');
-- array with two items matching schema (5, 6) is valid
SELECT contains_v7_1('[3,4,5,6]');
-- array without items matching schema is invalid
SELECT contains_v7_1('[2,3,4]');
-- empty array is invalid
SELECT contains_v7_1('[]');
-- not array is valid
SELECT contains_v7_1('{}');
-- contains keyword with const keyword
-- array with item 5 is valid
SELECT contains_v7_2('[3,4,5]');
-- array with two items 5 is valid
SELECT contains_v7_2('[3,4,5,5]');
-- array without item 5 is invalid
SELECT contains_v7_2('[1,2,3,4]');
-- contains keyword with boolean schema true
-- any non-empty array is valid
SELECT contains_v7_3('["foo"]');
-- empty array is invalid
SELECT contains_v7_3('[]');
-- contains keyword with boolean schema false
-- any non-empty array is invalid
SELECT contains_v7_4('["foo"]');
-- empty array is invalid
SELECT contains_v7_4('[]');
-- non-arrays are valid
SELECT contains_v7_4('"contains does not apply to strings"');
-- items + contains
-- matches items, does not match contains
SELECT contains_v7_5('[2,4,8]');
-- does not match items, matches contains
SELECT contains_v7_5('[3,6,9]');
-- matches both items and contains
SELECT contains_v7_5('[6,12]');
-- matches neither items nor contains
SELECT contains_v7_5('[1,5]');
-- contains with false if subschema
-- any non-empty array is valid
SELECT contains_v7_6('["foo"]');
-- empty array is invalid
SELECT contains_v7_6('[]');
-- contains with null instance elements
-- allows null items
SELECT contains_v7_7('[null]');
