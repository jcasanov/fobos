SELECT "GYE" AS loc,
	r10_marca AS marca,
	r73_desc_marca AS desc_marca,
	r10_filtro AS filtro,
	r10_codigo AS item,
	r10_cod_clase AS clase,
	r72_desc_clase AS desc_clase,
	r10_nombre AS decripcion,
	CASE WHEN r10_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM acero_gm@idsgye01:rept010, acero_gm@idsgye01:rept072,
		acero_gm@idsgye01:rept073
	WHERE r10_compania  = 1
	  AND r72_compania  = r10_compania
	  AND r72_linea     = r10_linea
	  AND r72_sub_linea = r10_sub_linea
	  AND r72_cod_grupo = r10_cod_grupo
	  AND r72_cod_clase = r10_cod_clase
	  AND r73_compania  = r10_compania
	  AND r73_marca     = r10_marca
UNION
SELECT "UIO" AS loc,
	r10_marca AS marca,
	r73_desc_marca AS desc_marca,
	r10_filtro AS filtro,
	r10_codigo AS item,
	r10_cod_clase AS clase,
	r72_desc_clase AS desc_clase,
	r10_nombre AS decripcion,
	CASE WHEN r10_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM acero_qm@idsuio01:rept010, acero_qm@idsuio01:rept072,
		acero_qm@idsuio01:rept073
	WHERE r10_compania  = 1
	  AND r72_compania  = r10_compania
	  AND r72_linea     = r10_linea
	  AND r72_sub_linea = r10_sub_linea
	  AND r72_cod_grupo = r10_cod_grupo
	  AND r72_cod_clase = r10_cod_clase
	  AND r73_compania  = r10_compania
	  AND r73_marca     = r10_marca
