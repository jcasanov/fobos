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
	END AS linea_venta,
	r73_desc_marca AS marca,
	r10_filtro AS filtro,
	LPAD(ROUND((DATE(r20_fecing) - MDY(1, 3, YEAR(DATE(r20_fecing)
		- WEEKDAY(DATE(r20_fecing) - 1 UNITS DAY) + 4 UNITS DAY))
		+ WEEKDAY(MDY(1, 3, YEAR(DATE(r20_fecing)
		- WEEKDAY(DATE(r20_fecing) - 1 UNITS DAY) + 4 UNITS DAY)))
		+ 5) / 7, 0), 2, 0) || " - " ||
	CASE WHEN MONTH(r20_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(r20_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(r20_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(r20_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(r20_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(r20_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(r20_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(r20_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(r20_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(r20_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(r20_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(r20_fecing) = 12 THEN "DICIEMBRE"
	END || " " || YEAR(r20_fecing) AS num_sem,
	CASE WHEN r01_tipo = "I" THEN "VENDEDOR ALMACEN"
	     WHEN r01_tipo = "E" THEN "VENDEDOR EXTERNO"
	     WHEN r01_tipo = "B" THEN "BODEGUERO"
	     WHEN r01_tipo = "J" THEN "JEFE DE VENTAS"
	     WHEN r01_tipo = "G" THEN "GERENTE VENTAS"
	END AS tip_v,
	CASE WHEN r01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est_v,
	NVL(SUM(r20_val_descto), 0) AS descuento,
	NVL(SUM((r20_cant_ven * r20_precio) - r20_val_descto), 0) AS valor
	FROM venta, vendedor, cliente, item, marca
	WHERE r20_localidad    IN (1, 2, 3, 4, 5)
	  AND YEAR(r20_fecing) >= 2012
	  AND r01_localidad     = r20_localidad
	  AND r01_codigo        = r20_vendedor
	  AND z01_localidad     = r20_localidad
	  AND z01_codcli        = r20_cliente
	  AND r10_codigo        = r20_item
	  AND r73_marca         = r10_marca
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
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
	END AS linea_venta,
	r73_desc_marca AS marca,
	r10_filtro AS filtro,
	LPAD(ROUND((DATE(r22_fecing) - MDY(1, 3, YEAR(DATE(r22_fecing)
		- WEEKDAY(DATE(r22_fecing) - 1 UNITS DAY) + 4 UNITS DAY))
		+ WEEKDAY(MDY(1, 3, YEAR(DATE(r22_fecing)
		- WEEKDAY(DATE(r22_fecing) - 1 UNITS DAY) + 4 UNITS DAY)))
		+ 5) / 7, 0), 2, 0) || " - " ||
	CASE WHEN MONTH(r22_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(r22_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(r22_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(r22_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(r22_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(r22_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(r22_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(r22_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(r22_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(r22_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(r22_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(r22_fecing) = 12 THEN "DICIEMBRE"
	END || " " || YEAR(r22_fecing) AS num_sem,
	CASE WHEN r01_tipo = "I" THEN "VENDEDOR ALMACEN"
	     WHEN r01_tipo = "E" THEN "VENDEDOR EXTERNO"
	     WHEN r01_tipo = "B" THEN "BODEGUERO"
	     WHEN r01_tipo = "J" THEN "JEFE DE VENTAS"
	     WHEN r01_tipo = "G" THEN "GERENTE VENTAS"
	END AS tip_v,
	CASE WHEN r01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est_v,
	NVL(SUM(r22_val_descto), 0) AS descuento,
	NVL(SUM((r22_cantidad * r22_precio) - r22_val_descto), 0) AS valor
	FROM proforma, vendedor, cliente, item, marca
	WHERE r22_localidad    IN (1, 2, 3, 4, 5)
	  AND r22_cod_tran     IS NOT NULL
	  AND YEAR(r22_fecing) >= 2012
	  AND z01_localidad     = r22_localidad
	  AND z01_codcli        = r22_codcli
	  AND r01_localidad     = r22_localidad
	  AND r01_codigo        = r22_vendedor
	  AND r10_codigo        = r22_item
	  AND r73_marca         = r10_marca
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16
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
	END AS linea_venta,
	r73_desc_marca AS marca,
	r10_filtro AS filtro,
	LPAD(ROUND((DATE(r22_fecing) - MDY(1, 3, YEAR(DATE(r22_fecing)
		- WEEKDAY(DATE(r22_fecing) - 1 UNITS DAY) + 4 UNITS DAY))
		+ WEEKDAY(MDY(1, 3, YEAR(DATE(r22_fecing)
		- WEEKDAY(DATE(r22_fecing) - 1 UNITS DAY) + 4 UNITS DAY)))
		+ 5) / 7, 0), 2, 0) || " - " ||
	CASE WHEN MONTH(r22_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(r22_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(r22_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(r22_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(r22_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(r22_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(r22_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(r22_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(r22_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(r22_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(r22_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(r22_fecing) = 12 THEN "DICIEMBRE"
	END || " " || YEAR(r22_fecing) AS num_sem,
	CASE WHEN r01_tipo = "I" THEN "VENDEDOR ALMACEN"
	     WHEN r01_tipo = "E" THEN "VENDEDOR EXTERNO"
	     WHEN r01_tipo = "B" THEN "BODEGUERO"
	     WHEN r01_tipo = "J" THEN "JEFE DE VENTAS"
	     WHEN r01_tipo = "G" THEN "GERENTE VENTAS"
	END AS tip_v,
	CASE WHEN r01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est_v,
	NVL(SUM(r22_val_descto), 0) AS descuento,
	NVL(SUM((r22_cantidad * r22_precio) - r22_val_descto), 0) AS valor
	FROM proforma, vendedor, cliente, item, marca
	WHERE r22_localidad    IN (1, 2, 3, 4, 5)
	  AND r22_cod_tran     IS NULL
	  AND YEAR(r22_fecing) >= 2012
	  AND z01_localidad     = r22_localidad
	  AND z01_codcli        = r22_codcli
	  AND r01_localidad     = r22_localidad
	  AND r01_codigo        = r22_vendedor
	  AND r10_codigo        = r22_item
	  AND r73_marca         = r10_marca
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16;
