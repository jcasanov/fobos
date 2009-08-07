set explain on;
SELECT r10_codigo, r10_nombre,r10_costo_mb costo, r10_precio_mb precio,
	0 margn , r11_stock_act
	FROM rept010, rept011
	WHERE r10_compania  = 1 AND 1 = 1 AND
	      r10_filtro MATCHES 'AS*' AND  1=1 AND
              r10_compania  = r11_compania AND
              r11_bodega    = 'AA' AND
              r10_codigo    = r11_item
INTO TEMP temp_item
