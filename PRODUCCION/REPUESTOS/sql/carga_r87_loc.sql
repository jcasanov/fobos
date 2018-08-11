begin work;
select * from rept087 where r87_compania = 16 into temp t1;
load from "rept087.unl" insert into t1;
insert into rept087
	select t1.* from t1, rept010
		where r87_compania   = 1
                  and r87_localidad  = 3
                  and r10_compania   = r87_compania
                  and r10_codigo     = r87_item
		  and r10_cantveh   <> 1;
drop table t1;
commit work;
