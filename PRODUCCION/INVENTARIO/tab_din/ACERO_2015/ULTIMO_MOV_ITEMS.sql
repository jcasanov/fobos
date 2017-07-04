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
	END AS mes,
	ROUND((DATE(r20_fecing) - MDY(1, 3, YEAR(DATE(r20_fecing)
		- WEEKDAY(DATE(r20_fecing) - 1 UNITS DAY) + 4 UNITS DAY))
		+ WEEKDAY(MDY(1, 3, YEAR(DATE(r20_fecing)
		- WEEKDAY(DATE(r20_fecing) - 1 UNITS DAY) + 4 UNITS DAY)))
		+ 5) / 7, 0) AS num_sem,
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
	r10_filtro AS filtro,
	r20_item AS ite,
	(SELECT TRIM(g21_nombre)
		FROM gent021
		WHERE g21_cod_tran = r20_cod_tran) AS cod_t,
	r20_num_tran AS num_t,
	CASE WHEN (r20_cod_tran = "DF" OR r20_cod_tran = "AF" OR
		   r20_cod_tran = "CL" OR r20_cod_tran = "IM" OR
		   r20_cod_tran = "A+")
		THEN r20_cant_ven
		ELSE r20_cant_ven * (-1)
	END AS cant,
	DATE(r20_fecing) AS fecha
	FROM rept020, rept010
	WHERE r20_compania   = 1
	  AND r20_localidad  = 1
	  AND r20_cod_tran  NOT IN ("DR", "RQ", "AC", "TR")
	  AND r10_compania   = r20_compania
	  AND r10_codigo     = r20_item
UNION
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
	END AS mes,
	ROUND((DATE(r20_fecing) - MDY(1, 3, YEAR(DATE(r20_fecing)
		- WEEKDAY(DATE(r20_fecing) - 1 UNITS DAY) + 4 UNITS DAY))
		+ WEEKDAY(MDY(1, 3, YEAR(DATE(r20_fecing)
		- WEEKDAY(DATE(r20_fecing) - 1 UNITS DAY) + 4 UNITS DAY)))
		+ 5) / 7, 0) AS num_sem,
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
	r10_filtro AS filtro,
	r20_item AS ite,
	(SELECT TRIM(g21_nombre)
		FROM gent021
		WHERE g21_cod_tran = r20_cod_tran) AS cod_t,
	r20_num_tran AS num_t,
	CASE WHEN (r02_localidad = r19_localidad AND
		   r02_codigo    = r19_bodega_dest)
		THEN r20_cant_ven
		ELSE r20_cant_ven * (-1)
	END AS cant,
	DATE(r20_fecing) AS fecha
	FROM rept020, rept019, rept002, rept010
	WHERE r20_compania     = 1
	  AND r20_localidad    = 1
	  AND r20_cod_tran     = "TR"
	  AND r19_compania     = r20_compania
	  AND r19_localidad    = r20_localidad
	  AND r19_cod_tran     = r20_cod_tran
	  AND r19_num_tran     = r20_num_tran
	  AND ((r02_compania   = r19_compania
	  AND   r02_codigo     = r19_bodega_ori 
	  AND   r02_localidad <> r19_localidad)
	   OR  (r02_compania   = r19_compania
	  AND   r02_codigo     = r19_bodega_dest 
	  AND   r02_localidad <> r19_localidad))
	  AND r10_compania     = r20_compania
	  AND r10_codigo       = r20_item
UNION
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
	END AS mes,
	ROUND((DATE(r20_fecing) - MDY(1, 3, YEAR(DATE(r20_fecing)
		- WEEKDAY(DATE(r20_fecing) - 1 UNITS DAY) + 4 UNITS DAY))
		+ WEEKDAY(MDY(1, 3, YEAR(DATE(r20_fecing)
		- WEEKDAY(DATE(r20_fecing) - 1 UNITS DAY) + 4 UNITS DAY)))
		+ 5) / 7, 0) AS num_sem,
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
	r10_filtro AS filtro,
	r20_item AS ite,
	(SELECT TRIM(g21_nombre)
		FROM acero_gc:gent021
		WHERE g21_cod_tran = r20_cod_tran) AS cod_t,
	r20_num_tran AS num_t,
	CASE WHEN (r20_cod_tran = "DF" OR r20_cod_tran = "AF" OR
		   r20_cod_tran = "CL" OR r20_cod_tran = "IM" OR
		   r20_cod_tran = "A+")
		THEN r20_cant_ven
		ELSE r20_cant_ven * (-1)
	END AS cant,
	DATE(r20_fecing) AS fecha
	FROM acero_gc:rept020, acero_gc:rept010
	WHERE r20_compania   = 1
	  AND r20_localidad  = 2
	  AND r20_cod_tran  NOT IN ("DR", "RQ", "AC", "TR")
	  AND r10_compania   = r20_compania
	  AND r10_codigo     = r20_item
UNION
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
	END AS mes,
	ROUND((DATE(r20_fecing) - MDY(1, 3, YEAR(DATE(r20_fecing)
		- WEEKDAY(DATE(r20_fecing) - 1 UNITS DAY) + 4 UNITS DAY))
		+ WEEKDAY(MDY(1, 3, YEAR(DATE(r20_fecing)
		- WEEKDAY(DATE(r20_fecing) - 1 UNITS DAY) + 4 UNITS DAY)))
		+ 5) / 7, 0) AS num_sem,
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
	r10_filtro AS filtro,
	r20_item AS ite,
	(SELECT TRIM(g21_nombre)
		FROM acero_gc:gent021
		WHERE g21_cod_tran = r20_cod_tran) AS cod_t,
	r20_num_tran AS num_t,
	CASE WHEN (r02_localidad = r19_localidad AND
		   r02_codigo    = r19_bodega_dest)
		THEN r20_cant_ven
		ELSE r20_cant_ven * (-1)
	END AS cant,
	DATE(r20_fecing) AS fecha
	FROM acero_gc:rept020, acero_gc:rept019, acero_gc:rept002,
		acero_gc:rept010
	WHERE r20_compania     = 1
	  AND r20_localidad    = 2
	  AND r20_cod_tran     = "TR"
	  AND r19_compania     = r20_compania
	  AND r19_localidad    = r20_localidad
	  AND r19_cod_tran     = r20_cod_tran
	  AND r19_num_tran     = r20_num_tran
	  AND ((r02_compania   = r19_compania
	  AND   r02_codigo     = r19_bodega_ori 
	  AND   r02_localidad <> r19_localidad)
	   OR  (r02_compania   = r19_compania
	  AND   r02_codigo     = r19_bodega_dest 
	  AND   r02_localidad <> r19_localidad))
	  AND r10_compania     = r20_compania
	  AND r10_codigo       = r20_item
UNION
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
	END AS mes,
	ROUND((DATE(r20_fecing) - MDY(1, 3, YEAR(DATE(r20_fecing)
		- WEEKDAY(DATE(r20_fecing) - 1 UNITS DAY) + 4 UNITS DAY))
		+ WEEKDAY(MDY(1, 3, YEAR(DATE(r20_fecing)
		- WEEKDAY(DATE(r20_fecing) - 1 UNITS DAY) + 4 UNITS DAY)))
		+ 5) / 7, 0) AS num_sem,
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
	r10_filtro AS filtro,
	r20_item AS ite,
	(SELECT TRIM(g21_nombre)
		FROM acero_qm:gent021
		WHERE g21_cod_tran = r20_cod_tran) AS cod_t,
	r20_num_tran AS num_t,
	CASE WHEN (r20_cod_tran = "DF" OR r20_cod_tran = "AF" OR
		   r20_cod_tran = "CL" OR r20_cod_tran = "IM" OR
		   r20_cod_tran = "A+")
		THEN r20_cant_ven
		ELSE r20_cant_ven * (-1)
	END AS cant,
	DATE(r20_fecing) AS fecha
	FROM acero_qm:rept020, acero_qm:rept010
	WHERE r20_compania   = 1
	  AND r20_localidad IN (3, 5)
	  AND r20_cod_tran  NOT IN ("DR", "RQ", "AC", "TR")
	  AND r10_compania   = r20_compania
	  AND r10_codigo     = r20_item
UNION
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
	END AS mes,
	ROUND((DATE(r20_fecing) - MDY(1, 3, YEAR(DATE(r20_fecing)
		- WEEKDAY(DATE(r20_fecing) - 1 UNITS DAY) + 4 UNITS DAY))
		+ WEEKDAY(MDY(1, 3, YEAR(DATE(r20_fecing)
		- WEEKDAY(DATE(r20_fecing) - 1 UNITS DAY) + 4 UNITS DAY)))
		+ 5) / 7, 0) AS num_sem,
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
	r10_filtro AS filtro,
	r20_item AS ite,
	(SELECT TRIM(g21_nombre)
		FROM acero_qm:gent021
		WHERE g21_cod_tran = r20_cod_tran) AS cod_t,
	r20_num_tran AS num_t,
	CASE WHEN (r02_localidad = r19_localidad AND
		   r02_codigo    = r19_bodega_dest)
		THEN r20_cant_ven
		ELSE r20_cant_ven * (-1)
	END AS cant,
	DATE(r20_fecing) AS fecha
	FROM acero_qm:rept020, acero_qm:rept019, acero_qm:rept002,
		acero_qm:rept010
	WHERE r20_compania     = 1
	  AND r20_localidad   IN (3, 5)
	  AND r20_cod_tran     = "TR"
	  AND r19_compania     = r20_compania
	  AND r19_localidad    = r20_localidad
	  AND r19_cod_tran     = r20_cod_tran
	  AND r19_num_tran     = r20_num_tran
	  AND ((r02_compania   = r19_compania
	  AND   r02_codigo     = r19_bodega_ori 
	  AND   r02_localidad <> r19_localidad)
	   OR  (r02_compania   = r19_compania
	  AND   r02_codigo     = r19_bodega_dest 
	  AND   r02_localidad <> r19_localidad))
	  AND r10_compania     = r20_compania
	  AND r10_codigo       = r20_item
UNION
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
	END AS mes,
	ROUND((DATE(r20_fecing) - MDY(1, 3, YEAR(DATE(r20_fecing)
		- WEEKDAY(DATE(r20_fecing) - 1 UNITS DAY) + 4 UNITS DAY))
		+ WEEKDAY(MDY(1, 3, YEAR(DATE(r20_fecing)
		- WEEKDAY(DATE(r20_fecing) - 1 UNITS DAY) + 4 UNITS DAY)))
		+ 5) / 7, 0) AS num_sem,
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
	r10_filtro AS filtro,
	r20_item AS ite,
	(SELECT TRIM(g21_nombre)
		FROM acero_qs:gent021
		WHERE g21_cod_tran = r20_cod_tran) AS cod_t,
	r20_num_tran AS num_t,
	CASE WHEN (r20_cod_tran = "DF" OR r20_cod_tran = "AF" OR
		   r20_cod_tran = "CL" OR r20_cod_tran = "IM" OR
		   r20_cod_tran = "A+")
		THEN r20_cant_ven
		ELSE r20_cant_ven * (-1)
	END AS cant,
	DATE(r20_fecing) AS fecha
	FROM acero_qs:rept020, acero_qs:rept010
	WHERE r20_compania   = 1
	  AND r20_localidad  = 4
	  AND r20_cod_tran  NOT IN ("DR", "RQ", "AC", "TR")
	  AND r10_compania   = r20_compania
	  AND r10_codigo     = r20_item
UNION
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
	END AS mes,
	ROUND((DATE(r20_fecing) - MDY(1, 3, YEAR(DATE(r20_fecing)
		- WEEKDAY(DATE(r20_fecing) - 1 UNITS DAY) + 4 UNITS DAY))
		+ WEEKDAY(MDY(1, 3, YEAR(DATE(r20_fecing)
		- WEEKDAY(DATE(r20_fecing) - 1 UNITS DAY) + 4 UNITS DAY)))
		+ 5) / 7, 0) AS num_sem,
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
	r10_filtro AS filtro,
	r20_item AS ite,
	(SELECT TRIM(g21_nombre)
		FROM acero_qs:gent021
		WHERE g21_cod_tran = r20_cod_tran) AS cod_t,
	r20_num_tran AS num_t,
	CASE WHEN (r02_localidad = r19_localidad AND
		   r02_codigo    = r19_bodega_dest)
		THEN r20_cant_ven
		ELSE r20_cant_ven * (-1)
	END AS cant,
	DATE(r20_fecing) AS fecha
	FROM acero_qs:rept020, acero_qs:rept019, acero_qs:rept002,
		acero_qs:rept010
	WHERE r20_compania     = 1
	  AND r20_localidad    = 4
	  AND r20_cod_tran     = "TR"
	  AND r19_compania     = r20_compania
	  AND r19_localidad    = r20_localidad
	  AND r19_cod_tran     = r20_cod_tran
	  AND r19_num_tran     = r20_num_tran
	  AND ((r02_compania   = r19_compania
	  AND   r02_codigo     = r19_bodega_ori 
	  AND   r02_localidad <> r19_localidad)
	   OR  (r02_compania   = r19_compania
	  AND   r02_codigo     = r19_bodega_dest 
	  AND   r02_localidad <> r19_localidad))
	  AND r10_compania     = r20_compania
	  AND r10_codigo       = r20_item;
