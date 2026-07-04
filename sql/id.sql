-- id inside an enum is not a real identifier
-- exact match to enum, and type matches
SELECT id_1('{"id":"https://localhost:1234/my_identifier.json","type":"null"}');
