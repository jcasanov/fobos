SELECT YEAR(z22_fecing) AS anio,
	CASE WHEN z22_localidad = 1 THEN "01 J T M"
	     WHEN z22_localidad = 2 THEN "02 CENTRO"
	     WHEN z22_localidad = 3 THEN "03 MATRIZ"
	     WHEN z22_localidad = 4 THEN "04 SUR"
	     WHEN z22_localidad = 5 THEN "05 KOHLER"
	END AS localidad,
	NVL(z06_nombre, "SIN ZONA COBRO") AS zona_cob,
	NVL((SELECT z05_nombres
		FROM cxct005
		WHERE z05_compania = z22_compania
		  AND z05_codigo   = z22_cobrador), "SIN COBRADOR") AS agente,
	fp_numero_semana(DATE(z22_fecing)) AS num_sem,
	z23_tipo_doc tp, z23_num_doc num, z23_div_doc divi,
	SUM(z23_valor_cap + z23_valor_int) AS sal_cart,
	ABS(DATE(z22_fecing) - z20_fecha_vcto) AS dias,
	SUM((z23_valor_cap + z23_valor_int) *
		ABS(DATE(z22_fecing) - z20_fecha_vcto)) AS edad
	FROM cxct022, cxct023, cxct020, cxct002, cxct006
	WHERE z22_compania     = 1
	  AND YEAR(z22_fecing) > 2009
	  AND z23_compania     = z22_compania
	  AND z23_localidad    = z22_localidad
	  AND z23_codcli       = z22_codcli
	  AND z23_tipo_trn     = z22_tipo_trn
	  AND z23_num_trn      = z22_num_trn
	  AND z20_compania     = z23_compania
	  AND z20_localidad    = z23_localidad
	  AND z20_codcli       = z23_codcli
	  AND z20_tipo_doc     = z23_tipo_doc
	  AND z20_num_doc      = z23_num_doc
	  AND z20_dividendo    = z23_div_doc
	  AND z02_compania     = z20_compania
	  AND z02_localidad    = z20_localidad
	  AND z02_codcli       = z20_codcli
	  AND z06_zona_cobro   = z02_zona_cobro
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 10
UNION
SELECT YEAR(z22_fecing) AS anio,
	CASE WHEN z22_localidad = 1 THEN "01 J T M"
	     WHEN z22_localidad = 2 THEN "02 CENTRO"
	     WHEN z22_localidad = 3 THEN "03 MATRIZ"
	     WHEN z22_localidad = 4 THEN "04 SUR"
	     WHEN z22_localidad = 5 THEN "05 KOHLER"
	END AS localidad,
	NVL(z06_nombre, "SIN ZONA COBRO") AS zona_cob,
	NVL((SELECT z05_nombres
		FROM acero_qm:cxct005
		WHERE z05_compania = z22_compania
		  AND z05_codigo   = z22_cobrador), "SIN COBRADOR") AS agente,
	fp_numero_semana(DATE(z22_fecing)) AS num_sem,
	z23_tipo_doc tp, z23_num_doc num, z23_div_doc divi,
	SUM(z23_valor_cap + z23_valor_int) AS sal_cart,
	ABS(DATE(z22_fecing) - z20_fecha_vcto) AS dias,
	SUM((z23_valor_cap + z23_valor_int) *
		ABS(DATE(z22_fecing) - z20_fecha_vcto)) AS edad
	FROM acero_qm:cxct022, acero_qm:cxct023, acero_qm:cxct020,
		acero_qm:cxct002, acero_qm:cxct006
	WHERE z22_compania     = 1
	  AND YEAR(z22_fecing) > 2009
	  AND z23_compania     = z22_compania
	  AND z23_localidad    = z22_localidad
	  AND z23_codcli       = z22_codcli
	  AND z23_tipo_trn     = z22_tipo_trn
	  AND z23_num_trn      = z22_num_trn
	  AND z20_compania     = z23_compania
	  AND z20_localidad    = z23_localidad
	  AND z20_codcli       = z23_codcli
	  AND z20_tipo_doc     = z23_tipo_doc
	  AND z20_num_doc      = z23_num_doc
	  AND z20_dividendo    = z23_div_doc
	  AND z02_compania     = z20_compania
	  AND z02_localidad    = z20_localidad
	  AND z02_codcli       = z20_codcli
	  AND z06_zona_cobro   = z02_zona_cobro
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 10;
