select n56_compania cia, 75 rubro, n30_cod_trab cod_trab, n30_nombres empleado,
	n56_aux_val_vac cuenta
	from rolt030, rolt056
	where n30_compania  = 1
	  and n30_estado    = 'A'
	  and n56_compania  = n30_compania
	  and n56_proceso   = 'AN'
	  and n56_cod_depto = n30_cod_depto
	  and n56_cod_trab  = n30_cod_trab
	into temp t1;

select cia compa, cod_trab emp, trim('51030701' || cuenta[9, 11]) cta,
	trim('GTOS.NO DEDUCIBLES ' || empleado[1, 21]) descripcion, 'A' est_c,
	'R' tip_c, 'D' tip_m, 6 nivel, 'N' flag_s
	from t1
	into temp tmp_b10;

select cia, rubro, cod_trab, cta
	from t1, tmp_b10
	where cod_trab = emp
	into temp tmp_n52;

drop table t1;

begin work;

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

	drop table tmp_b10;

	drop table tmp_n52;

commit work;
