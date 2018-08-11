SELECT n30_cod_trab AS codi,
	n30_nombres AS empl,
	g34_nombre AS depto,
	g35_nombre AS carg,
	a.n32_ano_proceso AS anio,
	MAX(a.n32_sueldo) AS sueld,
	ABS((MAX(a.n32_sueldo) /
	MAX((SELECT MAX(b.n32_sueldo)
		FROM rolt032 b
		WHERE b.n32_compania    = a.n32_compania
		  AND b.n32_cod_trab    = a.n32_cod_trab
		  AND b.n32_ano_proceso= a.n32_ano_proceso - 1))) - 1) AS prome,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est
	FROM rolt030, rolt032 a, gent034, gent035
	WHERE n30_compania       = 1
	  AND n30_estado        <> "J"
	  AND a.n32_compania     = n30_compania
	  AND a.n32_cod_trab     = n30_cod_trab
	  AND a.n32_ano_proceso  > YEAR(TODAY) - 5
	  AND g34_compania       = a.n32_compania
	  AND g34_cod_depto      = a.n32_cod_depto
	  AND g35_compania       = n30_compania
	  AND g35_cod_cargo      = n30_cod_cargo
	GROUP BY 1, 2, 3, 4, 5, 8;
