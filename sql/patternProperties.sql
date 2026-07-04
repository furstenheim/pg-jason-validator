-- patternProperties validates properties matching a regex
-- a single valid match is valid
SELECT misc_11('{"foo":1}');
-- multiple valid matches is valid
SELECT misc_11('{"foo":1,"foooooo":2}');
-- a single invalid match is invalid
SELECT misc_11('{"foo":"bar","fooooo":2}');
-- multiple invalid matches is invalid
SELECT misc_11('{"foo":"bar","foooooo":"baz"}');
-- ignores arrays
SELECT misc_11('[]');
-- ignores strings
SELECT misc_11('""');
-- ignores other non-objects
SELECT misc_11('12');
-- multiple simultaneous patternProperties are validated
-- a single valid match is valid
SELECT pattern_properties_1('{"a":21}');
-- a simultaneous match is valid
SELECT pattern_properties_1('{"aaaa":18}');
-- multiple matches is valid
SELECT pattern_properties_1('{"a":21,"aaaa":18}');
-- an invalid due to one is invalid
SELECT pattern_properties_1('{"a":"bar"}');
-- an invalid due to the other is invalid
SELECT pattern_properties_1('{"aaaa":31}');
-- an invalid due to both is invalid
SELECT pattern_properties_1('{"aaa":"foo","aaaa":31}');
-- regexes are not anchored by default and are case sensitive
-- non recognized members are ignored
SELECT pattern_properties_2('{"answer 1":"42"}');
-- recognized members are accounted for
SELECT pattern_properties_2('{"a31b":null}');
-- regexes are case sensitive
SELECT pattern_properties_2('{"a_x_3":3}');
-- regexes are case sensitive, 2
SELECT pattern_properties_2('{"a_X_3":3}');
-- patternProperties with null valued instance properties
-- allows null values
SELECT pattern_properties_3('{"foobar":null}');
