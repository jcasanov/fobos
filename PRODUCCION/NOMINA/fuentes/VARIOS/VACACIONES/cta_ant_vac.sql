select n56_compania cia, 'AV' proc, n30_cod_depto depto, n30_cod_trab cod_trab,
	n30_nombres empleado, 'A' est, n56_aux_val_vac cuenta,
	'11020101006' banco
	from rolt030, rolt056
	where n30_compania  = 1
	  and n30_estado    = 'A'
	  and n30_tipo_trab = 'N'
	  and n56_compania  = n30_compania
	  and n56_proceso   = 'AN'
	  and n56_cod_depto = n30_cod_depto
	  and n56_cod_trab  = n30_cod_trab
	into temp t1;

select cia compa, cod_trab emp, trim(cuenta[1, 6] || '10' || cuenta[9, 11]) cta,
	trim('ANT.VACACIONES ' || empleado[1, 25]) descripcion, est est_c,
	'B' tip_c, 'D' tip_m, 6 nivel, 'N' flag_s
	from t1
	into temp tmp_b10;

select cia, proc, depto, cod_trab, empleado, est, cta, banco
	from t1, tmp_b10
	where cod_trab = emp
	into temp t2;

drop table t1;

select cia, proc, depto, cod_trab, est, cta, banco, 'FOBOS' usua, current feci
	from t2
	where not exists
		(select 1 from rolt056 a
			where a.n56_compania  = cia
			  and a.n56_proceso   = proc
			  and a.n56_cod_depto = depto
			  and a.n56_cod_trab  = cod_trab)
	into temp tmp_n56;

select cia, proc, depto, cod_trab, est, cta, banco, 'FOBOS' usua, current feci
	from t2, rolt056 a
	where a.n56_compania  = cia
	  and a.n56_proceso   = proc
	  and a.n56_cod_depto = depto
	  and a.n56_cod_trab  = cod_trab
	into temp t3;

drop table t2;

begin work;

	insert into ctbt010
		(b10_compania, b10_cuenta, b10_descripcion, b10_descri_alt,
		 b10_estado, b10_tipo_cta, b10_tipo_mov, b10_nivel,
		 b10_cod_ccosto, b10_saldo_ma, b10_usuario, b10_fecing)
		values (1, '11210110', 'ANTICIPO VACACIONES TRABAJADORES', null,
			'A', 'B', 'D', 5, null, 'N', 'FOBOS', current);

	insert into ctbt010
		(b10_compania, b10_cuenta, b10_descripcion, b10_estado,
		 b10_tipo_cta, b10_tipo_mov, b10_nivel, b10_saldo_ma,
		 b10_usuario, b10_fecing)
		select compa, cta, descripcion, est_c, tip_c, tip_m, nivel,
			flag_s, 'FOBOS', current
			from tmp_b10;

	insert into rolt056
		(n56_compania, n56_proceso, n56_cod_depto, n56_cod_trab,
		 n56_estado, n56_aux_val_vac, n56_aux_banco, n56_usuario,
		 n56_fecing)
		select * from tmp_n56;

	update rolt056
		set n56_aux_val_vac = (select cta from t3
					where cia      = n56_compania
					  and proc     = n56_proceso
					  and depto    = n56_cod_depto
					  and cod_trab = n56_cod_trab),
		    n56_aux_banco   = (select banco from t3
					where cia      = n56_compania
					  and proc     = n56_proceso
					  and depto    = n56_cod_depto
					  and cod_trab = n56_cod_trab)
		where exists (select * from t3
				where cia      = n56_compania
				  and proc     = n56_proceso
				  and depto    = n56_cod_depto
				  and cod_trab = n56_cod_trab);

	update rolt056
		set n56_aux_iess = '21050101001'
		where n56_compania = 1
		  and n56_proceso  = 'VA'
		  and n56_estado   = 'A';

	--select * from tmp_b10 order by cta;

	--select * from tmp_n56 order by empleado;

	drop table tmp_b10;

	drop table tmp_n56;

	drop table t3;

commit work;
