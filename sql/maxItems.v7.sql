-- maxItems validation
-- shorter is valid
SELECT misc_22('[1]');
-- exact length is valid
SELECT misc_22('[1,2]');
-- too long is invalid
SELECT misc_22('[1,2,3]');
-- ignores non-arrays
SELECT misc_22('"foobar"');
-- maxItems validation with a decimal
-- shorter is valid
SELECT misc_22('[1]');
-- too long is invalid
SELECT misc_22('[1,2,3]');
