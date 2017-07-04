create temp table t1

	(
		cia		integer,
		rubro		smallint,
		cod_depto	smallint,
		depart		varchar(30,15),
		cuenta		char(12),
		fr_men		char(1),
		secuencia	serial
	);

select * from t1 into temp t2;

insert into t1
	select unique n50_compania cia,
		(select n06_cod_rubro
			from rolt006
			where n06_flag_ident = 'FM') rubro,
		n50_cod_depto cod_depto, g34_nombre depart, n50_aux_cont cuenta,
		n30_fon_res_anio fr_men, 0 sec
		from rolt050, gent034, rolt030
		where n50_compania     = 1
		  and n50_cod_rubro    = 2
		  and g34_compania     = n50_compania
		  and g34_cod_depto    = n50_cod_depto
		  and n30_compania     = g34_compania
		  and n30_cod_depto    = g34_cod_depto
		  and n30_estado       = 'A'
		  and n30_fon_res_anio = 'N';

insert into t2
	select unique n50_compania cia,
		(select n06_cod_rubro
			from rolt006
			where n06_flag_ident = 'FM') rubro,
		n50_cod_depto cod_depto, g34_nombre depart, n50_aux_cont cuenta,
		n30_fon_res_anio fr_men, 0 sec
		from rolt050, gent034, rolt030
		where n50_compania     = 1
		  and n50_cod_rubro    = 2
		  and g34_compania     = n50_compania
		  and g34_cod_depto    = n50_cod_depto
		  and n30_compania     = g34_compania
		  and n30_cod_depto    = g34_cod_depto
		  and n30_estado       = 'A'
		  and n30_fon_res_anio = 'S';

select cia compa, cod_depto dep, trim('51010404' || lpad(secuencia, 3, 0)) cta,
	trim('FONDO RESERVA MEN. ' || depart[1, 21]) descripcion,
	'A' est_c, 'R' tip_c, 'D' tip_m, 6 nivel, 'N' flag_s, fr_men fon_men
	from t1
	union
	select cia compa, cod_depto dep,
		trim('51010405' || lpad(secuencia, 3, 0)) cta,
		trim('FONDO RESERVA ACU. ' || depart[1, 21]) descripcion,
		'A' est_c, 'R' tip_c, 'D' tip_m, 6 nivel, 'N' flag_s,
		fr_men fon_men
		from t2
	into temp tmp_b10;

select cia, rubro, cod_depto, cta
	from t1, tmp_b10
	where cod_depto = dep
	  and fon_men   = fr_men
	into temp tmp_n50;

drop table t1;
drop table t2;

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

	insert into rolt050
		(n50_compania, n50_cod_rubro, n50_cod_depto, n50_aux_cont)
		select * from tmp_n50;

	update rolt056
		set n56_aux_val_vac = (select cta
					from tmp_b10
					where dep     = n56_cod_depto
					  and fon_men = 'S'),
		    n56_aux_banco   = '11020101003'
		where n56_compania  = 1
		  and n56_estado    = 'A'
		  and n56_proceso   = 'FR'
		  and n56_cod_depto in (select dep
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

	drop table tmp_n50;

commit work;
