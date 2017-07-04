select r10_compania loc, r10_filtro fil_ant, r10_filtro fil_act
	from rept010
	where r10_compania = 999
	into temp t1;

load from "filtros_fin.unl" insert into t1;

--begin work;

	update acero_gm@idsgye01:rept010
		set r10_filtro = (select unique fil_act
					from t1
					where fil_ant = r10_filtro
					  and loc     = 1)
		where r10_compania = 1
		  and r10_filtro   in (select unique fil_ant
					from t1
					where loc = 1);

	update acero_gm@idsgye01:rept010
		set r10_filtro = (select unique fil_act
					from t1
					where fil_ant is null
					  and loc     = 1)
		where r10_compania = 1
		  and r10_filtro   is null;

	update acero_gc@idsgye01:rept010
		set r10_filtro = (select unique fil_act
					from t1
					where fil_ant = r10_filtro
					  and loc     = 2)
		where r10_compania = 1
		  and r10_filtro   in (select unique fil_ant
					from t1
					where loc = 2);

	update acero_gc@idsgye01:rept010
		set r10_filtro = (select unique fil_act
					from t1
					where fil_ant is null
					  and loc     = 2)
		where r10_compania = 1
		  and r10_filtro   is null;

--commit work;

drop table t1;
