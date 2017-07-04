SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_gm@idsgye01:gent002
		WHERE g02_compania  = r10_compania
		  AND g02_localidad = 1) AS local,
	CAST(r10_codigo AS INTEGER) AS item,
	CAST(r10_linea AS INTEGER) AS cod_lin,
	(SELECT r03_nombre
		FROM acero_gm@idsgye01:rept003
		WHERE r03_compania = r10_compania
		  AND r03_codigo   = r10_linea) AS des_lin,
	CAST(r10_sub_linea AS INTEGER) AS cod_sub,
	(SELECT r70_desc_sub
		FROM acero_gm@idsgye01:rept070
		WHERE r70_compania  = r10_compania
		  AND r70_linea     = r10_linea
		  AND r70_sub_linea = r10_sub_linea) AS des_sub,
	r10_cod_grupo AS cod_gru,
	(SELECT r71_desc_grupo
		FROM acero_gm@idsgye01:rept071
		WHERE r71_compania  = r10_compania
		  AND r71_linea     = r10_linea
		  AND r71_sub_linea = r10_sub_linea
		  AND r71_cod_grupo = r10_cod_grupo) AS des_gru,
	r10_cod_clase AS cod_cla,
	(SELECT r72_desc_clase
		FROM acero_gm@idsgye01:rept072
		WHERE r72_compania  = r10_compania
		  AND r72_linea     = r10_linea
		  AND r72_sub_linea = r10_sub_linea
		  AND r72_cod_grupo = r10_cod_grupo
		  AND r72_cod_clase = r10_cod_clase) AS des_cla,
	r10_nombre AS descrip,
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
	END AS lin_venta,
	CASE WHEN r10_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est,
	NVL((SELECT SUM(r11_stock_act)
		FROM acero_gm@idsgye01:rept011,
			acero_gm@idsgye01:rept002
		WHERE r11_compania   = r10_compania
		  AND r11_item       = r10_codigo
		  AND r11_stock_act  > 0
		  AND r02_compania   = r11_compania
		  AND r02_codigo     = r11_bodega
		  AND r02_localidad  = 1
		  AND r02_tipo      <> "S"), 0.00) AS sto
	FROM acero_gm@idsgye01:rept010
	WHERE r10_compania = 1
	  AND NVL((SELECT SUM(r11_stock_act)
			FROM acero_gm@idsgye01:rept011,
				acero_gm@idsgye01:rept002
			WHERE r11_compania   = r10_compania
			  AND r11_item       = r10_codigo
			  AND r02_compania   = r11_compania
			  AND r02_codigo     = r11_bodega
			  AND r02_localidad  = 1
			  AND r02_tipo      <> "S"), 0.00) > 0
UNION ALL
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_qm@acgyede:gent002
		WHERE g02_compania  = r10_compania
		  AND g02_localidad = 3) AS local,
	CAST(r10_codigo AS INTEGER) AS item,
	CAST(r10_linea AS INTEGER) AS cod_lin,
	(SELECT r03_nombre
		FROM acero_qm@acgyede:rept003
		WHERE r03_compania = r10_compania
		  AND r03_codigo   = r10_linea) AS des_lin,
	CAST(r10_sub_linea AS INTEGER) AS cod_sub,
	(SELECT r70_desc_sub
		FROM acero_qm@acgyede:rept070
		WHERE r70_compania  = r10_compania
		  AND r70_linea     = r10_linea
		  AND r70_sub_linea = r10_sub_linea) AS des_sub,
	r10_cod_grupo AS cod_gru,
	(SELECT r71_desc_grupo
		FROM acero_qm@acgyede:rept071
		WHERE r71_compania  = r10_compania
		  AND r71_linea     = r10_linea
		  AND r71_sub_linea = r10_sub_linea
		  AND r71_cod_grupo = r10_cod_grupo) AS des_gru,
	r10_cod_clase AS cod_cla,
	(SELECT r72_desc_clase
		FROM acero_qm@acgyede:rept072
		WHERE r72_compania  = r10_compania
		  AND r72_linea     = r10_linea
		  AND r72_sub_linea = r10_sub_linea
		  AND r72_cod_grupo = r10_cod_grupo
		  AND r72_cod_clase = r10_cod_clase) AS des_cla,
	r10_nombre AS descrip,
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
	END AS lin_venta,
	CASE WHEN r10_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est,
	NVL((SELECT SUM(r11_stock_act)
		FROM acero_qm@acgyede:rept011,
			acero_qm@acgyede:rept002
		WHERE r11_compania   = r10_compania
		  AND r11_item       = r10_codigo
		  AND r11_stock_act  > 0
		  AND r02_compania   = r11_compania
		  AND r02_codigo     = r11_bodega
		  AND r02_localidad IN (3, 5)
		  AND r02_tipo      <> "S"), 0.00) AS sto
	FROM acero_qm@acgyede:rept010
	WHERE r10_compania = 1
	  AND NVL((SELECT SUM(r11_stock_act)
			FROM acero_qm@acgyede:rept011,
				acero_qm@acgyede:rept002
			WHERE r11_compania   = r10_compania
			  AND r11_item       = r10_codigo
			  AND r02_compania   = r11_compania
			  AND r02_codigo     = r11_bodega
			  AND r02_localidad IN (3, 5)
			  AND r02_tipo      <> "S"), 0.00) > 0
UNION ALL
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_qs@acgyede:gent002
		WHERE g02_compania  = r10_compania
		  AND g02_localidad = 4) AS local,
	CAST(r10_codigo AS INTEGER) AS item,
	CAST(r10_linea AS INTEGER) AS cod_lin,
	(SELECT r03_nombre
		FROM acero_qs@acgyede:rept003
		WHERE r03_compania = r10_compania
		  AND r03_codigo   = r10_linea) AS des_lin,
	CAST(r10_sub_linea AS INTEGER) AS cod_sub,
	(SELECT r70_desc_sub
		FROM acero_qs@acgyede:rept070
		WHERE r70_compania  = r10_compania
		  AND r70_linea     = r10_linea
		  AND r70_sub_linea = r10_sub_linea) AS des_sub,
	r10_cod_grupo AS cod_gru,
	(SELECT r71_desc_grupo
		FROM acero_qs@acgyede:rept071
		WHERE r71_compania  = r10_compania
		  AND r71_linea     = r10_linea
		  AND r71_sub_linea = r10_sub_linea
		  AND r71_cod_grupo = r10_cod_grupo) AS des_gru,
	r10_cod_clase AS cod_cla,
	(SELECT r72_desc_clase
		FROM acero_qs@acgyede:rept072
		WHERE r72_compania  = r10_compania
		  AND r72_linea     = r10_linea
		  AND r72_sub_linea = r10_sub_linea
		  AND r72_cod_grupo = r10_cod_grupo
		  AND r72_cod_clase = r10_cod_clase) AS des_cla,
	r10_nombre AS descrip,
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
	END AS lin_venta,
	CASE WHEN r10_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est,
	NVL((SELECT SUM(r11_stock_act)
		FROM acero_qs@acgyede:rept011,
			acero_qs@acgyede:rept002
		WHERE r11_compania   = r10_compania
		  AND r11_item       = r10_codigo
		  AND r11_stock_act  > 0
		  AND r02_compania   = r11_compania
		  AND r02_codigo     = r11_bodega
		  AND r02_localidad  = 4
		  AND r02_tipo      <> "S"), 0.00) AS sto
	FROM acero_qs@acgyede:rept010
	WHERE r10_compania = 1
	  AND NVL((SELECT SUM(r11_stock_act)
			FROM acero_qs@acgyede:rept011,
				acero_qs@acgyede:rept002
			WHERE r11_compania   = r10_compania
			  AND r11_item       = r10_codigo
			  AND r02_compania   = r11_compania
			  AND r02_codigo     = r11_bodega
			  AND r02_localidad  = 4
			  AND r02_tipo      <> "S"), 0.00) > 0;
