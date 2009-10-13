
INSERT INTO rept031
		SELECT r11_compania, 2009, 9
		, r11_bodega, r11_item, r11_stock_act,
		r10_costo_mb, r10_costo_ma, r10_precio_mb,
		r10_precio_ma
		 FROM rept011_sept30, rept010_sept30
		WHERE r11_compania  = 1
		  AND r11_stock_act > 0
		  AND r10_compania  = r11_compania
		  AND r10_codigo    = r11_item;
