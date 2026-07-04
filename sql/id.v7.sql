-- id inside an enum is not a real identifier
-- exact match to enum, and type matches
SELECT id_v7_1('{"$id":"https://localhost:1234/id/my_identifier.json","type":"null"}');
-- non-schema object containing a plain-name $id property
-- skip traversing definition for a valid result
SELECT id_v7_2('"skip not_a_real_anchor"');
-- const at const_not_anchor does not match
SELECT id_v7_2('1');
-- non-schema object containing an $id property
-- skip traversing definition for a valid result
SELECT id_v7_3('"skip not_a_real_id"');
-- const at const_not_id does not match
SELECT id_v7_3('1');
