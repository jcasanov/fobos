SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM gent002
		WHERE g02_compania  = r20_compania
		  AND g02_localidad = r20_localidad) AS local,
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
	(SELECT r73_desc_marca
		FROM rept073
		WHERE r73_compania = r10_compania
		  AND r73_marca    = r10_marca) AS marca,
	(SELECT r03_nombre
		FROM rept003
		WHERE r03_compania = r10_compania
		  AND r03_codigo   = r10_linea) AS desc_div,
	(SELECT r70_desc_sub
		FROM rept070
		WHERE r70_compania  = r10_compania
		  AND r70_linea     = r10_linea
		  AND r70_sub_linea = r10_sub_linea) AS desc_sub,
	(SELECT r71_desc_grupo
		FROM rept071
		WHERE r71_compania  = r10_compania
		  AND r71_linea     = r10_linea
		  AND r71_sub_linea = r10_sub_linea
		  AND r71_cod_grupo = r10_cod_grupo) AS desc_grp,
	(SELECT r72_desc_clase
		FROM rept072
		WHERE r72_compania  = r10_compania
		  AND r72_linea     = r10_linea
		  AND r72_sub_linea = r10_sub_linea
		  AND r72_cod_grupo = r10_cod_grupo
		  AND r72_cod_clase = r10_cod_clase) AS desc_cla,
	TO_CHAR(r20_fecing, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(r20_fecing)), 2, 0) AS num_sem,
	r19_cod_tran AS cod_t,
	r19_num_tran AS num_t,
	r19_nomcli AS nom_p,
	CAST(r20_item AS INTEGER) AS item,
	r10_nombre AS nom_ite,
	r10_uni_med AS uni_m,
	NVL(SUM(CASE WHEN r19_cod_tran <> "FA" AND r19_cod_tran <> "DC"
			THEN r20_cant_ven
			ELSE 0.00
		END), 0.00) AS ingr,
	NVL(SUM(CASE WHEN r19_cod_tran = "FA" OR r19_cod_tran = "DC"
			THEN r20_cant_ven
			ELSE 0.00
		END), 0.00) AS egr
	FROM rept020, rept019, rept010
	WHERE r20_compania      = 1
	  AND r20_localidad     = 1
	  AND r20_cod_tran     IN ("FA", "DF", "AF", "CL", "DC")
	  AND YEAR(r20_fecing) >= 2012
	  AND r19_compania      = r20_compania
	  AND r19_localidad     = r20_localidad
	  AND r19_cod_tran      = r20_cod_tran
	  AND r19_num_tran      = r20_num_tran
	  AND r10_compania      = r20_compania
	  AND r10_codigo        = r20_item
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17
UNION
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM gent002
		WHERE g02_compania  = r20_compania
		  AND g02_localidad = r20_localidad) AS local,
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
	(SELECT r73_desc_marca
		FROM rept073
		WHERE r73_compania = r10_compania
		  AND r73_marca    = r10_marca) AS marca,
	(SELECT r03_nombre
		FROM rept003
		WHERE r03_compania = r10_compania
		  AND r03_codigo   = r10_linea) AS desc_div,
	(SELECT r70_desc_sub
		FROM rept070
		WHERE r70_compania  = r10_compania
		  AND r70_linea     = r10_linea
		  AND r70_sub_linea = r10_sub_linea) AS desc_sub,
	(SELECT r71_desc_grupo
		FROM rept071
		WHERE r71_compania  = r10_compania
		  AND r71_linea     = r10_linea
		  AND r71_sub_linea = r10_sub_linea
		  AND r71_cod_grupo = r10_cod_grupo) AS desc_grp,
	(SELECT r72_desc_clase
		FROM rept072
		WHERE r72_compania  = r10_compania
		  AND r72_linea     = r10_linea
		  AND r72_sub_linea = r10_sub_linea
		  AND r72_cod_grupo = r10_cod_grupo
		  AND r72_cod_clase = r10_cod_clase) AS desc_cla,
	TO_CHAR(r20_fecing, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(r20_fecing)), 2, 0) AS num_sem,
	r19_cod_tran AS cod_t,
	r19_num_tran AS num_t,
	r19_nomcli AS nom_p,
	CAST(r20_item AS INTEGER) AS item,
	r10_nombre AS nom_ite,
	r10_uni_med AS uni_m,
	NVL(SUM(CASE WHEN r20_localidad <>
				(SELECT r02_localidad
					FROM rept002
					WHERE r02_compania = r19_compania
					  AND r02_codigo   = r19_bodega_ori)
			THEN r20_cant_ven
			ELSE 0.00
		END), 0.00) AS ingr,
	NVL(SUM(CASE WHEN r20_localidad =
				(SELECT r02_localidad
					FROM rept002
					WHERE r02_compania = r19_compania
					  AND r02_codigo   = r19_bodega_ori)
			THEN r20_cant_ven
			ELSE 0.00
		END), 0.00) AS egr
	FROM rept020, rept019, rept010
	WHERE  r20_compania      = 1
	  AND  r20_localidad     = 1
	  AND  r20_cod_tran      = "TR"
	  AND  YEAR(r20_fecing) >= 2012
	  AND  r19_compania      = r20_compania
	  AND  r19_localidad     = r20_localidad
	  AND  r19_cod_tran      = r20_cod_tran
	  AND  r19_num_tran      = r20_num_tran
	  AND (r19_bodega_ori   IN
		(SELECT r02_codigo
			FROM rept002
			WHERE r02_compania   = r19_compania
			  AND r02_localidad <> 1)
	   OR  r19_bodega_dest  IN
		(SELECT r02_codigo
			FROM rept002
			WHERE r02_compania   = r19_compania
			  AND r02_localidad <> 1))
	  AND  r10_compania      = r20_compania
	  AND  r10_codigo        = r20_item
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17;
