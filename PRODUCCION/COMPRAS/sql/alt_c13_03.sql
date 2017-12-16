begin work;

--	alter table "fobos".ordt013
--		drop c13_fec_emi_fact;

	alter table "fobos".ordt013
		add (c13_fec_emi_fac 		date		before c13_usuario);

	select * from ordt013 into temp t1;

	update ordt013
		set c13_fec_emi_fac =
				(select date(a.c13_fecing)
					from t1 a
					where a.c13_compania  = ordt013.c13_compania
					  and a.c13_localidad = ordt013.c13_localidad
					  and a.c13_numero_oc = ordt013.c13_numero_oc
					  and a.c13_num_recep = ordt013.c13_num_recep)
		where exists
				(select 1 from t1 a
					where a.c13_compania  = ordt013.c13_compania
					  and a.c13_localidad = ordt013.c13_localidad
					  and a.c13_numero_oc = ordt013.c13_numero_oc
					  and a.c13_num_recep = ordt013.c13_num_recep);

	drop table t1;

	alter table "fobos".ordt013
		modify (c13_fec_emi_fac 		date		not null);

--rollback work;
commit work;
