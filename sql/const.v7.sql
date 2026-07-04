-- const validation
-- same value is valid
SELECT const_v7_1('2');
-- another value is invalid
SELECT const_v7_1('5');
-- another type is invalid
SELECT const_v7_1('"a"');
-- const with object
-- same object is valid
SELECT const_v7_2('{"foo":"bar","baz":"bax"}');
-- same object with different property order is valid
SELECT const_v7_2('{"baz":"bax","foo":"bar"}');
-- another object is invalid
SELECT const_v7_2('{"foo":"bar"}');
-- another type is invalid
SELECT const_v7_2('[1,2]');
-- const with array
-- same array is valid
SELECT const_v7_3('[{"foo":"bar"}]');
-- another array item is invalid
SELECT const_v7_3('[2]');
-- array with additional items is invalid
SELECT const_v7_3('[1,2,3]');
-- const with null
-- null is valid
SELECT const_v7_4('null');
-- not null is invalid
SELECT const_v7_4('0');
-- const with false does not match 0
-- false is valid
SELECT const_v7_5('false');
-- integer zero is invalid
SELECT const_v7_5('0');
-- float zero is invalid
SELECT const_v7_5('0');
-- const with true does not match 1
-- true is valid
SELECT const_v7_6('true');
-- integer one is invalid
SELECT const_v7_6('1');
-- float one is invalid
SELECT const_v7_6('1');
-- const with [false] does not match [0]
-- [false] is valid
SELECT const_v7_7('[false]');
-- [0] is invalid
SELECT const_v7_7('[0]');
-- [0.0] is invalid
SELECT const_v7_7('[0]');
-- const with [true] does not match [1]
-- [true] is valid
SELECT const_v7_8('[true]');
-- [1] is invalid
SELECT const_v7_8('[1]');
-- [1.0] is invalid
SELECT const_v7_8('[1]');
-- const with {"a": false} does not match {"a": 0}
-- {"a": false} is valid
SELECT const_v7_9('{"a":false}');
-- {"a": 0} is invalid
SELECT const_v7_9('{"a":0}');
-- {"a": 0.0} is invalid
SELECT const_v7_9('{"a":0}');
-- const with {"a": true} does not match {"a": 1}
-- {"a": true} is valid
SELECT const_v7_10('{"a":true}');
-- {"a": 1} is invalid
SELECT const_v7_10('{"a":1}');
-- {"a": 1.0} is invalid
SELECT const_v7_10('{"a":1}');
-- const with 0 does not match other zero-like types
-- false is invalid
SELECT const_v7_11('false');
-- integer zero is valid
SELECT const_v7_11('0');
-- float zero is valid
SELECT const_v7_11('0');
-- empty object is invalid
SELECT const_v7_11('{}');
-- empty array is invalid
SELECT const_v7_11('[]');
-- empty string is invalid
SELECT const_v7_11('""');
-- const with 1 does not match true
-- true is invalid
SELECT const_v7_12('true');
-- integer one is valid
SELECT const_v7_12('1');
-- float one is valid
SELECT const_v7_12('1');
-- const with -2.0 matches integer and float types
-- integer -2 is valid
SELECT const_v7_13('-2');
-- integer 2 is invalid
SELECT const_v7_13('2');
-- float -2.0 is valid
SELECT const_v7_13('-2');
-- float 2.0 is invalid
SELECT const_v7_13('2');
-- float -2.00001 is invalid
SELECT const_v7_13('-2.00001');
-- float and integers are equal up to 64-bit representation limits
-- integer is valid
SELECT const_v7_14('9007199254740992');
-- integer minus one is invalid
SELECT const_v7_14('9007199254740991');
-- float is valid
SELECT const_v7_14('9007199254740992');
-- float minus one is invalid
SELECT const_v7_14('9007199254740991');
