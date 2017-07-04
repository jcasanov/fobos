DATABASE acero_gm

MAIN

CALL arregla_diario_pagos_tarjeta_credito()

END MAIN



FUNCTION arregla_diario_pagos_tarjeta_credito()
DEFINE r		RECORD LIKE cxct040.*
DEFINE r_z02		RECORD LIKE cxct002.*
DEFINE r_b13		RECORD LIKE ctbt013.*
DEFINE cuenta		LIKE ctbt013.b13_cuenta

DECLARE q1 CURSOR FOR SELECT * FROM cxct040
	WHERE z40_tipo_doc = 'PG' AND z40_codcli <= 10 
FOREACH q1 INTO r.*
	DISPLAY r.z40_codcli
	SELECT * INTO r_z02.* FROM cxct002
		WHERE z02_compania  = r.z40_compania  AND 
		      z02_localidad = r.z40_localidad AND 
		      z02_codcli    = r.z40_codcli
	IF status = NOTFOUND THEN
		DISPLAY 'No existe en cxct002...'
		CONTINUE FOREACH
	END IF
	DECLARE q2 CURSOR FOR SELECT * FROM ctbt013
		WHERE b13_compania  = r.z40_compania AND 
		      b13_tipo_comp = r.z40_tipo_comp AND 
		      b13_num_comp  = r.z40_num_comp 
		ORDER BY b13_cuenta
	FOREACH q2 INTO r_b13.*
		IF r_b13.b13_cuenta = '11210101001' THEN
			UPDATE ctbt013 SET b13_cuenta = r_z02.z02_aux_clte_mb
				WHERE b13_compania  = r.z40_compania AND 
		      		      b13_tipo_comp = r.z40_tipo_comp AND 
		      		      b13_num_comp  = r.z40_num_comp AND
				      b13_cuenta    = '11210101001'
		END IF
		IF r_b13.b13_cuenta = r_z02.z02_aux_clte_mb THEN
			LET cuenta = r_z02.z02_aux_clte_mb
		ELSE
			LET cuenta = NULL
		END IF
		DISPLAY r_b13.b13_tipo_comp, '-', r_b13.b13_num_comp, ' ',
			r_b13.b13_cuenta, ' ', cuenta, ' ',
			r_b13.b13_fec_proceso
	END FOREACH
END FOREACH

END FUNCTION

