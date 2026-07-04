-- dependencies
-- neither
SELECT dependencies_1('{}');
-- nondependant
SELECT dependencies_1('{"foo":1}');
-- with dependency
SELECT dependencies_1('{"foo":1,"bar":2}');
-- missing dependency
SELECT dependencies_1('{"bar":2}');
-- ignores arrays
SELECT dependencies_1('["bar"]');
-- ignores strings
SELECT dependencies_1('"foobar"');
-- ignores other non-objects
SELECT dependencies_1('12');
-- dependencies with empty array
-- empty object
SELECT dependencies_v7_1('{}');
-- object with one property
SELECT dependencies_v7_1('{"bar":2}');
-- non-object is valid
SELECT dependencies_v7_1('1');
-- multiple dependencies
-- neither
SELECT dependencies_2('{}');
-- nondependants
SELECT dependencies_2('{"foo":1,"bar":2}');
-- with dependencies
SELECT dependencies_2('{"foo":1,"bar":2,"quux":3}');
-- missing dependency
SELECT dependencies_2('{"foo":1,"quux":2}');
-- missing other dependency
SELECT dependencies_2('{"bar":1,"quux":2}');
-- missing both dependencies
SELECT dependencies_2('{"quux":1}');
-- multiple dependencies subschema
-- valid
SELECT dependencies_3('{"foo":1,"bar":2}');
-- no dependency
SELECT dependencies_3('{"foo":"quux"}');
-- wrong type
SELECT dependencies_3('{"foo":"quux","bar":2}');
-- wrong type other
SELECT dependencies_3('{"foo":2,"bar":"quux"}');
-- wrong type both
SELECT dependencies_3('{"foo":"quux","bar":"quux"}');
-- dependencies with boolean subschemas
-- object with property having schema true is valid
SELECT dependencies_v7_2('{"foo":1}');
-- object with property having schema false is invalid
SELECT dependencies_v7_2('{"bar":2}');
-- object with both properties is invalid
SELECT dependencies_v7_2('{"foo":1,"bar":2}');
-- empty object is valid
SELECT dependencies_v7_2('{}');
-- dependencies with escaped characters
-- valid object 1
SELECT dependencies_4('{"foo\nbar":1,"foo\rbar":2}');
-- valid object 2
SELECT dependencies_4('{"foo\tbar":1,"a":2,"b":3,"c":4}');
-- valid object 3
SELECT dependencies_4('{"foo''bar":1,"foo\"bar":2}');
-- invalid object 1
SELECT dependencies_4('{"foo\nbar":1,"foo":2}');
-- invalid object 2
SELECT dependencies_4('{"foo\tbar":1,"a":2}');
-- invalid object 3
SELECT dependencies_4('{"foo''bar":1}');
-- invalid object 4
SELECT dependencies_4('{"foo\"bar":2}');
-- dependent subschema incompatible with root
-- matches root
SELECT dependencies_5('{"foo":1}');
-- matches dependency
SELECT dependencies_5('{"bar":1}');
-- matches both
SELECT dependencies_5('{"foo":1,"bar":2}');
-- no dependency
SELECT dependencies_5('{"baz":1}');
