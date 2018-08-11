SELECT "01 J T M" AS localidad,
	z01_codcli,
	z01_nomcli,
	z01_tipo_doc_id,
	z01_num_doc_id,
	z01_direccion1,
	z01_telefono1,
	z01_telefono2
	FROM acero_gm@idsgye01:cxct001
	WHERE z01_estado     = "A"
UNION
SELECT "03 MATRIZ UIO" AS localidad,
	z01_codcli,
	z01_nomcli,
	z01_tipo_doc_id,
	z01_num_doc_id,
	z01_direccion1,
	z01_telefono1,
	z01_telefono2
	FROM acero_qm@idsuio01:cxct001
	WHERE z01_estado     = "A"
UNION
SELECT "04 ACERO SUR" AS localidad,
	z01_codcli,
	z01_nomcli,
	z01_tipo_doc_id,
	z01_num_doc_id,
	z01_direccion1,
	z01_telefono1,
	z01_telefono2
	FROM acero_qs@idsuio02:cxct001
	WHERE z01_estado     = "A";
