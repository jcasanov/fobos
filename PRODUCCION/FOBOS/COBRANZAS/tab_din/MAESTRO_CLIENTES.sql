SELECT LPAD(z02_localidad, 2, 0) || " " || TRIM(g02_abreviacion) AS loc,
	z01_codcli,
	z01_estado,
	z01_nomcli,
	z01_direccion1,
	z01_telefono1,
	z01_telefono2,
	z01_personeria,
	z01_tipo_doc_id,
	z01_num_doc_id,
	z01_rep_legal,
	z01_paga_impto,
	z02_localidad,
	z02_contacto,
	z02_referencia,
	z02_credit_dias,
	z02_cupocred_mb,
	z02_zona_cobro,
	z06_nombre AS cobrad,
	CASE WHEN z01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est
	FROM acero_gm@idsgye01:cxct001, acero_gm@idsgye01:cxct002,
		acero_gm@idsgye01:cxct006, acero_gm@idsgye01:gent002
	WHERE z02_compania   = 1
	  AND z02_codcli     = z01_codcli
	  AND z06_zona_cobro = z02_zona_cobro
	  AND g02_compania   = z02_compania
	  AND g02_localidad  = z02_localidad
UNION ALL
SELECT LPAD(z02_localidad, 2, 0) || " " || TRIM(g02_abreviacion) AS loc,
	z01_codcli,
	z01_estado,
	z01_nomcli,
	z01_direccion1,
	z01_telefono1,
	z01_telefono2,
	z01_personeria,
	z01_tipo_doc_id,
	z01_num_doc_id,
	z01_rep_legal,
	z01_paga_impto,
	z02_localidad,
	z02_contacto,
	z02_referencia,
	z02_credit_dias,
	z02_cupocred_mb,
	z02_zona_cobro,
	z06_nombre AS cobrad,
	CASE WHEN z01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est
	FROM acero_qm@idsuio01:cxct001, acero_qm@idsuio01:cxct002,
		acero_qm@idsuio01:cxct006, acero_qm@idsuio01:gent002
	WHERE z02_compania   = 1
	  AND z02_codcli     = z01_codcli
	  AND z06_zona_cobro = z02_zona_cobro
	  AND g02_compania   = z02_compania
	  AND g02_localidad  = z02_localidad
UNION ALL
SELECT LPAD(z02_localidad, 2, 0) || " " || TRIM(g02_abreviacion) AS loc,
	z01_codcli,
	z01_estado,
	z01_nomcli,
	z01_direccion1,
	z01_telefono1,
	z01_telefono2,
	z01_personeria,
	z01_tipo_doc_id,
	z01_num_doc_id,
	z01_rep_legal,
	z01_paga_impto,
	z02_localidad,
	z02_contacto,
	z02_referencia,
	z02_credit_dias,
	z02_cupocred_mb,
	z02_zona_cobro,
	z06_nombre AS cobrad,
	CASE WHEN z01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est
	FROM acero_qs@idsuio02:cxct001, acero_qs@idsuio02:cxct002,
		acero_qs@idsuio02:cxct006, acero_qs@idsuio02:gent002
	WHERE z02_compania   = 1
	  AND z02_localidad  = 4
	  AND z02_codcli     = z01_codcli
	  AND z06_zona_cobro = z02_zona_cobro
	  AND g02_compania   = z02_compania
	  AND g02_localidad  = z02_localidad
