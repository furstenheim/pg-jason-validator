-- maxLength validation
-- shorter is valid
SELECT misc_8('"f"');
-- exact length is valid
SELECT misc_8('"fo"');
-- too long is invalid
SELECT misc_8('"foo"');
-- ignores non-strings
SELECT misc_8('100');
-- two supplementary Unicode code points is long enough
SELECT misc_8('"💩💩"');
