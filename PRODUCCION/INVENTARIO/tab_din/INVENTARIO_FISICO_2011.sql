SELECT (SELECT g02_abreviacion
		FROM gent002
		WHERE g02_compania  = r89_compania
		  AND g02_localidad = r89_localidad) AS localidad,
		r89_bodega AS bodega, r10_marca AS marca,
		r72_desc_clase AS clase, r10_nombre AS descripcion,
		r89_item AS item,
		CASE WHEN (r89_bueno + r89_incompleto) > r89_stock_act
			THEN "SOBRANTE"
		     WHEN (r89_bueno + r89_incompleto) < r89_stock_act
			THEN "FALTANTE"
		     WHEN (r89_bueno + r89_incompleto) = r89_stock_act
			THEN "IGUAL"
		END AS mens_dife,
		r89_bueno AS vendible, r89_incompleto AS no_vendible,
		r89_stock_act AS stock,
		NVL((SELECT SUM(CASE WHEN r20_cod_tran = "FA"
					THEN r20_cant_ven
					ELSE r20_cant_ven * (-1)
				END)
			FROM rept020
			WHERE r20_compania      = r89_compania
			  AND r20_localidad     = r89_localidad
			  AND r20_cod_tran     IN ("FA", "DF", "AF")
			  AND r20_bodega        = r89_bodega
			  AND r20_item          = r89_item
			  AND DATE(r20_fecing) >= MDY(12, 30, 2010)),
		0) AS ventas,
		NVL((SELECT r11_stock_act
			FROM rept011
			WHERE r11_compania = r89_compania
			  AND r11_bodega   = r89_bodega
			  AND r11_item     = r89_item), 0) AS stock_act,
		r89_usuario AS usuario
	FROM rept089, rept010, rept072
	WHERE r89_compania   = 1
	  AND r89_localidad IN (1, 2)
	  AND r89_anio       = 2011
	  AND r10_compania   = r89_compania
	  AND r10_codigo     = r89_item
	  AND r72_compania   = r10_compania
	  AND r72_linea      = r10_linea
	  AND r72_sub_linea  = r10_sub_linea
	  AND r72_cod_grupo  = r10_cod_grupo
	  AND r72_cod_clase  = r10_cod_clase
	ORDER BY r89_bodega, r10_marca, r72_desc_clase, r10_nombre, r10_codigo
