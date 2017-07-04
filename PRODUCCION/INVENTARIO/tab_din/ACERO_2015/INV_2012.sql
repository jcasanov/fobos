SELECT r11_bodega AS bodega,
	r02_nombre AS desc_bd,
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
	CAST(r11_item AS INTEGER) AS item,
	r10_nombre AS descrip,
	r72_desc_clase AS clas,
	r11_stock_act AS sto,
	CASE WHEN r02_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est_b,
	CASE WHEN r10_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est_i
	FROM rept011, rept002, rept010, rept072, rept073
	WHERE r11_compania    = 1
	  AND r11_stock_act  <> 0
	  AND r02_compania    = r11_compania
	  AND r02_codigo      = r11_bodega
	  AND r02_tipo       IN ("F", "L")
	  AND r02_localidad   = 1
	  AND r02_tipo_ident NOT IN ("E", "S")
	  AND r10_compania    = r11_compania
	  AND r10_codigo      = r11_item
	  AND r72_compania    = r10_compania
	  AND r72_linea       = r10_linea
	  AND r72_sub_linea   = r10_sub_linea
	  AND r72_cod_grupo   = r10_cod_grupo
	  AND r72_cod_clase   = r10_cod_clase
	  AND r73_compania    = r10_compania
	  AND r73_marca       = r10_marca;
