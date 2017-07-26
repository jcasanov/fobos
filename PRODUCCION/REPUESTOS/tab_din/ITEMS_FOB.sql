SELECT (SELECT g02_abreviacion
		FROM gent002
		WHERE g02_compania  = r10_compania
		  AND g02_localidad = 1) AS loc,
	CAST(r10_codigo AS INTEGER) AS item,
	r10_nombre AS descrip,
	r10_marca AS marc,
	r10_filtro AS filtr,
	r72_desc_clase AS nom_cla,
	r10_precio_mb AS preci,
	r10_costo_mb AS cost,
	r10_fob AS p_fob,
	CASE WHEN r10_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est
	FROM rept010, rept072
	WHERE r10_compania  = 1
	  AND r72_compania  = r10_compania
	  AND r72_linea     = r10_linea
	  AND r72_sub_linea = r10_sub_linea
	  AND r72_cod_grupo = r10_cod_grupo
	  AND r72_cod_clase = r10_cod_clase
UNION
SELECT (SELECT g02_abreviacion
		FROM acero_qm@acgyede:gent002
		WHERE g02_compania  = r10_compania
		  AND g02_localidad = 3) AS loc,
	CAST(r10_codigo AS INTEGER) AS item,
	r10_nombre AS descrip,
	r10_marca AS marc,
	r10_filtro AS filtr,
	r72_desc_clase AS nom_cla,
	r10_precio_mb AS preci,
	r10_costo_mb AS cost,
	r10_fob AS p_fob,
	CASE WHEN r10_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est
	FROM acero_qm@acgyede:rept010, acero_qm@acgyede:rept072
	WHERE r10_compania  = 1
	  AND r72_compania  = r10_compania
	  AND r72_linea     = r10_linea
	  AND r72_sub_linea = r10_sub_linea
	  AND r72_cod_grupo = r10_cod_grupo
	  AND r72_cod_clase = r10_cod_clase;
