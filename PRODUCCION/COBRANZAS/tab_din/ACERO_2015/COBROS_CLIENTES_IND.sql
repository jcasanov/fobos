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
	fp_numero_semana(z22_fecha_emi) AS num_sem,
	z22_fecha_emi AS fecha,
	z22_tipo_trn AS tp_trn,
	z22_num_trn AS num_trn,
	z23_tipo_doc AS tip_d,
	z23_num_doc AS num_d,
	z23_div_doc AS div_d,
	SUM((z23_valor_cap + z23_valor_int) * (-1)) AS valor,
	SUM(z23_saldo_cap + z23_saldo_int) AS saldo
	FROM cxct022, cxct023,
		cxct002, OUTER cxct006
	WHERE z22_compania     = 1
	  AND z22_tipo_trn     = "PG"
	  AND YEAR(z22_fecing) > 2009
	  AND z23_compania     = z22_compania
	  AND z23_localidad    = z22_localidad
	  AND z23_codcli       = z22_codcli
	  AND z23_tipo_trn     = z22_tipo_trn
	  AND z23_num_trn      = z22_num_trn
	  AND z02_compania     = z22_compania
	  AND z02_localidad    = z22_localidad
	  AND z02_codcli       = z22_codcli
	  AND z06_zona_cobro   = z02_zona_cobro
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
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
	fp_numero_semana(z22_fecha_emi) AS num_sem,
	z22_fecha_emi AS fecha,
	z22_tipo_trn AS tp_trn,
	z22_num_trn AS num_trn,
	z23_tipo_doc AS tip_d,
	z23_num_doc AS num_d,
	z23_div_doc AS div_d,
	SUM((z23_valor_cap + z23_valor_int) * (-1)) AS valor,
	SUM(z23_saldo_cap + z23_saldo_int) AS saldo
	FROM acero_qm:cxct022, acero_qm:cxct023,
		acero_qm:cxct002, OUTER acero_qm:cxct006
	WHERE z22_compania     = 1
	  AND z22_tipo_trn     = "PG"
	  AND YEAR(z22_fecing) > 2009
	  AND z23_compania     = z22_compania
	  AND z23_localidad    = z22_localidad
	  AND z23_codcli       = z22_codcli
	  AND z23_tipo_trn     = z22_tipo_trn
	  AND z23_num_trn      = z22_num_trn
	  AND z02_compania     = z22_compania
	  AND z02_localidad    = z22_localidad
	  AND z02_codcli       = z22_codcli
	  AND z06_zona_cobro   = z02_zona_cobro
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10;
