SELECT a.b12_tipo_comp AS tp,
	a.b12_num_comp AS num,
	b.b13_glosa AS glosa,
	b.b13_fec_proceso AS fec,
	CASE WHEN b.b13_valor_base >= 0
		THEN b.b13_valor_base
		ELSE 0.00
	END AS val_deb,
	CASE WHEN b.b13_valor_base < 0
		THEN b.b13_valor_base
		ELSE 0.00
	END AS val_cre
	FROM ctbt012 a, ctbt013 b
	WHERE a.b12_compania          = 1
	  AND a.b12_estado            = "M"
	  --AND YEAR(a.b12_fec_proceso) = 2013
	  AND EXTEND(a.b12_fec_proceso, YEAR TO MONTH) = '2013-07'
	  AND b.b13_compania          = a.b12_compania
	  AND b.b13_tipo_comp         = a.b12_tipo_comp
	  AND b.b13_num_comp          = a.b12_num_comp
	  AND b.b13_cuenta            = "15010101001"
	  AND NOT EXISTS
		(SELECT 1
		FROM acero_qm@acgyede:ctbt012 c, acero_qm@acgyede:ctbt013 d
		WHERE c.b12_compania          = 1
		  AND c.b12_estado            = "M"
	  	  --AND YEAR(c.b12_fec_proceso) = 2013
		  AND EXTEND(c.b12_fec_proceso, YEAR TO MONTH) = '2013-07'
		  AND d.b13_compania          = c.b12_compania
		  AND d.b13_tipo_comp         = c.b12_tipo_comp
		  AND d.b13_num_comp          = c.b12_num_comp
		  AND d.b13_cuenta            = "15010101001"
		  AND d.b13_valor_base        = b.b13_valor_base * (-1));
