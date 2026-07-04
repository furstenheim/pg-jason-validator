-- minProperties validation
-- longer is valid
SELECT min_properties_1('{"foo":1,"bar":2}');
-- exact length is valid
SELECT min_properties_1('{"foo":1}');
-- too short is invalid
SELECT min_properties_1('{}');
-- ignores arrays
SELECT min_properties_1('[]');
-- ignores strings
SELECT min_properties_1('""');
-- ignores other non-objects
SELECT min_properties_1('12');
-- minProperties validation with a decimal
-- longer is valid
SELECT min_properties_1('{"foo":1,"bar":2}');
-- too short is invalid
SELECT min_properties_1('{}');
