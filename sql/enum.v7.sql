-- simple enum validation
-- one of the enum is valid
SELECT enum_1('1');
-- something else is invalid
SELECT enum_1('4');
-- heterogeneous enum validation
-- one of the enum is valid
SELECT enum_2('[]');
-- something else is invalid
SELECT enum_2('null');
-- objects are deep compared
SELECT enum_2('{"foo":false}');
-- valid object matches
SELECT enum_2('{"foo":12}');
-- extra properties in object is invalid
SELECT enum_2('{"foo":12,"boo":42}');
-- heterogeneous enum-with-null validation
-- null is valid
SELECT enum_3('null');
-- number is valid
SELECT enum_3('6');
-- something else is invalid
SELECT enum_3('"test"');
-- enums in properties
-- both properties are valid
SELECT enum_4('{"foo":"foo","bar":"bar"}');
-- wrong foo value
SELECT enum_4('{"foo":"foot","bar":"bar"}');
-- wrong bar value
SELECT enum_4('{"foo":"foo","bar":"bart"}');
-- missing optional property is valid
SELECT enum_4('{"bar":"bar"}');
-- missing required property is invalid
SELECT enum_4('{"foo":"foo"}');
-- missing all properties is invalid
SELECT enum_4('{}');
-- enum with escaped characters
-- member 1 is valid
SELECT enum_5('"foo\nbar"');
-- member 2 is valid
SELECT enum_5('"foo\rbar"');
-- another string is invalid
SELECT enum_5('"abc"');
-- enum with false does not match 0
-- false is valid
SELECT enum_6('false');
-- integer zero is invalid
SELECT enum_6('0');
-- float zero is invalid
SELECT enum_6('0');
-- enum with true does not match 1
-- true is valid
SELECT enum_7('true');
-- integer one is invalid
SELECT enum_7('1');
-- float one is invalid
SELECT enum_7('1');
-- enum with 0 does not match false
-- false is invalid
SELECT enum_8('false');
-- integer zero is valid
SELECT enum_8('0');
-- float zero is valid
SELECT enum_8('0');
-- enum with 1 does not match true
-- true is invalid
SELECT enum_9('true');
-- integer one is valid
SELECT enum_9('1');
-- float one is valid
SELECT enum_9('1');
