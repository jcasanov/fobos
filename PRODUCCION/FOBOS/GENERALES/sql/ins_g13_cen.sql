select * from gent013 where g13_moneda = 'XSX' into temp t1;
load from "gent013.unl" insert into t1;
delete from t1 where g13_moneda = (select a.g13_moneda from gent013 a
					where a.g13_moneda = g13_moneda);
begin work;
insert into gent013 select * from t1;
commit work;
drop table t1;
