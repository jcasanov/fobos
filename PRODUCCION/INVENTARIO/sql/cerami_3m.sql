SELECT r10_codigo AS item, r72_desc_clase AS clase, r10_nombre AS descripcion,
	r10_marca AS marca, r10_precio_mb AS precio, r11_bodega AS bodega,
	r11_stock_act AS stock_menor_3, 0.00 AS stock_local,
	CASE WHEN r10_estado = "A" THEN "ACTIVO"
	     WHEN r10_estado = "B" THEN "BLOQUEADO"
	END AS estado
	FROM rept010, rept072, rept011
	WHERE r10_compania   = 1
	  AND r10_linea      = '8'
	  AND r10_sub_linea  = '80'
	  AND r10_marca     IN ('ECERAM', 'KERAMI', 'RIALTO')
	  AND r72_compania   = r10_compania
	  AND r72_linea      = r10_linea
	  AND r72_sub_linea  = r10_sub_linea
	  AND r72_cod_grupo  = r10_cod_grupo
	  AND r72_cod_clase  = r10_cod_clase
	  AND r11_compania   = r10_compania
	  AND r11_bodega    IN
		(SELECT r02_codigo
			FROM rept002
			WHERE r02_compania   = r11_compania
			  AND r02_codigo     = r11_bodega
			  AND r02_localidad  = 1
			  AND r02_estado     = 'A'
			  AND r02_tipo      <> 'S')
	  AND r11_item       = r10_codigo
	  AND r11_stock_act  > 0
	  AND r11_stock_act <= 3
UNION
SELECT r10_codigo AS item, r72_desc_clase AS clase, r10_nombre AS descripcion,
	r10_marca AS marca, r10_precio_mb AS precio, r11_bodega AS bodega,
	0.00 AS stock_menor_3, r11_stock_act AS stock_local,
	CASE WHEN r10_estado = "A" THEN "ACTIVO"
	     WHEN r10_estado = "B" THEN "BLOQUEADO"
	END AS estado
	FROM rept010, rept072, rept011
	WHERE r10_compania   = 1
	  AND r10_linea      = '8'
	  AND r10_sub_linea  = '80'
	  AND r10_marca     IN ('ECERAM', 'KERAMI', 'RIALTO')
	  AND r72_compania   = r10_compania
	  AND r72_linea      = r10_linea
	  AND r72_sub_linea  = r10_sub_linea
	  AND r72_cod_grupo  = r10_cod_grupo
	  AND r72_cod_clase  = r10_cod_clase
	  AND r11_compania   = r10_compania
	  AND r11_bodega    IN
		(SELECT r02_codigo
			FROM rept002
			WHERE r02_compania   = r11_compania
			  AND r02_codigo     = r11_bodega
			  AND r02_localidad  = 1
			  AND r02_estado     = 'A'
			  AND r02_tipo      <> 'S')
	  AND r11_item       = r10_codigo
