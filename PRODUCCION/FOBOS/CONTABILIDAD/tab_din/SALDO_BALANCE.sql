SELECT b13_cuenta AS cuenta,
	b10_descripcion AS nom_cta,
	NVL(SUM(b13_valor_base), 0.00) AS saldo
	FROM ctbt012, ctbt013, ctbt010
	WHERE b12_compania      = 1
	  AND b12_estado        = "M"
	  AND b12_fec_proceso  <= MDY(01, 01, 2011) + 1 UNITS MONTH
					- 1 UNITS DAY
	  AND NOT EXISTS
		(SELECT 1 FROM ctbt050
			WHERE b50_compania  = b12_compania
			  AND b50_tipo_comp = b12_tipo_comp
			  AND b50_num_comp  = b12_num_comp)
	  AND b13_compania      = b12_compania
	  AND b13_tipo_comp     = b12_tipo_comp
	  AND b13_num_comp      = b12_num_comp
	  AND b13_cuenta[1, 1] IN ("1", "2", "3")
	  AND b10_compania      = b13_compania
	  AND b10_cuenta        = b13_cuenta
	GROUP BY 1, 2
UNION
SELECT b13_cuenta[1, 8] AS cuenta,
	b10_descripcion AS nom_cta,
	NVL(SUM(b13_valor_base), 0.00) AS saldo
	FROM ctbt012, ctbt013, ctbt010
	WHERE b12_compania      = 1
	  AND b12_estado        = "M"
	  AND b12_fec_proceso  <= MDY(01, 01, 2011) + 1 UNITS MONTH
					- 1 UNITS DAY
	  AND NOT EXISTS
		(SELECT 1 FROM ctbt050
			WHERE b50_compania  = b12_compania
			  AND b50_tipo_comp = b12_tipo_comp
			  AND b50_num_comp  = b12_num_comp)
	  AND b13_compania      = b12_compania
	  AND b13_tipo_comp     = b12_tipo_comp
	  AND b13_num_comp      = b12_num_comp
	  AND b13_cuenta[1, 1] IN ("1", "2", "3")
	  AND b10_compania      = b13_compania
	  AND b10_cuenta[1, 8]  = b13_cuenta[1, 8]
	GROUP BY 1, 2
UNION
SELECT b13_cuenta[1, 8] AS cuenta,
	b10_descripcion AS nom_cta,
	NVL(SUM(b13_valor_base), 0.00) AS saldo
	FROM ctbt012, ctbt013, ctbt010
	WHERE b12_compania      = 1
	  AND b12_estado        = "M"
	  AND b12_fec_proceso  <= MDY(01, 01, 2011) + 1 UNITS MONTH
					- 1 UNITS DAY
	  AND NOT EXISTS
		(SELECT 1 FROM ctbt050
			WHERE b50_compania  = b12_compania
			  AND b50_tipo_comp = b12_tipo_comp
			  AND b50_num_comp  = b12_num_comp)
	  AND b13_compania      = b12_compania
	  AND b13_tipo_comp     = b12_tipo_comp
	  AND b13_num_comp      = b12_num_comp
	  AND b13_cuenta[1, 1] IN ("1", "2", "3")
	  AND b10_compania      = b13_compania
	  AND b10_cuenta[1, 6]  = b13_cuenta[1, 6]
	GROUP BY 1, 2
UNION
SELECT b13_cuenta[1, 8] AS cuenta,
	b10_descripcion AS nom_cta,
	NVL(SUM(b13_valor_base), 0.00) AS saldo
	FROM ctbt012, ctbt013, ctbt010
	WHERE b12_compania      = 1
	  AND b12_estado        = "M"
	  AND b12_fec_proceso  <= MDY(01, 01, 2011) + 1 UNITS MONTH
					- 1 UNITS DAY
	  AND NOT EXISTS
		(SELECT 1 FROM ctbt050
			WHERE b50_compania  = b12_compania
			  AND b50_tipo_comp = b12_tipo_comp
			  AND b50_num_comp  = b12_num_comp)
	  AND b13_compania      = b12_compania
	  AND b13_tipo_comp     = b12_tipo_comp
	  AND b13_num_comp      = b12_num_comp
	  AND b13_cuenta[1, 1] IN ("1", "2", "3")
	  AND b10_compania      = b13_compania
	  AND b10_cuenta[1, 4]  = b13_cuenta[1, 4]
	GROUP BY 1, 2
UNION
SELECT b13_cuenta[1, 8] AS cuenta,
	b10_descripcion AS nom_cta,
	NVL(SUM(b13_valor_base), 0.00) AS saldo
	FROM ctbt012, ctbt013, ctbt010
	WHERE b12_compania      = 1
	  AND b12_estado        = "M"
	  AND b12_fec_proceso  <= MDY(01, 01, 2011) + 1 UNITS MONTH
					- 1 UNITS DAY
	  AND NOT EXISTS
		(SELECT 1 FROM ctbt050
			WHERE b50_compania  = b12_compania
			  AND b50_tipo_comp = b12_tipo_comp
			  AND b50_num_comp  = b12_num_comp)
	  AND b13_compania      = b12_compania
	  AND b13_tipo_comp     = b12_tipo_comp
	  AND b13_num_comp      = b12_num_comp
	  AND b13_cuenta[1, 1] IN ("1", "2", "3")
	  AND b10_compania      = b13_compania
	  AND b10_cuenta[1, 2]  = b13_cuenta[1, 2]
	GROUP BY 1, 2
UNION
SELECT b13_cuenta[1, 8] AS cuenta,
	b10_descripcion AS nom_cta,
	NVL(SUM(b13_valor_base), 0.00) AS saldo
	FROM ctbt012, ctbt013, ctbt010
	WHERE b12_compania      = 1
	  AND b12_estado        = "M"
	  AND b12_fec_proceso  <= MDY(01, 01, 2011) + 1 UNITS MONTH
					- 1 UNITS DAY
	  AND NOT EXISTS
		(SELECT 1 FROM ctbt050
			WHERE b50_compania  = b12_compania
			  AND b50_tipo_comp = b12_tipo_comp
			  AND b50_num_comp  = b12_num_comp)
	  AND b13_compania      = b12_compania
	  AND b13_tipo_comp     = b12_tipo_comp
	  AND b13_num_comp      = b12_num_comp
	  AND b13_cuenta[1, 1] IN ("1", "2", "3")
	  AND b10_compania      = b13_compania
	  AND b10_cuenta[1, 1]  = b13_cuenta[1, 1]
	GROUP BY 1, 2;
