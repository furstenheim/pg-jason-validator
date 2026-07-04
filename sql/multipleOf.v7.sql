-- by int
-- int by int
SELECT misc_16('10');
-- int by int fail
SELECT misc_16('7');
-- ignores non-numbers
SELECT misc_16('"foo"');
-- by number
-- zero is multiple of anything
SELECT misc_17('0');
-- 4.5 is multiple of 1.5
SELECT misc_17('4.5');
-- 35 is not multiple of 1.5
SELECT misc_17('35');
-- by small number
-- 0.0075 is multiple of 0.0001
SELECT multiple_of_1('0.0075');
-- 0.00751 is not multiple of 0.0001
SELECT multiple_of_1('0.00751');
-- float division = inf
-- always invalid, but naive implementations may raise an overflow error
SELECT multiple_of_2('1e+308');
-- small multiple of large integer
-- any integer is a multiple of 1e-8
SELECT multiple_of_3('12391239123');
