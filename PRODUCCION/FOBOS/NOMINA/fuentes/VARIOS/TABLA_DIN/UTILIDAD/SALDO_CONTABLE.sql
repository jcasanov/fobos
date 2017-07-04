SELECT 1 AS local,
	YEAR(b12_fec_proceso) AS anio,
	NVL(ROUND(SUM(b13_valor_base), 2), 0) AS utilidad,
	CASE WHEN 1 = 1 THEN "+" ELSE "/" END AS c
	FROM aceros@acgyede:ctbt012, aceros@acgyede:ctbt013
	WHERE b12_compania     = 1
	  AND b12_estado       = "M"
	  AND b12_fec_proceso  BETWEEN MDY(01, 01, 2006)
				   AND TODAY - 1 UNITS DAY
	  AND b13_compania     = b12_compania
	  AND b13_tipo_comp    = b12_tipo_comp
	  AND b13_num_comp     = b12_num_comp
	  AND b13_cuenta[1, 1] NOT IN ("1", "2", "3")
	  AND NOT EXISTS
		(SELECT 1 FROM aceros@acgyede:ctbt050
			WHERE b50_compania  = b12_compania
			  AND b50_tipo_comp = b12_tipo_comp
			  AND b50_num_comp  = b12_num_comp
			  AND b50_anio      = YEAR(b12_fec_proceso))
	GROUP BY 1, 2, 4
UNION
SELECT 3 AS local,
	YEAR(b12_fec_proceso) AS anio,
	NVL(ROUND(SUM(b13_valor_base), 2), 0) AS utilidad,
	CASE WHEN 1 = 1 THEN "+" ELSE "/" END AS c
	FROM acero_qm@acgyede:ctbt012, acero_qm@acgyede:ctbt013
	WHERE b12_compania     = 1
	  AND b12_estado       = "M"
	  AND b12_fec_proceso  BETWEEN MDY(01, 01, 2006)
				   AND TODAY - 1 UNITS DAY
	  AND b13_compania     = b12_compania
	  AND b13_tipo_comp    = b12_tipo_comp
	  AND b13_num_comp     = b12_num_comp
	  AND b13_cuenta[1, 1] NOT IN ("1", "2", "3")
	  AND NOT EXISTS
		(SELECT 1 FROM acero_qm@acgyede:ctbt050
			WHERE b50_compania  = b12_compania
			  AND b50_tipo_comp = b12_tipo_comp
			  AND b50_num_comp  = b12_num_comp
			  AND b50_anio      = YEAR(b12_fec_proceso))
	GROUP BY 1, 2, 4;
