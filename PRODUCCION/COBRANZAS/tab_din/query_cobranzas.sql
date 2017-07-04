SELECT YEAR(a.z22_fecha_emi) AS anio,
	CASE WHEN MONTH(a.z22_fecha_emi) = 01 THEN "ENE"
	     WHEN MONTH(a.z22_fecha_emi) = 02 THEN "FEB"
	     WHEN MONTH(a.z22_fecha_emi) = 03 THEN "MAR"
	     WHEN MONTH(a.z22_fecha_emi) = 04 THEN "ABR"
	     WHEN MONTH(a.z22_fecha_emi) = 05 THEN "MAY"
	     WHEN MONTH(a.z22_fecha_emi) = 06 THEN "JUN"
	     WHEN MONTH(a.z22_fecha_emi) = 07 THEN "JUL"
	     WHEN MONTH(a.z22_fecha_emi) = 08 THEN "AGO"
	     WHEN MONTH(a.z22_fecha_emi) = 09 THEN "SEP"
	     WHEN MONTH(a.z22_fecha_emi) = 10 THEN "OCT"
	     WHEN MONTH(a.z22_fecha_emi) = 11 THEN "NOV"
	     WHEN MONTH(a.z22_fecha_emi) = 12 THEN "DIC"
	END AS mes,
	LPAD(a.z22_localidad, 2, 0) || " " || TRIM(g02_nombre) AS local,
	NVL(z06_nombre, "SIN COBRADOR") AS cobrador,
	TO_CHAR(a.z22_fecha_emi, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(a.z22_fecha_emi)), 2, 0) AS num_sem,
	a.z22_fecha_emi AS fecha,
	a.z22_tipo_trn AS tp_trn,
	a.z22_num_trn AS num_trn,
	b.z23_codcli AS codcli,
	z01_nomcli AS nomcli,
	b.z23_tipo_doc AS tip_d,
	b.z23_num_doc AS num_d,
	b.z23_div_doc AS div_d,
	c.z20_fecha_emi AS fec_emi,
	c.z20_fecha_vcto AS fec_vcto,
	a.z22_localidad AS cod_loc,
	(DATE(a.z22_fecing) -
	NVL((SELECT MAX(e.z22_fecha_emi)
		FROM cxct023 d, cxct022 e
		WHERE d.z23_compania  = b.z23_compania
		  AND d.z23_localidad = b.z23_localidad
		  AND d.z23_codcli    = b.z23_codcli
		  AND d.z23_tipo_doc  = b.z23_tipo_doc
		  AND d.z23_num_doc   = b.z23_num_doc
		  AND e.z22_compania  = d.z23_compania
		  AND e.z22_localidad = d.z23_localidad
		  AND e.z22_codcli    = d.z23_codcli
		  AND e.z22_tipo_trn  = d.z23_tipo_trn
		  AND e.z22_num_trn   = d.z23_num_trn
		  AND e.z22_fecing    < a.z22_fecing),
	(SELECT f.z20_fecha_emi
		FROM cxct020 f
		WHERE f.z20_compania  = b.z23_compania
		  AND f.z20_localidad = b.z23_localidad
		  AND f.z20_codcli    = b.z23_codcli
		  AND f.z20_tipo_doc  = b.z23_tipo_doc
		  AND f.z20_num_doc   = b.z23_num_doc
		  AND f.z20_dividendo = 1))) AS dis_v_d,
	CASE WHEN a.z22_fecha_emi > c.z20_fecha_vcto
		THEN c.z20_fecha_vcto - a.z22_fecha_emi
		ELSE 0
	END AS dias_v,
	c.z20_valor_cap + c.z20_valor_int AS valor_doc,
	SUM((b.z23_valor_cap + b.z23_valor_int) * (-1)) AS valor,
	SUM(c.z20_saldo_cap + c.z20_saldo_int) AS saldo
	FROM cxct023 b, cxct022 a, cxct020 c, gent002, cxct002, cxct001,
		OUTER cxct006
	WHERE b.z23_compania      = 1
	  AND b.z23_tipo_trn     IN ("PG", "AR", "PR")
	  AND a.z22_compania      = b.z23_compania
	  AND a.z22_localidad     = b.z23_localidad
	  AND a.z22_codcli        = b.z23_codcli
	  AND a.z22_tipo_trn      = b.z23_tipo_trn
	  AND a.z22_num_trn       = b.z23_num_trn
	  AND YEAR(a.z22_fecing) >= 2014
	  AND c.z20_compania      = b.z23_compania
	  AND c.z20_localidad     = b.z23_localidad
	  AND c.z20_codcli        = b.z23_codcli
	  AND c.z20_tipo_doc      = b.z23_tipo_doc
	  AND c.z20_num_doc       = b.z23_num_doc
	  AND c.z20_dividendo     = b.z23_div_doc
	  AND g02_compania        = a.z22_compania
	  AND g02_localidad       = a.z22_localidad
	  AND z02_compania        = a.z22_compania
	  AND z02_localidad       = a.z22_localidad
	  AND z02_codcli          = a.z22_codcli
	  AND z01_codcli          = z02_codcli
	  AND z06_zona_cobro      = z02_zona_cobro
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18,
		19
UNION
SELECT YEAR(a.z22_fecha_emi) AS anio,
	CASE WHEN MONTH(a.z22_fecha_emi) = 01 THEN "ENE"
	     WHEN MONTH(a.z22_fecha_emi) = 02 THEN "FEB"
	     WHEN MONTH(a.z22_fecha_emi) = 03 THEN "MAR"
	     WHEN MONTH(a.z22_fecha_emi) = 04 THEN "ABR"
	     WHEN MONTH(a.z22_fecha_emi) = 05 THEN "MAY"
	     WHEN MONTH(a.z22_fecha_emi) = 06 THEN "JUN"
	     WHEN MONTH(a.z22_fecha_emi) = 07 THEN "JUL"
	     WHEN MONTH(a.z22_fecha_emi) = 08 THEN "AGO"
	     WHEN MONTH(a.z22_fecha_emi) = 09 THEN "SEP"
	     WHEN MONTH(a.z22_fecha_emi) = 10 THEN "OCT"
	     WHEN MONTH(a.z22_fecha_emi) = 11 THEN "NOV"
	     WHEN MONTH(a.z22_fecha_emi) = 12 THEN "DIC"
	END AS mes,
	LPAD(a.z22_localidad, 2, 0) || " " || TRIM(g02_nombre) AS local,
	NVL(z06_nombre, "SIN COBRADOR") AS cobrador,
	TO_CHAR(a.z22_fecha_emi, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(a.z22_fecha_emi)), 2, 0) AS num_sem,
	a.z22_fecha_emi AS fecha,
	a.z22_tipo_trn AS tp_trn,
	a.z22_num_trn AS num_trn,
	b.z23_codcli AS codcli,
	z01_nomcli AS nomcli,
	b.z23_tipo_doc AS tip_d,
	b.z23_num_doc AS num_d,
	b.z23_div_doc AS div_d,
	c.z20_fecha_emi AS fec_emi,
	c.z20_fecha_vcto AS fec_vcto,
	a.z22_localidad AS cod_loc,
	(DATE(a.z22_fecing) -
	NVL((SELECT MAX(e.z22_fecha_emi)
		FROM acero_qm:cxct023 d, acero_qm:cxct022 e
		WHERE d.z23_compania  = b.z23_compania
		  AND d.z23_localidad = b.z23_localidad
		  AND d.z23_codcli    = b.z23_codcli
		  AND d.z23_tipo_doc  = b.z23_tipo_doc
		  AND d.z23_num_doc   = b.z23_num_doc
		  AND e.z22_compania  = d.z23_compania
		  AND e.z22_localidad = d.z23_localidad
		  AND e.z22_codcli    = d.z23_codcli
		  AND e.z22_tipo_trn  = d.z23_tipo_trn
		  AND e.z22_num_trn   = d.z23_num_trn
		  AND e.z22_fecing    < a.z22_fecing),
	(SELECT f.z20_fecha_emi
		FROM acero_qm:cxct020 f
		WHERE f.z20_compania  = b.z23_compania
		  AND f.z20_localidad = b.z23_localidad
		  AND f.z20_codcli    = b.z23_codcli
		  AND f.z20_tipo_doc  = b.z23_tipo_doc
		  AND f.z20_num_doc   = b.z23_num_doc
		  AND f.z20_dividendo = 1))) AS dis_v_d,
	CASE WHEN a.z22_fecha_emi > c.z20_fecha_vcto
		THEN c.z20_fecha_vcto - a.z22_fecha_emi
		ELSE 0
	END AS dias_v,
	c.z20_valor_cap + c.z20_valor_int AS valor_doc,
	SUM((b.z23_valor_cap + b.z23_valor_int) * (-1)) AS valor,
	SUM(c.z20_saldo_cap + c.z20_saldo_int) AS saldo
	FROM acero_qm:cxct023 b, acero_qm:cxct022 a, acero_qm:cxct020 c,
		acero_qm:gent002, acero_qm:cxct002, acero_qm:cxct001,
		OUTER acero_qm:cxct006
	WHERE b.z23_compania      = 1
	  AND b.z23_tipo_trn     IN ("PG", "AR", "PR")
	  AND a.z22_compania      = b.z23_compania
	  AND a.z22_localidad     = b.z23_localidad
	  AND a.z22_codcli        = b.z23_codcli
	  AND a.z22_tipo_trn      = b.z23_tipo_trn
	  AND a.z22_num_trn       = b.z23_num_trn
	  AND YEAR(a.z22_fecing) >= 2014
	  AND c.z20_compania      = b.z23_compania
	  AND c.z20_localidad     = b.z23_localidad
	  AND c.z20_codcli        = b.z23_codcli
	  AND c.z20_tipo_doc      = b.z23_tipo_doc
	  AND c.z20_num_doc       = b.z23_num_doc
	  AND c.z20_dividendo     = b.z23_div_doc
	  AND g02_compania        = a.z22_compania
	  AND g02_localidad       = a.z22_localidad
	  AND z02_compania        = a.z22_compania
	  AND z02_localidad       = a.z22_localidad
	  AND z02_codcli          = a.z22_codcli
	  AND z01_codcli          = z02_codcli
	  AND z06_zona_cobro      = z02_zona_cobro
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18,
		19;
