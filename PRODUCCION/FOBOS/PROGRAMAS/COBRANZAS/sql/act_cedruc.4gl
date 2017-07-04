DATABASE aceros



MAIN

	CALL actualiza()

END MAIN



FUNCTION actualiza()
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE con, tra		LIKE cxct001.z01_num_doc_id
DEFINE i, j, l		SMALLINT
DEFINE ind		VARCHAR(10)

LET con = 'CONSUMIDOR FINA'
LET tra = 'EN TRAMITE'
DECLARE q_z01 CURSOR FOR
	SELECT * FROM cxct001
		WHERE z01_num_doc_id in (con, tra)
		ORDER BY z01_num_doc_id
LET i = 0
LET j = 0
LET l = 0
FOREACH q_z01 INTO r_z01.*
	CASE r_z01.z01_num_doc_id
		WHEN con
			LET i   = i + 1
			LET ind = 'No. ', i USING "&&&", ' '
		WHEN tra
			LET j   = j + 1
			LET ind = 'No. ', j USING "&&&", ' '
	END CASE
	LET l = l + 1
	DISPLAY ind, 'Cliente ', r_z01.z01_codcli, ' ', r_z01.z01_num_doc_id,
		'  antes ...'
	UPDATE cxct001 SET z01_num_doc_id = l
		WHERE z01_codcli = r_z01.z01_codcli
	DISPLAY ind, 'Cliente ', r_z01.z01_codcli, ' ', l, '  después ...'
END FOREACH
DISPLAY 'Reg. actualizados ', l USING "&&&", '  Ok.'

END FUNCTION
