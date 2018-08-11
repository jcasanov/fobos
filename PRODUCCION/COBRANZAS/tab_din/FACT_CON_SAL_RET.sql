SELECT YEAR(r19_fecing) AS anio,
	CASE WHEN MONTH(r19_fecing) = 01 THEN "01_ENERO"
	     WHEN MONTH(r19_fecing) = 02 THEN "02_FEBRERO"
	     WHEN MONTH(r19_fecing) = 03 THEN "03_MARZO"
	     WHEN MONTH(r19_fecing) = 04 THEN "04_ABRIL"
	     WHEN MONTH(r19_fecing) = 05 THEN "05_MAYO"
	     WHEN MONTH(r19_fecing) = 06 THEN "06_JUNIO"
	     WHEN MONTH(r19_fecing) = 07 THEN "07_JULIO"
	     WHEN MONTH(r19_fecing) = 08 THEN "08_AGOSTO"
	     WHEN MONTH(r19_fecing) = 09 THEN "09_SEPTIEMBRE"
	     WHEN MONTH(r19_fecing) = 10 THEN "10_OCTUBRE"
	     WHEN MONTH(r19_fecing) = 11 THEN "11_NOVIEMBRE"
	     WHEN MONTH(r19_fecing) = 12 THEN "12_DICIEMBRE"
	END AS meses,
	r19_codcli AS codigo,
	r19_nomcli AS cliente,
	r01_nombres AS vendedor,
	r19_cod_tran AS tipo_doc,
	r19_num_tran AS num_doc,
	DATE(r19_fecing) AS fecha_fact,
	(r19_tot_bruto - r19_tot_dscto) AS valor_fact,
	NVL((SELECT SUM(z20_saldo_cap + z20_saldo_int)
		FROM cxct020
		WHERE z20_compania  = r19_compania
		  AND z20_localidad = r19_localidad
		  AND z20_cod_tran  = r19_cod_tran
		  AND z20_num_tran  = r19_num_tran), 0) AS saldo
	FROM rept019, rept001
	WHERE r19_compania   = 1
	  AND r19_localidad  = 1
	  AND r19_cod_tran  IN ("FA", "DF", "AF")
	  AND r19_cont_cred  = "R"
	  AND r01_compania   = r19_compania
	  AND r01_codigo     = r19_vendedor
	  AND EXISTS
		(SELECT 1 FROM cxct020
			WHERE z20_compania  = r19_compania
			  AND z20_localidad = r19_localidad
			  AND z20_cod_tran  = r19_cod_tran
			  AND z20_num_tran  = r19_num_tran
			  AND (z20_saldo_cap + z20_saldo_int)
				BETWEEN 0.01
				    AND ((r19_tot_bruto - r19_tot_dscto)
					 * 0.01))
