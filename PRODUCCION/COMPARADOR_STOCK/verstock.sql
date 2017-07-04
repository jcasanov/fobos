SELECT
	r11_compania	compania,
	r11_bodega 	bodega,
	r11_item	item,
	r11_stock_act	stock_act,	
	r11_stock_ant	stock_ant
FROM
	rept011
WHERE
	r11_compania 	= 1 AND
	r11_bodega	IN (	SELECT r02_codigo FROM rept002 
				WHERE 	
					    r02_compania	= r11_compania
					AND r02_tipo		<> "S"
					AND r02_area 		<> "T"
					AND r02_localidad	= 4
			) AND
	r11_item 	= "@@CODIGO@@"


