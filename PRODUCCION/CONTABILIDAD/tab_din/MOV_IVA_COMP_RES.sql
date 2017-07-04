SELECT YEAR(b12_fec_proceso) AS anio1,
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
	END AS mes1,
	MONTH(b12_fec_proceso) AS n_mes,
	b12_tipo_comp AS tip_com,
	b12_num_comp AS num_com,
	NVL(b13_codprov, "") AS codp,
	NVL((SELECT p01_nomprov
		FROM cxpt001
		WHERE p01_codprov = b13_codprov), "SIN PROVEEDOR") AS nomp,
	NVL((SELECT p01_num_doc
		FROM cxpt001
		WHERE p01_codprov = b13_codprov), "") AS cedr,
	CASE WHEN b12_origen = "A"
		THEN "AUTOMATICO"
		ELSE "MANUAL"
	END AS orig,
	NVL((SELECT c13_factura
		FROM ordt040, ordt013
		WHERE c40_compania  = b12_compania
		  AND c40_tipo_comp = b12_tipo_comp
		  AND c40_num_comp  = b12_num_comp
		  AND c13_compania  = c40_compania
		  AND c13_localidad = c40_localidad
		  AND c13_numero_oc = c40_numero_oc
		  AND c13_num_recep = c40_num_recep
		  AND c13_estado    = "A"), "") AS fact,
	SUM(CASE WHEN b13_valor_base >= 0
		THEN b13_valor_base
		ELSE 0.00
	END) AS val_db,
	SUM(CASE WHEN b13_valor_base < 0
		THEN b13_valor_base
		ELSE 0.00
	END) AS val_cr,
	SUM(b13_valor_base) AS sald
	FROM ctbt013, ctbt012, ctbt010
	WHERE b13_compania           = 1
	  AND b13_cuenta[1, 8]       = "11300101"
	  AND YEAR(b13_fec_proceso) >= 2013
	  AND b12_compania           = b13_compania
	  AND b12_tipo_comp          = b13_tipo_comp
	  AND b12_num_comp           = b13_num_comp
	  AND b12_estado             = "M"
	  AND b10_compania           = b13_compania
	  AND b10_cuenta             = b13_cuenta
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
	ORDER BY 1, 3, 7, 13;
