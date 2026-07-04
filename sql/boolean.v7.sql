-- boolean schema 'true'
-- number is valid
SELECT boolean_v7_1('1');
-- string is valid
SELECT boolean_v7_1('"foo"');
-- boolean true is valid
SELECT boolean_v7_1('true');
-- boolean false is valid
SELECT boolean_v7_1('false');
-- null is valid
SELECT boolean_v7_1('null');
-- object is valid
SELECT boolean_v7_1('{"foo":"bar"}');
-- empty object is valid
SELECT boolean_v7_1('{}');
-- array is valid
SELECT boolean_v7_1('["foo"]');
-- empty array is valid
SELECT boolean_v7_1('[]');
-- boolean schema 'false'
-- number is invalid
SELECT boolean_v7_2('1');
-- string is invalid
SELECT boolean_v7_2('"foo"');
-- boolean true is invalid
SELECT boolean_v7_2('true');
-- boolean false is invalid
SELECT boolean_v7_2('false');
-- null is invalid
SELECT boolean_v7_2('null');
-- object is invalid
SELECT boolean_v7_2('{"foo":"bar"}');
-- empty object is invalid
SELECT boolean_v7_2('{}');
-- array is invalid
SELECT boolean_v7_2('["foo"]');
-- empty array is invalid
SELECT boolean_v7_2('[]');
