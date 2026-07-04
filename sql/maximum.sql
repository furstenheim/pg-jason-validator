-- maximum validation
-- below the maximum is valid
SELECT misc_37('2.6');
-- boundary point is valid
SELECT misc_37('3');
-- above the maximum is invalid
SELECT misc_37('3.5');
-- ignores non-numbers
SELECT misc_37('"x"');
-- maximum validation with unsigned integer
-- below the maximum is invalid
SELECT maximum_1('299.97');
-- boundary point integer is valid
SELECT maximum_1('300');
-- boundary point float is valid
SELECT maximum_1('300');
-- above the maximum is invalid
SELECT maximum_1('300.5');
-- maximum validation (explicit false exclusivity)
-- below the maximum is valid
SELECT maximum_2('2.6');
-- boundary point is valid
SELECT maximum_2('3');
-- above the maximum is invalid
SELECT maximum_2('3.5');
-- ignores non-numbers
SELECT maximum_2('"x"');
-- exclusiveMaximum validation
-- below the maximum is still valid
SELECT maximum_3('2.2');
-- boundary point is invalid
SELECT maximum_3('3');
