SELECT YEAR(b12_fec_proceso) AS anio,
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
	n56_cod_trab AS cod_emp,
	n30_nombres AS nom_emp,
	n56_aux_val_vac AS cta,
	b10_descripcion AS nom_cta,
	b12_tipo_comp AS tip_dc,
	b12_num_comp AS num_dc,
	b12_fec_proceso AS fec_pro,
	b13_secuencia AS secuen,
	TRIM(b12_glosa) || " " || TRIM(b13_glosa) AS glos,
	CASE WHEN b13_valor_base >= 0
		THEN b13_valor_base
		ELSE 0.00
	END AS val_db,
	CASE WHEN b13_valor_base < 0
		THEN b13_valor_base
		ELSE 0.00
	END AS val_cr,
	b13_valor_base AS sald,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est,
	(SELECT UNIQUE n16_descripcion
		FROM rolt018, rolt016
		WHERE n18_flag_ident = n56_proceso
		  AND n16_flag_ident = n18_flag_ident) AS tip_ant
	FROM rolt056, rolt030, ctbt010, ctbt013, ctbt012
	WHERE n56_compania     = 1
	  AND n56_proceso     IN (SELECT n18_flag_ident FROM rolt018)
	  AND n30_compania     = n56_compania
	  AND n30_cod_trab     = n56_cod_trab
	  AND b10_compania     = n56_compania
	  AND b10_cuenta       = n56_aux_val_vac
	  AND b13_compania     = b10_compania
	  AND b13_cuenta       = b10_cuenta
	  AND b12_compania     = b13_compania
	  AND b12_tipo_comp    = b13_tipo_comp
	  AND b12_num_comp     = b13_num_comp
	  AND b12_estado       = "M"
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16;
