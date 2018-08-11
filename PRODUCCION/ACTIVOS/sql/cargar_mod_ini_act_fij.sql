begin work;

	insert into actt000
		select * from acero_gm:actt000;

	select * from acero_gm:actt001
		into temp t1;

	update t1
		set a01_aux_activo  = null,
		    a01_aux_dep_act = null,
		    a01_aux_pago    = null,
			a01_aux_venta   = null,
			a01_aux_gasto   = null,
			a01_aux_iva     = null
		where 1 = 1;

	insert into actt001
		select * from t1;

	drop table t1;

	insert into actt002
		select * from acero_gm:actt002;

	insert into actt003
		select * from acero_gm:actt003
			where a03_responsable = 1;

	insert into actt004
		select * from acero_gm:actt004;

	insert into actt005
		select * from acero_gm:actt005;

	insert into actt006
		select * from acero_gm:actt006;

--rollback work;
commit work;
