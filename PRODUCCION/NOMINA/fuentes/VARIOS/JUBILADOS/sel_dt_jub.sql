SELECT LPAD(n48_cod_trab, 3, 0) AS cod, n30_nombres[1, 35] AS empleados,
	NVL(SUM(n48_val_jub_pat), 0) tot_gan,
	ROUND(NVL(SUM(n48_val_jub_pat / 12), 0), 2) val_dt
	FROM rolt048, rolt030, rolt003
	WHERE n48_compania    = 1
	  AND n48_proceso     = 'JU'
	  AND n48_cod_liqrol  = 'ME'
	  AND n48_fecha_ini  >= MDY(n03_mes_ini, n03_dia_ini, YEAR(TODAY) - 1)
	  AND n48_fecha_fin  <= MDY(n03_mes_fin, n03_dia_fin, YEAR(TODAY))
	  AND n30_compania    = n48_compania
	  AND n30_cod_trab    = n48_cod_trab
	  AND n03_proceso     = 'DT'
	GROUP BY 1, 2
	ORDER BY 2;
