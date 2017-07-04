DATABASE acero_gm

MAIN

CALL arregla_glosa_pagos_facturas()

END MAIN



FUNCTION arregla_glosa_pagos_facturas()
DEFINE r		RECORD LIKE cxct040.*
DEFINE r_z23		RECORD LIKE cxct023.*
DEFINE glosa		LIKE ctbt012.b12_glosa

DECLARE q1 CURSOR FOR SELECT * FROM cxct040
	WHERE z40_tipo_doc = 'PG'
FOREACH q1 INTO r.*
	DISPLAY r.z40_tipo_doc, ' ', r.z40_num_doc
	DECLARE q2 CURSOR FOR SELECT * FROM cxct023
		WHERE z23_compania  = r.z40_compania  AND 
                      z23_localidad = r.z40_localidad AND 
                      z23_codcli    = r.z40_codcli    AND 
                      z23_tipo_trn  = r.z40_tipo_doc  AND 
                      z23_num_trn   = r.z40_num_doc 
		ORDER BY z23_orden
	LET glosa = 'PAGO: ', r.z40_tipo_doc, '-', r.z40_num_doc
			USING '<<<<&', '  ***'
	FOREACH q2 INTO r_z23.*
		LET glosa = glosa CLIPPED, '  ', 
			    r_z23.z23_tipo_doc, ' ',
			    r_z23.z23_num_doc CLIPPED, '-',
			    r_z23.z23_div_doc USING '&&'
	END FOREACH
	DISPLAY glosa
	UPDATE ctbt012 SET b12_glosa = glosa
		WHERE b12_compania  = r.z40_compania  AND 
		      b12_tipo_comp = r.z40_tipo_comp AND 
		      b12_num_comp  = r.z40_num_comp
END FOREACH

END FUNCTION
