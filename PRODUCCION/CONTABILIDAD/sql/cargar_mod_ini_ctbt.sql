begin work;

	select * from jadesa:ctbt000
		into temp t1;

	select * from t1 into temp t2;

	update t2
		set b00_cuenta_uti  = null,
			b00_cta_uti_ant = null,
			b00_cuenta_difi = null,
			b00_cuenta_dife = null
		where 1 = 1;

	insert into ctbt000
		select * from t2;

	drop table t2;

	insert into ctbt001
		select * from jadesa:ctbt001;

	insert into ctbt002
		select * from jadesa:ctbt002;

	insert into ctbt003
		select * from jadesa:ctbt003;

	select * from jadesa:ctbt004
		into temp t2;

	update t2
		set b04_usuario = 'FOBOS'
		where 1 = 1;

	insert into ctbt004
		select * from t2;

	drop table t2;

	select b05_compania, b05_tipo_comp
		from jadesa:ctbt005
		group by 1, 2
		into temp t2;

	insert into ctbt005
		(b05_compania, b05_tipo_comp, b05_ano, b05_mes01, b05_mes02, b05_mes03,
		 b05_mes04, b05_mes05, b05_mes06, b05_mes07, b05_mes08, b05_mes09,
		 b05_mes10, b05_mes11, b05_mes12, b05_usuario, b05_fecing)

	-- PONER EL AÑO CON EL QUE SE QUIERE COMENZAR EL MODULO DE CONTABILIDAD
		select b05_compania, b05_tipo_comp, 2017, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
				0, 0, 'FOBOS', current
			from t2;
	--

	drop table t2;

	insert into ctbt007
		select * from jadesa:ctbt007;

	select * from jadesa:ctbt010
		into temp t2;

	update t2
		set b10_usuario = 'FOBOS'
		where 1 = 1;

	insert into ctbt010
		select * from t2;

	drop table t2;

	update ctbt000
		set b00_cuenta_uti  = (select b00_cuenta_uti
								from t1),
			b00_cta_uti_ant = (select b00_cta_uti_ant
								from t1)
		where 1 = 1;

	drop table t1;

--rollback work;
commit work;
