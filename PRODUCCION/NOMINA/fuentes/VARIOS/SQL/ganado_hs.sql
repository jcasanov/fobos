SELECT n30_cod_trab AS cod,
	n30_nombres AS nom,
	EXTEND(n32_fecha_fin, YEAR TO MONTH) AS peri,
	n32_ano_proceso AS anio,
	CASE WHEN n32_mes_proceso = 01 THEN "ENERO"
	     WHEN n32_mes_proceso = 02 THEN "FEBRERO"
	     WHEN n32_mes_proceso = 03 THEN "MARZO"
	     WHEN n32_mes_proceso = 04 THEN "ABRIL"
	     WHEN n32_mes_proceso = 05 THEN "MAYO"
	     WHEN n32_mes_proceso = 06 THEN "JUNIO"
	     WHEN n32_mes_proceso = 07 THEN "JULIO"
	     WHEN n32_mes_proceso = 08 THEN "AGOSTO"
	     WHEN n32_mes_proceso = 09 THEN "SEPTIEMBRE"
	     WHEN n32_mes_proceso = 10 THEN "OCTUBRE"
	     WHEN n32_mes_proceso = 11 THEN "NOVIEMBRE"
	     WHEN n32_mes_proceso = 12 THEN "DICIEMBRE"
	END AS mes,
	NVL(SUM(n32_tot_gan), 0.00) AS tot_gan
	FROM rolt032, rolt030
	WHERE n32_compania    = 1
	  AND n32_cod_liqrol IN ("Q1", "Q2")
	  AND n32_cod_trab    = 113
	  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) BETWEEN
		EXTEND(MDY(MONTH(TODAY), 01, YEAR(TODAY) - 5), YEAR TO MONTH)
		AND
		EXTEND(MDY(MONTH(TODAY), 01, YEAR(TODAY)) - 1 UNITS DAY,
			YEAR TO MONTH)
	  AND n30_compania    = n32_compania
	  AND n30_cod_trab    = n32_cod_trab
	GROUP BY 1, 2, 3, 4, 5;
