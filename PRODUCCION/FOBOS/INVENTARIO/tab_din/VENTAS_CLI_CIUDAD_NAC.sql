SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM gent002
		WHERE g02_compania  = r19_compania
		  AND g02_localidad = r19_localidad) AS loc,
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
	(SELECT r01_nombres
		FROM rept001
		WHERE r01_compania = r19_compania
		  AND r01_codigo   = r19_vendedor) AS vend,
	r19_codcli AS cod_cli,
	r19_nomcli AS nom_cli,
	(SELECT z01_num_doc_id
		FROM cxct001
		WHERE z01_codcli = r19_codcli) AS cedruc,
	(SELECT z01_direccion1
		FROM cxct001
		WHERE z01_codcli = r19_codcli) AS dircli,
	(SELECT z01_telefono1
		FROM cxct001
		WHERE z01_codcli = r19_codcli) AS telcli,
	(SELECT g31_nombre
		FROM cxct001, gent031
		WHERE z01_codcli = r19_codcli
		  AND g31_ciudad = z01_ciudad) AS ciud,
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
	CASE WHEN r19_cont_cred = "R"
		THEN "CREDITO"
		ELSE "CONTADO"
	END AS cont_cr,
	r10_marca AS marc,
	TO_CHAR(r20_fecing, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(r20_fecing)), 2, 0) AS num_sem,
	(SELECT CASE WHEN r01_tipo = "I" THEN "VENDEDOR ALMACEN"
		     WHEN r01_tipo = "E" THEN "VENDEDOR EXTERNO"
		     WHEN r01_tipo = "B" THEN "BODEGUERO"
		     WHEN r01_tipo = "J" THEN "JEFE DE VENTAS"
		     WHEN r01_tipo = "G" THEN "GERENTE VENTAS"
		END
		FROM rept001
		WHERE r01_compania = r19_compania
		  AND r01_codigo   = r19_vendedor) AS tip_v,
	(SELECT CASE WHEN r01_estado = "A"
			THEN "ACTIVO"
			ELSE "BLOQUEADO"
		END
		FROM rept001
		WHERE r01_compania = r19_compania
		  AND r01_codigo   = r19_vendedor) AS est_v,
	r19_cod_tran AS cod_t,
	r19_num_tran AS num_t,
	CAST(r20_item AS INTEGER) AS item,
	(SELECT r72_desc_clase
		FROM rept072
		WHERE r72_compania  = r10_compania
		  AND r72_linea     = r10_linea
		  AND r72_sub_linea = r10_sub_linea
		  AND r72_cod_grupo = r10_cod_grupo
		  AND r72_cod_clase = r10_cod_clase) AS clas,
	r10_nombre AS nom_ite,
	NVL(SUM(CASE WHEN r19_cod_tran = "FA"
			THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
			ELSE ((r20_cant_ven * r20_precio) - r20_val_descto)
				* (-1)
		END), 0.00) AS vta
	FROM rept019,
		rept020,
		rept010
	WHERE r19_compania      = 1
	  AND r19_localidad     = 1
	  AND r19_cod_tran     IN ("FA", "DF", "AF")
	  AND YEAR(r19_fecing) >= 2012
	  AND r20_compania      = r19_compania
	  AND r20_localidad     = r19_localidad
	  AND r20_cod_tran      = r19_cod_tran
	  AND r20_num_tran      = r19_num_tran
	  AND r10_compania      = r20_compania
	  AND r10_codigo        = r20_item
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
		17, 18, 19, 20, 21, 22
UNION ALL
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_qm@acgyede:gent002
		WHERE g02_compania  = r19_compania
		  AND g02_localidad = r19_localidad) AS loc,
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
	(SELECT r01_nombres
		FROM acero_qm@acgyede:rept001
		WHERE r01_compania = r19_compania
		  AND r01_codigo   = r19_vendedor) AS vend,
	r19_codcli AS cod_cli,
	r19_nomcli AS nom_cli,
	(SELECT z01_num_doc_id
		FROM acero_qm@acgyede:cxct001
		WHERE z01_codcli = r19_codcli) AS cedruc,
	(SELECT z01_direccion1
		FROM acero_qm@acgyede:cxct001
		WHERE z01_codcli = r19_codcli) AS dircli,
	(SELECT z01_telefono1
		FROM acero_qm@acgyede:cxct001
		WHERE z01_codcli = r19_codcli) AS telcli,
	(SELECT g31_nombre
		FROM acero_qm@acgyede:cxct001,
			acero_qm@acgyede:gent031
		WHERE z01_codcli = r19_codcli
		  AND g31_ciudad = z01_ciudad) AS ciud,
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
	CASE WHEN r19_cont_cred = "R"
		THEN "CREDITO"
		ELSE "CONTADO"
	END AS cont_cr,
	r10_marca AS marc,
	TO_CHAR(r20_fecing, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(r20_fecing)), 2, 0) AS num_sem,
	(SELECT CASE WHEN r01_tipo = "I" THEN "VENDEDOR ALMACEN"
		     WHEN r01_tipo = "E" THEN "VENDEDOR EXTERNO"
		     WHEN r01_tipo = "B" THEN "BODEGUERO"
		     WHEN r01_tipo = "J" THEN "JEFE DE VENTAS"
		     WHEN r01_tipo = "G" THEN "GERENTE VENTAS"
		END
		FROM acero_qm@acgyede:rept001
		WHERE r01_compania = r19_compania
		  AND r01_codigo   = r19_vendedor) AS tip_v,
	(SELECT CASE WHEN r01_estado = "A"
			THEN "ACTIVO"
			ELSE "BLOQUEADO"
		END
		FROM acero_qm@acgyede:rept001
		WHERE r01_compania = r19_compania
		  AND r01_codigo   = r19_vendedor) AS est_v,
	r19_cod_tran AS cod_t,
	r19_num_tran AS num_t,
	CAST(r20_item AS INTEGER) AS item,
	(SELECT r72_desc_clase
		FROM acero_qm@acgyede:rept072
		WHERE r72_compania  = r10_compania
		  AND r72_linea     = r10_linea
		  AND r72_sub_linea = r10_sub_linea
		  AND r72_cod_grupo = r10_cod_grupo
		  AND r72_cod_clase = r10_cod_clase) AS clas,
	r10_nombre AS nom_ite,
	NVL(SUM(CASE WHEN r19_cod_tran = "FA"
			THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
			ELSE ((r20_cant_ven * r20_precio) - r20_val_descto)
				* (-1)
		END), 0.00) AS vta
	FROM acero_qm@acgyede:rept019,
		acero_qm@acgyede:rept020,
		acero_qm@acgyede:rept010
	WHERE r19_compania      = 1
	  AND r19_localidad    IN (3, 5)
	  AND r19_cod_tran     IN ("FA", "DF", "AF")
	  AND YEAR(r19_fecing) >= 2012
	  AND r20_compania      = r19_compania
	  AND r20_localidad     = r19_localidad
	  AND r20_cod_tran      = r19_cod_tran
	  AND r20_num_tran      = r19_num_tran
	  AND r10_compania      = r20_compania
	  AND r10_codigo        = r20_item
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
		17, 18, 19, 20, 21, 22
UNION ALL
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_qs@acgyede:gent002
		WHERE g02_compania  = r19_compania
		  AND g02_localidad = r19_localidad) AS loc,
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
	(SELECT r01_nombres
		FROM acero_qs@acgyede:rept001
		WHERE r01_compania = r19_compania
		  AND r01_codigo   = r19_vendedor) AS vend,
	r19_codcli AS cod_cli,
	r19_nomcli AS nom_cli,
	(SELECT z01_num_doc_id
		FROM acero_qs@acgyede:cxct001
		WHERE z01_codcli = r19_codcli) AS cedruc,
	(SELECT z01_direccion1
		FROM acero_qs@acgyede:cxct001
		WHERE z01_codcli = r19_codcli) AS dircli,
	(SELECT z01_telefono1
		FROM acero_qs@acgyede:cxct001
		WHERE z01_codcli = r19_codcli) AS telcli,
	(SELECT g31_nombre
		FROM acero_qs@acgyede:cxct001,
			acero_qs@acgyede:gent031
		WHERE z01_codcli = r19_codcli
		  AND g31_ciudad = z01_ciudad) AS ciud,
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
	CASE WHEN r19_cont_cred = "R"
		THEN "CREDITO"
		ELSE "CONTADO"
	END AS cont_cr,
	r10_marca AS marc,
	TO_CHAR(r20_fecing, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(r20_fecing)), 2, 0) AS num_sem,
	(SELECT CASE WHEN r01_tipo = "I" THEN "VENDEDOR ALMACEN"
		     WHEN r01_tipo = "E" THEN "VENDEDOR EXTERNO"
		     WHEN r01_tipo = "B" THEN "BODEGUERO"
		     WHEN r01_tipo = "J" THEN "JEFE DE VENTAS"
		     WHEN r01_tipo = "G" THEN "GERENTE VENTAS"
		END
		FROM acero_qs@acgyede:rept001
		WHERE r01_compania = r19_compania
		  AND r01_codigo   = r19_vendedor) AS tip_v,
	(SELECT CASE WHEN r01_estado = "A"
			THEN "ACTIVO"
			ELSE "BLOQUEADO"
		END
		FROM acero_qs@acgyede:rept001
		WHERE r01_compania = r19_compania
		  AND r01_codigo   = r19_vendedor) AS est_v,
	r19_cod_tran AS cod_t,
	r19_num_tran AS num_t,
	CAST(r20_item AS INTEGER) AS item,
	(SELECT r72_desc_clase
		FROM acero_qs@acgyede:rept072
		WHERE r72_compania  = r10_compania
		  AND r72_linea     = r10_linea
		  AND r72_sub_linea = r10_sub_linea
		  AND r72_cod_grupo = r10_cod_grupo
		  AND r72_cod_clase = r10_cod_clase) AS clas,
	r10_nombre AS nom_ite,
	NVL(SUM(CASE WHEN r19_cod_tran = "FA"
			THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
			ELSE ((r20_cant_ven * r20_precio) - r20_val_descto)
				* (-1)
		END), 0.00) AS vta
	FROM acero_qs@acgyede:rept019,
		acero_qs@acgyede:rept020,
		acero_qs@acgyede:rept010
	WHERE r19_compania      = 1
	  AND r19_localidad     = 4
	  AND r19_cod_tran     IN ("FA", "DF", "AF")
	  AND YEAR(r19_fecing) >= 2012
	  AND r20_compania      = r19_compania
	  AND r20_localidad     = r19_localidad
	  AND r20_cod_tran      = r19_cod_tran
	  AND r20_num_tran      = r19_num_tran
	  AND r10_compania      = r20_compania
	  AND r10_codigo        = r20_item
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
		17, 18, 19, 20, 21, 22;
