DATABASE diteca

MAIN

CALL act_num_ret_recep_oc()

END MAIN



FUNCTION act_num_ret_recep_oc()
DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE r_c10		RECORD LIKE ordt010.*

DECLARE q1 CURSOR FOR SELECT * FROM ordt013
	WHERE c13_num_ret IS NULL
	ORDER BY c13_fecing
FOREACH q1 INTO r_c13.*
	DISPLAY r_c13.c13_numero_oc
	SELECT * INTO r_c10.* FROM ordt010
		WHERE c10_compania  = r_c13.c13_compania  AND 	
		      c10_localidad = r_c13.c13_localidad AND 	
		      c10_numero_oc = r_c13.c13_numero_oc
	IF status = NOTFOUND THEN
		DISPLAY 'No existe OC: ', r_c13.c13_numero_oc
		CONTINUE FOREACH
	END IF
	SELECT UNIQUE p28_num_ret INTO r_c13.c13_num_ret FROM cxpt028
		WHERE p28_compania  = r_c13.c13_compania  AND 	
		      p28_localidad = r_c13.c13_localidad AND 	
		      p28_codprov   = r_c10.c10_codprov   AND
		      p28_num_doc   = r_c13.c13_factura
	IF status = NOTFOUND THEN
		CONTINUE FOREACH
	END IF
	UPDATE ordt013 SET c13_num_ret = r_c13.c13_num_ret
		WHERE c13_compania  = r_c13.c13_compania  AND 	
		      c13_localidad = r_c13.c13_localidad AND 	
		      c13_numero_oc = r_c13.c13_numero_oc AND
		      c13_num_recep = r_c13.c13_num_recep
END FOREACH

END FUNCTION
