CREATE EXTENSION pg_jason_validator;
SELECT misc_1('{}');
SELECT misc_2('1');
SELECT misc_2('{}');
SELECT misc_3('{}');
SELECT misc_3('2');
SELECT misc_3('{"a": 1}');
SELECT misc_4('2');
SELECT misc_5('2');
SELECT misc_6('1');
SELECT misc_6('{"a": 2}');
SELECT misc_6('{"a": 1}');
SELECT misc_7('"abc"');
SELECT misc_7('"a"');
SELECT misc_8('"a"');
SELECT misc_8('"abc"');
SELECT misc_9('{
                                "a": "whatever",
                                "x": 131
                            }');
SELECT misc_9('{
                                "a": true,
                                "x": 1.1
                            }');
SELECT misc_10('{
                               "a": true,
                               "b": null
                           }');
SELECT misc_10('{
                                "c": false,
                                "d": 31
                            }');
SELECT misc_10('{
                                "c": false,
                                "d": 31,
                                "e": {"a": 1}
                            }');
SELECT misc_11('{"foo": 1}');
SELECT misc_11('{"foo": "bar", "fooooo": 2}');
SELECT misc_12('{"foo": 1, "a": 2.5}');
SELECT misc_12('{"foo": 1, "a": 2}');
SELECT misc_13('{"foo": 1, "a": 2}');
SELECT misc_13('{"foo": 1, "a": 2, "b": false}');
SELECT misc_14('{"foo": 1, "a": 2, "b": false}');
SELECT misc_15('{"foo": 1, "a": 2, "b": false}');
SELECT misc_16('4');
SELECT misc_17('4.5');
SELECT misc_18('2');
SELECT misc_19('"a"');
SELECT misc_20('"My blacksmith produces excellent steel"');
SELECT misc_20('"I am no good at smitking, I''m afraid"');
SELECT misc_21('[1, 2, 3, 4]');
SELECT misc_22('[1, 2, 3, 4]');
SELECT misc_23('[1, {"bc": 2}, 3, 4]');
SELECT misc_24('[{"a": 1}, 2, 3, 4]');
SELECT misc_25('"dab"');
SELECT misc_25('{"a": 1, "b": 4, "c": 4, "d": 67, "e": 91}');
SELECT misc_26('{"a": 1, "b": 4, "c": 4, "d": 67, "e": 91}');
SELECT misc_27('{"a": 1, "b": 4, "c": 4, "d": 67, "e": 91}');
SELECT misc_28('2');
SELECT misc_29('2');
SELECT misc_30('2');
SELECT misc_31('2');
SELECT misc_32('2');
SELECT misc_33('[1, 2, 3]');
SELECT misc_34('[1, 2, 2]');
SELECT misc_33('[1, 2, 2]');
SELECT misc_33('[1, {"a": {"b": 1}}, {"a": {"b": 1}}]');
SELECT misc_33('[1, {"a": {"b": 1}}, {"a": {"b": 2}}]');
SELECT misc_35('2');
SELECT misc_36('2');
SELECT misc_37('2');
SELECT misc_38('2');
SELECT misc_39('2');
SELECT misc_40('2');
SELECT misc_5('2');
SELECT misc_41('2');
SELECT misc_42('2');
SELECT misc_43('2');
SELECT misc_44('2');
SELECT misc_5('2.5');
SELECT misc_45('2.5');
SELECT misc_46('{"a": 1}');
SELECT misc_47('{"a": 1, "b": 5}');
SELECT misc_48('{"a": 1, "b": 5}');
SELECT misc_49('{"a": 1, "b": 5}');
SELECT misc_50('{"a": 1, "b": 5}');
SELECT misc_51('{"a": 2.5}');
SELECT misc_52('{"a": 2}');
SELECT misc_52('{"a": 2.5}');
--- property is compared with length of key, in this case 4
SELECT misc_53('{"a": 2}');
SELECT misc_54('{}');
SELECT misc_55('{}');
SELECT misc_54('{"a": 1}');
SELECT misc_56('{"a": 1}');
SELECT misc_56('{"a": 1, "b": 2}');
SELECT misc_56('1');
SELECT misc_57('[1, 2.5, 3.5]');
SELECT misc_58('[1, 2, 3]');
SELECT misc_58('[1, 2, 3.5]');
SELECT misc_59('[1, 2.5, 3.5]');
SELECT misc_60('[1, 2.5, 3.5]');
SELECT misc_61('[1, 2.5, 3.5]');
SELECT misc_52('{"b": 1}');
