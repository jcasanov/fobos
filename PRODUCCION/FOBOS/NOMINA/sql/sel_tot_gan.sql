unload to "emplado_reser.txt"
select n32_cod_trab, n30_nombres, round(nvl(sum(n32_tot_gan), 0), 2) valor
	from rolt032, rolt030
	where n32_compania   = 1
	  and n32_cod_liqrol in ('Q1', 'Q2')
	  and n32_fecha_ini  between mdy(07, 01, 2004) and mdy(06, 30, 2005)
	  and n32_fecha_fin  between mdy(07, 01, 2004) and mdy(06, 30, 2005)
	  and n30_compania   = n32_compania
	  and n30_cod_trab   = n32_cod_trab
	  and n30_estado     = 'A'
	group by 1, 2
	order by 2 asc;
