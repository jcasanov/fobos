SELECT z01_codcli AS codigo,
	z01_num_doc_id AS cedruc,
	Z01_nomcli AS clientes,
	z01_direccion1 AS direccion,
	z01_telefono1 AS telefono,
	CASE WHEN z01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS estado
	FROM cxct001
	ORDER BY 2 ASC;

SELECT r19_codcli AS codcli,
	r19_vendedor AS codven,
	r01_nombres AS vendedor,
	MAX(r19_fecing) AS fecing,
	CASE WHEN r01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS estado
	FROM rept019, rept001
	WHERE r19_compania   = 1
	  AND r19_localidad  = 1
	  AND r19_cod_tran  IN ("FA", "DF", "AF")
	  AND r01_compania   = r19_compania 
	  AND r01_codigo     = r19_vendedor
	  AND r01_nombres   NOT LIKE "%ACERO%"
	GROUP BY 1, 2, 3, 5
	ORDER BY 4 DESC, 3 ASC;
