SELECT UNIQUE n30_cod_trab AS codi,
	CASE WHEN n30_cod_trab = 170
		THEN n30_carnet_seg
		ELSE n30_num_doc_id
	END AS cedu,
	n30_nombres AS empl,
	g34_nombre AS depto,
	g35_nombre AS carg,
	YEAR(n32_fecha_fin) AS anio,
	CASE WHEN MONTH(n32_fecha_fin) = 01 THEN "ENE"
	     WHEN MONTH(n32_fecha_fin) = 02 THEN "FEB"
	     WHEN MONTH(n32_fecha_fin) = 03 THEN "MAR"
	     WHEN MONTH(n32_fecha_fin) = 04 THEN "ABR"
	     WHEN MONTH(n32_fecha_fin) = 05 THEN "MAY"
	     WHEN MONTH(n32_fecha_fin) = 06 THEN "JUN"
	     WHEN MONTH(n32_fecha_fin) = 07 THEN "JUL"
	     WHEN MONTH(n32_fecha_fin) = 08 THEN "AGO"
	     WHEN MONTH(n32_fecha_fin) = 09 THEN "SEP"
	     WHEN MONTH(n32_fecha_fin) = 10 THEN "OCT"
	     WHEN MONTH(n32_fecha_fin) = 11 THEN "NOV"
	     WHEN MONTH(n32_fecha_fin) = 12 THEN "DIC"
	END AS mes
	FROM rolt030, rolt032, gent034, gent035
	WHERE n30_compania    = 1
	  AND n32_compania    = n30_compania
	  AND n32_cod_liqrol IN ("Q1", "Q2")
	  AND n32_fecha_ini  >= MDY(01, 01, 2009)
	  AND n32_fecha_fin  <= MDY(12, 31, 2012)
	  AND n32_cod_trab    = n30_cod_trab
	  AND g34_compania    = n32_compania
	  AND g34_cod_depto   = n32_cod_depto 
	  AND g35_compania    = n30_compania
	  AND g35_cod_cargo   = n30_cod_cargo 
	ORDER BY 1, 2, 3, 4, 5, 6, 7;
