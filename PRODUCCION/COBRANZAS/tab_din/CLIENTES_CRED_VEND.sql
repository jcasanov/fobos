SELECT r19_codcli AS codigo,
	r19_nomcli AS cliente,
	CASE WHEN z01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS estado,
	r01_nombres AS vendedor
	FROM rept019, rept001, cxct001
	WHERE r19_compania      = 1
	  AND r19_localidad     = 1
	  AND r19_cod_tran      = "FA"
	  AND r19_cont_cred     = "R"
	  AND YEAR(r19_fecing) >= 2009
	  AND r01_compania      = r19_compania
	  AND r01_codigo        = r19_vendedor
	  AND z01_codcli        = r19_codcli
	GROUP BY 1, 2, 3, 4
	ORDER BY 2, 4;
