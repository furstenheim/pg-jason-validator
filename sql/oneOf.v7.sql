-- oneOf
-- first oneOf valid
SELECT one_of_1('1');
-- second oneOf valid
SELECT one_of_1('2.5');
-- both oneOf valid
SELECT one_of_1('3');
-- neither oneOf valid
SELECT one_of_1('1.5');
-- oneOf with base schema
-- mismatch base schema
SELECT one_of_2('3');
-- one oneOf valid
SELECT one_of_2('"foobar"');
-- both oneOf valid
SELECT one_of_2('"foo"');
-- oneOf with boolean schemas, all true
-- any value is invalid
SELECT one_of_v7_1('"foo"');
-- oneOf with boolean schemas, one true
-- any value is valid
SELECT one_of_v7_2('"foo"');
-- oneOf with boolean schemas, more than one true
-- any value is invalid
SELECT one_of_v7_3('"foo"');
-- oneOf with boolean schemas, all false
-- any value is invalid
SELECT one_of_v7_4('"foo"');
-- oneOf complex types
-- first oneOf valid (complex)
SELECT one_of_3('{"bar":2}');
-- second oneOf valid (complex)
SELECT one_of_3('{"foo":"baz"}');
-- both oneOf valid (complex)
SELECT one_of_3('{"foo":"baz","bar":2}');
-- neither oneOf valid (complex)
SELECT one_of_3('{"foo":2,"bar":"quux"}');
-- oneOf with empty schema
-- one valid - valid
SELECT one_of_4('"foo"');
-- both valid - invalid
SELECT one_of_4('123');
-- oneOf with required
-- both invalid - invalid
SELECT one_of_5('{"bar":2}');
-- first valid - valid
SELECT one_of_5('{"foo":1,"bar":2}');
-- second valid - valid
SELECT one_of_5('{"foo":1,"baz":3}');
-- both valid - invalid
SELECT one_of_5('{"foo":1,"bar":2,"baz":3}');
-- oneOf with missing optional property
-- first oneOf valid
SELECT one_of_v7_5('{"bar":8}');
-- second oneOf valid
SELECT one_of_v7_5('{"foo":"foo"}');
-- both oneOf valid
SELECT one_of_v7_5('{"foo":"foo","bar":8}');
-- neither oneOf valid
SELECT one_of_v7_5('{"baz":"quux"}');
-- nested oneOf, to check validation semantics
-- null is valid
SELECT one_of_7('null');
-- anything non-null is invalid
SELECT one_of_7('123');
