-- propertyNames validation
-- all property names valid
SELECT property_names_v7_1('{"f":{},"foo":{}}');
-- some property names invalid
SELECT property_names_v7_1('{"foo":{},"foobar":{}}');
-- object without properties is valid
SELECT property_names_v7_1('{}');
-- ignores arrays
SELECT property_names_v7_1('[1,2,3,4]');
-- ignores strings
SELECT property_names_v7_1('"foobar"');
-- ignores other non-objects
SELECT property_names_v7_1('12');
-- propertyNames validation with pattern
-- matching property names valid
SELECT property_names_v7_2('{"a":{},"aa":{},"aaa":{}}');
-- non-matching property name is invalid
SELECT property_names_v7_2('{"aaA":{}}');
-- object without properties is valid
SELECT property_names_v7_2('{}');
-- propertyNames with boolean schema true
-- object with any properties is valid
SELECT property_names_v7_3('{"foo":1}');
-- empty object is valid
SELECT property_names_v7_3('{}');
-- propertyNames with boolean schema false
-- object with any properties is invalid
SELECT property_names_v7_4('{"foo":1}');
-- empty object is valid
SELECT property_names_v7_4('{}');
