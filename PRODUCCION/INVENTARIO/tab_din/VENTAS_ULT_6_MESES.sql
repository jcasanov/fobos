SELECT YEAR(a.r19_fecing) AS anio,
	CASE WHEN MONTH(a.r19_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(a.r19_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(a.r19_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(a.r19_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(a.r19_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(a.r19_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(a.r19_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(a.r19_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(a.r19_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(a.r19_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(a.r19_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(a.r19_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	CASE WHEN a.r19_cont_cred = "C"
		THEN "CONTADO"
		ELSE "CREDITO"
	END AS tip_vta,
	r01_nombres AS vend,
	a.r19_codcli AS codcli,
	a.r19_nomcli AS nomcli,
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
	r10_marca AS marca,
	TO_CHAR(r19_fecing, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(a.r19_fecing)), 2, 0) AS num_sem,
	a.r19_num_tran AS num_t,
	SUM(CASE WHEN a.r19_cod_tran = "FA"
		THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
		ELSE ((r20_cant_ven * r20_precio) - r20_val_descto) * (-1)
	END) AS vta
	FROM rept019 a, rept001, rept020, rept010
	WHERE a.r19_compania      = 1
	  AND a.r19_localidad     = 1
	  AND a.r19_cod_tran     IN ("FA", "DF", "AF")
	  AND a.r19_codcli       NOT IN (99, 101)
	  AND DATE(a.r19_fecing) >= TODAY - 180 UNITS DAY
	  AND NOT EXISTS
		(SELECT 1 FROM rept019 b
			WHERE b.r19_compania     = a.r19_compania
			  AND b.r19_localidad    = a.r19_localidad
			  AND b.r19_cod_tran     = "FA"
			  AND b.r19_codcli       = a.r19_codcli
			  AND DATE(b.r19_fecing) < TODAY - 180 UNITS DAY)
			{--
			  AND DATE(b.r19_fecing) BETWEEN TODAY - 181 UNITS DAY
						     AND MDY(01, 01, 2007))
			--}
	  AND r01_compania      = a.r19_compania
	  AND r01_codigo        = a.r19_vendedor
	  AND r20_compania      = a.r19_compania
	  AND r20_localidad     = a.r19_localidad
	  AND r20_cod_tran      = a.r19_cod_tran
	  AND r20_num_tran      = a.r19_num_tran
	  AND r10_compania      = r20_compania
	  AND r10_codigo        = r20_item
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10;
