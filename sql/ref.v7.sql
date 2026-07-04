-- root pointer ref
-- match
SELECT ref_1('{"foo":false}');
-- recursive match
SELECT ref_1('{"foo":{"foo":false}}');
-- mismatch
SELECT ref_1('{"bar":false}');
-- recursive mismatch
SELECT ref_1('{"foo":{"bar":false}}');
-- relative pointer ref to object
-- match
SELECT ref_2('{"bar":3}');
-- mismatch
SELECT ref_2('{"bar":true}');
-- relative pointer ref to array
-- match array
SELECT ref_3('[1,2]');
-- mismatch array
SELECT ref_3('[1,"foo"]');
-- nested refs
-- nested ref valid
SELECT ref_4('5');
-- nested ref invalid
SELECT ref_4('"a"');
-- ref overrides any sibling keywords
-- ref valid
SELECT ref_5('{"foo":[]}');
-- ref valid, maxItems ignored
SELECT ref_5('{"foo":[1,2,3]}');
-- ref invalid
SELECT ref_5('{"foo":"string"}');
-- $ref prevents a sibling $id from changing the base uri
-- property named $ref that is not a reference
-- property named $ref valid
SELECT ref_6('{"$ref":"a"}');
-- property named $ref invalid
SELECT ref_6('{"$ref":2}');
-- property named $ref, containing an actual $ref
-- property named $ref valid
SELECT ref_7('{"$ref":"a"}');
-- property named $ref invalid
SELECT ref_7('{"$ref":2}');
-- $ref to boolean schema true
-- any value is valid
SELECT ref_v7_1('"foo"');
-- $ref to boolean schema false
-- any value is invalid
SELECT ref_v7_2('"foo"');
-- naive replacement of $ref with its destination is not correct
-- do not evaluate the $ref inside the enum, matching any string
SELECT ref_8('"this is a string"');
-- do not evaluate the $ref inside the enum, definition exact match
SELECT ref_8('{"type":"string"}');
-- match the enum exactly
SELECT ref_8('{"$ref":"#/definitions/a_string"}');
-- simple URN base URI with JSON pointer
-- a string is valid
SELECT ref_v7_3('{"foo":"bar"}');
-- a non-string is invalid
SELECT ref_v7_3('{"foo":12}');
-- URN base URI with NSS
-- a string is valid
SELECT ref_v7_4('{"foo":"bar"}');
-- a non-string is invalid
SELECT ref_v7_4('{"foo":12}');
-- URN base URI with r-component
-- a string is valid
SELECT ref_v7_5('{"foo":"bar"}');
-- a non-string is invalid
SELECT ref_v7_5('{"foo":12}');
-- URN base URI with q-component
-- a string is valid
SELECT ref_v7_6('{"foo":"bar"}');
-- a non-string is invalid
SELECT ref_v7_6('{"foo":12}');
-- $id with file URI still resolves pointers - *nix
-- number is valid
SELECT ref_v7_7('1');
-- non-number is invalid
SELECT ref_v7_7('"a"');
-- $id with file URI still resolves pointers - windows
-- number is valid
SELECT ref_v7_8('1');
-- non-number is invalid
SELECT ref_v7_8('"a"');
-- empty tokens in $ref json-pointer
-- number is valid
SELECT ref_11('1');
-- non-number is invalid
SELECT ref_11('"a"');
