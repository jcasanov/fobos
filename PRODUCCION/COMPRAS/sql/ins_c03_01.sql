select * from ordt003 where c03_compania = 99 into temp t1;
load from "concep_iva.unl" insert into t1;
select count(*) from t1;
begin work;
	insert into ordt003 select * from t1;
commit work;
drop table t1;
