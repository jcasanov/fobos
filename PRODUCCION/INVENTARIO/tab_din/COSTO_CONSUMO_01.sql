SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM gent002
		WHERE g02_compania  = r10_compania
		  AND g02_localidad = 1) AS local,
	CAST (r10_codigo AS INTEGER) AS item,
	r10_nombre AS descrip,
	r10_uni_med AS uni_m,
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
	(SELECT r06_nombre
		FROM rept006
		WHERE r06_codigo = r10_tipo) AS tip_ite,
	NVL((SELECT SUM(r11_stock_act)
		FROM rept011, rept002
		WHERE r11_compania   = r10_compania
		  AND r11_item       = r10_codigo
		  AND r11_stock_act  > 0
		  AND r02_compania   = r11_compania
		  AND r02_codigo     = r11_bodega
		  AND r02_localidad IN (1, 2)
		  AND r02_estado     = "A"
		  AND r02_tipo      <> "S"), 0.00) AS exist,
	r10_costo_mb AS costo,
	NVL((SELECT SUM(CASE WHEN r20_cod_tran = "FA"
				THEN r20_cant_ven
				ELSE r20_cant_ven * (-1)
			END)
		FROM rept020, rept019
		WHERE  r20_compania      = r10_compania
		  AND  r20_localidad     = 1
		  AND  r20_cod_tran     IN ("FA", "DF")
		  AND  r20_item          = r10_codigo
		  AND  DATE(r20_fecing) BETWEEN DATE(r20_fecing) - 90 UNITS DAY
					    AND TODAY - 1 UNITS DAY
		  AND  r19_compania      = r20_compania
		  AND  r19_localidad     = r20_localidad
		  AND  r19_cod_tran      = r20_cod_tran
		  AND  r19_num_tran      = r20_num_tran
		  AND (r19_tipo_dev     IS NULL
		   OR  r19_tipo_dev     <> "AF")), 0.00) AS sal_vta,
	NVL((SELECT TO_CHAR(MAX(DATE(r20_fecing)), "%Y-%m-%d")
		FROM rept020, rept019
		WHERE r20_compania   = r10_compania
		  AND r20_localidad  = 1
		  AND r20_cod_tran  IN ("IM", "CL", "DC")
		  AND r20_item       = r10_codigo
		  AND r19_compania   = r20_compania
		  AND r19_localidad  = r20_localidad
		  AND r19_cod_tran   = r20_cod_tran
		  AND r19_num_tran   = r20_num_tran), "") AS ult_com,
	NVL((SELECT TO_CHAR(MAX(DATE(r20_fecing)), "%Y-%m-%d")
		FROM rept020, rept019
		WHERE  r20_compania      = r10_compania
		  AND  r20_localidad     = 1
		  AND  r20_cod_tran     IN ("FA", "DF")
		  AND  r20_item          = r10_codigo
		  AND  r19_compania      = r20_compania
		  AND  r19_localidad     = r20_localidad
		  AND  r19_cod_tran      = r20_cod_tran
		  AND  r19_num_tran      = r20_num_tran
		  AND (r19_tipo_dev     IS NULL
		   OR  r19_tipo_dev     <> "AF")), "") AS ult_vta
	FROM rept010
	WHERE r10_compania = 1
	  AND r10_estado   = "A"
