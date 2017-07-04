SELECT "DEUDOR" AS tipo,
	YEAR(z20_fecha_emi) AS anio,
	CASE WHEN MONTH(z20_fecha_emi) = 01 THEN "ENERO"
	     WHEN MONTH(z20_fecha_emi) = 02 THEN "FEBRERO"
	     WHEN MONTH(z20_fecha_emi) = 03 THEN "MARZO"
	     WHEN MONTH(z20_fecha_emi) = 04 THEN "ABRIL"
	     WHEN MONTH(z20_fecha_emi) = 05 THEN "MAYO"
	     WHEN MONTH(z20_fecha_emi) = 06 THEN "JUNIO"
	     WHEN MONTH(z20_fecha_emi) = 07 THEN "JULIO"
	     WHEN MONTH(z20_fecha_emi) = 08 THEN "AGOSTO"
	     WHEN MONTH(z20_fecha_emi) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(z20_fecha_emi) = 10 THEN "OCTUBRE"
	     WHEN MONTH(z20_fecha_emi) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(z20_fecha_emi) = 12 THEN "DICIEMBRE"
	END AS meses,
	YEAR(z22_fecing) AS anio_p,
	CASE WHEN MONTH(z22_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(z22_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(z22_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(z22_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(z22_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(z22_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(z22_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(z22_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(z22_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(z22_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(z22_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(z22_fecing) = 12 THEN "DICIEMBRE"
	END AS mes_p,
	(SELECT LPAD(g02_localidad, 2, 0) || " " || g02_abreviacion
		FROM gent002
		WHERE g02_compania  = z20_compania
		  AND g02_localidad = z20_localidad) AS local,
	z20_codcli AS codcli,
	z01_nomcli AS clientes,
	CASE WHEN z20_areaneg = 1
		THEN "INVENTARIO"
		ELSE "TALLER"
	END AS areaneg,
	z20_tipo_doc AS tipo_doc,
	z20_num_doc AS num_doc,
	z20_dividendo AS dividendo,
	z20_fecha_emi AS fecha_emi,
	z20_fecha_vcto AS fecha_vcto,
	(z20_fecha_vcto - DATE(b.z22_fecing)) AS dias,
	z20_referencia AS refer,
	NVL((a.z23_saldo_cap + a.z23_saldo_int),
		(z20_valor_cap + z20_valor_int)) AS valor,
	NVL(CASE WHEN b.z22_fecing IS NOT NULL
		THEN CASE WHEN b.z22_fecing =
		(SELECT MAX(d.z22_fecing)
			FROM cxct023 c, cxct022 d
			WHERE c.z23_compania  = a.z23_compania
			  AND c.z23_localidad = a.z23_localidad
			  AND c.z23_codcli    = a.z23_codcli
			  AND c.z23_tipo_doc  = a.z23_tipo_doc
			  AND c.z23_num_doc   = a.z23_num_doc
			  AND c.z23_div_doc   = a.z23_div_doc
			  AND d.z22_compania  = c.z23_compania
			  AND d.z22_localidad = c.z23_localidad
			  AND d.z22_codcli    = c.z23_codcli
			  AND d.z22_tipo_trn  = c.z23_tipo_trn
			  AND d.z22_num_trn   = c.z23_num_trn)
		THEN (a.z23_valor_cap + a.z23_valor_int + a.z23_saldo_cap
			+ a.z23_saldo_int)
		ELSE 0.00
		END
		END, (z20_saldo_cap + z20_saldo_int)) AS saldo,
	NVL(b.z22_tipo_trn, "") AS tip_trn,
	NVL(b.z22_num_trn, "") AS num_trn,
	NVL(TO_CHAR(b.z22_fecing, "%Y-%m-%d"), "") AS fec_pag,
	NVL(z05_nombres, "SIN COBRADOR") AS agente,
	NVL((SELECT z06_nombre
		FROM cxct006
		WHERE z06_zona_cobro = z22_zona_cobro),
	NVL((SELECT z06_nombre
		FROM cxct002, cxct006
		WHERE z02_compania   = z20_compania
		  AND z02_localidad  = z20_localidad
		  AND z02_codcli     = z20_codcli
		  AND z06_zona_cobro = z02_zona_cobro), "SIN ZONA")) AS zon_c,
	NVL((a.z23_valor_cap + a.z23_valor_int), 0.00) AS pago,
	CASE WHEN g10_estado = "A"
		THEN "ACTIVA"
		ELSE "BLOQUEADA"
	END AS est_tj
	FROM gent010, cxct020, cxct001,
		OUTER(cxct023 a, cxct022 b, OUTER(cxct005))
	WHERE g10_compania    = 1
	  AND z20_compania    = g10_compania
	  AND z20_codcli      = g10_codcobr
	  AND z01_codcli      = z20_codcli
	  AND a.z23_compania  = z20_compania
	  AND a.z23_localidad = z20_localidad
	  AND a.z23_codcli    = z20_codcli
	  AND a.z23_tipo_doc  = z20_tipo_doc
	  AND a.z23_num_doc   = z20_num_doc
	  AND a.z23_div_doc   = z20_dividendo
	  AND b.z22_compania  = a.z23_compania
	  AND b.z22_localidad = a.z23_localidad
	  AND b.z22_codcli    = a.z23_codcli
	  AND b.z22_tipo_trn  = a.z23_tipo_trn
	  AND b.z22_num_trn   = a.z23_num_trn
	  AND z05_compania    = b.z22_compania
	  AND z05_codigo      = b.z22_cobrador
UNION
SELECT "A FAVOR" AS tipo,
	YEAR(z21_fecha_emi) AS anio,
	CASE WHEN MONTH(z21_fecha_emi) = 01 THEN "ENERO"
	     WHEN MONTH(z21_fecha_emi) = 02 THEN "FEBRERO"
	     WHEN MONTH(z21_fecha_emi) = 03 THEN "MARZO"
	     WHEN MONTH(z21_fecha_emi) = 04 THEN "ABRIL"
	     WHEN MONTH(z21_fecha_emi) = 05 THEN "MAYO"
	     WHEN MONTH(z21_fecha_emi) = 06 THEN "JUNIO"
	     WHEN MONTH(z21_fecha_emi) = 07 THEN "JULIO"
	     WHEN MONTH(z21_fecha_emi) = 08 THEN "AGOSTO"
	     WHEN MONTH(z21_fecha_emi) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(z21_fecha_emi) = 10 THEN "OCTUBRE"
	     WHEN MONTH(z21_fecha_emi) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(z21_fecha_emi) = 12 THEN "DICIEMBRE"
	END AS meses,
	YEAR(z22_fecing) AS anio_p,
	CASE WHEN MONTH(z22_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(z22_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(z22_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(z22_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(z22_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(z22_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(z22_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(z22_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(z22_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(z22_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(z22_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(z22_fecing) = 12 THEN "DICIEMBRE"
	END AS mes_p,
	(SELECT LPAD(g02_localidad, 2, 0) || " " || g02_abreviacion
		FROM gent002
		WHERE g02_compania  = z21_compania
		  AND g02_localidad = z21_localidad) AS local,
	z21_codcli AS codcli,
	z01_nomcli AS clientes,
	CASE WHEN z21_areaneg = 1
		THEN "INVENTARIO"
		ELSE "TALLER"
	END AS areaneg,
	z21_tipo_doc AS tipo_doc,
	z21_num_doc || "" AS num_doc,
	1 AS dividendo,
	z21_fecha_emi AS fecha_emi,
	z21_fecha_emi AS fecha_vcto,
	0 AS dias,
	z21_referencia AS refer,
	z21_valor * (-1) AS valor,
	0.00 AS saldo,
	NVL(b.z22_tipo_trn, "") AS tip_trn,
	NVL(b.z22_num_trn, "") AS num_trn,
	NVL(TO_CHAR(b.z22_fecing, "%Y-%m-%d"), "") AS fec_pag,
	NVL(z05_nombres, "SIN COBRADOR") AS agente,
	NVL((SELECT z06_nombre
		FROM cxct006
		WHERE z06_zona_cobro = z22_zona_cobro),
	NVL((SELECT z06_nombre
		FROM cxct002, cxct006
		WHERE z02_compania   = z21_compania
		  AND z02_localidad  = z21_localidad
		  AND z02_codcli     = z21_codcli
		  AND z06_zona_cobro = z02_zona_cobro), "SIN ZONA")) AS zon_c,
	0.00 AS pago,
	CASE WHEN g10_estado = "A"
		THEN "ACTIVA"
		ELSE "BLOQUEADA"
	END AS est_tj
	FROM gent010, cxct021, cxct001,
		OUTER(cxct023 a, cxct022 b, OUTER(cxct005))
	WHERE g10_compania     = 1
	  AND z21_compania     = g10_compania
	  AND z21_codcli       = g10_codcobr
	  AND z01_codcli       = z21_codcli
	  AND a.z23_compania   = z21_compania
	  AND a.z23_localidad  = z21_localidad
	  AND a.z23_codcli     = z21_codcli
	  AND a.z23_tipo_favor = z21_tipo_doc
	  AND a.z23_doc_favor  = z21_num_doc
	  AND b.z22_compania   = a.z23_compania
	  AND b.z22_localidad  = a.z23_localidad
	  AND b.z22_codcli     = a.z23_codcli
	  AND b.z22_tipo_trn   = a.z23_tipo_trn
	  AND b.z22_num_trn    = a.z23_num_trn
	  AND z05_compania     = b.z22_compania
	  AND z05_codigo       = b.z22_cobrador;
