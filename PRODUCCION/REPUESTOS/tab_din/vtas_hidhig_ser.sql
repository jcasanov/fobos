SELECT NVL((SELECT z21_num_sri
		FROM cxct021
		WHERE z21_compania  = a.r19_compania
		  AND z21_localidad = a.r19_localidad
		  AND z21_codcli    = a.r19_codcli
		  AND z21_cod_tran  = a.r19_cod_tran
		  AND z21_num_tran  = a.r19_num_tran), "SIN NUMERO") AS num_sri,
	DATE(a.r19_fecing) AS fecha_nc,
	CASE WHEN (a.r19_tot_neto - a.r19_tot_bruto + a.r19_tot_dscto -
			a.r19_flete) > 0
		THEN (a.r19_tot_bruto - a.r19_tot_dscto)
		ELSE 0.00
	END AS base_imp,
	CASE WHEN (a.r19_tot_neto - a.r19_tot_bruto + a.r19_tot_dscto -
			a.r19_flete) = 0
		THEN (a.r19_tot_bruto - a.r19_tot_dscto)
		ELSE 0.00
	END AS base_imp_cero,
	(a.r19_tot_neto - a.r19_tot_bruto + a.r19_tot_dscto
	- a.r19_flete) AS valor_iva,
	(SELECT r38_num_sri
		FROM rept038
		WHERE r38_compania    = a.r19_compania
		  AND r38_localidad   = a.r19_localidad
		  AND r38_tipo_fuente = 'PR'
		  AND r38_cod_tran    = a.r19_tipo_dev
		  AND r38_num_tran    = a.r19_num_dev) AS num_sri_fact,
	(SELECT DATE(b.r19_fecing)
		FROM rept019 b
		WHERE b.r19_compania  = a.r19_compania
		  AND b.r19_localidad = a.r19_localidad
		  AND b.r19_cod_tran  = a.r19_tipo_dev
		  AND b.r19_num_tran  = a.r19_num_dev) AS fecha_fact,
	a.r19_referencia AS motivo_emi
	FROM rept019 a
	WHERE a.r19_compania     = 2
	  AND a.r19_localidad    = 6
	  AND a.r19_cod_tran     = 'DF'
	  AND a.r19_codcli       = 1309
	  AND YEAR(a.r19_fecing) BETWEEN 2008 AND 2009
	ORDER BY 2 ASC;
