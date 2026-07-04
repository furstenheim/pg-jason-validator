-- exclusiveMaximum validation
-- below the exclusiveMaximum is valid
SELECT exclusive_maximum_v7_1('2.2');
-- boundary point is invalid
SELECT exclusive_maximum_v7_1('3');
-- above the exclusiveMaximum is invalid
SELECT exclusive_maximum_v7_1('3.5');
-- ignores non-numbers
SELECT exclusive_maximum_v7_1('"x"');
