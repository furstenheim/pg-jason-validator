-- minimum validation
-- above the minimum is valid
SELECT minimum_1('2.6');
-- boundary point is valid
SELECT minimum_1('1.1');
-- below the minimum is invalid
SELECT minimum_1('0.6');
-- ignores non-numbers
SELECT minimum_1('"x"');
-- minimum validation with signed integer
-- negative above the minimum is valid
SELECT minimum_4('-1');
-- positive above the minimum is valid
SELECT minimum_4('0');
-- boundary point is valid
SELECT minimum_4('-2');
-- boundary point with float is valid
SELECT minimum_4('-2');
-- float below the minimum is invalid
SELECT minimum_4('-2.0001');
-- int below the minimum is invalid
SELECT minimum_4('-3');
-- ignores non-numbers
SELECT minimum_4('"x"');
