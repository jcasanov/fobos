SELECT r11_bodega AS bodega,
	CAST(r11_item AS INTEGER) AS item,
	r11_stock_act AS stock,
	(SELECT CASE WHEN r10_estado = "A"
			THEN "ACTIVO"
			ELSE "BLOQUEADO"
		END
		FROM rept010
		WHERE r10_compania = r11_compania
		  AND r10_codigo   = r11_item) AS estado
	FROM rept011
	WHERE r11_compania   = 1
	  AND r11_bodega    IN
		(SELECT r02_codigo
			FROM rept002
			WHERE r02_compania   = r11_compania
			  AND r02_localidad  = 4
			  AND r02_tipo      <> "S")
	  AND r11_stock_act   < 0
	ORDER BY 1 ASC, 2 ASC;
