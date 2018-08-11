DATABASE acero_gm

MAIN

CALL arregla_glosa_compras_locales()

END MAIN



FUNCTION arregla_glosa_compras_locales()
DEFINE r		RECORD LIKE rept040.*
DEFINE r_b13		RECORD LIKE ctbt013.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_c13		RECORD LIKE ordt013.*
DEFINE glosa		LIKE ctbt013.b13_glosa

DECLARE q1 CURSOR FOR SELECT * FROM rept040
	WHERE r40_cod_tran = 'CL'
FOREACH q1 INTO r.*
	DISPLAY r.r40_cod_tran, ' ', r.r40_num_tran
	SELECT ordt010.* INTO r_c10.* FROM rept019, ordt010
		WHERE r19_compania   = r.r40_compania  AND 
		      r19_localidad  = r.r40_localidad AND 
		      r19_cod_tran   = r.r40_cod_tran  AND 
		      r19_num_tran   = r.r40_num_tran  AND
		      r19_compania   = c10_compania    AND 
		      r19_localidad  = c10_localidad   AND 
		      r19_oc_interna = c10_numero_oc 
	SELECT * INTO r_p01.* FROM cxpt001
		WHERE p01_codprov = r_c10.c10_codprov
	SELECT * INTO r_c13.* FROM ordt013
		WHERE c13_compania   = r_c10.c10_compania    AND 
		      c13_localidad  = r_c10.c10_localidad   AND 
		      c13_numero_oc  = r_c10.c10_numero_oc   AND
		      DATE(c13_fecing) = DATE(r_c10.c10_fecha_fact)
	IF status = NOTFOUND THEN
		DISPLAY 'No existe...'
	END IF
	LET glosa = r_p01.p01_nomprov[1,19], ' ', r_c13.c13_factura
	DECLARE q2 CURSOR FOR SELECT * FROM ctbt013
		WHERE b13_compania  = r.r40_compania  AND 
		      b13_tipo_comp = r.r40_tipo_comp AND 
		      b13_num_comp  = r.r40_num_comp
	FOREACH q2 INTO r_b13.*
		DISPLAY r_b13.b13_glosa, ' ', glosa
	END FOREACH
	UPDATE ctbt013 SET b13_glosa = glosa
		WHERE b13_compania  = r.r40_compania  AND 
		      b13_tipo_comp = r.r40_tipo_comp AND 
		      b13_num_comp  = r.r40_num_comp
END FOREACH

END FUNCTION
