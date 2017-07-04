SELECT n30_cod_trab AS codi,
	n30_nombres AS empl,
	ROUND((SELECT COUNT(*)
		FROM rolt032
		WHERE n32_compania         = n30_compania
		  AND n32_cod_liqrol      IN ("Q1", "Q2")
		  AND n32_cod_trab         = n30_cod_trab
		  AND DATE(n32_fecha_fin) BETWEEN
			DATE(MDY(MONTH(TODAY), DAY(TODAY), YEAR(TODAY) - 5))
			AND DATE(MDY(12, 31, YEAR(TODAY) - 5))) / 2,
	2) AS t_mes_anio1
	FROM rolt030
	WHERE n30_compania = 1
	  AND n30_estado   = "A"
	ORDER BY 2 ASC;
