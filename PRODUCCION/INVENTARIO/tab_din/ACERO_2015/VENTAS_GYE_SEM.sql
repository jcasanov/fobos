SELECT CASE WHEN a.r19_localidad = 01 THEN "01 GYE J T M"
	    WHEN a.r19_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN a.r19_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN a.r19_localidad = 04 THEN "04 ACERO SUR"
	    WHEN a.r19_localidad = 05 THEN "05 ACERO KHOLER"
	END AS local,
	YEAR(a.r19_fecing) AS anio,
	DATE(a.r19_fecing) AS fecha,
	r01_nombres AS vendedor,
	r01_iniciales AS ini_vend,
	a.r19_codcli AS cod_cli,
	a.r19_nomcli AS nom_cli,
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
	CASE WHEN a.r19_cont_cred = "R"
		THEN "CREDITO"
		ELSE "CONTADO"
	END AS cont_cr,
	r73_desc_marca AS marca,
	r10_filtro AS filtro,
	fp_numero_semana(DATE(a.r19_fecing)) AS nun_sem,
	CASE WHEN r01_tipo = "I" THEN "VENDEDOR ALMACEN"
	     WHEN r01_tipo = "E" THEN "VENDEDOR EXTERNO"
	     WHEN r01_tipo = "B" THEN "BODEGUERO"
	     WHEN r01_tipo = "J" THEN "JEFE DE VENTAS"
	     WHEN r01_tipo = "G" THEN "GERENTE VENTAS"
	END AS tip_v,
	CASE WHEN r01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est_v,
	CASE WHEN a.r19_cod_tran = "FA" THEN "FACTURACION"
	     WHEN a.r19_cod_tran = "DF" THEN "DEVOLUCIONES"
	     WHEN a.r19_cod_tran = "AF" THEN "ANULACIONES"
	END AS tip_t,
	CASE WHEN a.r19_cod_tran = "DF"
		THEN CASE WHEN (SELECT 1 FROM rept088
				WHERE r88_compania  = a.r19_compania
				  AND r88_localidad = a.r19_localidad
				  AND r88_cod_dev   = a.r19_cod_tran
				  AND r88_num_dev   = a.r19_num_tran) = 1
			THEN "REFACTURACION"
			ELSE CASE WHEN (SELECT COUNT(*) FROM rept019 c
				WHERE c.r19_compania     = a.r19_compania
				  AND c.r19_localidad    = a.r19_localidad
				  AND c.r19_cod_tran     = "FA"
				  AND c.r19_tipo_dev     IS NULL
				  AND DATE(c.r19_fecing) = DATE(a.r19_fecing)
				  AND c.r19_codcli       = a.r19_codcli
				  AND c.r19_tot_bruto    = a.r19_tot_bruto) > 0
				THEN "REFACTURACION"
				ELSE "N/C POR DEVOLUCION"
				END
		     END
		ELSE "N/C POR DEVOLUCION"
	END AS tip_df,
	r19_cod_tran AS cod_t,
	r19_num_tran AS num_t,
	NVL(SUM(CASE WHEN b.r20_cod_tran = "FA"
		THEN ((b.r20_cant_ven * b.r20_precio) - b.r20_val_descto)
		ELSE ((b.r20_cant_ven * b.r20_precio) - b.r20_val_descto)
			* (-1)
	END), 0) AS vta
	FROM rept019 a, rept001, rept020 b, rept010, rept073
	WHERE a.r19_compania      = 1
	  AND a.r19_localidad     = 1
	  AND a.r19_cod_tran     IN ("FA", "DF", "AF")
	  AND YEAR(a.r19_fecing) >= 2010
	  AND r01_compania        = a.r19_compania
	  AND r01_codigo          = a.r19_vendedor
	  AND b.r20_compania      = a.r19_compania
	  AND b.r20_localidad     = a.r19_localidad
	  AND b.r20_cod_tran      = a.r19_cod_tran
	  AND b.r20_num_tran      = a.r19_num_tran
	  AND r10_compania        = b.r20_compania
	  AND r10_codigo          = b.r20_item
	  AND r73_compania        = r10_compania
	  AND r73_marca           = r10_marca
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18;
