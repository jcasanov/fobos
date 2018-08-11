SELECT r11_item, COUNT(*) tot_bod
	FROM rept011
	WHERE r11_compania   = (SELECT g01_compania
					FROM gent001
					WHERE g01_principal = "S")
	  AND r11_bodega    IN
		(SELECT r02_codigo
			FROM rept002
			WHERE r02_compania    = r11_compania
			  AND r02_localidad  IN
				(SELECT g02_localidad
					FROM gent002
					WHERE g02_compania = r02_compania
					  AND g02_matriz   = "S")
			  AND r02_area        = "R"
			  AND r02_tipo       <> "S"
			  AND r02_tipo_ident  = "V"
			  AND r02_factura     = "S")
	  AND r11_stock_act <> 0
	GROUP BY 1
	HAVING COUNT(*) > 1
	ORDER BY 2 DESC, 1 ASC;
