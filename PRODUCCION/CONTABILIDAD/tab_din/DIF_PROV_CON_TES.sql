SELECT p01_codprov AS codigo,
	p01_nomprov AS proveedor,
	NVL((SELECT SUM(p20_saldo_cap + p20_saldo_int)
		FROM cxpt020
		WHERE p20_compania = 1
		  AND p20_codprov  = p01_codprov), 0.00) -
	NVL((SELECT SUM(p21_saldo)
		FROM cxpt021
		WHERE p21_compania = 1
		  AND p21_codprov  = p01_codprov), 0.00) AS saldo_tes,
	NVL((SELECT SUM(b13_valor_base)
		FROM ctbt013, ctbt012
		WHERE b13_compania  = 1
		  AND b13_codprov   = p01_codprov
		  AND b13_cuenta    = "21010101001"
		  AND b12_compania  = b13_compania
		  AND b12_tipo_comp = b13_tipo_comp
		  AND b12_num_comp  = b13_num_comp
		  AND b12_estado    = "M"), 0.00) AS saldo_cont,
	(NVL((SELECT SUM(p20_saldo_cap + p20_saldo_int)
		FROM cxpt020
		WHERE p20_compania = 1
		  AND p20_codprov  = p01_codprov), 0.00) -
	NVL((SELECT SUM(p21_saldo)
		FROM cxpt021
		WHERE p21_compania = 1
		  AND p21_codprov  = p01_codprov), 0.00)) +
	(NVL((SELECT SUM(b13_valor_base)
		FROM ctbt013, ctbt012
		WHERE b13_compania  = 1
		  AND b13_codprov   = p01_codprov
		  AND b13_cuenta    = "21010101001"
		  AND b12_compania  = b13_compania
		  AND b12_tipo_comp = b13_tipo_comp
		  AND b12_num_comp  = b13_num_comp
		  AND b12_estado    = "M"), 0.00)) AS diferencia,
	CASE WHEN p01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS estado
	FROM cxpt001
	WHERE (NVL((SELECT SUM(p20_saldo_cap + p20_saldo_int)
		FROM cxpt020
		WHERE p20_compania = 1
		  AND p20_codprov  = p01_codprov), 0.00) -
		NVL((SELECT SUM(p21_saldo)
			FROM cxpt021
			WHERE p21_compania = 1
			  AND p21_codprov  = p01_codprov), 0.00)) +
		(NVL((SELECT SUM(b13_valor_base)
			FROM ctbt013, ctbt012
			WHERE b13_compania  = 1
			  AND b13_codprov   = p01_codprov
			  AND b13_cuenta    = "21010101001"
			  AND b12_compania  = b13_compania
			  AND b12_tipo_comp = b13_tipo_comp
			  AND b12_num_comp  = b13_num_comp
			  AND b12_estado    = "M"), 0.00)) <> 0.00
	ORDER BY 2 ASC;
