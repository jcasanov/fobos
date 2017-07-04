SELECT CAST(r10_codigo AS INTEGER) AS item,
	r11_bodega AS bod,
	r10_marca AS marca,
	r10_nombre AS descrip,
	r72_desc_clase AS clas,
	CASE WHEN r02_localidad = 1 THEN "J T M"
	     WHEN r02_localidad = 2 THEN "CENTRO"
	END AS local,
	CASE WHEN r10_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est
	FROM rept010, rept072, rept011, rept002
	WHERE r10_compania   = 1
	  AND r72_compania   = r10_compania
	  AND r72_linea      = r10_linea
	  AND r72_sub_linea  = r10_sub_linea
	  AND r72_cod_grupo  = r10_cod_grupo
	  AND r72_cod_clase  = r10_cod_clase
	  AND r11_compania   = r10_compania
	  AND r11_item       = r10_codigo
	  AND r02_compania   = r11_compania
	  AND r02_codigo     = r11_bodega
	  AND r02_localidad IN (1, 2)
	ORDER BY 1 ASC, 2 ASC;
