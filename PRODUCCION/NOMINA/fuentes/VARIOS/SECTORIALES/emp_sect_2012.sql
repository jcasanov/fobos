SELECT n30_cod_trab AS codigo,
	CASE WHEN n30_cod_trab = 170
		THEN n30_carnet_seg
		ELSE n30_num_doc_id
	END AS cedula,
	n30_nombres AS empleado,
	n30_sueldo_mes AS sueldo,
	n30_sectorial AS sectorial,
	n17_descripcion AS nom_sectorial,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM rolt030, rolt017
	WHERE n30_compania  = 1
	  AND n30_estado    = 'A'
	  AND n17_sectorial = n30_sectorial
	ORDER BY 3 ASC;
