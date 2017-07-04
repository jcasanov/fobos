DATABASE acero_gm

MAIN

CALL elimina_contab_trans_bod_99()

END MAIN



FUNCTION elimina_contab_trans_bod_99()
DEFINE r		RECORD LIKE rept040.*
DEFINE r_r19		RECORD LIKE rept019.*
	
DECLARE q1 CURSOR FOR SELECT * FROM rept040
	WHERE r40_cod_tran = 'TR'
	ORDER BY r40_num_tran
FOREACH q1 INTO r.*
	SELECT * INTO r_r19.* FROM rept019
		WHERE r19_compania  = r.r40_compania  AND	
		      r19_localidad = r.r40_localidad AND	
		      r19_cod_tran  = r.r40_cod_tran  AND	
		      r19_num_tran  = r.r40_num_tran
	IF status = NOTFOUND THEN
		DISPLAY 'No existe: ', r.r40_num_tran
		CONTINUE FOREACH
	END IF
	IF r_r19.r19_bodega_ori  = '99' OR
	   r_r19.r19_bodega_dest = '99' THEN
		DISPLAY r.r40_cod_tran, ' ', r.r40_num_tran, ' ',
			r_r19.r19_bodega_ori,  ' ',
			r_r19.r19_bodega_dest, ' ', r_r19.r19_fecing, ' ',
			r_r19.r19_referencia
	END IF
END FOREACH

END FUNCTION
