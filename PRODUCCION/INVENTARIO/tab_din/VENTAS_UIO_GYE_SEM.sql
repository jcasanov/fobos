SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM localidad
		WHERE g02_localidad = r20_localidad) AS local,
	YEAR(r20_fecing) AS anio,
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
	END AS mes,
	DATE(r20_fecing) AS fecha,
	LPAD(DAY(r20_fecing), 2, 0) || " " ||
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
	END || " " || YEAR(r20_fecing) AS dia_v,
	(SELECT r01_nombres
		FROM vendedor
		WHERE r01_localidad = r20_localidad
		  AND r01_codigo    = r20_vendedor) AS vend,
	(SELECT r01_iniciales
		FROM vendedor
		WHERE r01_localidad = r20_localidad
		  AND r01_codigo    = r20_vendedor) AS ini_vend,
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
	TO_CHAR(r20_fecing, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(r20_fecing)), 2, 0) AS num_sem,
	(SELECT CASE WHEN r01_tipo = "I" THEN "VENDEDOR ALMACEN"
		     WHEN r01_tipo = "E" THEN "VENDEDOR EXTERNO"
		     WHEN r01_tipo = "B" THEN "BODEGUERO"
		     WHEN r01_tipo = "J" THEN "JEFE DE VENTAS"
		     WHEN r01_tipo = "G" THEN "GERENTE VENTAS"
		END
		FROM vendedor
		WHERE r01_localidad = r20_localidad
		  AND r01_codigo    = r20_vendedor) AS tip_v,
	(SELECT CASE WHEN r01_estado = "A"
			THEN "ACTIVO"
			ELSE "BLOQUEADO"
		END
		FROM vendedor
		WHERE r01_localidad = r20_localidad
		  AND r01_codigo    = r20_vendedor) AS est_v,
	NVL(SUM((r20_cant_ven * r20_precio) - r20_val_descto), 0) AS vta
	FROM venta, cliente, item, marca
	WHERE r20_localidad    IN (1, 2, 3, 4, 5)
	  AND YEAR(r20_fecing) >= 2010
	  AND z01_localidad     = r20_localidad
	  AND z01_codcli        = r20_cliente
	  AND r10_codigo        = r20_item
	  AND r73_marca         = r10_marca
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16;
