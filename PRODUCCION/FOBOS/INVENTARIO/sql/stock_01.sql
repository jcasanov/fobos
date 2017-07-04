SELECT (SELECT CASE WHEN r02_localidad = 1 THEN "J T M"
		    WHEN r02_localidad = 2 THEN "CENTRO"
		    WHEN r02_localidad = 3 THEN "U I O"
		    WHEN r02_localidad = 4 THEN "SUR"
		    WHEN r02_localidad = 5 THEN "KHOLER"
		END
		FROM rept002
		WHERE r02_compania = r11_compania
		  AND r02_codigo   = r11_bodega) AS localidad,
	r10_codigo AS items,
	r72_desc_clase AS nom_clase,
	r10_nombre AS descripcion,
	r10_marca AS marca,
	CASE WHEN r10_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS estado,
	r10_filtro AS filtro,
	r10_costo_mb AS costo,
	NVL(SUM(r11_stock_act), 0) AS stock
	FROM rept010, rept072, rept011
	WHERE r10_compania   = 1
	  AND r10_estado     = 'A'
	  AND r10_costo_mb   = 0.01
	  AND r72_compania   = r10_compania
	  AND r72_linea      = r10_linea
	  AND r72_sub_linea  = r10_sub_linea
	  AND r72_cod_grupo  = r10_cod_grupo
	  AND r72_cod_clase  = r10_cod_clase
	  AND r11_compania   = r10_compania
	  AND r11_bodega    IN (SELECT r02_codigo
				FROM rept002
				WHERE r02_compania  = r11_compania
				  AND r02_localidad = 1)
	  AND r11_item       = r10_codigo
	  AND r11_stock_act <> 0
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
UNION
SELECT (SELECT CASE WHEN r02_localidad = 1 THEN "J T M"
		    WHEN r02_localidad = 2 THEN "CENTRO"
		    WHEN r02_localidad = 3 THEN "U I O"
		    WHEN r02_localidad = 4 THEN "SUR"
		    WHEN r02_localidad = 5 THEN "KHOLER"
		END
		FROM acero_gc:rept002
		WHERE r02_compania = r11_compania
		  AND r02_codigo   = r11_bodega) AS localidad,
	r10_codigo AS items,
	r72_desc_clase AS nom_clase,
	r10_nombre AS descripcion,
	r10_marca AS marca,
	CASE WHEN r10_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS estado,
	r10_filtro AS filtro,
	r10_costo_mb AS costo,
	NVL(SUM(r11_stock_act), 0) AS stock
	FROM acero_gc:rept010, acero_gc:rept072, acero_gc:rept011
	WHERE r10_compania   = 1
	  AND r10_estado     = 'A'
	  AND r10_costo_mb   = 0.01
	  AND r72_compania   = r10_compania
	  AND r72_linea      = r10_linea
	  AND r72_sub_linea  = r10_sub_linea
	  AND r72_cod_grupo  = r10_cod_grupo
	  AND r72_cod_clase  = r10_cod_clase
	  AND r11_compania   = r10_compania
	  AND r11_bodega    IN (SELECT r02_codigo
				FROM acero_gc:rept002
				WHERE r02_compania  = r11_compania
				  AND r02_localidad = 2)
	  AND r11_item       = r10_codigo
	  AND r11_stock_act <> 0
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
UNION
SELECT (SELECT CASE WHEN r02_localidad = 1 THEN "J T M"
		    WHEN r02_localidad = 2 THEN "CENTRO"
		    WHEN r02_localidad = 3 THEN "U I O"
		    WHEN r02_localidad = 4 THEN "SUR"
		    WHEN r02_localidad = 5 THEN "KHOLER"
		END
		FROM acero_qm@acgyede:rept002
		WHERE r02_compania = r11_compania
		  AND r02_codigo   = r11_bodega) AS localidad,
	r10_codigo AS items,
	r72_desc_clase AS nom_clase,
	r10_nombre AS descripcion,
	r10_marca AS marca,
	CASE WHEN r10_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS estado,
	r10_filtro AS filtro,
	r10_costo_mb AS costo,
	NVL(SUM(r11_stock_act), 0) AS stock
	FROM acero_qm@acgyede:rept010,
		acero_qm@acgyede:rept072,
		acero_qm@acgyede:rept011
	WHERE r10_compania   = 1
	  AND r10_estado     = 'A'
	  AND r10_costo_mb   = 0.01
	  AND r72_compania   = r10_compania
	  AND r72_linea      = r10_linea
	  AND r72_sub_linea  = r10_sub_linea
	  AND r72_cod_grupo  = r10_cod_grupo
	  AND r72_cod_clase  = r10_cod_clase
	  AND r11_compania   = r10_compania
	  AND r11_bodega    IN (SELECT r02_codigo
				FROM acero_qm@acgyede:rept002
				WHERE r02_compania   = r11_compania
				  AND r02_localidad IN (3, 5))
	  AND r11_item       = r10_codigo
	  AND r11_stock_act <> 0
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
UNION
SELECT (SELECT CASE WHEN r02_localidad = 1 THEN "J T M"
		    WHEN r02_localidad = 2 THEN "CENTRO"
		    WHEN r02_localidad = 3 THEN "U I O"
		    WHEN r02_localidad = 4 THEN "SUR"
		    WHEN r02_localidad = 5 THEN "KHOLER"
		END
		FROM acero_qs@acgyede:rept002
		WHERE r02_compania = r11_compania
		  AND r02_codigo   = r11_bodega) AS localidad,
	r10_codigo AS items,
	r72_desc_clase AS nom_clase,
	r10_nombre AS descripcion,
	r10_marca AS marca,
	CASE WHEN r10_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS estado,
	r10_filtro AS filtro,
	r10_costo_mb AS costo,
	NVL(SUM(r11_stock_act), 0) AS stock
	FROM acero_qs@acgyede:rept010,
		acero_qs@acgyede:rept072,
		acero_qs@acgyede:rept011
	WHERE r10_compania   = 1
	  AND r10_estado     = 'A'
	  AND r10_costo_mb   = 0.01
	  AND r72_compania   = r10_compania
	  AND r72_linea      = r10_linea
	  AND r72_sub_linea  = r10_sub_linea
	  AND r72_cod_grupo  = r10_cod_grupo
	  AND r72_cod_clase  = r10_cod_clase
	  AND r11_compania   = r10_compania
	  AND r11_bodega    IN (SELECT r02_codigo
				FROM acero_qs@acgyede:rept002
				WHERE r02_compania  = r11_compania
				  AND r02_localidad = 4)
	  AND r11_item       = r10_codigo
	  AND r11_stock_act <> 0
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
