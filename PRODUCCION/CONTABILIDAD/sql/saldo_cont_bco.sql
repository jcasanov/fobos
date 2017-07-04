SELECT g09_numero_cta AS cta_bco,
	g09_aux_cont AS cuenta,
	(SELECT g08_nombre
		FROM gent008
		WHERE g08_banco = g09_banco) AS nom_banco,
	SUM(CASE WHEN b13_valor_base >= 0
			THEN b13_valor_base
			ELSE 0.00
		END) AS val_db,
	SUM(CASE WHEN b13_valor_base < 0
			THEN b13_valor_base
			ELSE 0.00
		END) AS val_cr
	FROM gent009, ctbt013, ctbt012
	WHERE g09_compania    = 1
	--  AND g09_estado      = "A"
	  AND b13_compania    = g09_compania
	  AND b13_cuenta      = g09_aux_cont
	  AND b13_fec_proceso BETWEEN MDY(01, 01, 2001)
				  AND MDY(11, 24, 2014)
	  AND b12_compania    = b13_compania
	  AND b12_tipo_comp   = b13_tipo_comp
	  AND b12_num_comp    = b13_num_comp
	  AND b12_estado      = "M"
	GROUP BY 1, 2, 3;
