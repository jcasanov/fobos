SELECT (SELECT CASE WHEN r02_localidad = 1 THEN "JTM"
		    WHEN r02_localidad = 2 THEN "CENTRO"
		    WHEN r02_localidad = 3 THEN "QUITO"
		    WHEN r02_localidad = 4 THEN "SUR"
		    WHEN r02_localidad = 5 THEN "KHOLER"
		END
		FROM rept002
		WHERE r02_compania = r11_compania
		  AND r02_codigo   = r11_bodega) AS localidad,
	r11_stock_act AS stock, r11_bodega AS bodega, r70_desc_sub AS linea,
	r73_desc_marca AS marca, CAST(r10_codigo AS INTEGER) AS item,
	r10_nombre AS descripcion, r10_precio_mb AS precio,
	r72_cod_clase AS cod_clase, r72_desc_clase AS nom_clase 
	FROM rept011, rept010, rept070, rept072, rept073
	WHERE r11_compania   = 1
	  AND r11_stock_act <> 0
	  AND r10_compania   = r11_compania
	  AND r10_codigo     = r11_item
	  AND r70_compania   = r10_compania
	  AND r70_linea      = r10_linea
	  AND r70_sub_linea  = r10_sub_linea
	  AND r72_compania   = r10_compania
	  AND r72_linea      = r10_linea
	  AND r72_sub_linea  = r10_sub_linea
	  AND r72_cod_grupo  = r10_cod_grupo
	  AND r72_cod_clase  = r10_cod_clase
	  AND r73_compania   = r10_compania
	  AND r73_marca      = r10_marca;
