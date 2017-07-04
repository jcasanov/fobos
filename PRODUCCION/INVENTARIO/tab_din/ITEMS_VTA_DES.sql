SELECT r10_codigo AS item,
	r10_cod_clase AS clase,
	r72_desc_clase AS nom_clase,
	r10_nombre AS descripcion,
	r10_cod_comerc AS referencia,
	r10_marca AS marca,
	CASE WHEN r10_estado = 'A'
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS estado
	FROM rept010, rept072
	WHERE r10_compania  = 1
	  AND r72_compania  = r10_compania
	  AND r72_linea     = r10_linea
	  AND r72_sub_linea = r10_sub_linea
	  AND r72_cod_grupo = r10_cod_grupo
	  AND r72_cod_clase = r10_cod_clase
	ORDER BY 1 ASC;
