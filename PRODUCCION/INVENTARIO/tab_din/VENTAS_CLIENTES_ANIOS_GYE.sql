SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM gent002
		WHERE g02_compania  = r19_compania
		  AND g02_localidad = r19_localidad) AS local,
	r19_codcli AS codcli, r19_nomcli AS cliente,
	z01_direccion1 AS direccion,
	z01_telefono1 AS telefono,
	(SELECT g31_nombre
		FROM gent031
		WHERE g31_ciudad = z01_ciudad) AS ciudad,
	CASE WHEN z01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS estado,
	YEAR(r19_fecing) AS anio,
	CASE WHEN MONTH(r19_fecing) = 01 THEN "01_ENERO"
	     WHEN MONTH(r19_fecing) = 02 THEN "02_FEBRERO"
	     WHEN MONTH(r19_fecing) = 03 THEN "03_MARZO"
	     WHEN MONTH(r19_fecing) = 04 THEN "04_ABRIL"
	     WHEN MONTH(r19_fecing) = 05 THEN "05_MAYO"
	     WHEN MONTH(r19_fecing) = 06 THEN "06_JUNIO"
	     WHEN MONTH(r19_fecing) = 07 THEN "07_JULIO"
	     WHEN MONTH(r19_fecing) = 08 THEN "08_AGOSTO"
	     WHEN MONTH(r19_fecing) = 09 THEN "09_SEPTIEMBRE"
	     WHEN MONTH(r19_fecing) = 10 THEN "10_OCTUBRE"
	     WHEN MONTH(r19_fecing) = 11 THEN "11_NOVIEMBRE"
	     WHEN MONTH(r19_fecing) = 12 THEN "12_DICIEMBRE"
	END AS meses,
	CASE WHEN r10_marca IN ("FRANKL", "GORMAN", "GRUNDF", "MARKGR", "MYERS",
				"WELLMA", "FAMAC", "F.P.S.", "MARKPE")
		THEN "01_FLUIDOS"
	     WHEN r10_marca IN ("RIDGID", "MILWAU", "ENERPA", "ARMSTR",
				"POWERS", "JET", "KITO")
		THEN "02_HERRAMIENTAS"
	     WHEN r10_marca IN ("INOXTE", "F.I.V", "KITZ", "KLINGE", "TECVAL",
				"REDWHI")
		THEN "03_VAPOR"
	     WHEN r10_marca IN ("ECERAM", "INSINK", "RIALTO", "SIDEC", "FVGRIF",
				"FVSANI", "FVCERA", "EDESA", "TEKVEN",
				"TEKA", "CALORE", "KOHGRI", "KOHSAN", "CERREC",
				"AVALON", "BRIGGS", "CREIN", "ALPHAJ", "ARISTO",
				"CATA", "CASTEL", "CONACA", "EREJIL", "FECSA",
				"FIBRAS", "HACEB", "INSINK", "INCAME", "INTACO",
				"KERAMI", "KWIKSE", "MATEX", "PERMAC")
		THEN "04_SANITARIOS"
	     WHEN r10_marca IN ("ANDEC", "FUJI", "IDEAL", "PLAGAM", "TUGALT",
				"1HAG", "1HAN", "1TO", "1VG", "IMPORT",
				"NACION", "ROOFTE")
		THEN "05_GENERICOS"
		ELSE "06_OTRAS_MARCAS"
	END AS linea_venta,
	(SELECT r01_nombres
		FROM rept001
		WHERE r01_compania = r19_compania
		  AND r01_codigo   = r19_vendedor) AS vendedor,
	TO_CHAR(r19_fecing, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(r19_fecing)), 2, 0) AS num_sem,
	NVL(SUM(CASE WHEN r19_cod_tran = "FA"
		THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
		ELSE ((r20_cant_ven * r20_precio) - r20_val_descto) * (-1)
	END), 0) AS venta
        FROM rept019, rept020, rept010, cxct001
        WHERE r19_compania      = 1
          AND r19_localidad     = 1
          AND r19_cod_tran     IN ("FA", "DF", "AF")
	  AND YEAR(r19_fecing) >= 2010
  	  AND r20_compania      = r19_compania
	  AND r20_localidad     = r19_localidad
	  AND r20_cod_tran      = r19_cod_tran
	  AND r20_num_tran      = r19_num_tran
	  AND r10_compania      = r20_compania
	  AND r10_codigo        = r20_item
          AND z01_codcli        = r19_codcli
        GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
	HAVING
	ABS(NVL(SUM(CASE WHEN r19_cod_tran = "FA"
		THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
		ELSE ((r20_cant_ven * r20_precio) - r20_val_descto) * (-1)
	END), 0)) > 3000;
