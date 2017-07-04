SELECT n30_num_doc_id AS cedula, n30_nombres AS empleados,
	g35_nombre AS cargo,
	ROUND(((TODAY - n30_fecha_nacim) + 1) / 365, 0) AS edad,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM rolt030, gent035
	WHERE n30_compania  = 1
	  AND n30_estado    = 'A'
	  AND g35_compania  = n30_compania
	  AND g35_cod_cargo = n30_cod_cargo
	ORDER BY 2;
