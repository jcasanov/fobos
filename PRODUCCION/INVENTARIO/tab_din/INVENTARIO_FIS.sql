SELECT r89_anio AS anio,
	r89_fecing AS fecha,
	r89_usuario AS usuario,
	r89_bodega AS bodega,
	r89_item AS item,
	r72_desc_clase AS clase,
	r10_nombre AS descripcion,
	r10_marca AS marca,
	r89_bueno AS vendible,
	r89_incompleto AS no_vendible,
	r89_suma AS total,
	r89_stock_act AS stock,
	CASE WHEN r89_stock_act < r89_suma THEN "SOBRANTE"
	     WHEN r89_stock_act > r89_suma THEN "FALTANTE"
	     ELSE ""
	END AS mensaje_difer,
	(r89_stock_act - r89_suma) AS diferencia,
	r89_usu_modifi AS usu_modifico
	FROM rept089, rept010, rept072
	WHERE r89_compania  = 1
	  AND r89_localidad = 1
	  AND r89_anio      > 2010
	  AND r10_compania  = r89_compania
	  AND r10_codigo    = r89_item
	  AND r72_compania  = r10_compania
	  AND r72_linea     = r10_linea
	  AND r72_sub_linea = r10_sub_linea
	  AND r72_cod_grupo = r10_cod_grupo
	  AND r72_cod_clase = r10_cod_clase
UNION
SELECT YEAR(r11_fec_corte) AS anio,
	r11_fec_corte AS fecha,
	"" AS usuario,
	r11_bodega AS bodega,
	r11_item AS item,
	r72_desc_clase AS clase,
	r10_nombre AS descripcion,
	r10_marca AS marca,
	0.00 AS vendible,
	0.00 AS no_vendible,
	0.00 AS total,
	r11_stock_act AS stock,
	"NO DIGITADO" AS mensaje_difer,
	0.00 AS diferencia,
	"" AS usu_modifico
	FROM resp_exis, rept010, rept072
	WHERE r11_compania         = 1
	  AND r11_stock_act       <> 0
	  AND NOT EXISTS
		(SELECT 1 FROM rept089
			WHERE r89_compania  = r11_compania
			  AND r89_bodega    = r11_bodega
			  AND r89_item      = r11_item
			  AND r89_fec_corte = r11_fec_corte)
	  AND r10_compania         = r11_compania
	  AND r10_codigo           = r11_item
	  AND r72_compania         = r10_compania
	  AND r72_linea            = r10_linea
	  AND r72_sub_linea        = r10_sub_linea
	  AND r72_cod_grupo        = r10_cod_grupo
	  AND r72_cod_clase        = r10_cod_clase
	ORDER BY 1, 4, 5, 8;
