-- minItems validation
-- longer is valid
SELECT misc_23('[1,2]');
-- exact length is valid
SELECT misc_23('[1]');
-- too short is invalid
SELECT misc_23('[]');
-- ignores non-arrays
SELECT misc_23('""');
-- minItems validation with a decimal
-- longer is valid
SELECT misc_23('[1,2]');
-- too short is invalid
SELECT misc_23('[]');
