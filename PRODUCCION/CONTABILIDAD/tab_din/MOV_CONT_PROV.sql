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
	CASE WHEN MONTH(a.b12_fec_proceso) IN (01, 02, 03) THEN "TRIM-01"
	     WHEN MONTH(a.b12_fec_proceso) IN (04, 05, 06) THEN "TRIM-02"
	     WHEN MONTH(a.b12_fec_proceso) IN (07, 08, 09) THEN "TRIM-03"
	     WHEN MONTH(a.b12_fec_proceso) IN (10, 11, 12) THEN "TRIM-04"
	END AS trimes,
	NVL(LPAD(a.b12_subtipo, 2, 0) || " " ||
		(SELECT TRIM(b04_nombre)
			FROM acero_gm@idsgye01:ctbt004
			WHERE b04_compania = a.b12_compania
			  AND b04_subtipo  = a.b12_subtipo),
		"SIN SUBTIPO") AS subt,
	a.b12_tipo_comp AS tip_comp, 
	TRIM(a.b12_num_comp) AS num_comp,
	a.b12_fec_proceso AS fec_pro,
	CASE WHEN b12_origen = "A"
		THEN "AUTOMATICO"
		ELSE "MANUAL"
	END AS orig,
	CASE WHEN LENGTH(TRIM(a.b12_glosa)) > 1
		THEN TRIM(a.b12_glosa)
		ELSE ""
	END || " " || TRIM(b.b13_glosa) AS glos,
	NVL(b13_codprov, "") AS codprov,
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
		THEN "CON SALDO"
		ELSE "SIN SALDO"
	END AS con_sl,
	NVL((SELECT p01_nomprov
		FROM acero_gm@idsgye01:cxpt001
		WHERE p01_codprov = b.b13_codprov), "SIN PROVEEDOR") AS nomprov,
	CASE WHEN b.b13_valor_base > 0
		THEN b.b13_valor_base
		ELSE 0.00
	END AS val_deb,
	CASE WHEN b.b13_valor_base <= 0
		THEN b.b13_valor_base
		ELSE 0.00
	END AS val_cre,
	NVL(b.b13_valor_base, 0.00) AS saldo
	FROM acero_gm@idsgye01:ctbt013 b,
		acero_gm@idsgye01:ctbt012 a
	WHERE b.b13_compania  = 1
	  AND b.b13_cuenta    = "21010101001"
	  AND a.b12_compania  = b.b13_compania
	  AND a.b12_tipo_comp = b.b13_tipo_comp
	  AND a.b12_num_comp  = b.b13_num_comp
	  AND a.b12_estado    = "M";
