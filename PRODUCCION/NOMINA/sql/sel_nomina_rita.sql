unload to "rol_rita.txt"
	select n32_fecha_fin, n30_nombres, n32_tot_neto
		from rolt032, rolt030
		where n32_compania    = 1
		  and n32_cod_liqrol in ('Q1', 'Q2')
		  and n32_fecha_ini  >= mdy(02, 16, 2005)
		  and n32_fecha_fin  <= mdy(04, 15, 2005)
		  and n30_compania    = n32_compania
		  and n30_cod_trab    = n32_cod_trab
		order by n32_fecha_fin, n30_nombres;
