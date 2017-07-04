SELECT n30_cod_trab AS codigo,
	n30_nombres AS empleados,
	n30_num_doc_id AS cedula,
	n30_domicilio AS direccion,
	n30_telef_domic AS telefono,
	n30_sectorial AS cod_sect,
	n17_descripcion AS sectorial,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM rolt030, rolt017
	WHERE n30_compania   = 1
	  AND n30_cod_trab  IN
		(SELECT UNIQUE n32_cod_trab
			FROM rolt032
			WHERE n32_compania     = n30_compania
			  AND n32_cod_liqrol  IN ("Q1", "Q2")
			  AND n32_ano_proceso  = 2013)
	  AND n17_compania   = n30_compania
	  AND n17_ano_sect   = n30_ano_sect
	  AND n17_sectorial  = n30_sectorial
	ORDER BY 2;
