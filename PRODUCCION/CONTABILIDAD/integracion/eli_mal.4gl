DATABASE acero_gm

MAIN

CALL elimina_diarios_inv_malos()

END MAIN



FUNCTION elimina_diarios_inv_malos()
DEFINE r_r40		RECORD LIKE rept040.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE numreg		INTEGER

DECLARE q1 CURSOR FOR SELECT ROWID, * FROM rept040
	WHERE r40_cod_tran IN ('FA','DF','AF')
FOREACH q1 INTO numreg, r_r40.*
	SELECT * INTO r_r19.* FROM rept019
		WHERE r19_compania  = r_r40.r40_compania  AND 
		      r19_localidad = r_r40.r40_localidad AND 
		      r19_cod_tran  = r_r40.r40_cod_tran  AND 
		      r19_num_tran  = r_r40.r40_num_tran
	IF status = NOTFOUND THEN
		CONTINUE FOREACH
	END IF
	IF MONTH(r_r19.r19_fecing) > 2 THEN
		CONTINUE FOREACH
	END IF
	DISPLAY r_r40.r40_cod_tran, ' ', r_r40.r40_num_tran
	DELETE FROM ctbt013 
		WHERE b13_compania  = r_r40.r40_compania  AND 
		      b13_tipo_comp = r_r40.r40_tipo_comp AND 
		      b13_num_comp  = r_r40.r40_num_comp
	DELETE FROM ctbt012 
		WHERE b12_compania  = r_r40.r40_compania  AND 
		      b12_tipo_comp = r_r40.r40_tipo_comp AND 
		      b12_num_comp  = r_r40.r40_num_comp
	DELETE FROM rept040		
		WHERE ROWID = numreg
END FOREACH

END FUNCTION
