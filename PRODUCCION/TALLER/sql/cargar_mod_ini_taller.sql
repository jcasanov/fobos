begin work;

	insert into talt000
		select * from acero_gm:talt000;

	update talt000
		set t00_anopro = 2018
		where 1 = 1;

	insert into talt001
		(t01_compania, t01_linea, t01_nombre, t01_cod_mod_veh, t01_dcto_mo_cont,
		 t01_dcto_rp_cont, t01_dcto_mo_cred, t01_dcto_rp_cred, t01_grupo_linea,
		 t01_usuario, t01_fecing)
		values (1, 'VTAST', 'VENTAS TALLER', 'N', 0, 15, 0, 15, 'VTAST',
				'FOBOS', current);

	insert into talt002
		(t02_compania, t02_seccion, t02_nombre, t02_jefe, t02_usuario,
		 t02_fecing)
		values (1, 1, 'TALLER', 'JEFE DE TALLER', 'FOBOS', current);

	insert into talt004
		(t04_compania, t04_modelo, t04_linea, t04_dificultad, t04_cod_mod_veh,
		 t04_usuario, t04_fecing)
		values (1, 'GENERICO', 'VTAST', 5, 'N', 'FOBOS', current);

	insert into talt005
		select * from acero_gm:talt005;

	insert into talt006
		select * from acero_gm:talt006;

	select * from acero_gm:talt007
		into temp t1;

	update t1
		set t07_usuario = 'FOBOS'
		where 1 = 1;

	insert into talt007
		select * from t1;

	drop table t1;

--rollback work;
commit work;
