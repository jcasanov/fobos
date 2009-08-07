DATABASE diteca

MAIN

--CALL act_glosa_facturas_repuestos()
--CALL act_glosa_egresos_automaticos()
--CALL act_glosa_ingresos_caja()
CALL act_glosa_facturas_talleres()

END MAIN



FUNCTION act_glosa_facturas_repuestos()
DEFINE r		RECORD LIKE rept040.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE glosa		LIKE ctbt013.b13_glosa

DECLARE q1 CURSOR FOR SELECT * FROM rept040 WHERE r40_cod_tran IN ('FA','DF')
FOREACH q1 INTO r.*
	DISPLAY r.r40_cod_tran, ' ', r.r40_num_tran
	SELECT * INTO r_r19.* FROM rept019
		WHERE r19_compania  = r.r40_compania  AND 
		      r19_localidad = r.r40_localidad AND 
		      r19_cod_tran  = r.r40_cod_tran  AND 
		      r19_num_tran  = r.r40_num_tran
	IF status = NOTFOUND THEN
		DISPLAY 'No existe...'
		CONTINUE FOREACH
	END IF
	LET glosa = r_r19.r19_nomcli[1,25], ' ', r.r40_cod_tran, '-',
		    r_r19.r19_num_tran USING '<<<<<<<<<<<<<<<'
	UPDATE ctbt013
		SET b13_glosa = glosa
		WHERE b13_compania  = r_z40_compania AND 
		      b13_tipo_comp = r.z40_tipo_comp  AND 
		      b13_num_comp  = r.z40_num_comp
END FOREACH

END FUNCTION



FUNCTION act_glosa_egresos_automaticos()
DEFINE r		RECORD LIKE ctbt012.*
DEFINE r_p24		RECORD LIKE cxpt024.*
DEFINE glosa		LIKE ctbt013.b13_glosa

DECLARE q2 CURSOR FOR SELECT * FROM ctbt012 WHERE b12_tipo_comp = 'EG' AND    
	b12_origen = 'A'
FOREACH q2 INTO r.*
	DISPLAY r.b12_tipo_comp, ' ', r.b12_num_comp
	SELECT * INTO r_p24.* FROM cxpt024
		WHERE p24_compania     = r.b12_compania AND 
		      p24_tip_contable = r.b12_tipo_comp AND 
		      p24_num_contable = r.b12_num_comp
	IF status = NOTFOUND THEN
		DISPLAY 'No existe...'
		CONTINUE FOREACH
	END IF
	LET glosa = r.b12_benef_che[1,25], ' OP-', r_p24.p24_orden_pago USING '<<<<<'
	display glosa
	UPDATE ctbt013
		SET b13_glosa = glosa
		WHERE b13_compania  = r.b12_compania AND 
		      b13_tipo_comp = r.b12_tipo_comp  AND 
		      b13_num_comp  = r.b12_num_comp
END FOREACH

END FUNCTION



FUNCTION act_glosa_ingresos_caja()
DEFINE r		RECORD LIKE cxct040.*
DEFINE r_z20		RECORD LIKE cxct020.*
DEFINE r_z21		RECORD LIKE cxct021.*
DEFINE glosa		LIKE ctbt013.b13_glosa
DEFINE nomcli		LIKE cxct001.z01_nomcli

DECLARE q3 CURSOR FOR SELECT * FROM cxct040 WHERE z40_tipo_doc IN ('PG','PA')
FOREACH q3 INTO r.*
	DISPLAY r.z40_tipo_doc, ' ', r.z40_num_doc 
	SELECT z01_nomcli INTO nomcli FROM cxct001
		WHERE z01_codcli = r.z40_codcli
	IF status = NOTFOUND THEN
		DISPLAY 'No existe...'
		CONTINUE FOREACH
	END IF
	LET glosa = nomcli[1,25], ' ', r.z40_tipo_doc, '-',
		    r.z40_num_doc USING '<<<<<'
	display glosa
	UPDATE ctbt013
		SET b13_glosa = glosa
		WHERE b13_compania  = r.z40_compania AND 
		      b13_tipo_comp = r.z40_tipo_comp  AND 
		      b13_num_comp  = r.z40_num_comp
END FOREACH

END FUNCTION



FUNCTION act_glosa_facturas_talleres()
DEFINE r		RECORD LIKE talt050.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE glosa		LIKE ctbt013.b13_glosa
DEFINE nomcli		LIKE cxct001.z01_nomcli

DECLARE q4 CURSOR FOR SELECT * FROM talt050 
FOREACH q4 INTO r.*
	DISPLAY r.t50_orden
	SELECT * INTO r_t23.* FROM talt023
		WHERE t23_compania  = r.t50_compania  AND 
		      t23_localidad = r.t50_localidad AND 
		      t23_orden     = r.t50_orden
	IF status = NOTFOUND THEN
		DISPLAY 'No existe...'
		CONTINUE FOREACH
	END IF
	LET glosa = r_t23.t23_nom_cliente[1,25], ' FA-',
		    r.t50_factura USING '<<<<<<<<<<<<<<<'
	display glosa
	UPDATE ctbt013
		SET b13_glosa = glosa
		WHERE b13_compania  = r.t50_compania AND 
		      b13_tipo_comp = r.t50_tipo_comp  AND 
		      b13_num_comp  = r.t50_num_comp
END FOREACH

END FUNCTION
