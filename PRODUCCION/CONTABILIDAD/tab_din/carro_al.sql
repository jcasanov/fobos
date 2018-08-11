SELECT CASE WHEN b12_origen
		THEN "AUTOMATICO"
		ELSE "MANUAL"
	END AS origen,
	b12_tipo_comp AS tipo,
	b12_num_comp AS numero,
	b12_fec_proceso AS fecha,
	b13_glosa AS glosa,
	NVL(CASE WHEN b13_valor_base > 0
		THEN b13_valor_base
		END, 0.00) AS debito,
	NVL(CASE WHEN b13_valor_base <= 0
		THEN b13_valor_base
		END, 0.00) AS credito
	FROM ctbt012, ctbt013
	WHERE b12_compania     = 1
	  AND b12_estado       = 'M'
	  AND b12_fec_proceso >= MDY(05, 01, 2008)
	  AND b13_compania     = b12_compania
	  AND b13_tipo_comp    = b12_tipo_comp
	  AND b13_num_comp     = b12_num_comp
	  AND b13_cuenta       = '11210103024'
	ORDER BY 4;
