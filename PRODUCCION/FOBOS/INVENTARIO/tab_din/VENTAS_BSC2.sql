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
	DAY(r20_fecing) AS dia,
	r01_nombres AS vendedor,
	r20_cliente AS cod_cli,
	z01_nomcli AS nom_cli,
	CASE WHEN r10_filtro IN ("F.P.S.", "FAMAC", "FRANKL", "GORMAN",
				"GRUNDF", "MARK", "MYERS", "WELLMA")
		THEN "01_FLUIDOS"
	     WHEN r10_filtro IN ("ARMSTR", "ENERPA", "JET", "KITO", "MILWAU",
				"POWERS", "RIDGID")
		THEN "02_HERRAMIENTAS"
	     WHEN r10_filtro IN ("F.I.V", "INOXTE", "KITZ", "KLINGE", "REDWHI",
				"TECVAL")
		THEN "03_VAPOR"
	     WHEN r10_filtro IN ("ARISTON", "AVALON", "ALPHAJ", "ARISTO",
				"BRIGGS", "CALORE", "CASTEL", "CATA", "CERREC",
				"CONACA", "CREIN", "ECERAM", "EDESA", "EREJIL",
				"FECSA", "FIBRAS", "FV", "FVCERA", "FVGRIF",
				"FVSANI", "HACEB", "INCAME", "INSINK", "INTACO",
				"KERAMI","KOHGRI", "KOHSAN", "KWIKSE", "MATEX",
				"PERMAC", "RIALTO", "SIDEC", "TEKA", "TEKVEN")
		THEN "04_SANITARIOS"
	     WHEN r10_filtro IN ("1HAG", "1TO", "1VG", "ANDEC", "FUJI", "IDEAL",
				"IMPORT", "NACION", "PLAGAM", "PLETINA_N",
				"TUGALT")
		THEN "05_GENERICOS"
		ELSE "06_OTRAS_MARCAS"
	END AS linea_venta,
	r73_desc_marca AS marca,
	r72_desc_clase AS clase,
	r10_nombre AS descripcion,
	r20_item AS item,
	NVL(SUM((r20_cant_ven * r20_precio) - r20_val_descto), 0) AS venta
	FROM venta, item, clase, marca, vendedor, cliente
	WHERE YEAR(r20_fecing) > 2007
	  AND r10_codigo     = r20_item
	  AND r72_linea      = r10_linea
	  AND r72_sub_linea  = r10_sub_linea
	  AND r72_cod_grupo  = r10_cod_grupo
	  AND r72_cod_clase  = r10_cod_clase
	  AND r73_marca      = r10_marca
	  AND z01_localidad  = r20_localidad
	  AND z01_codcli     = r20_cliente
	  AND r01_localidad  = r20_localidad
	  AND r01_codigo     = r20_vendedor
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12;
