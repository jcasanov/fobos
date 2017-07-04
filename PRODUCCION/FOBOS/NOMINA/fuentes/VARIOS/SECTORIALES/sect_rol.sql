SELECT n30_cod_trab AS codigo,
	n30_num_doc_id AS cedula,
	n30_nombres AS empleados,
	CAST(TRIM(n30_sectorial) AS DECIMAL) AS sectorial,
	n17_descripcion AS descripcion,
	NVL((SELECT n32_sueldo_mes
		FROM rolt032
		WHERE n32_compania   = n30_compania
		  AND n32_cod_liqrol = "Q1"
		  AND n32_fecha_ini  = MDY(01,01,2013)
		  AND n32_fecha_fin  = MDY(01,15,2013)
		  AND n32_cod_trab   = n30_cod_trab),
		n30_sueldo_mes) AS sueldo_act,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	END AS estado
	FROM rolt030, rolt017
	WHERE n30_compania   = 1
	  AND n30_estado    <> "I"
	  AND n17_compania   = n30_compania
	  AND n17_ano_sect   = n30_ano_sect
	  AND n17_sectorial  = n30_sectorial
	ORDER BY 3 ASC;
