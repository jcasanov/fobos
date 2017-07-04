SELECT CASE WHEN r19_localidad = 01 THEN "01 GYE J T M"
	    WHEN r19_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r19_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r19_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r19_localidad = 05 THEN "05 ACERO KHOLER"
	END AS local,
	YEAR(r19_fecing) AS anio,
	r01_nombres AS vendedor,
	NVL(z06_nombre, "SIN COBRADOR") AS agente,
	fp_numero_semana (DATE(r20_fecing)) AS num_sem,
	r19_num_tran AS num_t,
	CASE WHEN r20_cod_tran = "FA"
		THEN r19_tot_neto
		ELSE r19_tot_neto * (-1)
	END AS tot_net,
	NVL(SUM(CASE WHEN r20_cod_tran = "FA"
			THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
			ELSE ((r20_cant_ven * r20_precio) - r20_val_descto)
				* (-1)
		END), 0) AS vta
	FROM rept019, rept001, rept020,
		cxct002, OUTER cxct006
	WHERE r19_compania      = 1
	  AND r19_localidad     = 1
	  AND r19_cod_tran     IN ("FA", "DF", "AF")
	  AND r19_cont_cred     = "R"
	  AND YEAR(r19_fecing) >= 2012
	  AND r01_compania      = r19_compania
	  AND r01_codigo        = r19_vendedor
	  AND r20_compania      = r19_compania
	  AND r20_localidad     = r19_localidad
	  AND r20_cod_tran      = r19_cod_tran
	  AND r20_num_tran      = r19_num_tran
	  AND z02_compania      = r19_compania
	  AND z02_localidad     = r19_localidad
	  AND z02_codcli        = r19_codcli
	  AND z06_zona_cobro    = z02_zona_cobro
	GROUP BY 1, 2, 3, 4, 5, 6, 7
UNION
SELECT CASE WHEN r19_localidad = 01 THEN "01 GYE J T M"
	    WHEN r19_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r19_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r19_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r19_localidad = 05 THEN "05 ACERO KHOLER"
	END AS local,
	YEAR(r19_fecing) AS anio,
	r01_nombres AS vendedor,
	NVL(z06_nombre, "SIN COBRADOR") AS agente,
	fp_numero_semana (DATE(r20_fecing)) AS num_sem,
	r19_num_tran AS num_t,
	CASE WHEN r20_cod_tran = "FA"
		THEN r19_tot_neto
		ELSE r19_tot_neto * (-1)
	END AS tot_net,
	NVL(SUM(CASE WHEN r20_cod_tran = "FA"
			THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
			ELSE ((r20_cant_ven * r20_precio) - r20_val_descto)
				* (-1)
		END), 0) AS vta
	FROM acero_gc:rept019, acero_gc:rept001, acero_gc:rept020,
		acero_gc:cxct002, OUTER acero_gc:cxct006
	WHERE r19_compania      = 1
	  AND r19_localidad     = 2
	  AND r19_cod_tran     IN ("FA", "DF", "AF")
	  AND r19_cont_cred     = "R"
	  AND YEAR(r19_fecing) >= 2012
	  AND r01_compania      = r19_compania
	  AND r01_codigo        = r19_vendedor
	  AND r20_compania      = r19_compania
	  AND r20_localidad     = r19_localidad
	  AND r20_cod_tran      = r19_cod_tran
	  AND r20_num_tran      = r19_num_tran
	  AND z02_compania      = r19_compania
	  AND z02_localidad     = r19_localidad
	  AND z02_codcli        = r19_codcli
	  AND z06_zona_cobro    = z02_zona_cobro
	GROUP BY 1, 2, 3, 4, 5, 6, 7
UNION
SELECT CASE WHEN r19_localidad = 01 THEN "01 GYE J T M"
	    WHEN r19_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r19_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r19_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r19_localidad = 05 THEN "05 ACERO KHOLER"
	END AS local,
	YEAR(r19_fecing) AS anio,
	r01_nombres AS vendedor,
	NVL(z06_nombre, "SIN COBRADOR") AS agente,
	fp_numero_semana (DATE(r20_fecing)) AS num_sem,
	r19_num_tran AS num_t,
	CASE WHEN r20_cod_tran = "FA"
		THEN r19_tot_neto
		ELSE r19_tot_neto * (-1)
	END AS tot_net,
	NVL(SUM(CASE WHEN r20_cod_tran = "FA"
			THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
			ELSE ((r20_cant_ven * r20_precio) - r20_val_descto)
				* (-1)
		END), 0) AS vta
	FROM acero_qm:rept019, acero_qm:rept001, acero_qm:rept020,
		acero_qm:cxct002, OUTER acero_qm:cxct006
	WHERE r19_compania      = 1
	  AND r19_localidad    IN (3, 5)
	  AND r19_cod_tran     IN ("FA", "DF", "AF")
	  AND r19_cont_cred     = "R"
	  AND YEAR(r19_fecing) >= 2012
	  AND r01_compania      = r19_compania
	  AND r01_codigo        = r19_vendedor
	  AND r20_compania      = r19_compania
	  AND r20_localidad     = r19_localidad
	  AND r20_cod_tran      = r19_cod_tran
	  AND r20_num_tran      = r19_num_tran
	  AND z02_compania      = r19_compania
	  AND z02_localidad     = r19_localidad
	  AND z02_codcli        = r19_codcli
	  AND z06_zona_cobro    = z02_zona_cobro
	GROUP BY 1, 2, 3, 4, 5, 6, 7
UNION
SELECT CASE WHEN r19_localidad = 01 THEN "01 GYE J T M"
	    WHEN r19_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r19_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r19_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r19_localidad = 05 THEN "05 ACERO KHOLER"
	END AS local,
	YEAR(r19_fecing) AS anio,
	r01_nombres AS vendedor,
	NVL(z06_nombre, "SIN COBRADOR") AS agente,
	fp_numero_semana (DATE(r20_fecing)) AS num_sem,
	r19_num_tran AS num_t,
	CASE WHEN r20_cod_tran = "FA"
		THEN r19_tot_neto
		ELSE r19_tot_neto * (-1)
	END AS tot_net,
	NVL(SUM(CASE WHEN r20_cod_tran = "FA"
			THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
			ELSE ((r20_cant_ven * r20_precio) - r20_val_descto)
				* (-1)
		END), 0) AS vta
	FROM acero_qs:rept019, acero_qs:rept001, acero_qs:rept020,
		acero_qs:cxct002, OUTER acero_qs:cxct006
	WHERE r19_compania      = 1
	  AND r19_localidad     = 4
	  AND r19_cod_tran     IN ("FA", "DF", "AF")
	  AND r19_cont_cred     = "R"
	  AND YEAR(r19_fecing) >= 2012
	  AND r01_compania      = r19_compania
	  AND r01_codigo        = r19_vendedor
	  AND r20_compania      = r19_compania
	  AND r20_localidad     = r19_localidad
	  AND r20_cod_tran      = r19_cod_tran
	  AND r20_num_tran      = r19_num_tran
	  AND z02_compania      = r19_compania
	  AND z02_localidad     = r19_localidad
	  AND z02_codcli        = r19_codcli
	  AND z06_zona_cobro    = z02_zona_cobro
	GROUP BY 1, 2, 3, 4, 5, 6, 7;
