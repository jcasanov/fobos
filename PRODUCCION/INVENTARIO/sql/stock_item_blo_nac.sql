SELECT "J T M MATRIZ" AS LOCALIDAD, r11_item AS ITEMS, r72_desc_clase AS CLASE,
	r10_nombre AS DESCRIPCION, r11_bodega AS BODEGA, r11_stock_act AS STOCK,
	CASE WHEN r10_estado = 'A'
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS ESTADO, r10_marca AS MARCA
	FROM rept010, rept072, rept011
	WHERE r10_compania   = 1
	  AND r10_estado     = 'B'
	  AND r72_compania   = r10_compania
	  AND r72_linea      = r10_linea
	  AND r72_sub_linea  = r10_sub_linea
	  AND r72_cod_grupo  = r10_cod_grupo
	  AND r72_cod_clase  = r10_cod_clase
	  AND r11_compania   = r10_compania
	  AND r11_bodega    IN (SELECT r02_codigo
				FROM rept002
				WHERE r02_compania  = r11_compania
				  AND r02_estado    = 'A'
				  AND r02_localidad = 1)
	  AND r11_item       = r10_codigo
	  AND r11_stock_act <> 0
	UNION
	SELECT "GYE CENTRO" AS LOCALIDAD, r11_item AS ITEMS,
		r72_desc_clase AS CLASE, r10_nombre AS DESCRIPCION,
		r11_bodega AS BODEGA, r11_stock_act AS STOCK,
		CASE WHEN r10_estado = 'A'
			THEN "ACTIVO"
			ELSE "BLOQUEADO"
		END AS ESTADO, r10_marca AS MARCA
		FROM acero_gc:rept010, acero_gc:rept072, acero_gc:rept011
		WHERE r10_compania   = 1
		  AND r10_estado     = 'B'
		  AND r72_compania   = r10_compania
		  AND r72_linea      = r10_linea
		  AND r72_sub_linea  = r10_sub_linea
		  AND r72_cod_grupo  = r10_cod_grupo
		  AND r72_cod_clase  = r10_cod_clase
		  AND r11_compania   = r10_compania
		  AND r11_bodega    IN (SELECT r02_codigo
					FROM acero_gc:rept002
					WHERE r02_compania  = r11_compania
					  AND r02_estado    = 'A'
					  AND r02_localidad = 2)
		  AND r11_item       = r10_codigo
		  AND r11_stock_act <> 0
	UNION
	SELECT "UIO MATRIZ" AS LOCALIDAD, r11_item AS ITEMS,
		r72_desc_clase AS CLASE, r10_nombre AS DESCRIPCION,
		r11_bodega AS BODEGA, r11_stock_act AS STOCK,
		CASE WHEN r10_estado = 'A'
			THEN "ACTIVO"
			ELSE "BLOQUEADO"
		END AS ESTADO, r10_marca AS MARCA
		FROM acero_qm@acgyede:rept010, acero_qm@acgyede:rept072,
			acero_qm@acgyede:rept011
		WHERE r10_compania   = 1
		  AND r10_estado     = 'B'
		  AND r72_compania   = r10_compania
		  AND r72_linea      = r10_linea
		  AND r72_sub_linea  = r10_sub_linea
		  AND r72_cod_grupo  = r10_cod_grupo
		  AND r72_cod_clase  = r10_cod_clase
		  AND r11_compania   = r10_compania
		  AND r11_bodega    IN (SELECT r02_codigo
					FROM acero_gc:rept002
					WHERE r02_compania  = r11_compania
					  AND r02_estado    = 'A'
					  AND r02_localidad IN (3, 5))
		  AND r11_item       = r10_codigo
		  AND r11_stock_act <> 0
	UNION
	SELECT "UIO SUR" AS LOCALIDAD, r11_item AS ITEMS,
		r72_desc_clase AS CLASE, r10_nombre AS DESCRIPCION,
		r11_bodega AS BODEGA, r11_stock_act AS STOCK,
		CASE WHEN r10_estado = 'A'
			THEN "ACTIVO"
			ELSE "BLOQUEADO"
		END AS ESTADO, r10_marca AS MARCA
		FROM acero_qs@acgyede:rept010, acero_qs@acgyede:rept072,
			acero_qs@acgyede:rept011
		WHERE r10_compania   = 1
		  AND r10_estado     = 'B'
		  AND r72_compania   = r10_compania
		  AND r72_linea      = r10_linea
		  AND r72_sub_linea  = r10_sub_linea
		  AND r72_cod_grupo  = r10_cod_grupo
		  AND r72_cod_clase  = r10_cod_clase
		  AND r11_compania   = r10_compania
		  AND r11_bodega    IN (SELECT r02_codigo
					FROM acero_gc:rept002
					WHERE r02_compania  = r11_compania
					  AND r02_estado    = 'A'
					  AND r02_localidad = 4)
		  AND r11_item       = r10_codigo
		  AND r11_stock_act <> 0;
