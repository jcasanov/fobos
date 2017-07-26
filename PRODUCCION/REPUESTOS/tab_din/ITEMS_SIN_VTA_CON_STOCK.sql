SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM gent002
		WHERE g02_compania  = r10_compania
		  AND g02_localidad = 1) AS local,
	r10_codigo AS item,
	r72_desc_clase AS clas,
	r10_nombre AS descri,
	r10_filtro AS filt,
	r10_marca AS marc,
	r10_uni_med AS uni,
	r10_precio_mb AS pvp,
	r10_costo_mb AS cost,
	CASE WHEN r10_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est,
	NVL((SELECT SUM(r11_stock_act)
		FROM rept011, rept002
		WHERE r11_compania   = r10_compania
		  AND r11_item       = r10_codigo
		  AND r02_compania   = r11_compania
		  AND r02_codigo     = r11_bodega
		  AND r02_localidad  = 1
		  AND r02_tipo      <> "S"), 0) AS sto
	FROM rept010, rept072
	WHERE r10_compania  = 1
	  AND r72_compania  = r10_compania
	  AND r72_linea     = r10_linea
	  AND r72_sub_linea = r10_sub_linea
	  AND r72_cod_grupo = r10_cod_grupo
	  AND r72_cod_clase = r10_cod_clase
	  AND NVL((SELECT SUM(r11_stock_act)
		FROM rept011, rept002
		WHERE r11_compania   = r10_compania
		  AND r11_item       = r10_codigo
		  AND r02_compania   = r11_compania
		  AND r02_codigo     = r11_bodega
		  AND r02_localidad  = 1
		  AND r02_tipo      <> "S"), 0) > 0
	  AND NOT EXISTS
		(SELECT 1 FROM rept020
			WHERE r20_compania      = r10_compania
			  AND r20_item          = r10_codigo
			  AND YEAR(r20_fecing)  > 2009
			  AND r20_cod_tran     IN ("FA", "DF", "AF"))
UNION
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_gc:gent002
		WHERE g02_compania  = r10_compania
		  AND g02_localidad = 2) AS local,
	r10_codigo AS item,
	r72_desc_clase AS clas,
	r10_nombre AS descri,
	r10_filtro AS filt,
	r10_marca AS marc,
	r10_uni_med AS uni,
	r10_precio_mb AS pvp,
	r10_costo_mb AS cost,
	CASE WHEN r10_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est,
	NVL((SELECT SUM(r11_stock_act)
		FROM acero_gc:rept011, acero_gc:rept002
		WHERE r11_compania   = r10_compania
		  AND r11_item       = r10_codigo
		  AND r02_compania   = r11_compania
		  AND r02_codigo     = r11_bodega
		  AND r02_localidad  = 2
		  AND r02_tipo      <> "S"), 0) AS sto
	FROM acero_gc:rept010, acero_gc:rept072
	WHERE r10_compania  = 1
	  AND r72_compania  = r10_compania
	  AND r72_linea     = r10_linea
	  AND r72_sub_linea = r10_sub_linea
	  AND r72_cod_grupo = r10_cod_grupo
	  AND r72_cod_clase = r10_cod_clase
	  AND NVL((SELECT SUM(r11_stock_act)
		FROM acero_gc:rept011, acero_gc:rept002
		WHERE r11_compania   = r10_compania
		  AND r11_item       = r10_codigo
		  AND r02_compania   = r11_compania
		  AND r02_codigo     = r11_bodega
		  AND r02_localidad  = 2
		  AND r02_tipo      <> "S"), 0) > 0
	  AND NOT EXISTS
		(SELECT 1 FROM acero_gc:rept020
			WHERE r20_compania      = r10_compania
			  AND r20_item          = r10_codigo
			  AND YEAR(r20_fecing)  > 2009
			  AND r20_cod_tran     IN ("FA", "DF", "AF"))
UNION
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_qm:gent002
		WHERE g02_compania  = r10_compania
		  AND g02_localidad = 3) AS local,
	r10_codigo AS item,
	r72_desc_clase AS clas,
	r10_nombre AS descri,
	r10_filtro AS filt,
	r10_marca AS marc,
	r10_uni_med AS uni,
	r10_precio_mb AS pvp,
	r10_costo_mb AS cost,
	CASE WHEN r10_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est,
	NVL((SELECT SUM(r11_stock_act)
		FROM acero_qm:rept011, acero_qm:rept002
		WHERE r11_compania   = r10_compania
		  AND r11_item       = r10_codigo
		  AND r02_compania   = r11_compania
		  AND r02_codigo     = r11_bodega
		  AND r02_localidad IN (3, 5)
		  AND r02_tipo      <> "S"), 0) AS sto
	FROM acero_qm:rept010, acero_qm:rept072
	WHERE r10_compania  = 1
	  AND r72_compania  = r10_compania
	  AND r72_linea     = r10_linea
	  AND r72_sub_linea = r10_sub_linea
	  AND r72_cod_grupo = r10_cod_grupo
	  AND r72_cod_clase = r10_cod_clase
	  AND NVL((SELECT SUM(r11_stock_act)
		FROM acero_qm:rept011, acero_qm:rept002
		WHERE r11_compania   = r10_compania
		  AND r11_item       = r10_codigo
		  AND r02_compania   = r11_compania
		  AND r02_codigo     = r11_bodega
		  AND r02_localidad IN (3, 5)
		  AND r02_tipo      <> "S"), 0) > 0
	  AND NOT EXISTS
		(SELECT 1 FROM acero_qm:rept020
			WHERE r20_compania      = r10_compania
			  AND r20_item          = r10_codigo
			  AND YEAR(r20_fecing)  > 2009
			  AND r20_cod_tran     IN ("FA", "DF", "AF"))
UNION
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_qs:gent002
		WHERE g02_compania  = r10_compania
		  AND g02_localidad = 4) AS local,
	r10_codigo AS item,
	r72_desc_clase AS clas,
	r10_nombre AS descri,
	r10_filtro AS filt,
	r10_marca AS marc,
	r10_uni_med AS uni,
	r10_precio_mb AS pvp,
	r10_costo_mb AS cost,
	CASE WHEN r10_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est,
	NVL((SELECT SUM(r11_stock_act)
		FROM acero_qs:rept011, acero_qs:rept002
		WHERE r11_compania   = r10_compania
		  AND r11_item       = r10_codigo
		  AND r02_compania   = r11_compania
		  AND r02_codigo     = r11_bodega
		  AND r02_localidad  = 4
		  AND r02_tipo      <> "S"), 0) AS sto
	FROM acero_qs:rept010, acero_qs:rept072
	WHERE r10_compania  = 1
	  AND r72_compania  = r10_compania
	  AND r72_linea     = r10_linea
	  AND r72_sub_linea = r10_sub_linea
	  AND r72_cod_grupo = r10_cod_grupo
	  AND r72_cod_clase = r10_cod_clase
	  AND NVL((SELECT SUM(r11_stock_act)
		FROM acero_qs:rept011, acero_qs:rept002
		WHERE r11_compania   = r10_compania
		  AND r11_item       = r10_codigo
		  AND r02_compania   = r11_compania
		  AND r02_codigo     = r11_bodega
		  AND r02_localidad  = 4
		  AND r02_tipo      <> "S"), 0) > 0
	  AND NOT EXISTS
		(SELECT 1 FROM acero_qs:rept020
			WHERE r20_compania      = r10_compania
			  AND r20_item          = r10_codigo
			  AND YEAR(r20_fecing)  > 2009
			  AND r20_cod_tran     IN ("FA", "DF", "AF"));
