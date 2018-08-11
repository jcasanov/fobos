SELECT CASE WHEN r20_localidad = 01 THEN "01 GYE J T M"
	    WHEN r20_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r20_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r20_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r20_localidad = 05 THEN "05 ACERO KHOLER"
	END AS localidad,
	YEAR(r20_fecing) AS anio,
	CASE WHEN MONTH(r20_fecing) = 01 THEN "01 ENERO"
	     WHEN MONTH(r20_fecing) = 02 THEN "02 FEBRERO"
	     WHEN MONTH(r20_fecing) = 03 THEN "03 MARZO"
	     WHEN MONTH(r20_fecing) = 04 THEN "04 ABRIL"
	     WHEN MONTH(r20_fecing) = 05 THEN "05 MAYO"
	     WHEN MONTH(r20_fecing) = 06 THEN "06 JUNIO"
	     WHEN MONTH(r20_fecing) = 07 THEN "07 JULIO"
	     WHEN MONTH(r20_fecing) = 08 THEN "08 AGOSTO"
	     WHEN MONTH(r20_fecing) = 09 THEN "09 SEPTIEMBRE"
	     WHEN MONTH(r20_fecing) = 10 THEN "10 OCTUBRE"
	     WHEN MONTH(r20_fecing) = 11 THEN "11 NOVIEMBRE"
	     WHEN MONTH(r20_fecing) = 12 THEN "12 DICIEMBRE"
	END AS meses,
	DAY(r20_fecing) AS dia,
	r01_nombres AS vendedor,
	r01_iniciales AS ini_vend,
	r20_cliente AS cod_cli,
	z01_nomcli AS nom_cli,
	z01_direccion1 AS dir_cliente,
	r20_bodega AS bodega,
	r72_desc_clase AS clase,
	r10_nombre AS descripcion,
	r20_item AS item,
	r10_marca AS marca,
	"01_VENTAS" AS tipo,
	NVL(SUM(r20_val_descto), 0) AS descuento,
	NVL(SUM((r20_cant_ven * r20_precio) - r20_val_descto), 0) AS valor
	FROM venta, item, clase, vendedor, cliente
	WHERE r20_localidad IN (1, 2)
	  AND YEAR(r20_fecing) > 2009
	  --AND r20_vendedor  IN (25, 8, 65, 62, 10, 37, 14, 16, 41)
	  AND r10_codigo     = r20_item
	  AND r72_linea      = r10_linea
	  AND r72_sub_linea  = r10_sub_linea
	  AND r72_cod_grupo  = r10_cod_grupo
	  AND r72_cod_clase  = r10_cod_clase
	  AND z01_localidad  = r20_localidad
	  AND z01_codcli     = r20_cliente
	  AND r01_localidad  = r20_localidad
	  AND r01_codigo     = r20_vendedor
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
UNION
SELECT CASE WHEN r22_localidad = 01 THEN "01 GYE J T M"
	    WHEN r22_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r22_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r22_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r22_localidad = 05 THEN "05 ACERO KHOLER"
	END AS localidad,
	YEAR(r22_fecing) AS anio,
	CASE WHEN MONTH(r22_fecing) = 01 THEN "01 ENERO"
	     WHEN MONTH(r22_fecing) = 02 THEN "02 FEBRERO"
	     WHEN MONTH(r22_fecing) = 03 THEN "03 MARZO"
	     WHEN MONTH(r22_fecing) = 04 THEN "04 ABRIL"
	     WHEN MONTH(r22_fecing) = 05 THEN "05 MAYO"
	     WHEN MONTH(r22_fecing) = 06 THEN "06 JUNIO"
	     WHEN MONTH(r22_fecing) = 07 THEN "07 JULIO"
	     WHEN MONTH(r22_fecing) = 08 THEN "08 AGOSTO"
	     WHEN MONTH(r22_fecing) = 09 THEN "09 SEPTIEMBRE"
	     WHEN MONTH(r22_fecing) = 10 THEN "10 OCTUBRE"
	     WHEN MONTH(r22_fecing) = 11 THEN "11 NOVIEMBRE"
	     WHEN MONTH(r22_fecing) = 12 THEN "12 DICIEMBRE"
	END AS meses,
	DAY(r22_fecing) AS dia,
	r01_nombres AS vendedor,
	r01_iniciales AS ini_vend,
	r22_codcli AS cod_cli,
	r22_nomcli AS nom_cli,
	z01_direccion1 AS dir_cliente,
	r22_bodega AS bodega,
	r72_desc_clase AS clase,
	r10_nombre AS descripcion,
	r22_item AS item,
	r10_marca AS marca,
	"02_PROFORMAS_FACT" AS tipo,
	NVL(SUM(r22_val_descto), 0) AS descuento,
	NVL(SUM((r22_cantidad * r22_precio) - r22_val_descto), 0) AS valor
	FROM proforma, item, clase, vendedor, cliente
	WHERE r22_localidad IN (1, 2)
	  AND r22_cod_tran  IS NOT NULL
	  AND YEAR(r22_fecing) > 2009
	  --AND r22_vendedor  IN (25, 8, 65, 62, 10, 37, 14, 16, 41)
	  AND r10_codigo     = r22_item
	  AND r72_linea      = r10_linea
	  AND r72_sub_linea  = r10_sub_linea
	  AND r72_cod_grupo  = r10_cod_grupo
	  AND r72_cod_clase  = r10_cod_clase
	  AND z01_localidad  = r22_localidad
	  AND z01_codcli     = r22_codcli
	  AND r01_localidad  = r22_localidad
	  AND r01_codigo     = r22_vendedor
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
UNION
SELECT CASE WHEN r22_localidad = 01 THEN "01 GYE J T M"
	    WHEN r22_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r22_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r22_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r22_localidad = 05 THEN "05 ACERO KHOLER"
	END AS localidad,
	YEAR(r22_fecing) AS anio,
	CASE WHEN MONTH(r22_fecing) = 01 THEN "01 ENERO"
	     WHEN MONTH(r22_fecing) = 02 THEN "02 FEBRERO"
	     WHEN MONTH(r22_fecing) = 03 THEN "03 MARZO"
	     WHEN MONTH(r22_fecing) = 04 THEN "04 ABRIL"
	     WHEN MONTH(r22_fecing) = 05 THEN "05 MAYO"
	     WHEN MONTH(r22_fecing) = 06 THEN "06 JUNIO"
	     WHEN MONTH(r22_fecing) = 07 THEN "07 JULIO"
	     WHEN MONTH(r22_fecing) = 08 THEN "08 AGOSTO"
	     WHEN MONTH(r22_fecing) = 09 THEN "09 SEPTIEMBRE"
	     WHEN MONTH(r22_fecing) = 10 THEN "10 OCTUBRE"
	     WHEN MONTH(r22_fecing) = 11 THEN "11 NOVIEMBRE"
	     WHEN MONTH(r22_fecing) = 12 THEN "12 DICIEMBRE"
	END AS meses,
	DAY(r22_fecing) AS dia,
	r01_nombres AS vendedor,
	r01_iniciales AS ini_vend,
	r22_codcli AS cod_cli,
	r22_nomcli AS nom_cli,
	z01_direccion1 AS dir_cliente,
	r22_bodega AS bodega,
	r72_desc_clase AS clase,
	r10_nombre AS descripcion,
	r22_item AS item,
	r10_marca AS marca,
	"03_PROFORMAS_NO_FACT" AS tipo,
	NVL(SUM(r22_val_descto), 0) AS descuento,
	NVL(SUM((r22_cantidad * r22_precio) - r22_val_descto), 0) AS valor
	FROM proforma, item, clase, vendedor, cliente
	WHERE r22_localidad IN (1, 2)
	  AND r22_cod_tran  IS NULL
	  AND YEAR(r22_fecing) > 2009
	  --AND r22_vendedor  IN (25, 8, 65, 62, 10, 37, 14, 16, 41)
	  AND r10_codigo     = r22_item
	  AND r72_linea      = r10_linea
	  AND r72_sub_linea  = r10_sub_linea
	  AND r72_cod_grupo  = r10_cod_grupo
	  AND r72_cod_clase  = r10_cod_clase
	  AND z01_localidad  = r22_localidad
	  AND z01_codcli     = r22_codcli
	  AND r01_localidad  = r22_localidad
	  AND r01_codigo     = r22_vendedor
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15;
