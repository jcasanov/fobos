set isolation to dirty read;
select r10_codigo item from rept010 where r10_compania = 999 into temp t1;
load from "ite_blo.unl" insert into t1;
begin work;
	update rept010
		set r10_estado = 'B',
		    r10_feceli = current
		where r10_compania = 1
		  and r10_codigo   in (select item from t1);
commit work;
drop table t1;
