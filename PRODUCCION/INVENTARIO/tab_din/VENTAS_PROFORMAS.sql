SELECT CASE WHEN r20_localidad = 01 THEN "01 GYE J T M"
	    WHEN r20_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r20_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r20_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r20_localidad = 05 THEN "05 ACERO KHOLER"
	END AS localidad,
	r20_anio AS anio,
	CASE WHEN r20_mes = 01 THEN "01 ENERO"
	     WHEN r20_mes = 02 THEN "02 FEBRERO"
	     WHEN r20_mes = 03 THEN "03 MARZO"
	     WHEN r20_mes = 04 THEN "04 ABRIL"
	     WHEN r20_mes = 05 THEN "05 MAYO"
	     WHEN r20_mes = 06 THEN "06 JUNIO"
	     WHEN r20_mes = 07 THEN "07 JULIO"
	     WHEN r20_mes = 08 THEN "08 AGOSTO"
	     WHEN r20_mes = 09 THEN "09 SEPTIEMBRE"
	     WHEN r20_mes = 10 THEN "10 OCTUBRE"
	     WHEN r20_mes = 11 THEN "11 NOVIEMBRE"
	     WHEN r20_mes = 12 THEN "12 DICIEMBRE"
	END AS meses,
	r01_nombres AS vendedor,
	r01_iniciales AS ini_vend,
	r20_cliente AS cod_cli,
	z01_nomcli AS nom_cli,
	r20_bodega AS bodega,
	r72_desc_clase AS clase,
	r10_nombre AS descripcion,
	r20_item AS item,
	r10_marca AS marca,
	"01_VENTAS" AS tipo,
	CASE WHEN r10_marca IN ("F.P.S.", "FAMAC", "FRANKL", "GORMAN", "GRUNDF",
				"MARKGR", "MARKPE", "MYERS", "WELLMA")
		THEN "01_FLUIDOS"
	     WHEN r10_marca IN ("ARMSTR", "ENERPA", "JET", "KITO", "MILWAU",
				"POWERS", "RIDGID")
		THEN "02_HERRAMIENTAS"
	     WHEN r10_marca IN ("F.I.V", "INOXTE", "KITZ", "KLINGE", "REDWHI",
				"TECVAL")
		THEN "03_VAPOR"
	     WHEN r10_marca IN ("ARISTON", "AVALON", "ALPHAJ", "ARISTO",
				"BRIGGS", "CALORE", "CASTEL", "CATA", "CERREC",
				"CONACA", "CREIN", "ECERAM", "EDESA", "EREJIL",
				"FECSA", "FIBRAS", "FV", "FVCERA", "FVGRIF",
				"FVSANI", "HACEB", "INCAME", "INSINK", "INTACO",
				"KERAMI","KOHGRI", "KOHSAN", "KWIKSE", "MATEX",
				"PERMAC", "RIALTO", "SIDEC", "TEKA", "TEKVEN")
		THEN "04_SANITARIOS"
	     WHEN r10_marca IN ("1HAG", "1HAN", "1TO", "1VG", "ANDEC", "FUJI",
				"IDEAL", "IMPORT", "NACION", "PLAGAM", "TUGALT",
				"ROOFTE")
		THEN "05_GENERICOS"
		ELSE "06_OTRAS_MARCAS"
	END AS linea_vta,
	NVL(SUM(r20_val_descto), 0) AS descuento,
	NVL(SUM((r20_cant_ven * r20_precio) - r20_val_descto), 0) AS valor
	FROM venta, item, clase, vendedor, cliente
	WHERE r20_localidad IN (1, 2)
	  AND YEAR(r20_fecing) > 2007
	  AND r10_codigo     = r20_item
	  AND r72_linea      = r10_linea
	  AND r72_sub_linea  = r10_sub_linea
	  AND r72_cod_grupo  = r10_cod_grupo
	  AND r72_cod_clase  = r10_cod_clase
	  AND z01_localidad  = r20_localidad
	  AND z01_codcli     = r20_cliente
	  AND r01_localidad  = r20_localidad
	  AND r01_codigo     = r20_vendedor
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
UNION
SELECT CASE WHEN r22_localidad = 01 THEN "01 GYE J T M"
	    WHEN r22_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r22_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r22_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r22_localidad = 05 THEN "05 ACERO KHOLER"
	END AS localidad,
	r22_anio AS anio,
	CASE WHEN r22_mes = 01 THEN "01 ENERO"
	     WHEN r22_mes = 02 THEN "02 FEBRERO"
	     WHEN r22_mes = 03 THEN "03 MARZO"
	     WHEN r22_mes = 04 THEN "04 ABRIL"
	     WHEN r22_mes = 05 THEN "05 MAYO"
	     WHEN r22_mes = 06 THEN "06 JUNIO"
	     WHEN r22_mes = 07 THEN "07 JULIO"
	     WHEN r22_mes = 08 THEN "08 AGOSTO"
	     WHEN r22_mes = 09 THEN "09 SEPTIEMBRE"
	     WHEN r22_mes = 10 THEN "10 OCTUBRE"
	     WHEN r22_mes = 11 THEN "11 NOVIEMBRE"
	     WHEN r22_mes = 12 THEN "12 DICIEMBRE"
	END AS meses,
	r01_nombres AS vendedor,
	r01_iniciales AS ini_vend,
	r22_codcli AS cod_cli,
	r22_nomcli AS nom_cli,
	r22_bodega AS bodega,
	r72_desc_clase AS clase,
	r10_nombre AS descripcion,
	r22_item AS item,
	r10_marca AS marca,
	"02_PROFORMAS_FACT" AS tipo,
	CASE WHEN r10_marca IN ("F.P.S.", "FAMAC", "FRANKL", "GORMAN", "GRUNDF",
				"MARKGR", "MARKPE", "MYERS", "WELLMA")
		THEN "01_FLUIDOS"
	     WHEN r10_marca IN ("ARMSTR", "ENERPA", "JET", "KITO", "MILWAU",
				"POWERS", "RIDGID")
		THEN "02_HERRAMIENTAS"
	     WHEN r10_marca IN ("F.I.V", "INOXTE", "KITZ", "KLINGE", "REDWHI",
				"TECVAL")
		THEN "03_VAPOR"
	     WHEN r10_marca IN ("ARISTON", "AVALON", "ALPHAJ", "ARISTO",
				"BRIGGS", "CALORE", "CASTEL", "CATA", "CERREC",
				"CONACA", "CREIN", "ECERAM", "EDESA", "EREJIL",
				"FECSA", "FIBRAS", "FV", "FVCERA", "FVGRIF",
				"FVSANI", "HACEB", "INCAME", "INSINK", "INTACO",
				"KERAMI","KOHGRI", "KOHSAN", "KWIKSE", "MATEX",
				"PERMAC", "RIALTO", "SIDEC", "TEKA", "TEKVEN")
		THEN "04_SANITARIOS"
	     WHEN r10_marca IN ("1HAG", "1HAN", "1TO", "1VG", "ANDEC", "FUJI",
				"IDEAL", "IMPORT", "NACION", "PLAGAM", "TUGALT",
				"ROOFTE")
		THEN "05_GENERICOS"
		ELSE "06_OTRAS_MARCAS"
	END AS linea_vta,
	NVL(SUM(r22_val_descto), 0) AS descuento,
	NVL(SUM((r22_cantidad * r22_precio) - r22_val_descto), 0) AS valor
	FROM proforma, item, clase, vendedor
	WHERE r22_localidad IN (1, 2)
	  AND r22_cod_tran  IS NOT NULL
	  AND YEAR(r22_fecing) > 2007
	  AND r10_codigo     = r22_item
	  AND r72_linea      = r10_linea
	  AND r72_sub_linea  = r10_sub_linea
	  AND r72_cod_grupo  = r10_cod_grupo
	  AND r72_cod_clase  = r10_cod_clase
	  AND r01_localidad  = r22_localidad
	  AND r01_codigo     = r22_vendedor
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14
UNION
SELECT CASE WHEN r22_localidad = 01 THEN "01 GYE J T M"
	    WHEN r22_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r22_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r22_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r22_localidad = 05 THEN "05 ACERO KHOLER"
	END AS localidad,
	r22_anio AS anio,
	CASE WHEN r22_mes = 01 THEN "01 ENERO"
	     WHEN r22_mes = 02 THEN "02 FEBRERO"
	     WHEN r22_mes = 03 THEN "03 MARZO"
	     WHEN r22_mes = 04 THEN "04 ABRIL"
	     WHEN r22_mes = 05 THEN "05 MAYO"
	     WHEN r22_mes = 06 THEN "06 JUNIO"
	     WHEN r22_mes = 07 THEN "07 JULIO"
	     WHEN r22_mes = 08 THEN "08 AGOSTO"
	     WHEN r22_mes = 09 THEN "09 SEPTIEMBRE"
	     WHEN r22_mes = 10 THEN "10 OCTUBRE"
	     WHEN r22_mes = 11 THEN "11 NOVIEMBRE"
	     WHEN r22_mes = 12 THEN "12 DICIEMBRE"
	END AS meses,
	r01_nombres AS vendedor,
	r01_iniciales AS ini_vend,
	r22_codcli AS cod_cli,
	r22_nomcli AS nom_cli,
	r22_bodega AS bodega,
	r72_desc_clase AS clase,
	r10_nombre AS descripcion,
	r22_item AS item,
	r10_marca AS marca,
	"03_PROFORMAS_NO_FACT" AS tipo,
	CASE WHEN r10_marca IN ("F.P.S.", "FAMAC", "FRANKL", "GORMAN", "GRUNDF",
				"MARKGR", "MARKPE", "MYERS", "WELLMA")
		THEN "01_FLUIDOS"
	     WHEN r10_marca IN ("ARMSTR", "ENERPA", "JET", "KITO", "MILWAU",
				"POWERS", "RIDGID")
		THEN "02_HERRAMIENTAS"
	     WHEN r10_marca IN ("F.I.V", "INOXTE", "KITZ", "KLINGE", "REDWHI",
				"TECVAL")
		THEN "03_VAPOR"
	     WHEN r10_marca IN ("ARISTON", "AVALON", "ALPHAJ", "ARISTO",
				"BRIGGS", "CALORE", "CASTEL", "CATA", "CERREC",
				"CONACA", "CREIN", "ECERAM", "EDESA", "EREJIL",
				"FECSA", "FIBRAS", "FV", "FVCERA", "FVGRIF",
				"FVSANI", "HACEB", "INCAME", "INSINK", "INTACO",
				"KERAMI","KOHGRI", "KOHSAN", "KWIKSE", "MATEX",
				"PERMAC", "RIALTO", "SIDEC", "TEKA", "TEKVEN")
		THEN "04_SANITARIOS"
	     WHEN r10_marca IN ("1HAG", "1HAN", "1TO", "1VG", "ANDEC", "FUJI",
				"IDEAL", "IMPORT", "NACION", "PLAGAM", "TUGALT",
				"ROOFTE")
		THEN "05_GENERICOS"
		ELSE "06_OTRAS_MARCAS"
	END AS linea_vta,
	NVL(SUM(r22_val_descto), 0) AS descuento,
	NVL(SUM((r22_cantidad * r22_precio) - r22_val_descto), 0) AS valor
	FROM proforma, item, clase, vendedor
	WHERE r22_localidad IN (1, 2)
	  AND r22_cod_tran  IS NULL
	  AND YEAR(r22_fecing) > 2007
	  AND r10_codigo     = r22_item
	  AND r72_linea      = r10_linea
	  AND r72_sub_linea  = r10_sub_linea
	  AND r72_cod_grupo  = r10_cod_grupo
	  AND r72_cod_clase  = r10_cod_clase
	  AND r01_localidad  = r22_localidad
	  AND r01_codigo     = r22_vendedor
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14;
