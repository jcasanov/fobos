SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_gm@idsgye01:gent002
		WHERE g02_compania  = z20_compania
		  AND g02_localidad = z20_localidad) AS local,
	z20_codcli AS codcli,
	z01_nomcli AS nomcli,
	z01_num_doc_id AS cdruc,
	z01_direccion1 AS direc,
	z01_telefono1 AS telcli,
	z20_tipo_doc AS tipdoc,
	z20_num_doc AS numdoc,
	z20_dividendo AS divi,
	YEAR(z20_fecha_emi) AS anio,
	z20_fecha_emi AS fecemi,
	z20_fecha_vcto AS fecvcto,
	(z20_valor_cap + z20_valor_int) AS valo,
	(z20_saldo_cap + z20_saldo_int) AS sald,
	TO_CHAR(z20_fecha_emi, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(z20_fecha_emi)), 2, 0) AS num_sem,
	CASE WHEN z01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END as est
	FROM acero_gm@idsgye01:cxct020, acero_gm@idsgye01:cxct001
	WHERE   z20_compania                   = 1
	  AND ((z20_tipo_doc                   = "FA"
	  AND   YEAR(z20_fecha_emi)            > 2011
	  AND   z20_saldo_cap + z20_saldo_int  = 0)
	   OR   z20_saldo_cap + z20_saldo_int <> 0)
	  AND   z01_codcli                     = z20_codcli
UNION
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_gm@idsgye01:gent002
		WHERE g02_compania  = z21_compania
		  AND g02_localidad = z21_localidad) AS local,
	z21_codcli AS codcli,
	z01_nomcli AS nomcli,
	z01_num_doc_id AS cdruc,
	z01_direccion1 AS direc,
	z01_telefono1 AS telcli,
	z21_tipo_doc AS tipdoc,
	z21_num_doc || ""  AS numdoc,
	1 AS divi,
	YEAR(z21_fecha_emi) AS anio,
	z21_fecha_emi AS fecemi,
	z21_fecha_emi AS fecvcto,
	z21_valor AS valo,
	z21_saldo AS sald,
	TO_CHAR(z21_fecha_emi, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(z21_fecha_emi)), 2, 0) AS num_sem,
	CASE WHEN z01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END as est
	FROM acero_gm@idsgye01:cxct021, acero_gm@idsgye01:cxct001
	WHERE   z21_compania         = 1
	  AND ((z21_tipo_doc         = "NC"
	  AND   YEAR(z21_fecha_emi)  > 2011
	  AND   z21_saldo            = 0)
	   OR   z21_saldo           <> 0)
	  AND   z01_codcli           = z21_codcli
UNION
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_qm@acgyede:gent002
		WHERE g02_compania  = z20_compania
		  AND g02_localidad = z20_localidad) AS local,
	z20_codcli AS codcli,
	z01_nomcli AS nomcli,
	z01_num_doc_id AS cdruc,
	z01_direccion1 AS direc,
	z01_telefono1 AS telcli,
	z20_tipo_doc AS tipdoc,
	z20_num_doc AS numdoc,
	z20_dividendo AS divi,
	YEAR(z20_fecha_emi) AS anio,
	z20_fecha_emi AS fecemi,
	z20_fecha_vcto AS fecvcto,
	(z20_valor_cap + z20_valor_int) AS valo,
	(z20_saldo_cap + z20_saldo_int) AS sald,
	TO_CHAR(z20_fecha_emi, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(z20_fecha_emi)), 2, 0) AS num_sem,
	CASE WHEN z01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END as est
	FROM acero_qm@acgyede:cxct020, acero_qm@acgyede:cxct001
	WHERE   z20_compania                   = 1
	  AND ((z20_tipo_doc                   = "FA"
	  AND   YEAR(z20_fecha_emi)            > 2011
	  AND   z20_saldo_cap + z20_saldo_int  = 0)
	   OR   z20_saldo_cap + z20_saldo_int <> 0)
	  AND   z01_codcli                     = z20_codcli
UNION
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_qm@acgyede:gent002
		WHERE g02_compania  = z21_compania
		  AND g02_localidad = z21_localidad) AS local,
	z21_codcli AS codcli,
	z01_nomcli AS nomcli,
	z01_num_doc_id AS cdruc,
	z01_direccion1 AS direc,
	z01_telefono1 AS telcli,
	z21_tipo_doc AS tipdoc,
	z21_num_doc || ""  AS numdoc,
	1 AS divi,
	YEAR(z21_fecha_emi) AS anio,
	z21_fecha_emi AS fecemi,
	z21_fecha_emi AS fecvcto,
	z21_valor AS valo,
	z21_saldo AS sald,
	TO_CHAR(z21_fecha_emi, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(z21_fecha_emi)), 2, 0) AS num_sem,
	CASE WHEN z01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END as est
	FROM acero_qm@acgyede:cxct021, acero_qm@acgyede:cxct001
	WHERE   z21_compania         = 1
	  AND ((z21_tipo_doc         = "NC"
	  AND   YEAR(z21_fecha_emi)  > 2011
	  AND   z21_saldo            = 0)
	   OR   z21_saldo           <> 0)
	  AND   z01_codcli           = z21_codcli;
