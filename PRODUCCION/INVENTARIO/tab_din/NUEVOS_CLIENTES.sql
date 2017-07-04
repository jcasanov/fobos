SELECT YEAR(z01_fecing) AS anio,
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
	CASE WHEN r19_cont_cred = "C"
		THEN "CONTADO"
		ELSE "CREDITO"
	END AS tip_vta,
	r01_nombres AS vend,
	r19_codcli AS codcli,
	r19_nomcli AS nomcli,
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
	DATE(z01_fecing) AS feccre,
	CASE WHEN z01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est_cli,
	fp_numero_semana(DATE(z01_fecing)) AS num_sem,
	r19_num_tran AS num_t,
        NVL(SUM((SELECT
                SUM(NVL((SELECT SUM(z23_valor_cap + z23_valor_int +
                                z23_saldo_cap + z23_saldo_int)
                FROM cxct023, cxct022
                WHERE z23_compania  = z20_compania
                  AND z23_localidad = z20_localidad
                  AND z23_codcli    = z20_codcli
                  AND z23_tipo_doc  = z20_tipo_doc
                  AND z23_num_doc   = z20_num_doc
                  AND z23_div_doc   = z20_dividendo
                  AND z22_compania  = z23_compania
                  AND z22_localidad = z23_localidad
                  AND z22_codcli    = z23_codcli
                  AND z22_tipo_trn  = z23_tipo_trn
                  AND z22_num_trn   = z23_num_trn
                  AND z22_fecing    = (SELECT MAX(z22_fecing)
                                        FROM cxct023, cxct022
                                        WHERE z23_compania   = z20_compania
                                          AND z23_localidad  = z20_localidad
                                          AND z23_codcli     = z20_codcli
                                          AND z23_tipo_doc   = z20_tipo_doc
                                          AND z23_num_doc    = z20_num_doc
                                          AND z23_div_doc    = z20_dividendo
                                          AND z22_compania   = z23_compania
                                          AND z22_localidad  = z23_localidad
                                          AND z22_codcli     = z23_codcli
                                          AND z22_tipo_trn   = z23_tipo_trn
                                          AND z22_num_trn    = z23_num_trn
                                          AND z22_fecing    <= CURRENT)),
                CASE WHEN z20_fecha_emi <=
                                (SELECT z60_fecha_carga
                                        FROM cxct060
                                        WHERE z60_compania  = z20_compania
                                          AND z60_localidad = z20_localidad)
                        THEN z20_saldo_cap + z20_saldo_int -
                                NVL((SELECT SUM(z23_valor_cap + z23_valor_int)
                                        FROM cxct023
                                        WHERE z23_compania  = z20_compania
                                          AND z23_localidad = z20_localidad
                                          AND z23_codcli    = z20_codcli
                                          AND z23_tipo_doc  = z20_tipo_doc
                                          AND z23_num_doc   = z20_num_doc
                                          AND z23_div_doc   = z20_dividendo), 0)
                        ELSE z20_valor_cap + z20_valor_int
                END))
        FROM cxct020
        WHERE z20_compania   = r19_compania
          AND z20_localidad  = r19_localidad
          AND z20_codcli     = r19_codcli
          AND z20_fecha_vcto < TODAY)), 0.00) * (-1) AS venc,
	SUM(CASE WHEN r19_cod_tran = "FA"
		THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
		ELSE ((r20_cant_ven * r20_precio) - r20_val_descto) * (-1)
	END) AS vta
	FROM cxct001, rept019, rept001, rept020, rept010, rept073
	WHERE YEAR(z01_fecing) >= 2008
	  AND r19_compania      = 1
	  AND r19_localidad     = 1
	  AND r19_cod_tran     IN ("FA", "DF", "AF")
	  AND r19_codcli        = z01_codcli
	  AND YEAR(r19_fecing)  = YEAR(z01_fecing)
	  AND r01_compania      = r19_compania
	  AND r01_codigo        = r19_vendedor
	  AND r20_compania      = r19_compania
	  AND r20_localidad     = r19_localidad
	  AND r20_cod_tran      = r19_cod_tran
	  AND r20_num_tran      = r19_num_tran
	  AND r10_compania      = r20_compania
	  AND r10_codigo        = r20_item
	  AND r73_compania      = r10_compania
	  AND r73_marca         = r10_marca
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
	ORDER BY 14, 1, 6;
