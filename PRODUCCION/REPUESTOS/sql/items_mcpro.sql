set isolation to dirty read;
select r10_codigo items from rept010 where r10_compania = 999 into temp t1;
load from "items_mcpro.unl" insert into t1;
select count(*) from t1;
begin work;
	update rept010
		set r10_cod_util = 'MCPRO'
		where r10_compania  = 1
		  and r10_codigo   in (select * from t1);
--rollback work;
commit work;
drop table t1;
