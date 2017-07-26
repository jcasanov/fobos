SELECT CASE WHEN r20_localidad = 01 THEN "01 GYE J T M"
	    WHEN r20_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r20_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r20_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r20_localidad = 05 THEN "05 ACERO KHOLER"
	END AS localidad,
	YEAR(r20_fecing) AS anio,
	DATE(r20_fecing) AS fecha,
	r01_nombres AS vendedor,
	r01_iniciales AS ini_vend,
	r20_cliente AS cod_cli,
	z01_nomcli AS nom_cli,
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
	CASE WHEN r20_cont_cred = "R"
		THEN "CREDITO"
		ELSE "CONTADO"
	END AS cont_cr,
	r73_desc_marca AS marca,
	r10_filtro AS filtro,
	fp_numero_semana(DATE(r20_fecing)) AS nun_sem,
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
	NVL(SUM((r20_cant_ven * r20_precio) - r20_val_descto), 0) AS vta
	FROM venta, vendedor, cliente, item, marca
	WHERE r20_localidad    IN (1, 2, 3, 4, 5)
	  AND YEAR(r20_fecing) >= 2010
	  AND r01_codigo        = r20_vendedor
	  AND z01_localidad     = r20_localidad
	  AND z01_codcli        = r20_cliente
	  AND r01_localidad     = r20_localidad
	  AND r10_codigo        = r20_item
	  AND r73_marca         = r10_marca
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14;
