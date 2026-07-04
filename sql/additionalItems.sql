-- additionalItems as schema
-- additional items match schema
SELECT additional_items_1('[null,2,3,4]');
-- additional items do not match schema
SELECT additional_items_1('[null,2,3,"foo"]');
-- when items is schema, additionalItems does nothing
-- all items match schema
SELECT additional_items_2('[1,2,3,4,5]');
-- array of items with no additionalItems permitted
-- empty array
SELECT additional_items_3('[]');
-- fewer number of items present (1)
SELECT additional_items_3('[1]');
-- fewer number of items present (2)
SELECT additional_items_3('[1,2]');
-- equal number of items present
SELECT additional_items_3('[1,2,3]');
-- additional items are not permitted
SELECT additional_items_3('[1,2,3,4]');
-- additionalItems as false without items
-- items defaults to empty schema so everything is valid
SELECT additional_items_4('[1,2,3,4,5]');
-- ignores non-arrays
SELECT additional_items_4('{"foo":"bar"}');
-- additionalItems are allowed by default
-- only the first item is validated
SELECT additional_items_5('[1,"foo",false]');
-- additionalItems does not look in applicators, valid case
-- items defined in allOf are not examined
SELECT additional_items_6('[1,null]');
-- additionalItems does not look in applicators, invalid case
-- items defined in allOf are not examined
SELECT additional_items_7('[1,"hello"]');
-- items validation adjusts the starting index for additionalItems
-- valid items
SELECT additional_items_8('["x",2,3]');
-- wrong type of second item
SELECT additional_items_8('["x","y"]');
-- additionalItems with null instance elements
-- allows null elements
SELECT additional_items_9('[null]');
