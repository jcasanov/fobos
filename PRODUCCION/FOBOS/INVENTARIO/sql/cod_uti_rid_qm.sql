select r10_codigo item, r10_cod_util cod_u
	from rept010
	where r10_compania = 999
	into temp t1;

load from "cod_uti_rid_qm.unl" insert into t1;

begin work;

	update rept010
		set r10_cod_util = (select cod_u
					from t1
					where item = r10_codigo)
		where r10_compania = 1
		  and r10_codigo   in (select item from t1);

commit work;

drop table t1;
