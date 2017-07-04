select r10_filtro fil_ant, r10_filtro fil_act
	from rept010
	where r10_compania = 999
	into temp t1;

load from "filtros_ql.unl" insert into t1;

begin work;

	update rept010
		set r10_filtro = (select fil_act
					from t1
					where fil_ant = r10_filtro)
		where r10_compania = 1
		  and r10_filtro   in (select fil_ant from t1);

commit work;

drop table t1;
