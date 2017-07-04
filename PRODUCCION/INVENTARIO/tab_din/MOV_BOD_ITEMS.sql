SELECT YEAR(r19_fecing) AS anio,
	CASE WHEN MONTH(r19_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(r19_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(r19_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(r19_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(r19_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(r19_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(r19_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(r19_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(r19_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(r19_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(r19_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(r19_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	TO_CHAR(r19_fecing, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(r19_fecing)), 2, 0) AS num_sem,
	(SELECT TRIM(g21_nombre)
		FROM acero_gm@idsgye01:gent021
		WHERE g21_cod_tran = r19_cod_tran) AS cod_t,
	r19_num_tran AS num_t,
	r19_referencia AS refer,
	r19_nomcli AS nom_c,
	DATE(r19_fecing) AS fecha,
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
	(SELECT r01_nombres
		FROM acero_gm@idsgye01:rept001
		WHERE r01_compania = r19_compania
		  AND r01_codigo   = r19_vendedor) AS usuar,
	CAST(r20_item AS INTEGER) AS ite,
	r10_nombre AS descrip,
	(SELECT r72_desc_clase
		FROM acero_gm@idsgye01:rept072
		WHERE r72_compania  = r10_compania
		  AND r72_linea     = r10_linea
		  AND r72_sub_linea = r10_sub_linea
		  AND r72_cod_grupo = r10_cod_grupo
		  AND r72_cod_clase = r10_cod_clase) AS clas,
	CASE WHEN r20_cod_tran = "FA" OR r20_cod_tran = "CL" OR
		  r20_cod_tran = "IM" OR r20_cod_tran = "A+" OR
		  r20_cod_tran = "RQ" OR r20_cod_tran = "AC"
		THEN r20_cant_ven
		ELSE r20_cant_ven * (-1)
	END AS cant,
	r20_bodega AS bode
	FROM acero_gm@idsgye01:rept019, acero_gm@idsgye01:rept020,
		acero_gm@idsgye01:rept010
	WHERE r19_compania   = 1
	  AND r19_localidad  = 1
	  AND r19_cod_tran  IN ("A+", "A-", "AC", "FA", "DF", "AF", "CL",
				"DC", "RQ", "DR", "IM", "DI")
	  AND r20_compania   = r19_compania
	  AND r20_localidad  = r19_localidad
	  AND r20_cod_tran   = r19_cod_tran
	  AND r20_num_tran   = r19_num_tran
	  AND r10_compania   = r20_compania
	  AND r10_codigo     = r20_item
UNION
SELECT YEAR(r19_fecing) AS anio,
	CASE WHEN MONTH(r19_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(r19_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(r19_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(r19_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(r19_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(r19_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(r19_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(r19_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(r19_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(r19_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(r19_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(r19_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	TO_CHAR(r19_fecing, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(r19_fecing)), 2, 0) AS num_sem,
	(SELECT TRIM(g21_nombre)
		FROM acero_gm@idsgye01:gent021
		WHERE g21_cod_tran = r19_cod_tran) AS cod_t,
	r19_num_tran AS num_t,
	r19_referencia AS refer,
	r19_nomcli AS nom_c,
	DATE(r19_fecing) AS fecha,
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
	(SELECT r01_nombres
		FROM acero_gm@idsgye01:rept001
		WHERE r01_compania = r19_compania
		  AND r01_codigo   = r19_vendedor) AS usuar,
	CAST(r20_item AS INTEGER) AS ite,
	r10_nombre AS descrip,
	(SELECT r72_desc_clase
		FROM acero_gm@idsgye01:rept072
		WHERE r72_compania  = r10_compania
		  AND r72_linea     = r10_linea
		  AND r72_sub_linea = r10_sub_linea
		  AND r72_cod_grupo = r10_cod_grupo
		  AND r72_cod_clase = r10_cod_clase) AS clas,
	CASE WHEN r20_bodega = r19_bodega_ori
		THEN r20_cant_ven
		ELSE r20_cant_ven * (-1)
	END AS cant,
	CASE WHEN r20_bodega = r19_bodega_ori
		THEN r19_bodega_ori
		ELSE r19_bodega_dest
	END AS bode
	FROM acero_gm@idsgye01:rept019, acero_gm@idsgye01:rept020,
		acero_gm@idsgye01:rept010
	WHERE r19_compania   = 1
	  AND r19_localidad  = 1
	  AND r19_cod_tran   = "TR"
	  AND r20_compania   = r19_compania
	  AND r20_localidad  = r19_localidad
	  AND r20_cod_tran   = r19_cod_tran
	  AND r20_num_tran   = r19_num_tran
	  AND r10_compania   = r20_compania
	  AND r10_codigo     = r20_item
