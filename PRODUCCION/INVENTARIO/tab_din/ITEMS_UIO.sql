SELECT (SELECT g02_abreviacion
		FROM acero_qm@acgyede:gent002
		WHERE g02_compania  = r10_compania
		  AND g02_localidad = 3) AS loc,
	CAST(r10_codigo AS INTEGER) AS item,
	r03_nombre AS divi,
	r70_desc_sub AS nom_lin,
	r71_desc_grupo AS nom_grp,
	r72_desc_clase AS nom_cla,
	r10_nombre AS descrip,
	r10_marca AS marc,
	r10_filtro AS filtr,
	r10_precio_mb AS preci,
	r10_costo_mb AS cost,
	r10_fob AS p_fob,
	CASE WHEN r10_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est
	FROM acero_qm@acgyede:rept010, acero_qm@acgyede:rept003,
		acero_qm@acgyede:rept070, acero_qm@acgyede:rept071,
		acero_qm@acgyede:rept072
	WHERE r10_compania  = 1
	  AND r03_compania  = r10_compania
	  AND r03_codigo    = r10_linea
	  AND r70_compania  = r10_compania
	  AND r70_linea     = r10_linea
	  AND r70_sub_linea = r10_sub_linea
	  AND r71_compania  = r10_compania
	  AND r71_linea     = r10_linea
	  AND r71_sub_linea = r10_sub_linea
	  AND r71_cod_grupo = r10_cod_grupo
	  AND r72_compania  = r10_compania
	  AND r72_linea     = r10_linea
	  AND r72_sub_linea = r10_sub_linea
	  AND r72_cod_grupo = r10_cod_grupo
	  AND r72_cod_clase = r10_cod_clase;
