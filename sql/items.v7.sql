-- a schema given for items
-- valid items
SELECT misc_58('[1,2,3]');
-- wrong type of items
SELECT misc_58('[1,"x"]');
-- ignores non-arrays
SELECT misc_58('{"foo":"bar"}');
-- JavaScript pseudo-array is valid
SELECT misc_58('{"0":"invalid","length":1}');
-- an array of schemas for items
-- correct types
SELECT items_1('[1,"foo"]');
-- wrong types
SELECT items_1('["foo",1]');
-- incomplete array of items
SELECT items_1('[1]');
-- array with additional items
SELECT items_1('[1,"foo",true]');
-- empty array
SELECT items_1('[]');
-- JavaScript pseudo-array is valid
SELECT items_1('{"0":"invalid","1":"valid","length":2}');
-- items with boolean schema (true)
-- any array is valid
SELECT items_v7_1('[1,"foo",true]');
-- empty array is valid
SELECT items_v7_1('[]');
-- items with boolean schema (false)
-- any non-empty array is invalid
SELECT items_v7_2('[1,"foo",true]');
-- empty array is valid
SELECT items_v7_2('[]');
-- items with boolean schemas
-- array with one item is valid
SELECT items_v7_3('[1]');
-- array with two items is invalid
SELECT items_v7_3('[1,"foo"]');
-- empty array is valid
SELECT items_v7_3('[]');
-- items and subitems
-- valid items
SELECT items_2('[[{"foo":null},{"foo":null}],[{"foo":null},{"foo":null}],[{"foo":null},{"foo":null}]]');
-- too many items
SELECT items_2('[[{"foo":null},{"foo":null}],[{"foo":null},{"foo":null}],[{"foo":null},{"foo":null}],[{"foo":null},{"foo":null}]]');
-- too many sub-items
SELECT items_2('[[{"foo":null},{"foo":null},{"foo":null}],[{"foo":null},{"foo":null}],[{"foo":null},{"foo":null}]]');
-- wrong item
SELECT items_2('[{"foo":null},[{"foo":null},{"foo":null}],[{"foo":null},{"foo":null}]]');
-- wrong sub-item
SELECT items_2('[[{},{"foo":null}],[{"foo":null},{"foo":null}],[{"foo":null},{"foo":null}]]');
-- fewer items is valid
SELECT items_2('[[{"foo":null}],[{"foo":null}]]');
-- nested items
-- valid nested array
SELECT items_3('[[[[1]],[[2],[3]]],[[[4],[5],[6]]]]');
-- nested array with invalid type
SELECT items_3('[[[["1"]],[[2],[3]]],[[[4],[5],[6]]]]');
-- not deep enough
SELECT items_3('[[[1],[2],[3]],[[4],[5],[6]]]');
-- single-form items with null instance elements
-- allows null elements
SELECT items_4('[null]');
-- array-form items with null instance elements
-- allows null elements
SELECT items_5('[null]');
