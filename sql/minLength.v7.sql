-- minLength validation
-- longer is valid
SELECT misc_7('"foo"');
-- exact length is valid
SELECT misc_7('"fo"');
-- too short is invalid
SELECT misc_7('"f"');
-- ignores non-strings
SELECT misc_7('1');
-- one supplementary Unicode code point is not long enough
SELECT misc_7('"💩"');
-- minLength validation with a decimal
-- longer is valid
SELECT misc_7('"foo"');
-- too short is invalid
SELECT misc_7('"f"');
