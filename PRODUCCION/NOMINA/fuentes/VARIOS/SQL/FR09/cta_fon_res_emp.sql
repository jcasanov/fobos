select n56_compania cia,
	(select n06_cod_rubro
		from rolt006
		where n06_flag_ident = 'FM') rubro,
	n30_cod_trab cod_trab, n30_nombres empleado, n56_aux_val_vac cuenta,
	n30_fon_res_anio fr_men
	from rolt030, rolt056
	where n30_compania  = 1
	  and n30_estado    = 'A'
	  and n56_compania  = n30_compania
	  and n56_proceso   = 'AN'
	  and n56_cod_depto = n30_cod_depto
	  and n56_cod_trab  = n30_cod_trab
	into temp t1;

select cia compa, cod_trab emp,
	case when fr_men = 'N'
		then trim('51010404' || cuenta[9, 11])
		else trim('51010405' || cuenta[9, 11])
	end cta,
	case when fr_men = 'N'
		then trim('FONDO RESERVA MEN. ' || empleado[1, 21])
		else trim('FONDO RESERVA ACU. ' || empleado[1, 21])
	end descripcion,
	'A' est_c, 'R' tip_c, 'D' tip_m, 6 nivel, 'N' flag_s, fr_men fon_men
	from t1
	into temp tmp_b10;

select cia, rubro, cod_trab, cta
	from t1, tmp_b10
	where cod_trab = emp
	  and fr_men   = 'N'
	into temp tmp_n52;

drop table t1;

begin work;

	insert into ctbt010
		(b10_compania, b10_cuenta, b10_descripcion, b10_descri_alt,
		 b10_estado, b10_tipo_cta, b10_tipo_mov, b10_nivel,
		 b10_cod_ccosto, b10_saldo_ma, b10_usuario, b10_fecing)
		values (1, '51010404', 'FONDO DE RESERVA MENSUAL TRABAJADORES',
			'FONDO RESERVA MEN.', 'A', 'B', 'D', 5, null, 'N',
			'FOBOS', current);

	insert into ctbt010
		(b10_compania, b10_cuenta, b10_descripcion, b10_descri_alt,
		 b10_estado, b10_tipo_cta, b10_tipo_mov, b10_nivel,
		 b10_cod_ccosto, b10_saldo_ma, b10_usuario, b10_fecing)
		values (1, '51010405','FONDO DE RESERVA ACUMULADO TRABAJADORES',
			'FONDO RESERVA ACU.', 'A', 'B', 'D', 5, null, 'N',
			'FOBOS', current);

	insert into ctbt010
		(b10_compania, b10_cuenta, b10_descripcion, b10_estado,
		 b10_tipo_cta, b10_tipo_mov, b10_nivel, b10_saldo_ma,
		 b10_usuario, b10_fecing)
		select compa, cta, descripcion, est_c, tip_c, tip_m, nivel,
			flag_s, 'FOBOS', current
			from tmp_b10
			where not exists
				(select 1 from ctbt010
					where b10_compania = compa
					  and b10_cuenta   = cta);

	insert into rolt052
		(n52_compania, n52_cod_rubro, n52_cod_trab, n52_aux_cont)
		select * from tmp_n52;

	update rolt056
		set n56_aux_val_vac = (select cta
					from tmp_b10
					where emp     = n56_cod_trab
					  and fon_men = 'S'),
		    n56_aux_banco   = '11020101003'
		where n56_compania  = 1
		  and n56_estado    = 'A'
		  and n56_proceso   = 'FR'
		  and n56_cod_trab in (select emp
					from tmp_b10
					where fon_men = 'S');

	update rolt056
		set n56_estado = 'B'
		where n56_compania = 1
		  and n56_estado   = 'A'
		  and n56_proceso  = 'FR'
		  and n56_cod_trab in
			(select n30_cod_trab
				from rolt030
				where n30_compania     = n56_compania
				  and n30_cod_trab     = n56_cod_trab
				  and n30_cod_depto    = n56_cod_depto
				  and n30_estado       = 'A'
				  and n30_fon_res_anio = 'N');

	drop table tmp_b10;

	drop table tmp_n52;

commit work;
