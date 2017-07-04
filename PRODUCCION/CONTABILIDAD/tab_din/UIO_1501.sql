SELECT "ACERO GUAYAQUIL" AS loc,
	YEAR(b12_fec_proceso) AS anio,
	CASE WHEN MONTH(b12_fec_proceso) = 01 THEN "ENERO"
	     WHEN MONTH(b12_fec_proceso) = 02 THEN "FEBRERO"
	     WHEN MONTH(b12_fec_proceso) = 03 THEN "MARZO"
	     WHEN MONTH(b12_fec_proceso) = 04 THEN "ABRIL"
	     WHEN MONTH(b12_fec_proceso) = 05 THEN "MAYO"
	     WHEN MONTH(b12_fec_proceso) = 06 THEN "JUNIO"
	     WHEN MONTH(b12_fec_proceso) = 07 THEN "JULIO"
	     WHEN MONTH(b12_fec_proceso) = 08 THEN "AGOSTO"
	     WHEN MONTH(b12_fec_proceso) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(b12_fec_proceso) = 10 THEN "OCTUBRE"
	     WHEN MONTH(b12_fec_proceso) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(b12_fec_proceso) = 12 THEN "DICIEMBRE"
	END AS mes,
	NVL(LPAD(b12_subtipo, 2, 0) || " " ||
		(SELECT TRIM(b04_nombre)
			FROM acero_qm@idsuio01:ctbt004
			WHERE b04_compania = b12_compania
			  AND b04_subtipo  = b12_subtipo),
		"SIN SUBTIPO") AS subt,
	b12_tipo_comp AS tip_comp, 
	TRIM(b12_num_comp) AS num_comp,
	b13_fec_proceso AS fec_pro,
	CASE WHEN b12_origen = "A"
		THEN "AUTOMATICO"
		ELSE "MANUAL"
	END AS orig,
	CASE WHEN LENGTH(TRIM(b12_glosa)) < 2
		THEN TRIM(b13_glosa)
		ELSE TRIM(b12_glosa) || " " || TRIM(b13_glosa)
	END AS glos,
	CASE WHEN b13_valor_base > 0
		THEN b13_valor_base
		ELSE 0.00
	END AS val_deb,
	CASE WHEN b13_valor_base <= 0
		THEN b13_valor_base
		ELSE 0.00
	END AS val_cre
	FROM acero_qm@idsuio01:ctbt012,
		acero_qm@idsuio01:ctbt013
	WHERE b12_compania          = 1
	  AND b12_estado            = "M"
	  AND YEAR(b12_fec_proceso) > 2001
	  AND b12_compania || b12_tipo_comp || b12_num_comp
		NOT IN
		(SELECT b50_compania || b50_tipo_comp || b50_num_comp
			FROM acero_qm@idsuio01:ctbt050
			WHERE b50_anio = YEAR(b12_fec_proceso))
	  AND b13_compania          = b12_compania
	  AND b13_tipo_comp         = b12_tipo_comp
	  AND b13_num_comp          = b12_num_comp
	  AND b13_cuenta            = "15010101001"
	ORDER BY b13_fec_proceso ASC;
