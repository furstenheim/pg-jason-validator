-- uniqueItems validation
-- unique array of integers is valid
SELECT misc_33('[1,2]');
-- non-unique array of integers is invalid
SELECT misc_33('[1,1]');
-- non-unique array of more than two integers is invalid
SELECT misc_33('[1,2,1]');
-- numbers are unique if mathematically unequal
SELECT misc_33('[1,1,1]');
-- false is not equal to zero
SELECT misc_33('[0,false]');
-- true is not equal to one
SELECT misc_33('[1,true]');
-- unique array of strings is valid
SELECT misc_33('["foo","bar","baz"]');
-- non-unique array of strings is invalid
SELECT misc_33('["foo","bar","foo"]');
-- unique array of objects is valid
SELECT misc_33('[{"foo":"bar"},{"foo":"baz"}]');
-- non-unique array of objects is invalid
SELECT misc_33('[{"foo":"bar"},{"foo":"bar"}]');
-- property order of array of objects is ignored
SELECT misc_33('[{"foo":"bar","bar":"foo"},{"bar":"foo","foo":"bar"}]');
-- unique array of nested objects is valid
SELECT misc_33('[{"foo":{"bar":{"baz":true}}},{"foo":{"bar":{"baz":false}}}]');
-- non-unique array of nested objects is invalid
SELECT misc_33('[{"foo":{"bar":{"baz":true}}},{"foo":{"bar":{"baz":true}}}]');
-- unique array of arrays is valid
SELECT misc_33('[["foo"],["bar"]]');
-- non-unique array of arrays is invalid
SELECT misc_33('[["foo"],["foo"]]');
-- non-unique array of more than two arrays is invalid
SELECT misc_33('[["foo"],["bar"],["foo"]]');
-- 1 and true are unique
SELECT misc_33('[1,true]');
-- 0 and false are unique
SELECT misc_33('[0,false]');
-- [1] and [true] are unique
SELECT misc_33('[[1],[true]]');
-- [0] and [false] are unique
SELECT misc_33('[[0],[false]]');
-- nested [1] and [true] are unique
SELECT misc_33('[[[1],"foo"],[[true],"foo"]]');
-- nested [0] and [false] are unique
SELECT misc_33('[[[0],"foo"],[[false],"foo"]]');
-- unique heterogeneous types are valid
SELECT misc_33('[{},[1],true,null,1,"{}"]');
-- non-unique heterogeneous types are invalid
SELECT misc_33('[{},[1],true,null,{},1]');
-- different objects are unique
SELECT misc_33('[{"a":1,"b":2},{"a":2,"b":1}]');
-- objects are non-unique despite key order
SELECT misc_33('[{"a":1,"b":2},{"b":2,"a":1}]');
-- {"a": false} and {"a": 0} are unique
SELECT misc_33('[{"a":false},{"a":0}]');
-- {"a": true} and {"a": 1} are unique
SELECT misc_33('[{"a":true},{"a":1}]');
-- uniqueItems with an array of items
-- [false, true] from items array is valid
SELECT unique_items_1('[false,true]');
-- [true, false] from items array is valid
SELECT unique_items_1('[true,false]');
-- [false, false] from items array is not valid
SELECT unique_items_1('[false,false]');
-- [true, true] from items array is not valid
SELECT unique_items_1('[true,true]');
-- unique array extended from [false, true] is valid
SELECT unique_items_1('[false,true,"foo","bar"]');
-- unique array extended from [true, false] is valid
SELECT unique_items_1('[true,false,"foo","bar"]');
-- non-unique array extended from [false, true] is not valid
SELECT unique_items_1('[false,true,"foo","foo"]');
-- non-unique array extended from [true, false] is not valid
SELECT unique_items_1('[true,false,"foo","foo"]');
-- uniqueItems with an array of items and additionalItems=false
-- [false, true] from items array is valid
SELECT unique_items_2('[false,true]');
-- [true, false] from items array is valid
SELECT unique_items_2('[true,false]');
-- [false, false] from items array is not valid
SELECT unique_items_2('[false,false]');
-- [true, true] from items array is not valid
SELECT unique_items_2('[true,true]');
-- extra items are invalid even if unique
SELECT unique_items_2('[false,true,null]');
-- uniqueItems=false validation
-- unique array of integers is valid
SELECT misc_34('[1,2]');
-- non-unique array of integers is valid
SELECT misc_34('[1,1]');
-- numbers are unique if mathematically unequal
SELECT misc_34('[1,1,1]');
-- false is not equal to zero
SELECT misc_34('[0,false]');
-- true is not equal to one
SELECT misc_34('[1,true]');
-- unique array of objects is valid
SELECT misc_34('[{"foo":"bar"},{"foo":"baz"}]');
-- non-unique array of objects is valid
SELECT misc_34('[{"foo":"bar"},{"foo":"bar"}]');
-- unique array of nested objects is valid
SELECT misc_34('[{"foo":{"bar":{"baz":true}}},{"foo":{"bar":{"baz":false}}}]');
-- non-unique array of nested objects is valid
SELECT misc_34('[{"foo":{"bar":{"baz":true}}},{"foo":{"bar":{"baz":true}}}]');
-- unique array of arrays is valid
SELECT misc_34('[["foo"],["bar"]]');
-- non-unique array of arrays is valid
SELECT misc_34('[["foo"],["foo"]]');
-- 1 and true are unique
SELECT misc_34('[1,true]');
-- 0 and false are unique
SELECT misc_34('[0,false]');
-- unique heterogeneous types are valid
SELECT misc_34('[{},[1],true,null,1]');
-- non-unique heterogeneous types are valid
SELECT misc_34('[{},[1],true,null,{},1]');
-- uniqueItems=false with an array of items
-- [false, true] from items array is valid
SELECT unique_items_3('[false,true]');
-- [true, false] from items array is valid
SELECT unique_items_3('[true,false]');
-- [false, false] from items array is valid
SELECT unique_items_3('[false,false]');
-- [true, true] from items array is valid
SELECT unique_items_3('[true,true]');
-- unique array extended from [false, true] is valid
SELECT unique_items_3('[false,true,"foo","bar"]');
-- unique array extended from [true, false] is valid
SELECT unique_items_3('[true,false,"foo","bar"]');
-- non-unique array extended from [false, true] is valid
SELECT unique_items_3('[false,true,"foo","foo"]');
-- non-unique array extended from [true, false] is valid
SELECT unique_items_3('[true,false,"foo","foo"]');
-- uniqueItems=false with an array of items and additionalItems=false
-- [false, true] from items array is valid
SELECT unique_items_4('[false,true]');
-- [true, false] from items array is valid
SELECT unique_items_4('[true,false]');
-- [false, false] from items array is valid
SELECT unique_items_4('[false,false]');
-- [true, true] from items array is valid
SELECT unique_items_4('[true,true]');
-- extra items are invalid even if unique
SELECT unique_items_4('[false,true,null]');
