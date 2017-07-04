SELECT YEAR(a.z22_fecing) AS anio,
	CASE WHEN MONTH(a.z22_fecing) = 01 THEN "ENE"
	     WHEN MONTH(a.z22_fecing) = 02 THEN "FEB"
	     WHEN MONTH(a.z22_fecing) = 03 THEN "MAR"
	     WHEN MONTH(a.z22_fecing) = 04 THEN "ABR"
	     WHEN MONTH(a.z22_fecing) = 05 THEN "MAY"
	     WHEN MONTH(a.z22_fecing) = 06 THEN "JUN"
	     WHEN MONTH(a.z22_fecing) = 07 THEN "JUL"
	     WHEN MONTH(a.z22_fecing) = 08 THEN "AGO"
	     WHEN MONTH(a.z22_fecing) = 09 THEN "SEP"
	     WHEN MONTH(a.z22_fecing) = 10 THEN "OCT"
	     WHEN MONTH(a.z22_fecing) = 11 THEN "NOV"
	     WHEN MONTH(a.z22_fecing) = 12 THEN "DIC"
	END AS mes,
	a.z22_localidad AS cod_loc,
	b.z23_codcli AS codcli,
	z01_nomcli AS nomcli,
	b.z23_tipo_doc AS tip_d,
	b.z23_num_doc AS num_d,
	(SELECT f.z20_fecha_emi
		FROM cxct020 f
		WHERE f.z20_compania  = b.z23_compania
		  AND f.z20_localidad = b.z23_localidad
		  AND f.z20_codcli    = b.z23_codcli
		  AND f.z20_tipo_doc  = b.z23_tipo_doc
		  AND f.z20_num_doc   = b.z23_num_doc
		  AND f.z20_dividendo = 1) AS fec_emi,
	(SELECT MAX(g.z20_fecha_vcto)
		FROM cxct020 g
		WHERE g.z20_compania  = b.z23_compania
		  AND g.z20_localidad = b.z23_localidad
		  AND g.z20_codcli    = b.z23_codcli
		  AND g.z20_tipo_doc  = b.z23_tipo_doc
		  AND g.z20_num_doc   = b.z23_num_doc
		  AND g.z20_dividendo = b.z23_div_doc) AS fec_vcto,
	(SELECT MAX(DATE(d.z22_fecing))
		FROM cxct023 c, cxct022 d
		WHERE c.z23_compania   = b.z23_compania
		  AND c.z23_localidad  = b.z23_localidad
		  AND c.z23_codcli     = b.z23_codcli
		  AND c.z23_tipo_doc   = b.z23_tipo_doc
		  AND c.z23_num_doc    = b.z23_num_doc
		  AND d.z22_compania   = c.z23_compania
		  AND d.z22_localidad  = c.z23_localidad
		  AND d.z22_codcli     = c.z23_codcli
		  AND d.z22_tipo_trn   = c.z23_tipo_trn
		  AND d.z22_num_trn    = c.z23_num_trn
		  AND EXTEND(d.z22_fecing, YEAR TO MONTH) =
			EXTEND(a.z22_fecing, YEAR TO MONTH)) AS fec_pag,
	(SELECT MAX(DATE(d.z22_fecing))
		FROM cxct023 c, cxct022 d
		WHERE c.z23_compania   = b.z23_compania
		  AND c.z23_localidad  = b.z23_localidad
		  AND c.z23_codcli     = b.z23_codcli
		  AND c.z23_tipo_doc   = b.z23_tipo_doc
		  AND c.z23_num_doc    = b.z23_num_doc
		  AND d.z22_compania   = c.z23_compania
		  AND d.z22_localidad  = c.z23_localidad
		  AND d.z22_codcli     = c.z23_codcli
		  AND d.z22_tipo_trn   = c.z23_tipo_trn
		  AND d.z22_num_trn    = c.z23_num_trn
		  AND EXTEND(d.z22_fecing, YEAR TO MONTH) =
			EXTEND(a.z22_fecing, YEAR TO MONTH)) -
	(SELECT MAX(g.z20_fecha_vcto)
		FROM cxct020 g
		WHERE g.z20_compania  = b.z23_compania
		  AND g.z20_localidad = b.z23_localidad
		  AND g.z20_codcli    = b.z23_codcli
		  AND g.z20_tipo_doc  = b.z23_tipo_doc
		  AND g.z20_num_doc   = b.z23_num_doc
		  AND g.z20_dividendo = b.z23_div_doc) AS dias_pag,
	ROUND(SUM((SELECT SUM(e.z20_valor_cap + e.z20_valor_int)
		FROM cxct020 e
		WHERE e.z20_compania  = b.z23_compania
		  AND e.z20_localidad = b.z23_localidad
		  AND e.z20_codcli    = b.z23_codcli
		  AND e.z20_tipo_doc  = b.z23_tipo_doc
		  AND e.z20_num_doc   = b.z23_num_doc)), 2) AS valor_doc,
	(SELECT SUM(h.z20_saldo_cap + h.z20_saldo_int)
		FROM cxct020 h
		WHERE h.z20_compania  = b.z23_compania
		  AND h.z20_localidad = b.z23_localidad
		  AND h.z20_codcli    = b.z23_codcli
		  AND h.z20_tipo_doc  = b.z23_tipo_doc
		  AND h.z20_num_doc   = b.z23_num_doc) AS saldo,
	ROUND(SUM((b.z23_valor_cap + b.z23_valor_int) * (-1)), 2) AS val_pag,
	ROUND(SUM((b.z23_valor_cap + b.z23_valor_int) * (-1)) /
	SUM((SELECT SUM(e.z20_valor_cap + e.z20_valor_int)
		FROM cxct020 e
		WHERE e.z20_compania  = b.z23_compania
		  AND e.z20_localidad = b.z23_localidad
		  AND e.z20_codcli    = b.z23_codcli
		  AND e.z20_tipo_doc  = b.z23_tipo_doc
		  AND e.z20_num_doc   = b.z23_num_doc)), 2) AS porc
	FROM cxct023 b, cxct022 a, cxct001
	WHERE   b.z23_compania      = 1
	  AND ((b.z23_tipo_trn     IN ("PG", "AR")
	  AND   b.z23_tipo_doc      = "FA")
	   OR  (b.z23_tipo_trn      = "AJ"
	  AND   b.z23_tipo_doc      = "FA"))
	  AND   a.z22_compania      = b.z23_compania
	  AND   a.z22_localidad     = b.z23_localidad
	  AND   a.z22_codcli        = b.z23_codcli
	  AND   a.z22_tipo_trn      = b.z23_tipo_trn
	  AND   a.z22_num_trn       = b.z23_num_trn
	  AND   YEAR(a.z22_fecing) >= 2014
	  AND   z01_codcli          = a.z22_codcli
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 13
UNION
SELECT YEAR(a.z22_fecing) AS anio,
	CASE WHEN MONTH(a.z22_fecing) = 01 THEN "ENE"
	     WHEN MONTH(a.z22_fecing) = 02 THEN "FEB"
	     WHEN MONTH(a.z22_fecing) = 03 THEN "MAR"
	     WHEN MONTH(a.z22_fecing) = 04 THEN "ABR"
	     WHEN MONTH(a.z22_fecing) = 05 THEN "MAY"
	     WHEN MONTH(a.z22_fecing) = 06 THEN "JUN"
	     WHEN MONTH(a.z22_fecing) = 07 THEN "JUL"
	     WHEN MONTH(a.z22_fecing) = 08 THEN "AGO"
	     WHEN MONTH(a.z22_fecing) = 09 THEN "SEP"
	     WHEN MONTH(a.z22_fecing) = 10 THEN "OCT"
	     WHEN MONTH(a.z22_fecing) = 11 THEN "NOV"
	     WHEN MONTH(a.z22_fecing) = 12 THEN "DIC"
	END AS mes,
	a.z22_localidad AS cod_loc,
	b.z23_codcli AS codcli,
	z01_nomcli AS nomcli,
	b.z23_tipo_doc AS tip_d,
	b.z23_num_doc AS num_d,
	(SELECT f.z20_fecha_emi
		FROM acero_qm:cxct020 f
		WHERE f.z20_compania  = b.z23_compania
		  AND f.z20_localidad = b.z23_localidad
		  AND f.z20_codcli    = b.z23_codcli
		  AND f.z20_tipo_doc  = b.z23_tipo_doc
		  AND f.z20_num_doc   = b.z23_num_doc
		  AND f.z20_dividendo = 1) AS fec_emi,
	(SELECT MAX(g.z20_fecha_vcto)
		FROM acero_qm:cxct020 g
		WHERE g.z20_compania  = b.z23_compania
		  AND g.z20_localidad = b.z23_localidad
		  AND g.z20_codcli    = b.z23_codcli
		  AND g.z20_tipo_doc  = b.z23_tipo_doc
		  AND g.z20_num_doc   = b.z23_num_doc
		  AND g.z20_dividendo = b.z23_div_doc) AS fec_vcto,
	(SELECT MAX(DATE(d.z22_fecing))
		FROM acero_qm:cxct023 c, acero_qm:cxct022 d
		WHERE c.z23_compania   = b.z23_compania
		  AND c.z23_localidad  = b.z23_localidad
		  AND c.z23_codcli     = b.z23_codcli
		  AND c.z23_tipo_doc   = b.z23_tipo_doc
		  AND c.z23_num_doc    = b.z23_num_doc
		  AND d.z22_compania   = c.z23_compania
		  AND d.z22_localidad  = c.z23_localidad
		  AND d.z22_codcli     = c.z23_codcli
		  AND d.z22_tipo_trn   = c.z23_tipo_trn
		  AND d.z22_num_trn    = c.z23_num_trn
		  AND EXTEND(d.z22_fecing, YEAR TO MONTH) =
			EXTEND(a.z22_fecing, YEAR TO MONTH)) AS fec_pag,
	(SELECT MAX(DATE(d.z22_fecing))
		FROM acero_qm:cxct023 c, acero_qm:cxct022 d
		WHERE c.z23_compania   = b.z23_compania
		  AND c.z23_localidad  = b.z23_localidad
		  AND c.z23_codcli     = b.z23_codcli
		  AND c.z23_tipo_doc   = b.z23_tipo_doc
		  AND c.z23_num_doc    = b.z23_num_doc
		  AND d.z22_compania   = c.z23_compania
		  AND d.z22_localidad  = c.z23_localidad
		  AND d.z22_codcli     = c.z23_codcli
		  AND d.z22_tipo_trn   = c.z23_tipo_trn
		  AND d.z22_num_trn    = c.z23_num_trn
		  AND EXTEND(d.z22_fecing, YEAR TO MONTH) =
			EXTEND(a.z22_fecing, YEAR TO MONTH)) -
	(SELECT MAX(g.z20_fecha_vcto)
		FROM acero_qm:cxct020 g
		WHERE g.z20_compania  = b.z23_compania
		  AND g.z20_localidad = b.z23_localidad
		  AND g.z20_codcli    = b.z23_codcli
		  AND g.z20_tipo_doc  = b.z23_tipo_doc
		  AND g.z20_num_doc   = b.z23_num_doc
		  AND g.z20_dividendo = b.z23_div_doc) AS dias_pag,
	ROUND(SUM((SELECT SUM(e.z20_valor_cap + e.z20_valor_int)
		FROM acero_qm:cxct020 e
		WHERE e.z20_compania  = b.z23_compania
		  AND e.z20_localidad = b.z23_localidad
		  AND e.z20_codcli    = b.z23_codcli
		  AND e.z20_tipo_doc  = b.z23_tipo_doc
		  AND e.z20_num_doc   = b.z23_num_doc)), 2) AS valor_doc,
	(SELECT SUM(h.z20_saldo_cap + h.z20_saldo_int)
		FROM acero_qm:cxct020 h
		WHERE h.z20_compania  = b.z23_compania
		  AND h.z20_localidad = b.z23_localidad
		  AND h.z20_codcli    = b.z23_codcli
		  AND h.z20_tipo_doc  = b.z23_tipo_doc
		  AND h.z20_num_doc   = b.z23_num_doc) AS saldo,
	ROUND(SUM((b.z23_valor_cap + b.z23_valor_int) * (-1)), 2) AS val_pag,
	ROUND(SUM((b.z23_valor_cap + b.z23_valor_int) * (-1)) /
	SUM((SELECT SUM(e.z20_valor_cap + e.z20_valor_int)
		FROM acero_qm:cxct020 e
		WHERE e.z20_compania  = b.z23_compania
		  AND e.z20_localidad = b.z23_localidad
		  AND e.z20_codcli    = b.z23_codcli
		  AND e.z20_tipo_doc  = b.z23_tipo_doc
		  AND e.z20_num_doc   = b.z23_num_doc)), 2) AS porc
	FROM acero_qm:cxct023 b, acero_qm:cxct022 a, acero_qm:cxct001
	WHERE   b.z23_compania      = 1
	  AND ((b.z23_tipo_trn     IN ("PG", "AR")
	  AND   b.z23_tipo_doc      = "FA")
	   OR  (b.z23_tipo_trn      = "AJ"
	  AND   b.z23_tipo_doc      = "FA"))
	  AND   a.z22_compania      = b.z23_compania
	  AND   a.z22_localidad     = b.z23_localidad
	  AND   a.z22_codcli        = b.z23_codcli
	  AND   a.z22_tipo_trn      = b.z23_tipo_trn
	  AND   a.z22_num_trn       = b.z23_num_trn
	  AND   YEAR(a.z22_fecing) >= 2014
	  AND   z01_codcli          = a.z22_codcli
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 13;
