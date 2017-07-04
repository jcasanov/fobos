create temp table t1
	(
		cia		integer,
		cod_trab	smallint,
		aux_cont	char(12),
		valor           decimal(12,2),
		secuencia	serial
	);

insert into t1
	select n44_compania, n44_cod_trab, n52_aux_cont, n44_valor, 0
		from rolt052, rolt044
		where n52_compania   = 1
		  and n52_cod_rubro  = 75
		  and n44_compania   = n52_compania
		  and n44_num_rol    = 7	-- CAMBIA POR ROL DE USO VARIO
		  and n44_cod_trab   = n52_cod_trab;

begin work;

	update rolt044
		set n44_tipo_pago   = 'E',
		    n44_bco_empresa = null,
		    n44_cta_empresa = null,
		    n44_cta_trabaj  = null
		where n44_compania = 1
		  and n44_num_rol  = 7;		-- CAMBIA POR ROL DE USO VARIO

	update ctbt012
		set b12_origen     = 'A',
		    b12_modulo     = 'RO',
		    b12_fec_modifi = null
		where b12_compania  = 1
		  and b12_tipo_comp = 'DN'
		  and b12_num_comp  = '10100002';

	update ctbt013
		set b13_secuencia = b13_secuencia + (select count(*) from t1)
		where b13_compania  = 1
		  and b13_tipo_comp = 'DN'
		  and b13_num_comp  = '10100002';

	insert into ctbt013
		(b13_compania, b13_tipo_comp, b13_num_comp, b13_secuencia,
		 b13_cuenta, b13_glosa, b13_valor_base, b13_valor_aux,
		 b13_fec_proceso)
		select cia, 'DN', '10100002', secuencia, aux_cont,
			'ROL USO VARIOS # 7. FECHA: 08-10-2010',
			valor, 0.00, today
			from t1;

	{--
	insert into ctbt013
		(b13_compania, b13_tipo_comp, b13_num_comp, b13_secuencia,
		 b13_cuenta, b13_glosa, b13_valor_base, b13_valor_aux,
		 b13_fec_proceso)
		select cia, 'DN', '10070003', secuencia, aux_cont,
			'ROL USO VARIOS # 6. FECHA: 23-07-2010',
			valor, 0.00, today
			from t1;

	insert into ctbt013
		(b13_compania, b13_tipo_comp, b13_num_comp, b13_secuencia,
		 b13_cuenta, b13_glosa, b13_valor_base, b13_valor_aux,
		 b13_fec_proceso)
		select cia, 'DN', '09100002', secuencia, aux_cont,
			'ROL USO VARIOS # 5. FECHA: 08-10-2009',
			valor, 0.00, today
			from t1;

	insert into ctbt013
		(b13_compania, b13_tipo_comp, b13_num_comp, b13_secuencia,
		 b13_cuenta, b13_glosa, b13_valor_base, b13_valor_aux,
		 b13_fec_proceso)
		select cia, 'EG', '09070128', secuencia, aux_cont,
			'ROL USO VARIOS # 4. FECHA: 07-24-2009',
			valor, 0.00, today
			from t1;
	--}

commit work;

drop table t1;
