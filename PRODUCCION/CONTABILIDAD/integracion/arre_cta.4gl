DATABASE acero_gm

MAIN

CALL arregla_cta_dev_costo()

END MAIN



FUNCTION arregla_cta_dev_costo()
DEFINE r		RECORD LIKE ctbt013.*
DEFINE numreg		INTEGER

DECLARE q1 CURSOR FOR SELECT ctbt013.ROWID, ctbt013.* FROM ctbt012, ctbt013 
	WHERE b12_tipo_comp = 'DR' AND b12_subtipo IN (53) AND
	      b13_cuenta = '11400101001' AND 
	      b12_compania  = b13_compania AND 
	      b12_tipo_comp = b13_tipo_comp AND 
	      b12_num_comp  = b13_num_comp
FOREACH q1 INTO numreg, r.*
	DISPLAY r.b13_cuenta, ' ', r.b13_valor_base
	IF r.b13_valor_base > 0 THEN
		DISPLAY 'Error: valor positivo.'
	END IF
	UPDATE ctbt013 SET b13_cuenta = '11400101002'
		WHERE ROWID = numreg
END FOREACH

END FUNCTION
