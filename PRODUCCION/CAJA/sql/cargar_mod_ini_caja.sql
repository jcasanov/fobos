begin work;

	insert into cajt000
		select * from jadesa:cajt000;

	select * from jadesa:cajt001
		into temp t1;

	update t1
		set j01_usuario = 'FOBOS'
		where 1 = 1;

	insert into cajt001
		select * from t1;

	drop table t1;

	insert into cajt002
		(j02_compania, j02_localidad, j02_codigo_caja, j02_nombre_caja,
		 j02_pre_ventas, j02_ordenes, j02_solicitudes, j02_usua_caja,
		 j02_aux_cont)
		values (1, 1, 1, 'CAJA FOBOS', 'S', 'S', 'S', 'FOBOS', '10108');

	select * from jadesa:cajt091
		into temp t1;

	update t1
		set j91_usuario = 'FOBOS'
		where 1 = 1;

	insert into cajt091
		select * from t1;

	drop table t1;

--rollback work;
commit work;
