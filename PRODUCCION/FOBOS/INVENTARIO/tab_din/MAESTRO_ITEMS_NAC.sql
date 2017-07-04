SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM gent002
		WHERE g02_compania  = r10_compania
		  AND g02_localidad = 1) AS local,
	CAST (r10_codigo AS INTEGER) AS item,
	(SELECT r03_nombre
		FROM rept003
		WHERE r03_compania = r10_compania
		  AND r03_codigo   = r10_linea) AS lin,
	(SELECT r70_desc_sub
		FROM rept070
		WHERE r70_compania  = r10_compania
		  AND r70_linea     = r10_linea
		  AND r70_sub_linea = r10_sub_linea) AS sub_lin,
	(SELECT r71_desc_grupo
		FROM rept071
		WHERE r71_compania  = r10_compania
		  AND r71_linea     = r10_linea
		  AND r71_sub_linea = r10_sub_linea
		  AND r71_cod_grupo = r10_cod_grupo) AS cod_gru,
	(SELECT r72_desc_clase
		FROM rept072
		WHERE r72_compania  = r10_compania
		  AND r72_linea     = r10_linea
		  AND r72_sub_linea = r10_sub_linea
		  AND r72_cod_grupo = r10_cod_grupo
		  AND r72_cod_clase = r10_cod_clase) AS cod_cla,
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
	END AS linea_venta,
	CASE WHEN r10_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est
	FROM rept010
	WHERE r10_compania = 1
	  AND r10_estado   = "A";
