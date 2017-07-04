SELECT n30_num_doc_id AS cedula, n30_nombres AS empleados, n30_sexo AS genero,
	g35_nombre AS ocupacion, n42_num_cargas AS cargas,
	n42_dias_trab AS dias_laborados,
	CASE WHEN n42_tipo_pago = 'T'
		THEN "A"
		ELSE "P"
	END tipo_dep
	FROM rolt042, rolt030, gent035
	WHERE n42_compania  = 1
	  AND n42_ano       = 2010
	  AND n30_compania  = n42_compania
	  AND n30_cod_trab  = n42_cod_trab
	  AND g35_compania  = n30_compania
	  AND g35_cod_cargo = n30_cod_cargo
	ORDER BY n30_nombres ASC;
