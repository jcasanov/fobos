DATABASE diteca

MAIN

BEGIN WORK
CALL elimina_comprob_malos()
COMMIT WORK

END MAIN



FUNCTION elimina_comprob_malos()
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE i		SMALLINT

DECLARE q1 CURSOR FOR SELECT * FROM ctbt012
	WHERE DATE(b12_fecing) = TODAY AND b12_tipo_comp = 'DR'
LET i = 0
FOREACH q1 INTO r_b12.*
	DELETE FROM rept040
		WHERE r40_compania  = r_b12.b12_compania  AND
		      r40_tipo_comp = r_b12.b12_tipo_comp AND
		      r40_num_comp  = r_b12.b12_num_comp AND
		      r40_cod_tran  = 'DF'
	DELETE FROM ctbt013 
	            WHERE b13_compania  = r_b12.b12_compania  AND 
                          b13_tipo_comp = r_b12.b12_tipo_comp AND 
                          b13_num_comp  = r_b12.b12_num_comp 
        DELETE FROM ctbt012 
		    WHERE b12_compania  = r_b12.b12_compania  AND 
                          b12_tipo_comp = r_b12.b12_tipo_comp AND 
                          b12_num_comp  = r_b12.b12_num_comp 
END FOREACH

END FUNCTION
