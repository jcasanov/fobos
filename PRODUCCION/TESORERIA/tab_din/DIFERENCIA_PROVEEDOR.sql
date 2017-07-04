SELECT YEAR(p20_fecha_emi) AS anio,
	CASE WHEN MONTH(p20_fecha_emi) = 01 THEN "ENERO"
	     WHEN MONTH(p20_fecha_emi) = 02 THEN "FEBRERO"
	     WHEN MONTH(p20_fecha_emi) = 03 THEN "MARZO"
	     WHEN MONTH(p20_fecha_emi) = 04 THEN "ABRIL"
	     WHEN MONTH(p20_fecha_emi) = 05 THEN "MAYO"
	     WHEN MONTH(p20_fecha_emi) = 06 THEN "JUNIO"
	     WHEN MONTH(p20_fecha_emi) = 07 THEN "JULIO"
	     WHEN MONTH(p20_fecha_emi) = 08 THEN "AGOSTO"
	     WHEN MONTH(p20_fecha_emi) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(p20_fecha_emi) = 10 THEN "OCTUBRE"
	     WHEN MONTH(p20_fecha_emi) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(p20_fecha_emi) = 12 THEN "DICIEMBRE"
	END AS mes,
	"DOC. DEUDOR" AS subt,
	(SELECT p01_nomprov
		FROM acero_gm@idsgye01:cxpt001
		WHERE p01_codprov = p20_codprov) AS prov,
	p20_codprov AS codp,
	DATE(p20_fecha_emi) AS fec,
	CAST(p20_referencia AS VARCHAR(250)) AS refer,
	p20_tipo_doc AS tip_d,
	p20_num_doc AS num_d,
	p20_dividendo AS div_d,
	"" AS tip_t,
	"" AS num_t,
	"TESORERIA" AS orig,
	(SELECT CASE WHEN p01_estado = "A"
			THEN "ACTIVO"
			ELSE "BLOQUEADO"
		END
		FROM acero_gm@idsgye01:cxpt001
		WHERE p01_codprov = p20_codprov) AS est,
	{--
	CASE WHEN (p20_saldo_cap + p20_saldo_int) > 0
		THEN "CON SALDO DEUDOR"
		ELSE "SIN SALDO"
	END AS con_sl,
	--}
	(p20_valor_cap + p20_valor_int) AS val_doc,
	0.00 AS val_m_d,
	0.00 AS val_m_f,
	(p20_valor_cap + p20_valor_int) AS sal_t,
	0.00 AS val_deb,
	0.00 AS val_cre,
	0.00 AS sal_c,
	(p20_valor_cap + p20_valor_int) AS sald
	FROM acero_gm@idsgye01:cxpt020
	WHERE p20_compania  = 1
	  AND p20_localidad = 1
UNION ALL
SELECT YEAR(p21_fecha_emi) AS anio,
	CASE WHEN MONTH(p21_fecha_emi) = 01 THEN "ENERO"
	     WHEN MONTH(p21_fecha_emi) = 02 THEN "FEBRERO"
	     WHEN MONTH(p21_fecha_emi) = 03 THEN "MARZO"
	     WHEN MONTH(p21_fecha_emi) = 04 THEN "ABRIL"
	     WHEN MONTH(p21_fecha_emi) = 05 THEN "MAYO"
	     WHEN MONTH(p21_fecha_emi) = 06 THEN "JUNIO"
	     WHEN MONTH(p21_fecha_emi) = 07 THEN "JULIO"
	     WHEN MONTH(p21_fecha_emi) = 08 THEN "AGOSTO"
	     WHEN MONTH(p21_fecha_emi) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(p21_fecha_emi) = 10 THEN "OCTUBRE"
	     WHEN MONTH(p21_fecha_emi) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(p21_fecha_emi) = 12 THEN "DICIEMBRE"
	END AS mes,
	"DOC. A FAVOR" AS subt,
	(SELECT p01_nomprov
		FROM acero_gm@idsgye01:cxpt001
		WHERE p01_codprov = p21_codprov) AS prov,
	p21_codprov AS codp,
	DATE(p21_fecha_emi) AS fec,
	CAST(p21_referencia AS VARCHAR(250)) AS refer,
	p21_tipo_doc AS tip_d,
	CAST(p21_num_doc AS CHAR(21)) AS num_d,
	1 AS div_d,
	"" AS tip_t,
	"" AS num_t,
	"TESORERIA" AS orig,
	(SELECT CASE WHEN p01_estado = "A"
			THEN "ACTIVO"
			ELSE "BLOQUEADO"
		END
		FROM acero_gm@idsgye01:cxpt001
		WHERE p01_codprov = p21_codprov) AS est,
	{--
	CASE WHEN p21_saldo > 0
		THEN "CON SALDO A FAVOR"
		ELSE "SIN SALDO"
	END AS con_sl,
	--}
	(p21_valor * (-1)) AS val_doc,
	0.00 AS val_m_d,
	0.00 AS val_m_f,
	(p21_valor * (-1)) AS sal_t,
	0.00 AS val_deb,
	0.00 AS val_cre,
	0.00 AS sal_c,
	(p21_valor * (-1)) AS sald
	FROM acero_gm@idsgye01:cxpt021
	WHERE p21_compania  = 1
	  AND p21_localidad = 1
UNION ALL
SELECT YEAR(p22_fecing) AS anio,
	CASE WHEN MONTH(p22_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(p22_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(p22_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(p22_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(p22_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(p22_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(p22_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(p22_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(p22_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(p22_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(p22_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(p22_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	"MOV. DEUDOR" AS subt,
	(SELECT p01_nomprov
		FROM acero_gm@idsgye01:cxpt001
		WHERE p01_codprov = p22_codprov) AS prov,
	p23_codprov AS codp,
	DATE(p22_fecing) AS fec,
	CAST(p22_referencia AS VARCHAR(250)) AS refer,
	p23_tipo_doc AS tip_d,
	p23_num_doc AS num_d,
	p23_div_doc AS div_d,
	p22_tipo_trn AS tip_t,
	CAST(p22_num_trn AS VARCHAR(10)) AS num_t,
	"TESORERIA" AS orig,
	(SELECT CASE WHEN p01_estado = "A"
			THEN "ACTIVO"
			ELSE "BLOQUEADO"
		END
		FROM acero_gm@idsgye01:cxpt001
		WHERE p01_codprov = p22_codprov) AS est,
	{--
	CASE WHEN (SELECT (p20_saldo_cap + p20_saldo_int)
			FROM acero_gm@idsgye01:cxpt020
			WHERE p20_compania  = p23_compania
			  AND p20_localidad = p23_localidad
			  AND p20_codprov   = p23_codprov
			  AND p20_tipo_doc  = p23_tipo_doc
			  AND p20_num_doc   = p23_num_doc
			  AND p20_dividendo = p23_div_doc) > 0
		THEN "CON SALDO MOV."
		ELSE "SIN SALDO"
	END AS con_sl,
	--}
	0.00 AS val_doc,
	CASE WHEN (p23_valor_cap + p23_valor_int) <= 0
		THEN (p23_valor_cap + p23_valor_int)
		ELSE 0.00
	END AS val_m_d,
	CASE WHEN (p23_valor_cap + p23_valor_int) > 0
		THEN (p23_valor_cap + p23_valor_int)
		ELSE 0.00
	END AS val_m_f,
	(p23_valor_cap + p23_valor_int) AS sal_t,
	0.00 AS val_deb,
	0.00 AS val_cre,
	0.00 AS sal_c,
	(p23_valor_cap + p23_valor_int) AS sald
	FROM acero_gm@idsgye01:cxpt022,
		acero_gm@idsgye01:cxpt023
	WHERE p22_compania  = 1
	  AND p23_compania  = p22_compania
	  AND p23_localidad = p22_localidad
	  AND p23_codprov   = p22_codprov
	  AND p23_tipo_trn  = p22_tipo_trn
	  AND p23_num_trn   = p22_num_trn
UNION ALL
SELECT YEAR(p22_fecing) AS anio,
	CASE WHEN MONTH(p22_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(p22_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(p22_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(p22_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(p22_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(p22_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(p22_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(p22_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(p22_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(p22_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(p22_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(p22_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	"MOV. A FAVOR" AS subt,
	(SELECT p01_nomprov
		FROM acero_gm@idsgye01:cxpt001
		WHERE p01_codprov = p22_codprov) AS prov,
	p23_codprov AS codp,
	DATE(p22_fecing) AS fec,
	CAST(p22_referencia AS VARCHAR(250)) AS refer,
	p23_tipo_doc AS tip_d,
	p23_num_doc AS num_d,
	p23_div_doc AS div_d,
	p23_tipo_favor AS tip_t,
	CAST(p23_doc_favor AS VARCHAR(10)) AS num_t,
	"TESORERIA" AS orig,
	(SELECT CASE WHEN p01_estado = "A"
			THEN "ACTIVO"
			ELSE "BLOQUEADO"
		END
		FROM acero_gm@idsgye01:cxpt001
		WHERE p01_codprov = p22_codprov) AS est,
	{--
	CASE WHEN (SELECT p21_saldo
			FROM acero_gm@idsgye01:cxpt021
			WHERE p21_compania  = p23_compania
			  AND p21_localidad = p23_localidad
			  AND p21_codprov   = p23_codprov
			  AND p21_tipo_doc  = p23_tipo_favor
			  AND p21_num_doc   = p23_doc_favor) > 0
		THEN "CON SALDO MOV."
		ELSE "SIN SALDO"
	END AS con_sl,
	--}
	0.00 AS val_doc,
	CASE WHEN (p23_valor_cap + p23_valor_int) > 0
		THEN (p23_valor_cap + p23_valor_int) * (-1)
		ELSE 0.00
	END AS val_m_d,
	CASE WHEN (p23_valor_cap + p23_valor_int) <= 0
		THEN (p23_valor_cap + p23_valor_int) * (-1)
		ELSE 0.00
	END AS val_m_f,
	((p23_valor_cap + p23_valor_int) * (-1)) AS sal_t,
	0.00 AS val_deb,
	0.00 AS val_cre,
	0.00 AS sal_c,
	((p23_valor_cap + p23_valor_int) * (-1)) AS sald
	FROM acero_gm@idsgye01:cxpt022,
		acero_gm@idsgye01:cxpt023
	WHERE p22_compania    = 1
	  AND p23_compania    = p22_compania
	  AND p23_localidad   = p22_localidad
	  AND p23_codprov     = p22_codprov
	  AND p23_tipo_trn    = p22_tipo_trn
	  AND p23_num_trn     = p22_num_trn
	  AND p23_tipo_favor IS NOT NULL
UNION ALL
SELECT YEAR(a.b12_fec_proceso) AS anio,
	CASE WHEN MONTH(a.b12_fec_proceso) = 01 THEN "ENERO"
	     WHEN MONTH(a.b12_fec_proceso) = 02 THEN "FEBRERO"
	     WHEN MONTH(a.b12_fec_proceso) = 03 THEN "MARZO"
	     WHEN MONTH(a.b12_fec_proceso) = 04 THEN "ABRIL"
	     WHEN MONTH(a.b12_fec_proceso) = 05 THEN "MAYO"
	     WHEN MONTH(a.b12_fec_proceso) = 06 THEN "JUNIO"
	     WHEN MONTH(a.b12_fec_proceso) = 07 THEN "JULIO"
	     WHEN MONTH(a.b12_fec_proceso) = 08 THEN "AGOSTO"
	     WHEN MONTH(a.b12_fec_proceso) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(a.b12_fec_proceso) = 10 THEN "OCTUBRE"
	     WHEN MONTH(a.b12_fec_proceso) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(a.b12_fec_proceso) = 12 THEN "DICIEMBRE"
	END AS mes,
	NVL(LPAD(a.b12_subtipo, 2, 0) || " " ||
		(SELECT TRIM(b04_nombre)
			FROM acero_gm@idsgye01:ctbt004
			WHERE b04_compania = a.b12_compania
			  AND b04_subtipo  = a.b12_subtipo),
		"SIN SUBTIPO") AS subt,
	NVL((SELECT p01_nomprov
		FROM acero_gm@idsgye01:cxpt001
		WHERE p01_codprov = b.b13_codprov), "SIN PROVEEDOR") AS prov,
	NVL(b13_codprov, 0) AS codp,
	DATE(a.b12_fec_proceso) AS fec,
	CAST(CASE WHEN LENGTH(TRIM(a.b12_glosa)) > 1
		THEN TRIM(a.b12_glosa)
		ELSE ""
	END || " " || TRIM(b.b13_glosa) AS VARCHAR(250)) AS refer,
	a.b12_tipo_comp AS tip_d, 
	CAST(TRIM(a.b12_num_comp) AS CHAR(21)) AS num_d,
	1 AS div_d,
	"" AS tip_t,
	"" AS num_t,
	CASE WHEN b12_origen = "A"
		THEN "AUTOMATICO"
		ELSE "MANUAL"
	END AS orig,
	(SELECT CASE WHEN p01_estado = "A"
			THEN "ACTIVO"
			ELSE "BLOQUEADO"
		END
		FROM acero_gm@idsgye01:cxpt001
		WHERE p01_codprov = b.b13_codprov) AS est,
	{--
	CASE WHEN NVL((SELECT SUM(d.b13_valor_base)
			FROM acero_gm@idsgye01:ctbt013 d,
				acero_gm@idsgye01:ctbt012 c
			WHERE d.b13_compania  = b.b13_compania
			  AND d.b13_cuenta    = b.b13_cuenta
			  AND d.b13_codprov   = b.b13_codprov
			  AND c.b12_compania  = d.b13_compania
			  AND c.b12_tipo_comp = d.b13_tipo_comp
			  AND c.b12_num_comp  = d.b13_num_comp
			  AND c.b12_estado    = "M"), 0.00) <> 0
		THEN "CON SALDO CON."
		ELSE "SIN SALDO"
	END AS con_sl,
	--}
	0.00 AS val_doc,
	0.00 AS val_m_d,
	0.00 AS val_m_f,
	0.00 AS sal_t,
	CAST(CASE WHEN b.b13_valor_base > 0
		THEN b.b13_valor_base
		ELSE 0.00
	END AS DECIMAL(12,2)) AS val_deb,
	CAST(CASE WHEN b.b13_valor_base <= 0
		THEN b.b13_valor_base
		ELSE 0.00
	END AS DECIMAL(12,2)) AS val_cre,
	CAST(NVL(b.b13_valor_base, 0.00) AS DECIMAL(12,2)) AS sal_c,
	CAST(NVL(b.b13_valor_base, 0.00) AS DECIMAL(12,2)) AS sald
	FROM acero_gm@idsgye01:ctbt013 b,
		acero_gm@idsgye01:ctbt012 a
	WHERE b.b13_compania  = 1
	  AND b.b13_cuenta    = "21010101001"
	  AND a.b12_compania  = b.b13_compania
	  AND a.b12_tipo_comp = b.b13_tipo_comp
	  AND a.b12_num_comp  = b.b13_num_comp
	  AND a.b12_estado    = "M";
