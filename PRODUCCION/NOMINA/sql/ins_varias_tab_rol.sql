
--******************************************************************************
-- ESTE SCRIPT SE DEBE DE EJECUTAR DESPUES DE CREAR LOS PARAMETROS EN LOS 
-- PROGRAMAS rolp100 y rolp101
--******************************************************************************

begin work;

	update rolt001
		set n01_ano_proceso = 2017,
			n01_mes_proceso = 12
		where n01_compania = 1;

	insert into rolt003
		select * from acero_gm:rolt003;

	insert into rolt005
		select n05_compania, n05_proceso, n05_activo, n05_fecini_act,
				n05_fecfin_act, n05_fec_ultcie, n05_fec_cierre, "FOBOS",
				current
			from acero_gm:rolt005;

	update rolt005
		set n05_activo     = 'N',
			n05_fecini_act = null,
			n05_fecfin_act = null,
			n05_fec_ultcie = mdy(11, 30, 2017),
			n05_fec_cierre = mdy(11, 30, 2017)
		where 1 = 1;

	insert into rolt016
		select * from acero_gm:rolt016;

	insert into rolt006
		select n06_cod_rubro, n06_nombre, n06_nombre_abr, n06_etiq_impr,
				n06_estado, n06_orden, n06_det_tot, n06_cant_valor, n06_calculo,
				n06_ing_usuario, n06_imprime_0, n06_cont_colect, n06_flag_ident,
				n06_rubro_dscto, n06_valor_fijo, n06_cont_prest, "FOBOS",
				current
			from acero_gm:rolt006;

	insert into rolt007
		select n07_cod_rubro, n07_tipo_calc, n07_operacion, n07_factor,
				n07_valor_max, n07_valor_min, n07_ganado_max, n07_sum_liq_ant,
				"FOBOS", current
			from acero_gm:rolt007;

	insert into rolt008
		select * from acero_gm:rolt008;

	insert into rolt009
		select n09_compania, n09_cod_rubro, n09_estado, n09_valor, "FOBOS",
				current
			from acero_gm:rolt009;

	insert into rolt011
		select * from acero_gm:rolt011;

	insert into rolt013
		select * from acero_gm:rolt013;

	select * from rolt017
		where n17_compania = 999
		into temp tmp_n17;

	insert into tmp_n17
		select * from acero_gm:rolt017;

	insert into tmp_n17
		(n17_compania, n17_ano_sect, n17_sectorial, n17_descripcion, n17_valor,
		 n17_usuario, n17_fecing)
		select n17_compania, 2018, n17_sectorial, n17_descripcion,
				n17_valor + 30, "FOBOS", current
			from tmp_n17
			where n17_ano_sect = 2015;

	insert into rolt017
		select * from tmp_n17;

	drop table tmp_n17;

	insert into rolt018
		select * from acero_gm:rolt018;

	insert into rolt022
		select * from acero_gm:rolt022;

	insert into rolt023
		select * from acero_gm:rolt023;

	insert into rolt024
		select * from acero_gm:rolt024;

	insert into rolt025
		select * from acero_gm:rolt025;

	insert into rolt028
		select * from acero_gm:rolt028;

	insert into rolt090
		select * from acero_gm:rolt090;

--rollback work;
commit work;
