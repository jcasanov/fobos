set isolation to dirty read;

select r10_codigo item, r10_cod_util cod_util
	from rept010
	where r10_compania = 999
	into temp t1;

load from "util_ridgid_res.unl" insert into t1;

begin work;

	update rept010
		set r10_cod_util = (select cod_util
					from t1
					where item = r10_codigo)
		where r10_compania = 1
		  and r10_codigo   in (select item from t1)
		  and r10_estado   = 'A'
		  and r10_marca    = 'RIDGID';

commit work;

drop table t1;
