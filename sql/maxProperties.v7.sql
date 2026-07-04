-- maxProperties validation
-- shorter is valid
SELECT max_properties_1('{"foo":1}');
-- exact length is valid
SELECT max_properties_1('{"foo":1,"bar":2}');
-- too long is invalid
SELECT max_properties_1('{"foo":1,"bar":2,"baz":3}');
-- ignores arrays
SELECT max_properties_1('[1,2,3]');
-- ignores strings
SELECT max_properties_1('"foobar"');
-- ignores other non-objects
SELECT max_properties_1('12');
-- maxProperties validation with a decimal
-- shorter is valid
SELECT max_properties_1('{"foo":1}');
-- too long is invalid
SELECT max_properties_1('{"foo":1,"bar":2,"baz":3}');
-- maxProperties = 0 means the object is empty
-- no properties is valid
SELECT max_properties_2('{}');
-- one property is invalid
SELECT max_properties_2('{"foo":1}');
