select r10_compania loc, r10_filtro fil_ant, r10_filtro fil_act
	from rept010
	where r10_compania = 999
	into temp t1;

load from "filtros_ql3.unl" insert into t1;

--begin work;

	update acero_gm@acuiopr:rept010
		set r10_filtro = (select unique fil_act
					from t1
					where fil_ant = r10_filtro
					  and loc     = 1)
		where r10_compania = 1
		  and r10_filtro   in (select unique fil_ant
					from t1
					where loc = 1);

	update acero_gc@acuiopr:rept010
		set r10_filtro = (select unique fil_act
					from t1
					where fil_ant = r10_filtro
					  and loc     = 2)
		where r10_compania = 1
		  and r10_filtro   in (select unique fil_ant
					from t1
					where loc = 2);

	update acero_qm@acuiopr:rept010
		set r10_filtro = (select unique fil_act
					from t1
					where fil_ant = r10_filtro
					  and fil_ant is not null
					  and loc     = 3)
		where r10_compania = 1
		  and r10_filtro   in (select unique fil_ant
					from t1
					where loc = 3
					  and fil_ant is not null)
		  and r10_filtro   is not null;

	update acero_qm@acuiopr:rept010
		set r10_filtro = (select unique fil_act
					from t1
					where fil_ant = r10_filtro
					  and fil_ant is null
					  and loc     = 3)
		where r10_compania = 1
		  and r10_filtro   in (select unique fil_ant
					from t1
					where loc = 3
					  and fil_ant is null)
		  and r10_filtro   is null;

	update acero_qs@acuiopr:rept010
		set r10_filtro = (select unique fil_act
					from t1
					where fil_ant = r10_filtro
					  and loc     = 4)
		where r10_compania = 1
		  and r10_filtro   in (select unique fil_ant
					from t1
					where loc = 4);

--commit work;

drop table t1;
