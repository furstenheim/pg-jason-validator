-- integer type matches integers
-- an integer is an integer
SELECT misc_5('1');
-- a float is not an integer
SELECT misc_5('1.1');
-- a string is not an integer
SELECT misc_5('"foo"');
-- a string is still not an integer, even if it looks like one
SELECT misc_5('"1"');
-- an object is not an integer
SELECT misc_5('{}');
-- an array is not an integer
SELECT misc_5('[]');
-- a boolean is not an integer
SELECT misc_5('true');
-- null is not an integer
SELECT misc_5('null');
-- number type matches numbers
-- an integer is a number
SELECT misc_4('1');
-- a float with zero fractional part is a number
SELECT misc_4('1');
-- a float is a number
SELECT misc_4('1.1');
-- a string is not a number
SELECT misc_4('"foo"');
-- a string is still not a number, even if it looks like one
SELECT misc_4('"1"');
-- an object is not a number
SELECT misc_4('{}');
-- an array is not a number
SELECT misc_4('[]');
-- a boolean is not a number
SELECT misc_4('true');
-- null is not a number
SELECT misc_4('null');
-- string type matches strings
-- 1 is not a string
SELECT type_1('1');
-- a float is not a string
SELECT type_1('1.1');
-- a string is a string
SELECT type_1('"foo"');
-- a string is still a string, even if it looks like a number
SELECT type_1('"1"');
-- an empty string is still a string
SELECT type_1('""');
-- an object is not a string
SELECT type_1('{}');
-- an array is not a string
SELECT type_1('[]');
-- a boolean is not a string
SELECT type_1('true');
-- null is not a string
SELECT type_1('null');
-- object type matches objects
-- an integer is not an object
SELECT misc_3('1');
-- a float is not an object
SELECT misc_3('1.1');
-- a string is not an object
SELECT misc_3('"foo"');
-- an object is an object
SELECT misc_3('{}');
-- an array is not an object
SELECT misc_3('[]');
-- a boolean is not an object
SELECT misc_3('true');
-- null is not an object
SELECT misc_3('null');
-- array type matches arrays
-- an integer is not an array
SELECT type_2('1');
-- a float is not an array
SELECT type_2('1.1');
-- a string is not an array
SELECT type_2('"foo"');
-- an object is not an array
SELECT type_2('{}');
-- an array is an array
SELECT type_2('[]');
-- a boolean is not an array
SELECT type_2('true');
-- null is not an array
SELECT type_2('null');
-- boolean type matches booleans
-- an integer is not a boolean
SELECT type_3('1');
-- zero is not a boolean
SELECT type_3('0');
-- a float is not a boolean
SELECT type_3('1.1');
-- a string is not a boolean
SELECT type_3('"foo"');
-- an empty string is not a boolean
SELECT type_3('""');
-- an object is not a boolean
SELECT type_3('{}');
-- an array is not a boolean
SELECT type_3('[]');
-- true is a boolean
SELECT type_3('true');
-- false is a boolean
SELECT type_3('false');
-- null is not a boolean
SELECT type_3('null');
-- null type matches only the null object
-- an integer is not null
SELECT type_4('1');
-- a float is not null
SELECT type_4('1.1');
-- zero is not null
SELECT type_4('0');
-- a string is not null
SELECT type_4('"foo"');
-- an empty string is not null
SELECT type_4('""');
-- an object is not null
SELECT type_4('{}');
-- an array is not null
SELECT type_4('[]');
-- true is not null
SELECT type_4('true');
-- false is not null
SELECT type_4('false');
-- null is null
SELECT type_4('null');
-- multiple types can be specified in an array
-- an integer is valid
SELECT type_5('1');
-- a string is valid
SELECT type_5('"foo"');
-- a float is invalid
SELECT type_5('1.1');
-- an object is invalid
SELECT type_5('{}');
-- an array is invalid
SELECT type_5('[]');
-- a boolean is invalid
SELECT type_5('true');
-- null is invalid
SELECT type_5('null');
-- type as array with one item
-- string is valid
SELECT type_6('"foo"');
-- number is invalid
SELECT type_6('123');
-- type: array or object
-- array is valid
SELECT type_7('[1,2,3]');
-- object is valid
SELECT type_7('{"foo":123}');
-- number is invalid
SELECT type_7('123');
-- string is invalid
SELECT type_7('"foo"');
-- null is invalid
SELECT type_7('null');
-- type: array, object or null
-- array is valid
SELECT type_8('[1,2,3]');
-- object is valid
SELECT type_8('{"foo":123}');
-- null is valid
SELECT type_8('null');
-- number is invalid
SELECT type_8('123');
-- string is invalid
SELECT type_8('"foo"');
