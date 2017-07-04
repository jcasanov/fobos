select * from rolt043
	where n43_compania  = 1
	  and n43_num_rol  in (16, 17)
	into temp t1;

update t1
	set n43_num_rol = n43_num_rol + 2
	where 1 = 1;

begin work;
	
	insert into rolt043
		select * from t1;

	drop table t1;

	update rolt044
		set n44_num_rol = 18
		where n44_compania = 1
		  and n44_num_rol  = 16;

	update rolt044
		set n44_num_rol = 19
		where n44_compania = 1
		  and n44_num_rol  = 17;

	delete from rolt043
		where n43_compania  = 1
		  and n43_num_rol  in (16, 17);

	select * from rolt043
		where n43_compania  = 1
		  and n43_num_rol  in (18, 19)
		into temp t1;

	update t1
		set n43_num_rol = n43_num_rol - 1
		where 1 = 1;
	
	insert into rolt043
		select * from t1
			where n43_num_rol = 17;

	update rolt044
		set n44_num_rol = 17
		where n44_compania = 1
		  and n44_num_rol  = 18;

	delete from rolt043
		where n43_compania = 1
		  and n43_num_rol  = 18;
	
	insert into rolt043
		select * from t1
			where n43_num_rol = 18;

	drop table t1;

	update rolt044
		set n44_num_rol = 18
		where n44_compania = 1
		  and n44_num_rol  = 19;

	delete from rolt043
		where n43_compania = 1
		  and n43_num_rol  = 19;

	insert into rolt043
		(n43_compania, n43_num_rol, n43_titulo, n43_estado, n43_moneda,
		 n43_paridad, n43_pago_efec, n43_tributa, n43_incluir_ej,
		 n43_usuario, n43_fecing)
		values (1, 16, "BONIFICACION POR FIESTAS GYE JULIO 2014",
			"P", "DO", 1, "S", "N", "S", "FOBOS",
			"2014-07-23 16:04:10");

	insert into rolt044
		(n44_compania, n44_num_rol, n44_cod_trab, n44_cod_depto,
		 n44_tipo_pago, n44_valor)
		select n32_compania, 16, n32_cod_trab, n32_cod_depto, "E", 20
			from rolt032
			where n32_compania    = 1
			  and n32_cod_liqrol  = "Q2"
			  and n32_fecha_ini   = mdy(07, 16, 2014)
			  and n32_fecha_fin   = mdy(07, 31, 2014)
			  and n32_cod_trab   <> 221;

	insert into rolt053
		(n53_compania, n53_cod_liqrol, n53_fecha_ini, n53_fecha_fin,
		 n53_tipo_comp, n53_num_comp)
		values (1, "UV", mdy(07, 23, 2014), mdy(07, 23, 2014), "DC",
			"14070728");

	select b12_compania cia, b12_tipo_comp tc, b12_num_comp num,
		replace(b12_glosa, "# 016", "# 017") glosa
		from ctbt012
		where b12_compania  = 1
		  and b12_tipo_comp = "DN"
		  and b12_num_comp  = "14100001"
		into temp t1;

	select b13_compania cia, b13_tipo_comp tc, b13_num_comp num,
		b13_secuencia secu, replace(b13_glosa, "# 16", "# 17") glosa
		from ctbt013
		where b13_compania  = 1
		  and b13_tipo_comp = "DN"
		  and b13_num_comp  = "14100001"
		into temp t2;

	insert into t1
		select b12_compania cia, b12_tipo_comp tc, b12_num_comp num,
			replace(b12_glosa, "# 017", "# 018") glosa
			from ctbt012
			where b12_compania  = 1
			  and b12_tipo_comp = "DN"
			  and b12_num_comp  = "14100004";

	insert into t2
		select b13_compania cia, b13_tipo_comp tc, b13_num_comp num,
			b13_secuencia secu,
			replace(b13_glosa, "# 17", "# 18") glosa
			from ctbt013
			where b13_compania  = 1
			  and b13_tipo_comp = "DN"
			  and b13_num_comp  = "14100004";

	update ctbt012
		set b12_glosa = (select glosa
					from t1
					where cia = b12_compania
					  and tc  = b12_tipo_comp
					  and num = b12_num_comp)
		where b12_compania || b12_tipo_comp || b12_num_comp in
			(select cia || tc || num from t1);

	update ctbt013
		set b13_glosa = (select glosa
					from t2
					where cia  = b13_compania
					  and tc   = b13_tipo_comp
					  and num  = b13_num_comp
					  and secu = b13_secuencia)
		where b13_compania || b13_tipo_comp || b13_num_comp
			|| b13_secuencia in
			(select cia || tc || num || secu from t2);

	drop table t1;
	drop table t2;

--rollback work;
commit work;
