SELECT n30_cod_trab AS codigo,
	CASE WHEN n30_cod_trab = 170
		THEN n30_num_doc_id[5, 10]
		ELSE n30_num_doc_id
	END AS cedula,
	n30_nombres AS empleados,
	CASE WHEN n30_estado = "A"
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM rolt030
	WHERE n30_compania = 1
	  AND n30_estado   = "A"
UNION
SELECT n30_cod_trab AS codigo,
	CASE WHEN n30_cod_trab = 170
		THEN n30_num_doc_id[5, 10]
		ELSE n30_num_doc_id
	END AS cedula,
	n30_nombres AS empleados,
	CASE WHEN n30_estado = "A"
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM rolt030
	WHERE n30_compania        = 1
	  AND n30_estado          = "I"
	  AND YEAR(n30_fecha_sal) = 2013
	ORDER BY 3;
