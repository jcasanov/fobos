SELECT (SELECT g02_abreviacion
		FROM acero_gm@idsgye01:gent002
		WHERE g02_compania  = b12_compania
		  AND g02_localidad = 1) AS local,
	NVL(ROUND(SUM(b13_valor_base), 2), 0) AS utilidad,
	CASE WHEN 1 = 1 THEN "+" ELSE "/" END AS c
	FROM acero_gm@idsgye01:ctbt012, acero_gm@idsgye01:ctbt013
	WHERE b12_compania                      = 1
	  AND b12_estado                        = "M"
	  AND YEAR(b12_fec_proceso)             = 2014
	  AND b12_compania || b12_tipo_comp || b12_num_comp
		NOT IN
		(SELECT b50_compania || b50_tipo_comp || b50_num_comp
			FROM acero_gm@idsgye01:ctbt050
			WHERE b50_anio = 2014)
	  AND b13_compania                      = b12_compania
	  AND b13_tipo_comp                     = b12_tipo_comp
	  AND b13_num_comp                      = b12_num_comp
	  AND CAST(b13_cuenta[1, 1] AS INTEGER) > 3
	GROUP BY 1, 3
UNION
SELECT (SELECT g02_abreviacion
		FROM acero_qm@idsuio01:gent002
		WHERE g02_compania  = b12_compania
		  AND g02_localidad = 3) AS local,
	NVL(ROUND(SUM(b13_valor_base), 2), 0) AS utilidad,
	CASE WHEN 1 = 1 THEN "+" ELSE "/" END AS c
	FROM acero_qm@idsuio01:ctbt012, acero_qm@idsuio01:ctbt013
	WHERE b12_compania                      = 1
	  AND b12_estado                        = "M"
	  AND YEAR(b12_fec_proceso)             = 2014
	  AND b12_compania || b12_tipo_comp || b12_num_comp
		NOT IN
		(SELECT b50_compania || b50_tipo_comp || b50_num_comp
			FROM acero_qm@idsuio01:ctbt050
			WHERE b50_anio = 2014)
	  AND b13_compania                      = b12_compania
	  AND b13_tipo_comp                     = b12_tipo_comp
	  AND b13_num_comp                      = b12_num_comp
	  AND CAST(b13_cuenta[1, 1] AS INTEGER) > 3
	GROUP BY 1, 3;
