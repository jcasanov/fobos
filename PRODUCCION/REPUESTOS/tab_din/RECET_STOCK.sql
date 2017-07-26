SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM gent002
		WHERE g02_compania  = r47_compania
		  AND g02_localidad = r47_localidad) AS local,
	CAST(r47_item_part AS INTEGER) AS item_p,
	r47_desc_part AS desc_ite_p,
	NVL(SUM(r47_cantidad), 0.00) AS cant_p,
	NVL((SELECT SUM(r11_stock_act)
		FROM rept011
		WHERE r11_compania  = r47_compania
		  AND r11_bodega   IN (SELECT r02_codigo
					FROM rept002
					WHERE r02_compania   = r11_compania
					  AND r02_localidad  = 1
					  AND r02_estado     = "A"
					  AND r02_tipo      <> "S")
		  AND r11_item      = r47_item_part), 0.00) AS sto
	FROM rept047
	WHERE r47_compania  = 1
	  AND r47_localidad = 1
	GROUP BY 1, 2, 3, 5
	ORDER BY 2;
