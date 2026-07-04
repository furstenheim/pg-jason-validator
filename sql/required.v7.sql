-- required validation
-- present required property is valid
SELECT required_1('{"foo":1}');
-- non-present required property is invalid
SELECT required_1('{"bar":1}');
-- ignores arrays
SELECT required_1('[]');
-- ignores strings
SELECT required_1('""');
-- ignores other non-objects
SELECT required_1('12');
-- required default validation
-- not required by default
SELECT required_2('{}');
-- required with empty array
-- property not required
SELECT required_v7_1('{}');
-- required with escaped characters
-- object with all properties present is valid
SELECT required_3('{"foo\nbar":1,"foo\"bar":1,"foo\\bar":1,"foo\rbar":1,"foo\tbar":1,"foo\fbar":1}');
-- object with some properties missing is invalid
SELECT required_3('{"foo\nbar":"1","foo\"bar":"1"}');
-- required properties whose names are Javascript object property names
-- ignores arrays
SELECT required_4('[]');
-- ignores other non-objects
SELECT required_4('12');
-- none of the properties mentioned
SELECT required_4('{}');
-- __proto__ present
SELECT required_4('{"__proto__":"foo"}');
-- toString present
SELECT required_4('{"toString":{"length":37}}');
-- constructor present
SELECT required_4('{"constructor":{"length":37}}');
-- all present
SELECT required_4('{"__proto__":12,"toString":{"length":"foo"},"constructor":37}');
