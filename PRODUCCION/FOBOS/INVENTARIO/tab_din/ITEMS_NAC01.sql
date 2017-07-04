SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || g02_abreviacion
		FROM aceros@acgyede:gent002
		WHERE g02_compania  = r10_compania
		  AND g02_localidad = 1) AS loc,
	CAST(r10_codigo AS INTEGER) AS item,
	r72_desc_clase AS nom_cla,
	r10_nombre AS descrip,
	r10_precio_mb AS preci,
	CASE WHEN r10_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est,
	r10_costo_mb AS cost,
	r10_marca AS marc,
	NVL((SELECT SUM(r11_stock_act)
		FROM aceros@acgyede:rept011,
			aceros@acgyede:rept002
		WHERE r11_compania   = r10_compania
		  AND r11_item       = r10_codigo
		  AND r11_stock_act  > 0
		  AND r02_compania   = r11_compania
		  AND r02_codigo     = r11_bodega
		  AND r02_localidad  = 1
		  AND r02_tipo      <> "S"), 0.00) AS sto
	FROM aceros@acgyede:rept010,
		aceros@acgyede:rept072
	WHERE r10_compania  = 1
	  AND r72_compania  = r10_compania
	  AND r72_linea     = r10_linea
	  AND r72_sub_linea = r10_sub_linea
	  AND r72_cod_grupo = r10_cod_grupo
	  AND r72_cod_clase = r10_cod_clase;
