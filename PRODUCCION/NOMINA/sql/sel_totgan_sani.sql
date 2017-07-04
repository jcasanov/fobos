unload to "emplado_sani.txt"
select lpad(n32_cod_trab, 3, 0) cod, n30_nombres[1, 35] empleado,
	year(n32_fecha_fin) anio, nvl(round(sum(n32_tot_gan), 2), 0) tot_gan
	from rolt032, rolt030
	where n32_compania    = 1
	  and n32_cod_trab   in(4, 119, 35, 41, 62, 63, 64, 72, 76, 77, 86)
	  and n32_cod_liqrol in('Q1', 'Q2')
	  and n32_fecha_ini  >= mdy(01, 01, 2003)
	  and n32_fecha_fin  <= mdy(11, 30, 2005)
	  and n30_compania    = n32_compania
	  and n30_cod_trab    = n32_cod_trab
	group by 1, 2, 3
	order by 3, 2;
