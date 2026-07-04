-- exclusiveMinimum validation
-- above the exclusiveMinimum is valid
SELECT exclusive_minimum_v7_1('1.2');
-- boundary point is invalid
SELECT exclusive_minimum_v7_1('1.1');
-- below the exclusiveMinimum is invalid
SELECT exclusive_minimum_v7_1('0.6');
-- ignores non-numbers
SELECT exclusive_minimum_v7_1('"x"');
