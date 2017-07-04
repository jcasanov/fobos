SELECT (SELECT g02_abreviacion
		FROM gent002
		WHERE g02_compania  = r89_compania
		  AND g02_localidad = r89_localidad) AS localidad,
	r89_bodega AS bodega, r10_marca AS marca, r72_desc_clase AS clase,
	r10_nombre AS descripcion, r89_item AS item,
	CASE WHEN r89_suma > r89_stock_act
		THEN "SOBRANTE"
	     WHEN r89_suma < r89_stock_act
		THEN "FALTANTE"
	     WHEN r89_suma = r89_stock_act
		THEN "IGUAL"
	END AS mens_dife,
	r89_bueno AS vendible, r89_incompleto AS no_vendible,
	r89_stock_act AS stock,
	NVL((SELECT SUM(r20_cant_ven)
		FROM rept020
		WHERE r20_compania      = r89_compania
		  AND r20_localidad     = r89_localidad
		  AND r20_cod_tran     IN ("DF", "AF", "CL", "A+")
		  AND r20_bodega        = r89_bodega
		  AND r20_item          = r89_item
		  AND DATE(r20_fecing) >= MDY(12, 09, 2011)),
		0) +
	NVL((SELECT SUM(r20_cant_ven)
		FROM rept019, rept020
		WHERE r19_compania      = r89_compania
		  AND r19_localidad     = r89_localidad
		  AND r19_cod_tran      = "TR"
		  AND r19_bodega_dest   = r89_bodega
		  AND DATE(r19_fecing) >= MDY(12, 09, 2011)
		  AND r20_compania      = r19_compania
		  AND r20_localidad     = r19_localidad
		  AND r20_cod_tran      = r19_cod_tran
		  AND r20_num_tran      = r19_num_tran
		  AND r20_item          = r89_item),
		0) AS ingresos,
	NVL((SELECT SUM(r20_cant_ven) * (-1)
		FROM rept020
		WHERE r20_compania      = r89_compania
		  AND r20_localidad     = r89_localidad
		  AND r20_cod_tran     IN ("FA", "DC", "A-")
		  AND r20_bodega        = r89_bodega
		  AND r20_item          = r89_item
		  AND DATE(r20_fecing) >= MDY(12, 09, 2011)),
		0) +
	NVL((SELECT SUM(r20_cant_ven) * (-1)
		FROM rept019, rept020
		WHERE r19_compania      = r89_compania
		  AND r19_localidad     = r89_localidad
		  AND r19_cod_tran      = "TR"
		  AND r19_bodega_ori    = r89_bodega
		  AND DATE(r19_fecing) >= MDY(12, 09, 2011)
		  AND r20_compania      = r19_compania
		  AND r20_localidad     = r19_localidad
		  AND r20_cod_tran      = r19_cod_tran
		  AND r20_num_tran      = r19_num_tran
		  AND r20_item          = r89_item),
		0) AS egresos,
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
UNION
SELECT (SELECT g02_abreviacion
		FROM gent002
		WHERE g02_compania  = a.r11_compania
		  AND g02_localidad = 1) AS localidad,
	a.r11_bodega AS bodega, r10_marca AS marca, r72_desc_clase AS clase,
	r10_nombre AS descripcion, a.r11_item AS item, "NO DIGITADO" AS mens_dife,
	0.00 AS vendible, 0.00 AS no_vendible, a.r11_stock_act AS stock,
	NVL((SELECT SUM(r20_cant_ven)
		FROM rept020
		WHERE r20_compania      = a.r11_compania
		  AND r20_localidad     = 1
		  AND r20_cod_tran     IN ("DF", "AF", "CL", "A+")
		  AND r20_bodega        = a.r11_bodega
		  AND r20_item          = a.r11_item
		  AND DATE(r20_fecing) >= MDY(12, 09, 2011)),
		0) +
	NVL((SELECT SUM(r20_cant_ven)
		FROM rept019, rept020
		WHERE r19_compania      = a.r11_compania
		  AND r19_localidad     = 1
		  AND r19_cod_tran      = "TR"
		  AND r19_bodega_dest   = a.r11_bodega
		  AND DATE(r19_fecing) >= MDY(12, 09, 2011)
		  AND r20_compania      = r19_compania
		  AND r20_localidad     = r19_localidad
		  AND r20_cod_tran      = r19_cod_tran
		  AND r20_num_tran      = r19_num_tran
		  AND r20_item          = a.r11_item),
		0) AS ingresos,
	NVL((SELECT SUM(r20_cant_ven) * (-1)
		FROM rept020
		WHERE r20_compania      = a.r11_compania
		  AND r20_localidad     = 1
		  AND r20_cod_tran     IN ("FA", "DC", "A-")
		  AND r20_bodega        = a.r11_bodega
		  AND r20_item          = a.r11_item
		  AND DATE(r20_fecing) >= MDY(12, 09, 2011)),
		0) +
	NVL((SELECT SUM(r20_cant_ven) * (-1)
		FROM rept019, rept020
		WHERE r19_compania      = a.r11_compania
		  AND r19_localidad     = 1
		  AND r19_cod_tran      = "TR"
		  AND r19_bodega_ori    = a.r11_bodega
		  AND DATE(r19_fecing) >= MDY(12, 09, 2011)
		  AND r20_compania      = r19_compania
		  AND r20_localidad     = r19_localidad
		  AND r20_cod_tran      = r19_cod_tran
		  AND r20_num_tran      = r19_num_tran
		  AND r20_item          = a.r11_item),
		0) AS egresos,
	NVL((SELECT b.r11_stock_act
		FROM rept011 b
		WHERE b.r11_compania = a.r11_compania
		  AND b.r11_bodega   = a.r11_bodega
		  AND b.r11_item     = a.r11_item), 0) AS stock_act,
	"" AS usuario
	FROM resp_exis a, rept010, rept072
	WHERE a.r11_compania        = 1
	  AND YEAR(a.r11_fec_corte) = 2011
	  AND a.r11_stock_act       <> 0
	  AND r10_compania          = a.r11_compania
	  AND r10_codigo            = a.r11_item
	  AND r72_compania          = r10_compania
	  AND r72_linea             = r10_linea
	  AND r72_sub_linea         = r10_sub_linea
	  AND r72_cod_grupo         = r10_cod_grupo
	  AND r72_cod_clase         = r10_cod_clase
	ORDER BY 2, 3, 6;
