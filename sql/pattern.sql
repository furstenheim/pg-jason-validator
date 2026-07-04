-- pattern validation
-- a matching pattern is valid
SELECT pattern_1('"aaa"');
-- a non-matching pattern is invalid
SELECT pattern_1('"abc"');
-- ignores booleans
SELECT pattern_1('true');
-- ignores integers
SELECT pattern_1('123');
-- ignores floats
SELECT pattern_1('1');
-- ignores objects
SELECT pattern_1('{}');
-- ignores arrays
SELECT pattern_1('[]');
-- ignores null
SELECT pattern_1('null');
-- pattern is not anchored
-- matches a substring
SELECT pattern_2('"xxaayy"');
