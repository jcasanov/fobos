SELECT b12_tipo_comp AS tp,
	b12_num_comp AS num,
	b13_glosa AS glosa,
	b13_fec_proceso AS fec,
	CASE WHEN b13_valor_base >= 0
		THEN b13_valor_base
		ELSE 0.00
	END AS val_deb,
	CASE WHEN b13_valor_base < 0
		THEN b13_valor_base
		ELSE 0.00
	END AS val_cre
	FROM acero_gm@idsgye01:ctbt012, acero_gm@idsgye01:ctbt013
	WHERE b12_compania          = 1
	  AND b12_estado            = "M"
	  AND YEAR(b12_fec_proceso) = 2013
	  AND b13_compania          = b12_compania
	  AND b13_tipo_comp         = b12_tipo_comp
	  AND b13_num_comp          = b12_num_comp
	  AND b13_cuenta            = "11400101006"
	INTO TEMP tmp_gm;
SELECT b12_tipo_comp AS tp,
	b12_num_comp AS num,
	b13_glosa AS glosa,
	b13_fec_proceso AS fec,
	CASE WHEN b13_valor_base >= 0
		THEN b13_valor_base
		ELSE 0.00
	END AS val_deb,
	CASE WHEN b13_valor_base < 0
		THEN b13_valor_base
		ELSE 0.00
	END AS val_cre
	FROM acero_qm@idsuio01:ctbt012, acero_qm@idsuio01:ctbt013
	WHERE b12_compania          = 1
	  AND b12_estado            = "M"
	  AND YEAR(b12_fec_proceso) = 2013
	  AND b13_compania          = b12_compania
	  AND b13_tipo_comp         = b12_tipo_comp
	  AND b13_num_comp          = b12_num_comp
	  AND b13_cuenta            = "11400101006"
	INTO TEMP tmp_qm;
UNLOAD TO "dia_gye.unl"
	SELECT a.* FROM tmp_gm a
		WHERE NOT EXISTS
			(SELECT 1 FROM tmp_qm b
				WHERE b.val_deb = a.val_cre * (-1));
UNLOAD TO "dia_uio.unl"
	SELECT a.* FROM tmp_qm a
		WHERE NOT EXISTS
			(SELECT 1 FROM tmp_gm b
				WHERE b.val_deb = a.val_cre * (-1));
DROP TABLE tmp_gm;
DROP TABLE tmp_qm;
