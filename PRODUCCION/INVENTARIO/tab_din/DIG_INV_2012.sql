SELECT r89_bodega AS bod,
	CAST(r89_item AS INTEGER) AS item,
	r72_desc_clase AS clas,
	r10_nombre AS descrip,
	r10_marca AS marc,
	r89_stock_act AS sto_cong,
	r89_bueno AS vend,
	r89_incompleto AS no_vend,
	r89_suma AS tot,
        (r89_suma - r89_stock_act) AS difer,
        CASE WHEN r89_stock_act > r89_suma THEN "FALTANTE"
             WHEN r89_stock_act < r89_suma THEN "SOBRANTE"
	     WHEN r89_stock_act = r89_suma THEN "COMPLETO"
        END AS mens_dif,
	r89_usuario AS usuar
	FROM rept089, rept010, rept072
	WHERE r89_compania  = 1
	  AND r89_localidad = 1
	  AND r89_anio      = 2012
	  AND r89_mes       = 12
	  AND r10_compania  = r89_compania
	  AND r10_codigo    = r89_item
	  AND r72_compania  = r10_compania
	  AND r72_linea     = r10_linea
	  AND r72_sub_linea = r10_sub_linea
	  AND r72_cod_grupo = r10_cod_grupo
	  AND r72_cod_clase = r10_cod_clase
UNION
SELECT r11_bodega AS bod,
	CAST(r11_item AS INTEGER) AS item,
	r72_desc_clase AS clas,
	r10_nombre AS descrip,
	r10_marca AS marc,
	r11_stock_act AS sto_cong,
	0.00 AS vend,
	0.00 AS no_vend,
	0.00 AS tot,
	0.00 AS difer,
	"NO DIGITADO" AS mens_dif,
	"SIN USUARIO" AS usuar
	FROM resp_exis, rept002, rept010, rept072
	WHERE r11_compania                          = 1
	  AND EXTEND(r11_fec_corte, YEAR TO MONTH)  = "2012-12"
	  AND r11_stock_act                        <> 0
	  AND NOT EXISTS
		(SELECT 1 FROM rept089
			WHERE r89_compania  = r11_compania
			  AND r89_localidad = 1
		 	  AND r89_anio      = YEAR(r11_fec_corte)
			  AND r89_mes       = MONTH(r11_fec_corte)
			  AND r89_bodega    = r11_bodega
			  AND r89_item      = r11_item)
	  AND r02_compania                          = r11_compania
	  AND r02_codigo                            = r11_bodega
	  AND r02_tipo                             IN ("F", "L")
	  AND r02_localidad                         = 1
	  AND r02_tipo_ident                       NOT IN ("E", "S")
	  AND r10_compania                         = r11_compania
	  AND r10_codigo                           = r11_item
	  AND r72_compania                         = r10_compania
	  AND r72_linea                            = r10_linea
	  AND r72_sub_linea                        = r10_sub_linea
	  AND r72_cod_grupo                        = r10_cod_grupo
	  AND r72_cod_clase                        = r10_cod_clase
