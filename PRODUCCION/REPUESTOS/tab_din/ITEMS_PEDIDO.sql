SELECT CAST(r10_codigo AS INTEGER) AS item,
	r10_nombre AS descripcion,
	r10_marca AS marca,
	r10_cod_pedido AS cod_pedido,
	NVL((SELECT SUM(r11_stock_act)
		FROM rept011, rept002
		WHERE r11_compania   = r10_compania
		  AND r11_item       = r10_codigo
		  AND r02_compania   = r11_compania
		  AND r02_codigo     = r11_bodega
		  AND r02_localidad  = 1
		  AND r02_tipo      <> "S"), 0) AS stock,
	CASE WHEN r10_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS estado
	FROM rept010
	WHERE r10_compania = 1
	  AND r10_linea    = "7"
	ORDER BY 1;
