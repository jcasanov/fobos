SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM gent002
		WHERE g02_compania  = 1
		  AND g02_localidad = 1) AS local,
	g07_user AS usua,
	g05_nombres AS nom_usu,
	g07_impresora AS impr,
	g06_nombre AS nom_imp,
	CASE WHEN g07_default = "S"
		THEN "X"
		ELSE ""
	END AS imp_def,
	CASE WHEN g07_default = "S"
		THEN "X"
		ELSE "X"
	END AS imp_asi,
	CASE WHEN g05_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est_usu
	FROM gent007, gent006, gent005
	WHERE g06_impresora = g07_impresora
	  AND g05_usuario   = g07_user
UNION
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_gc:gent002
		WHERE g02_compania  = 1
		  AND g02_localidad = 2) AS local,
	g07_user AS usua,
	g05_nombres AS nom_usu,
	g07_impresora AS impr,
	g06_nombre AS nom_imp,
	CASE WHEN g07_default = "S"
		THEN "X"
		ELSE ""
	END AS imp_def,
	CASE WHEN g07_default = "S"
		THEN "X"
		ELSE "X"
	END AS imp_asi,
	CASE WHEN g05_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est_usu
	FROM acero_gc:gent007, acero_gc:gent006, acero_gc:gent005
	WHERE g06_impresora = g07_impresora
	  AND g05_usuario   = g07_user
UNION
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_qm@acgyede:gent002
		WHERE g02_compania  = 1
		  AND g02_localidad = 3) AS local,
	g07_user AS usua,
	g05_nombres AS nom_usu,
	g07_impresora AS impr,
	g06_nombre AS nom_imp,
	CASE WHEN g07_default = "S"
		THEN "X"
		ELSE ""
	END AS imp_def,
	CASE WHEN g07_default = "S"
		THEN "X"
		ELSE "X"
	END AS imp_asi,
	CASE WHEN g05_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est_usu
	FROM acero_qm@acgyede:gent007, acero_qm@acgyede:gent006,
		acero_qm@acgyede:gent005
	WHERE g06_impresora = g07_impresora
	  AND g05_usuario   = g07_user
UNION
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_qs@acgyede:gent002
		WHERE g02_compania  = 1
		  AND g02_localidad = 4) AS local,
	g07_user AS usua,
	g05_nombres AS nom_usu,
	g07_impresora AS impr,
	g06_nombre AS nom_imp,
	CASE WHEN g07_default = "S"
		THEN "X"
		ELSE ""
	END AS imp_def,
	CASE WHEN g07_default = "S"
		THEN "X"
		ELSE "X"
	END AS imp_asi,
	CASE WHEN g05_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est_usu
	FROM acero_qs@acgyede:gent007, acero_qs@acgyede:gent006,
		acero_qs@acgyede:gent005
	WHERE g06_impresora = g07_impresora
	  AND g05_usuario   = g07_user;
