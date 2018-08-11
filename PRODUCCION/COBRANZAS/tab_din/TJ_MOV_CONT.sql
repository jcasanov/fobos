SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || g02_abreviacion
		FROM acero_gm@idsgye01:gent002
		WHERE g02_compania  = b12_compania
		  AND g02_localidad = 1) AS local,
	YEAR(a.b12_fec_proceso) AS anio,
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
	YEAR(a.b12_fec_proceso) || "-" ||
	CASE WHEN MONTH(a.b12_fec_proceso) IN (01, 02, 03) THEN "TRIM-01"
	     WHEN MONTH(a.b12_fec_proceso) IN (04, 05, 06) THEN "TRIM-02"
	     WHEN MONTH(a.b12_fec_proceso) IN (07, 08, 09) THEN "TRIM-03"
	     WHEN MONTH(a.b12_fec_proceso) IN (10, 11, 12) THEN "TRIM-04"
	END AS trimes,
	NVL(LPAD(a.b12_subtipo, 2, 0) || " " || TRIM(b04_nombre),
		"SIN SUBTIPO") AS subt,
	a.b12_tipo_comp AS tip_comp, 
	TRIM(a.b12_num_comp) AS num_comp,
	NVL(TO_CHAR(a.b12_fec_proceso, "%Y-%m-%d"), "") AS fec_pro,
	TRIM(b.b13_cuenta) AS cta,
	TRIM(b10_descripcion) AS desc_cta,
	CASE WHEN b12_origen = "A"
		THEN "AUTOMATICO"
		ELSE "MANUAL"
	END AS orig,
	TRIM(a.b12_glosa) || " " || TRIM(b.b13_glosa) AS glos,
	SUM(CASE WHEN b.b13_valor_base > 0
		THEN b.b13_valor_base
		ELSE 0.00
	END) AS val_deb,
	SUM(CASE WHEN b.b13_valor_base <= 0
		THEN b.b13_valor_base
		ELSE 0.00
	END) AS val_cre,
	NVL(SUM(b.b13_valor_base), 0.00) AS saldo
	FROM acero_gm@idsgye01:ctbt012 a, acero_gm@idsgye01:ctbt013 b,
		acero_gm@idsgye01:ctbt010, OUTER acero_gm@idsgye01:ctbt004
	WHERE a.b12_compania           = 1
	  AND a.b12_estado             = "M"
	  AND YEAR(a.b12_fec_proceso)  > 2001
	  AND NOT EXISTS
		(SELECT 1 FROM acero_gm@idsgye01:ctbt050
			WHERE b50_compania  = a.b12_compania
	  		  AND b50_tipo_comp = a.b12_tipo_comp
	 		  AND b50_num_comp  = a.b12_num_comp)
	  AND b.b13_compania           = a.b12_compania
	  AND b.b13_tipo_comp          = a.b12_tipo_comp
	  AND b.b13_num_comp           = a.b12_num_comp
	  AND b.b13_cuenta            MATCHES "11210107*"
	  AND b10_compania             = b.b13_compania
	  AND b10_cuenta               = b.b13_cuenta
	  AND b04_compania             = a.b12_compania
	  AND b04_subtipo              = a.b12_subtipo
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
UNION
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || g02_abreviacion
		FROM acero_qm@acgyede:gent002
		WHERE g02_compania  = b12_compania
		  AND g02_localidad = 3) AS local,
	YEAR(a.b12_fec_proceso) AS anio,
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
	YEAR(a.b12_fec_proceso) || "-" ||
	CASE WHEN MONTH(a.b12_fec_proceso) IN (01, 02, 03) THEN "TRIM-01"
	     WHEN MONTH(a.b12_fec_proceso) IN (04, 05, 06) THEN "TRIM-02"
	     WHEN MONTH(a.b12_fec_proceso) IN (07, 08, 09) THEN "TRIM-03"
	     WHEN MONTH(a.b12_fec_proceso) IN (10, 11, 12) THEN "TRIM-04"
	END AS trimes,
	NVL(LPAD(a.b12_subtipo, 2, 0) || " " || TRIM(b04_nombre),
		"SIN SUBTIPO") AS subt,
	a.b12_tipo_comp AS tip_comp, 
	TRIM(a.b12_num_comp) AS num_comp,
	NVL(TO_CHAR(a.b12_fec_proceso, "%Y-%m-%d"), "") AS fec_pro,
	TRIM(b.b13_cuenta) AS cta,
	TRIM(b10_descripcion) AS desc_cta,
	CASE WHEN b12_origen = "A"
		THEN "AUTOMATICO"
		ELSE "MANUAL"
	END AS orig,
	TRIM(a.b12_glosa) || " " || TRIM(b.b13_glosa) AS glos,
	SUM(CASE WHEN b.b13_valor_base > 0
		THEN b.b13_valor_base
		ELSE 0.00
	END) AS val_deb,
	SUM(CASE WHEN b.b13_valor_base <= 0
		THEN b.b13_valor_base
		ELSE 0.00
	END) AS val_cre,
	NVL(SUM(b.b13_valor_base), 0.00) AS saldo
	FROM acero_qm@acgyede:ctbt012 a, acero_qm@acgyede:ctbt013 b,
		acero_qm@acgyede:ctbt010, OUTER acero_qm@acgyede:ctbt004
	WHERE a.b12_compania           = 1
	  AND a.b12_estado             = "M"
	  AND YEAR(a.b12_fec_proceso)  > 2001
	  AND NOT EXISTS
		(SELECT 1 FROM acero_qm@acgyede:ctbt050
			WHERE b50_compania  = a.b12_compania
	  		  AND b50_tipo_comp = a.b12_tipo_comp
	 		  AND b50_num_comp  = a.b12_num_comp)
	  AND b.b13_compania           = a.b12_compania
	  AND b.b13_tipo_comp          = a.b12_tipo_comp
	  AND b.b13_num_comp           = a.b12_num_comp
	  AND b.b13_cuenta            MATCHES "11210107*"
	  AND b10_compania             = b.b13_compania
	  AND b10_cuenta               = b.b13_cuenta
	  AND b04_compania             = a.b12_compania
	  AND b04_subtipo              = a.b12_subtipo
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12;
