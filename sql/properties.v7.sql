-- object properties validation
-- both properties present and valid is valid
SELECT properties_1('{"foo":1,"bar":"baz"}');
-- one property invalid is invalid
SELECT properties_1('{"foo":1,"bar":{}}');
-- both properties invalid is invalid
SELECT properties_1('{"foo":[],"bar":{}}');
-- doesn't invalidate other properties
SELECT properties_1('{"quux":[]}');
-- ignores arrays
SELECT properties_1('[]');
-- ignores other non-objects
SELECT properties_1('12');
-- properties, patternProperties, additionalProperties interaction
-- property validates property
SELECT properties_2('{"foo":[1,2]}');
-- property invalidates property
SELECT properties_2('{"foo":[1,2,3,4]}');
-- patternProperty invalidates property
SELECT properties_2('{"foo":[]}');
-- patternProperty validates nonproperty
SELECT properties_2('{"fxo":[1,2]}');
-- patternProperty invalidates nonproperty
SELECT properties_2('{"fxo":[]}');
-- additionalProperty ignores property
SELECT properties_2('{"bar":[]}');
-- additionalProperty validates others
SELECT properties_2('{"quux":3}');
-- additionalProperty invalidates others
SELECT properties_2('{"quux":"foo"}');
-- properties with boolean schema
-- no property present is valid
SELECT properties_v7_1('{}');
-- only 'true' property present is valid
SELECT properties_v7_1('{"foo":1}');
-- only 'false' property present is invalid
SELECT properties_v7_1('{"bar":2}');
-- both properties present is invalid
SELECT properties_v7_1('{"foo":1,"bar":2}');
-- properties with escaped characters
-- object with all numbers is valid
SELECT properties_3('{"foo\nbar":1,"foo\"bar":1,"foo\\bar":1,"foo\rbar":1,"foo\tbar":1,"foo\fbar":1}');
-- object with strings is invalid
SELECT properties_3('{"foo\nbar":"1","foo\"bar":"1","foo\\bar":"1","foo\rbar":"1","foo\tbar":"1","foo\fbar":"1"}');
-- properties with null valued instance properties
-- allows null values
SELECT properties_4('{"foo":null}');
-- properties whose names are Javascript object property names
-- ignores arrays
SELECT properties_5('[]');
-- ignores other non-objects
SELECT properties_5('12');
-- none of the properties mentioned
SELECT properties_5('{}');
-- __proto__ not valid
SELECT properties_5('{"__proto__":"foo"}');
-- toString not valid
SELECT properties_5('{"toString":{"length":37}}');
-- constructor not valid
SELECT properties_5('{"constructor":{"length":37}}');
-- all present and valid
SELECT properties_5('{"__proto__":12,"toString":{"length":"foo"},"constructor":37}');
