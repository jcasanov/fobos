set isolation to dirty read;

begin work;

set lock mode to wait 20;

update rept010 set r10_linea = '0' where r10_linea = '10';

update rept020 set r20_linea = '0' where r20_linea = '10';
update rept022 set r22_linea = '0' where r22_linea = '10';
update rept024 set r24_linea = '0' where r24_linea = '10';

update rept060 set r60_linea = '0' where r60_linea = '10';
update rept061 set r61_linea = '0' where r61_linea = '10';

delete from rept072 where r72_linea = '10';
delete from rept071 where r71_linea = '10';
delete from rept070 where r70_linea = '10';

delete from rept003 where r03_codigo = '10';

commit work;
