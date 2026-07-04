-- allOf
-- allOf
SELECT all_of_1('{"foo":"baz","bar":2}');
-- mismatch second
SELECT all_of_1('{"foo":"baz"}');
-- mismatch first
SELECT all_of_1('{"bar":2}');
-- wrong type
SELECT all_of_1('{"foo":"baz","bar":"quux"}');
-- allOf with base schema
-- valid
SELECT all_of_2('{"foo":"quux","bar":2,"baz":null}');
-- mismatch base schema
SELECT all_of_2('{"foo":"quux","baz":null}');
-- mismatch first allOf
SELECT all_of_2('{"bar":2,"baz":null}');
-- mismatch second allOf
SELECT all_of_2('{"foo":"quux","bar":2}');
-- mismatch both
SELECT all_of_2('{"bar":2}');
-- allOf simple types
-- valid
SELECT all_of_3('25');
-- mismatch one
SELECT all_of_3('35');
-- allOf with one empty schema
-- any data is valid
SELECT all_of_4('1');
-- allOf with two empty schemas
-- any data is valid
SELECT all_of_5('1');
-- allOf with the first empty schema
-- number is valid
SELECT all_of_6('1');
-- string is invalid
SELECT all_of_6('"foo"');
-- allOf with the last empty schema
-- number is valid
SELECT all_of_7('1');
-- string is invalid
SELECT all_of_7('"foo"');
-- nested allOf, to check validation semantics
-- null is valid
SELECT all_of_8('null');
-- anything non-null is invalid
SELECT all_of_8('123');
-- allOf combined with anyOf, oneOf
-- allOf: false, anyOf: false, oneOf: false
SELECT all_of_9('1');
-- allOf: false, anyOf: false, oneOf: true
SELECT all_of_9('5');
-- allOf: false, anyOf: true, oneOf: false
SELECT all_of_9('3');
-- allOf: false, anyOf: true, oneOf: true
SELECT all_of_9('15');
-- allOf: true, anyOf: false, oneOf: false
SELECT all_of_9('2');
-- allOf: true, anyOf: false, oneOf: true
SELECT all_of_9('10');
-- allOf: true, anyOf: true, oneOf: false
SELECT all_of_9('6');
-- allOf: true, anyOf: true, oneOf: true
SELECT all_of_9('30');
