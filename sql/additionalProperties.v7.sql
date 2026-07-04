-- additionalProperties being false does not allow other properties
-- no additional properties is valid
SELECT additional_properties_1('{"foo":1}');
-- an additional property is invalid
SELECT additional_properties_1('{"foo":1,"bar":2,"quux":"boom"}');
-- ignores arrays
SELECT additional_properties_1('[1,2,3]');
-- ignores strings
SELECT additional_properties_1('"foobarbaz"');
-- ignores other non-objects
SELECT additional_properties_1('12');
-- patternProperties are not additional properties
SELECT additional_properties_1('{"foo":1,"vroom":2}');
-- non-ASCII pattern with additionalProperties
-- matching the pattern is valid
SELECT additional_properties_2('{"ármányos":2}');
-- not matching the pattern is invalid
SELECT additional_properties_2('{"élmény":2}');
-- additionalProperties with schema
-- no additional properties is valid
SELECT additional_properties_3('{"foo":1}');
-- an additional valid property is valid
SELECT additional_properties_3('{"foo":1,"bar":2,"quux":true}');
-- an additional invalid property is invalid
SELECT additional_properties_3('{"foo":1,"bar":2,"quux":12}');
-- additionalProperties can exist by itself
-- an additional valid property is valid
SELECT additional_properties_4('{"foo":true}');
-- an additional invalid property is invalid
SELECT additional_properties_4('{"foo":1}');
-- additionalProperties are allowed by default
-- additional properties are allowed
SELECT additional_properties_5('{"foo":1,"bar":2,"quux":true}');
-- additionalProperties does not look in applicators
-- properties defined in allOf are not examined
SELECT additional_properties_6('{"foo":1,"bar":true}');
-- additionalProperties with null valued instance properties
-- allows null values
SELECT additional_properties_7('{"foo":null}');
