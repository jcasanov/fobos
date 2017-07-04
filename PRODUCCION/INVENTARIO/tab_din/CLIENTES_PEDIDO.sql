SELECT r19_codcli AS codcli,
	r19_nomcli AS clientes,
	CASE WHEN z01_tipo_doc_id = "C"
		THEN LPAD(z01_num_doc_id, 10, 0)
		ELSE LPAD(z01_num_doc_id, 13, 0)
	END AS cedruc,
	z01_direccion1 AS direccion,
	z01_telefono1 AS telefono,
	r01_iniciales AS vendedor,
	CASE WHEN z01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS estado,
	TRIM(r19_nomcli[1, 40]) || " --> VEND: " || TRIM(r01_nombres) AS cliven
	FROM rept019, rept020, rept001, cxct001
	WHERE r19_compania   = 1
	  AND r19_localidad  = 1
	  AND r19_cod_tran  IN ("FA", "DF", "AF")
	  AND r20_compania   = r19_compania
	  AND r20_localidad  = r19_localidad
	  AND r20_cod_tran   = r19_cod_tran
	  AND r20_num_tran   = r19_num_tran
	  AND r20_linea      = "7"
	  AND r01_compania   = r19_compania
	  AND r01_codigo     = r19_vendedor
	  AND z01_codcli     = r19_codcli
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8;
