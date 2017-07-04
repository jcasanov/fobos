SELECT YEAR(p22_fecing) AS anio,
	CASE WHEN p22_localidad = 1 THEN "01 J T M"
	     WHEN p22_localidad = 2 THEN "02 CENTRO"
	     WHEN p22_localidad = 3 THEN "03 MATRIZ"
	     WHEN p22_localidad = 4 THEN "04 SUR"
	     WHEN p22_localidad = 5 THEN "05 KOHLER"
	END AS local,
	fp_numero_semana (DATE(p22_fecing)) AS num_sem,
	p01_nomprov AS prov,
	SUM((p23_valor_cap + p23_valor_int) * (-1)) AS valor,
	SUM(p23_saldo_cap + p23_saldo_int) AS saldo
	FROM cxpt022, cxpt023, cxpt020, cxpt001
	WHERE p22_compania     = 1
	  AND p22_tipo_trn     = "PG"
	  AND YEAR(p22_fecing) > 2011
	  AND p23_compania     = p22_compania
	  AND p23_localidad    = p22_localidad
	  AND p23_codprov      = p22_codprov
	  AND p23_tipo_trn     = p22_tipo_trn
	  AND p23_num_trn      = p22_num_trn
	  AND p20_compania     = p23_compania
	  AND p20_localidad    = p23_localidad
	  AND p20_codprov      = p23_codprov
	  AND p20_tipo_doc     = p23_tipo_doc
	  AND p20_num_doc      = p23_num_doc
	  AND p20_dividendo    = p23_div_doc
	  AND p01_codprov      = p20_codprov
	GROUP BY 1, 2, 3, 4
UNION
SELECT YEAR(p22_fecing) AS anio,
	CASE WHEN p22_localidad = 1 THEN "01 J T M"
	     WHEN p22_localidad = 2 THEN "02 CENTRO"
	     WHEN p22_localidad = 3 THEN "03 MATRIZ"
	     WHEN p22_localidad = 4 THEN "04 SUR"
	     WHEN p22_localidad = 5 THEN "05 KOHLER"
	END AS local,
	fp_numero_semana (DATE(p22_fecing)) AS num_sem,
	p01_nomprov AS prov,
	SUM((p23_valor_cap + p23_valor_int) * (-1)) AS valor,
	SUM(p23_saldo_cap + p23_saldo_int) AS saldo
	FROM acero_qm:cxpt022, acero_qm:cxpt023, acero_qm:cxpt020,
		acero_qm:cxpt001
	WHERE p22_compania     = 1
	  AND p22_tipo_trn     = "PG"
	  AND YEAR(p22_fecing) > 2011
	  AND p23_compania     = p22_compania
	  AND p23_localidad    = p22_localidad
	  AND p23_codprov      = p22_codprov
	  AND p23_tipo_trn     = p22_tipo_trn
	  AND p23_num_trn      = p22_num_trn
	  AND p20_compania     = p23_compania
	  AND p20_localidad    = p23_localidad
	  AND p20_codprov      = p23_codprov
	  AND p20_tipo_doc     = p23_tipo_doc
	  AND p20_num_doc      = p23_num_doc
	  AND p20_dividendo    = p23_div_doc
	  AND p01_codprov      = p20_codprov
	GROUP BY 1, 2, 3, 4;
