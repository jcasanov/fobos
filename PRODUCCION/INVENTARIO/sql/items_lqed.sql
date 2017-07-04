set isolation to dirty read;
select r10_codigo items, r10_cod_util util
	from rept010
	where r10_compania = 999
	into temp t1;
load from "lq_edesa.unl" insert into t1;
select count(*) reg_t1 from t1;
--select count(*), items, util from t1 group by 2, 3 having count(*) > 1;
select unique items, util
	from t1
	into temp t2;
drop table t1;
select count(*) reg_t2 from t2;
select count(*) reg, items from t2 group by 2 having count(*) > 1 into temp t3;
delete from t2 where items in (select t3.items from t3);
begin work;
	update rept010
		set r10_cod_util    = (select unique util from t2
					where items = r10_codigo),
		    r10_usu_cosrepo = 'KARIARIC',
		    r10_fec_cosrepo = current
		where r10_compania  = 1
		  and r10_codigo   in (select unique items from t2);
	update rept010
		set r10_cod_util    = 'ELIQ2',
		    r10_usu_cosrepo = 'KARIARIC',
		    r10_fec_cosrepo = current
		where r10_compania  = 1
		  and r10_codigo   in (select unique items from t3);
--rollback work;
commit work;
drop table t2;
drop table t3;
