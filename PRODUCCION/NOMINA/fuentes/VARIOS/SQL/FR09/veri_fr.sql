select n32_cod_trab cod_trab, n33_valor val_fon, n33_horas_porc dias
	from rolt032, rolt033
	where n32_compania     = 1
	  and n32_cod_liqrol   = 'Q1'
	  and n32_ano_proceso  = 2009
	  and n32_mes_proceso  = 9
	  and n33_compania     = n32_compania
	  and n33_cod_liqrol   = n32_cod_liqrol
	  and n33_fecha_ini    = n32_fecha_ini
	  and n33_fecha_fin    = n32_fecha_fin
	  and n33_cod_trab     = n32_cod_trab
	  and n33_cod_rubro    = (select n06_cod_rubro from rolt006
					where n06_flag_ident = 'FM')
	  and n33_valor        > 0
	into temp t1;
select lpad(n32_cod_trab, 3, 0) cod, n30_nombres[1,15] empleado,
	nvl(sum(n32_tot_gan), 0) tot_gan
	from rolt032, rolt030
	where n32_compania     = 1
	  and n32_cod_liqrol  in ('Q1', 'Q2')
	  and n32_ano_proceso  = 2009
	  and n32_mes_proceso  = 8
	  and n32_cod_trab    in (select cod_trab from t1)
	  and n30_compania     = n32_compania
	  and n30_cod_trab     = n32_cod_trab
	  and n30_fon_res_anio = 'N'
	group by 1, 2
	into temp t2;
select cod, empleado, round((tot_gan / dias) * 30, 2) tot_gan, dias,
	round(((tot_gan / 30) * dias) * 8.33 / 100, 2) veri, val_fon
	from t2, t1
	where cod = cod_trab
	into temp t3;
drop table t1;
drop table t2;
select sum(veri), sum(val_fon) from t3;
select * from t3 order by 2;
drop table t3;
