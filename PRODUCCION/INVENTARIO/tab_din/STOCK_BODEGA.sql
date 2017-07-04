SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM gent002
		WHERE g02_compania  = r02_compania
		  AND g02_localidad = r02_localidad) AS loc,
	CAST (r10_codigo AS INTEGER) AS item,
	r10_nombre AS descrip,
	(SELECT r72_desc_clase
		FROM rept072
		WHERE r72_compania  = r10_compania
		  AND r72_linea     = r10_linea
		  AND r72_sub_linea = r10_sub_linea
		  AND r72_cod_grupo = r10_cod_grupo
		  AND r72_cod_clase = r10_cod_clase) AS clas,
	r10_marca AS marc,
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
	(SELECT r09_descripcion
		FROM rept009
		WHERE r09_compania   = r02_compania
		  AND r09_tipo_ident = r02_tipo_ident) AS tipo,
	r11_bodega AS bod,
	CASE WHEN r10_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est,
	NVL(SUM(r11_stock_act), 0.00) AS sto
	FROM rept010, rept011, rept002
	WHERE r10_compania   = 1
	  AND r11_compania   = r10_compania
	  AND r11_item       = r10_codigo
	  AND r11_stock_act <> 0
	  AND r02_compania   = r11_compania
	  AND r02_codigo     = r11_bodega
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9;
