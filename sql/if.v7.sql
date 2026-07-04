-- ignore if without then or else
-- valid when valid against lone if
SELECT if_v7_1('0');
-- valid when invalid against lone if
SELECT if_v7_1('"hello"');
-- ignore then without if
-- valid when valid against lone then
SELECT if_v7_2('0');
-- valid when invalid against lone then
SELECT if_v7_2('"hello"');
-- ignore else without if
-- valid when valid against lone else
SELECT if_v7_3('0');
-- valid when invalid against lone else
SELECT if_v7_3('"hello"');
-- if and then without else
-- valid through then
SELECT if_v7_4('-1');
-- invalid through then
SELECT if_v7_4('-100');
-- valid when if test fails
SELECT if_v7_4('3');
-- if and else without then
-- valid when if test passes
SELECT if_v7_5('-1');
-- valid through else
SELECT if_v7_5('4');
-- invalid through else
SELECT if_v7_5('3');
-- validate against correct branch, then vs else
-- valid through then
SELECT if_v7_6('-1');
-- invalid through then
SELECT if_v7_6('-100');
-- valid through else
SELECT if_v7_6('4');
-- invalid through else
SELECT if_v7_6('3');
-- non-interference across combined schemas
-- valid, but would have been invalid through then
SELECT if_v7_7('-100');
-- valid, but would have been invalid through else
SELECT if_v7_7('3');
-- if with boolean schema true
-- boolean schema true in if always chooses the then path (valid)
SELECT if_v7_8('"then"');
-- boolean schema true in if always chooses the then path (invalid)
SELECT if_v7_8('"else"');
-- if with boolean schema false
-- boolean schema false in if always chooses the else path (invalid)
SELECT if_v7_9('"then"');
-- boolean schema false in if always chooses the else path (valid)
SELECT if_v7_9('"else"');
-- if appears at the end when serialized (keyword processing sequence)
-- yes redirects to then and passes
SELECT if_v7_10('"yes"');
-- other redirects to else and passes
SELECT if_v7_10('"other"');
-- no redirects to then and fails
SELECT if_v7_10('"no"');
-- invalid redirects to else and fails
SELECT if_v7_10('"invalid"');
