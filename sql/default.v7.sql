-- invalid type for default
-- valid when property is specified
SELECT default_1('{"foo":13}');
-- still valid when the invalid default is used
SELECT default_1('{}');
-- invalid string value for default
-- valid when property is specified
SELECT default_2('{"bar":"good"}');
-- still valid when the invalid default is used
SELECT default_2('{}');
-- the default keyword does not do anything if the property is missing
-- an explicit property value is checked against maximum (passing)
SELECT default_3('{"alpha":1}');
-- an explicit property value is checked against maximum (failing)
SELECT default_3('{"alpha":5}');
-- missing properties are not filled in with the default
SELECT default_3('{}');
