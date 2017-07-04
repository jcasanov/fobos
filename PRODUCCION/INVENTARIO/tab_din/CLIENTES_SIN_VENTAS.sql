SELECT YEAR(a.r19_fecing) AS anio,
	CASE WHEN MONTH(a.r19_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(a.r19_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(a.r19_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(a.r19_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(a.r19_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(a.r19_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(a.r19_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(a.r19_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(a.r19_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(a.r19_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(a.r19_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(a.r19_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	CASE WHEN a.r19_cont_cred = "C"
		THEN "CONTADO"
		ELSE "CREDITO"
	END AS tip_vta,
	r01_nombres AS vend,
	a.r19_codcli AS codcli,
	a.r19_nomcli AS nomcli,
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
	DATE(z01_fecing) AS feccre,
	CASE WHEN z01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est_cli,
	"MAS 90 DIAS" AS sin_v,
	(SELECT (TODAY - MAX(DATE(b.r19_fecing)))
		FROM rept019 b
		WHERE b.r19_compania  = a.r19_compania
		  AND b.r19_localidad = a.r19_localidad
		  AND b.r19_cod_tran  = "FA"
		  AND b.r19_codcli    = a.r19_codcli) AS n_dias,
	SUM(CASE WHEN a.r19_cod_tran = "FA"
		THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
		ELSE ((r20_cant_ven * r20_precio) - r20_val_descto) * (-1)
	END) AS vta
	FROM rept019 a, rept001, rept020, rept010, rept073, cxct001
	WHERE a.r19_compania      = 1
	  AND a.r19_cod_tran     IN ("FA", "DF", "AF")
	  AND YEAR(a.r19_fecing) >= 2009
	  AND r01_compania        = a.r19_compania
	  AND r01_codigo          = a.r19_vendedor
	  AND r20_compania        = a.r19_compania
	  AND r20_localidad       = a.r19_localidad
	  AND r20_cod_tran        = a.r19_cod_tran
	  AND r20_num_tran        = a.r19_num_tran
	  AND r10_compania        = r20_compania
	  AND r10_codigo          = r20_item
	  AND r73_compania        = r10_compania
	  AND r73_marca           = r10_marca
	  AND z01_codcli          = a.r19_codcli
	  AND (SELECT (TODAY - MAX(DATE(b.r19_fecing)))
			FROM rept019 b
			WHERE b.r19_compania  = a.r19_compania
			  AND b.r19_localidad = a.r19_localidad
			  AND b.r19_cod_tran  = "FA"
			  AND b.r19_codcli    = a.r19_codcli) BETWEEN 90 AND 180
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
UNION
SELECT YEAR(a.r19_fecing) AS anio,
	CASE WHEN MONTH(a.r19_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(a.r19_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(a.r19_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(a.r19_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(a.r19_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(a.r19_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(a.r19_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(a.r19_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(a.r19_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(a.r19_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(a.r19_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(a.r19_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	CASE WHEN a.r19_cont_cred = "C"
		THEN "CONTADO"
		ELSE "CREDITO"
	END AS tip_vta,
	r01_nombres AS vend,
	a.r19_codcli AS codcli,
	a.r19_nomcli AS nomcli,
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
	DATE(z01_fecing) AS feccre,
	CASE WHEN z01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est_cli,
	"MAS 180 DIAS" AS sin_v,
	(SELECT (TODAY - MAX(DATE(b.r19_fecing)))
		FROM rept019 b
		WHERE b.r19_compania  = a.r19_compania
		  AND b.r19_localidad = a.r19_localidad
		  AND b.r19_cod_tran  = "FA"
		  AND b.r19_codcli    = a.r19_codcli) AS n_dias,
	SUM(CASE WHEN a.r19_cod_tran = "FA"
		THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
		ELSE ((r20_cant_ven * r20_precio) - r20_val_descto) * (-1)
	END) AS vta
	FROM rept019 a, rept001, rept020, rept010, rept073, cxct001
	WHERE a.r19_compania      = 1
	  AND a.r19_cod_tran     IN ("FA", "DF", "AF")
	  AND YEAR(a.r19_fecing) >= 2009
	  AND r01_compania        = a.r19_compania
	  AND r01_codigo          = a.r19_vendedor
	  AND r20_compania        = a.r19_compania
	  AND r20_localidad       = a.r19_localidad
	  AND r20_cod_tran        = a.r19_cod_tran
	  AND r20_num_tran        = a.r19_num_tran
	  AND r10_compania        = r20_compania
	  AND r10_codigo          = r20_item
	  AND r73_compania        = r10_compania
	  AND r73_marca           = r10_marca
	  AND z01_codcli          = a.r19_codcli
	  AND (SELECT (TODAY - MAX(DATE(b.r19_fecing)))
			FROM rept019 b
			WHERE b.r19_compania  = a.r19_compania
			  AND b.r19_localidad = a.r19_localidad
			  AND b.r19_cod_tran  = "FA"
			  AND b.r19_codcli    = a.r19_codcli) > 180
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
	ORDER BY 13, 1, 6;
