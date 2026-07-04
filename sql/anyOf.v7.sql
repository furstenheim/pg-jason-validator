-- anyOf
-- first anyOf valid
SELECT any_of_1('1');
-- second anyOf valid
SELECT any_of_1('2.5');
-- both anyOf valid
SELECT any_of_1('3');
-- neither anyOf valid
SELECT any_of_1('1.5');
-- anyOf with base schema
-- mismatch base schema
SELECT any_of_2('3');
-- one anyOf valid
SELECT any_of_2('"foobar"');
-- both anyOf invalid
SELECT any_of_2('"foo"');
-- anyOf with boolean schemas, all true
-- any value is valid
SELECT any_of_v7_1('"foo"');
-- anyOf with boolean schemas, some true
-- any value is valid
SELECT any_of_v7_2('"foo"');
-- anyOf with boolean schemas, all false
-- any value is invalid
SELECT any_of_v7_3('"foo"');
-- anyOf complex types
-- first anyOf valid (complex)
SELECT any_of_3('{"bar":2}');
-- second anyOf valid (complex)
SELECT any_of_3('{"foo":"baz"}');
-- both anyOf valid (complex)
SELECT any_of_3('{"foo":"baz","bar":2}');
-- neither anyOf valid (complex)
SELECT any_of_3('{"foo":2,"bar":"quux"}');
-- anyOf with one empty schema
-- string is valid
SELECT any_of_4('"foo"');
-- number is valid
SELECT any_of_4('123');
-- nested anyOf, to check validation semantics
-- null is valid
SELECT any_of_5('null');
-- anything non-null is invalid
SELECT any_of_5('123');
