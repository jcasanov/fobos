DATABASE acero_gm

MAIN

CALL corrige_cta_cobranzas_centro()

END MAIN



FUNCTION corrige_cta_cobranzas_centro()
DEFINE r		RECORD LIKE cxct040.*

DECLARE q1 CURSOR FOR SELECT * FROM cxct040
	WHERE z40_localidad = 2 AND z40_tipo_doc = 'PG'
FOREACH q1 INTO r.*
	UPDATE ctbt013 SET b13_cuenta = '11010101008'
		WHERE b13_compania  = r.z40_compania  AND	
		      b13_tipo_comp = r.z40_tipo_comp AND	
		      b13_num_comp  = r.z40_num_comp  AND	
		      b13_cuenta  IN ('11010101006','11010101007')
END FOREACH

END FUNCTION
