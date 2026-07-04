-- not
-- allowed
SELECT not_1('"foo"');
-- disallowed
SELECT not_1('1');
-- not multiple types
-- valid
SELECT not_2('"foo"');
-- mismatch
SELECT not_2('1');
-- other mismatch
SELECT not_2('true');
-- not more complex schema
-- match
SELECT not_3('1');
-- other match
SELECT not_3('{"foo":1}');
-- mismatch
SELECT not_3('{"foo":"bar"}');
-- forbidden property
-- property present
SELECT not_4('{"foo":1,"bar":2}');
-- property absent
SELECT not_4('{"bar":1,"baz":2}');
