SELECT n30_num_doc_id cedula, n30_nombres[1,25], NVL(SUM(n33_valor), 0) valor
	FROM rolt033, rolt030
	WHERE n33_compania    = 1
	  AND n33_cod_liqrol IN ('Q1', 'Q2')
	  AND n33_fecha_ini  >= mdy(07,01,2005)
	  AND n33_fecha_fin  <= mdy(07,31,2005)
	  AND n33_cod_rubro  IN (8, 10, 13, 17)
	  AND n30_compania    = n33_compania
	  AND n30_cod_trab    = n33_cod_trab
	GROUP BY 1, 2
	HAVING NVL(SUM(n33_valor), 0) > 0;

SELECT n30_num_doc_id cedula, n30_nombres[1,25],
	(select nvl(sum(n32_tot_gan), 0) - n30_sueldo_mes tot_gan
		from rolt032, rolt033 b
		WHERE n32_compania     = 1
		  AND n32_cod_liqrol  IN ('Q1', 'Q2')
		  AND n32_fecha_ini   >= mdy(07,01,2005)
		  AND n32_fecha_fin   <= mdy(07,31,2005)
		  and n32_cod_trab     = n33_cod_trab
		  and b.n33_compania   = n32_compania
		  and b.n33_cod_liqrol = n32_cod_liqrol
		  and b.n33_fecha_ini  = n32_fecha_ini
		  and b.n33_fecha_fin  = n32_fecha_fin
		  and b.n33_cod_trab   = n32_cod_trab
		  and b.n33_cod_rubro  = 12
		  and b.n33_valor      > 0
		group by 1
		having nvl(sum(n32_tot_gan), 0) >= n30_sueldo_mes) -
	NVL(SUM(n33_valor), 0) valor
	FROM rolt033, rolt030
	WHERE n33_compania    = 1
	  AND n33_cod_liqrol IN ('Q1', 'Q2')
	  AND n33_fecha_ini  >= mdy(07,01,2005)
	  AND n33_fecha_fin  <= mdy(07,31,2005)
	  AND n33_cod_rubro  IN (8, 10, 13, 17)
	  AND n30_compania    = n33_compania
	  AND n30_cod_trab    = n33_cod_trab
	GROUP BY 1, 2
	HAVING NVL(SUM(n33_valor), 0) > 0;
