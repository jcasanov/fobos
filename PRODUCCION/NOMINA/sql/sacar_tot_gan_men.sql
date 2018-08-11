select n30_num_doc_id[1, 10] cedula, n30_nombres[1,35] empleado,
	n32_ano_proceso anio, n32_mes_proceso mes,
	round(sum(n32_tot_gan), 2) valor
	from rolt032, rolt033, rolt030
	where n32_compania    =  1
	  and n32_cod_liqrol  in ('Q1', 'Q2')
	  and n32_ano_proceso >= 2005
	  and n33_compania    =  n32_compania
	  and n33_cod_liqrol  =  n32_cod_liqrol
	  and n33_fecha_ini   =  n32_fecha_ini
	  and n33_fecha_fin   =  n32_fecha_fin
	  and n33_cod_trab    =  n32_cod_trab
	  and n33_cod_rubro   =  12
	  and n33_valor       >  0
	  and n30_compania    =  n32_compania
	  and n30_cod_trab    =  n32_cod_trab
	group by 1, 2, 3, 4
	order by 3 desc, 4 desc, 2 asc;
