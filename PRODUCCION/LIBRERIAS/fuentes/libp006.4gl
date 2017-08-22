GLOBALS "../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl"

DEFINE vm_programa      VARCHAR(12)
DEFINE rm_auxv		RECORD LIKE ctbt043.*
DEFINE rm_auxc		RECORD LIKE ctbt041.*
DEFINE rm_auxg		RECORD LIKE ctbt042.*
DEFINE rm_ctb		RECORD LIKE ctbt000.*
DEFINE rm_c13		RECORD LIKE ordt013.*
DEFINE rm_c10		RECORD LIKE ordt010.*
DEFINE vm_modulo	LIKE gent050.g50_modulo
DEFINE vm_tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE vm_indice	SMALLINT
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_compra	LIKE ordt010.c10_numero_oc
DEFINE vm_tipo_trn	CHAR(1)

FUNCTION fl_control_master_contab_compras(cod_cia, cod_loc, num_oc, num_recep)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE cod_loc		LIKE gent002.g02_localidad
DEFINE num_oc		LIKE ordt010.c10_numero_oc
DEFINE tipo		LIKE ctbt012.b12_tipo_comp
DEFINE num		LIKE ctbt012.b12_num_comp
DEFINE num_recep	LIKE ordt013.c13_num_recep
DEFINE mensaje		VARCHAR(200)

LET vm_compra = num_oc
CALL fl_lee_compania_contabilidad(cod_cia) RETURNING rm_ctb.*	
IF rm_ctb.b00_inte_online = 'N' THEN
	RETURN
END IF
LET vm_modulo    = 'OC'
LET vm_tipo_comp = 'DO'
LET vm_indice    = 1
CALL fl_lee_recepcion_orden_compra(cod_cia, cod_loc, num_oc, num_recep)
	RETURNING rm_c13.*
IF rm_c13.c13_compania IS NULL THEN
	LET mensaje = 'No existe recepción de compra: ', num_oc CLIPPED
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_orden_compra(cod_cia, cod_loc, num_oc)
	RETURNING rm_c10.*
CREATE TEMP TABLE te_master
	(te_tipo_comp		CHAR(2),
         te_num_comp		CHAR(8),
	 te_subtipo		SMALLINT,
	 te_orden		INTEGER,
	 te_num_recep		SMALLINT,
	 te_factura		CHAR(15),
	 te_cuenta		CHAR(12),
	 --te_glosa		CHAR(35),
	 te_glosa		CHAR(90),
	 te_tipo_mov		CHAR(1),
	 te_valor		DECIMAL(14,2),
	 te_indice		SMALLINT)
DECLARE qu_dcomp CURSOR FOR SELECT * FROM ordt014
	WHERE c14_compania  = rm_c13.c13_compania  AND 
	      c14_localidad = rm_c13.c13_localidad AND 
	      c14_numero_oc = rm_c13.c13_numero_oc AND 
	      c14_num_recep = rm_c13.c13_num_recep
IF rm_c10.c10_ord_trabajo IS NOT NULL THEN	
	CALL fl_contabiliza_oc_taller(47)
END IF
LET vm_indice = vm_indice + 1
BEGIN WORK
CALL fl_genera_comprobantes_compras()
COMMIT WORK
IF rm_ctb.b00_mayo_online = 'N' THEN
	RETURN
END IF
DECLARE q_tintin CURSOR WITH HOLD 
	FOR SELECT UNIQUE te_tipo_comp, te_num_comp
	FROM te_master
FOREACH q_tintin INTO tipo, num
	CALL fl_mayoriza_comprobante(rm_c13.c13_compania, tipo, num, 'M')
END FOREACH
DROP TABLE te_master

END FUNCTION
	


FUNCTION fl_contabiliza_oc_taller(subtipo)
DEFINE tot_ret		DECIMAL(14,2)
DEFINE val_iva		DECIMAL(14,2)
DEFINE val_prov		DECIMAL(14,2)
DEFINE tot_compra	DECIMAL(14,2)
DEFINE glosa       	LIKE ctbt013.b13_glosa
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE cuenta 		LIKE ctbt013.b13_cuenta
DEFINE r_c14		RECORD LIKE ordt014.*
DEFINE r_c02		RECORD LIKE ordt002.*
DEFINE r_c01		RECORD LIKE ordt001.*
DEFINE r_c10		RECORD LIKE ordt010.*
DEFINE r_p28		RECORD LIKE cxpt028.*
DEFINE r_p02		RECORD LIKE cxpt002.*
DEFINE r_t01		RECORD LIKE talt001.*
DEFINE r_t04		RECORD LIKE talt004.*
DEFINE r_t23		RECORD LIKE talt023.*
DEFINE r_s23		RECORD LIKE srit023.*
DEFINE tributa		LIKE srit023.s23_tributa
DEFINE mensaje		VARCHAR(200)

LET glosa = 'OC: ' || rm_c10.c10_numero_oc USING '<<<<<<' || 
            ' FAC.: '    || rm_c13.c13_factura
CALL fl_lee_tipo_orden_compra(rm_c10.c10_tipo_orden) RETURNING r_c01.*
IF r_c01.c01_aux_ot_proc IS NULL THEN
	LET mensaje = 'El tipo de O.C.: ', rm_c10.c10_tipo_orden USING '<<&',
			' de la O.C. ', rm_c10.c10_numero_oc USING '<<<<<&',
			' no tiene auxiliar contable para O.T. en proceso.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
IF r_c01.c01_aux_ot_cost IS NULL THEN
	LET mensaje = 'El tipo de O.C.: ',rm_c10.c10_tipo_orden USING '<<&',
		      ' de la O.C. ', rm_c10.c10_numero_oc USING '<<<<<&', 
		      ' no tiene auxiliar contable para costo de venta.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_orden_trabajo(rm_c10.c10_compania, rm_c10.c10_localidad, 
			  rm_c10.c10_ord_trabajo)
	RETURNING r_t23.*
IF r_t23.t23_compania IS NULL THEN
	LET mensaje = 'No existe O.T.: ', rm_c10.c10_ord_trabajo CLIPPED
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_tipo_vehiculo(r_t23.t23_compania, r_t23.t23_modelo)
	RETURNING r_t04.*
CALL fl_lee_linea_taller(r_t23.t23_compania, r_t04.t04_linea)
	RETURNING r_t01.*
CALL fl_lee_proveedor_localidad(rm_c10.c10_compania, rm_c10.c10_localidad, 
	rm_c10.c10_codprov)
	RETURNING r_p02.*
DECLARE qu_tanga CURSOR FOR SELECT * FROM cxpt028
	WHERE p28_compania  = rm_c13.c13_compania   AND 
	      p28_localidad = rm_c13.c13_localidad  AND 
	      p28_num_ret   = rm_c13.c13_num_ret
LET tot_ret = 0
FOREACH qu_tanga INTO r_p28.*
	CALL fl_lee_tipo_retencion(rm_c13.c13_compania, r_p28.p28_tipo_ret,
			   r_p28.p28_porcentaje)
	RETURNING r_c02.*
	IF r_c02.c02_compania IS NULL THEN
		LET mensaje = 'No existe tipo retención en ordt002 para compra No.: ', rm_c10.c10_numero_oc CLIPPED
		CALL fl_mostrar_mensaje(mensaje, 'stop')
		EXIT PROGRAM
	END IF
	LET tot_ret = tot_ret + r_p28.p28_valor_ret
	CALL fl_genera_detalle_compras(vm_tipo_comp, subtipo, r_c02.c02_aux_cont,'H',
	r_p28.p28_valor_ret, glosa, rm_c13.c13_numero_oc, rm_c13.c13_num_recep,
	rm_c13.c13_factura)
END FOREACH
LET rm_c13.c13_tot_bruto = rm_c13.c13_tot_bruto * rm_c10.c10_paridad
CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, rm_c13.c13_tot_bruto)
	RETURNING rm_c13.c13_tot_bruto
LET rm_c13.c13_tot_dscto = rm_c13.c13_tot_dscto * rm_c10.c10_paridad
CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, rm_c13.c13_tot_dscto)
	RETURNING rm_c13.c13_tot_dscto
LET rm_c13.c13_tot_impto = rm_c13.c13_tot_impto * rm_c10.c10_paridad
CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, rm_c13.c13_tot_impto)
	RETURNING rm_c13.c13_tot_impto
LET tot_compra  = rm_c13.c13_tot_bruto - rm_c13.c13_tot_dscto + 
	          rm_c13.c13_tot_impto
CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base, tot_compra)
	RETURNING tot_compra
LET rm_c13.c13_tot_bruto = rm_c13.c13_tot_bruto - rm_c13.c13_tot_dscto
LET val_prov = tot_compra - tot_ret
CALL fl_lee_auxiliares_generales(rm_c13.c13_compania, rm_c13.c13_localidad)
	RETURNING rm_auxg.*
IF rm_auxg.b42_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No hay configuración de auxiliares generales.', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_orden_compra(rm_c13.c13_compania, rm_c13.c13_localidad,
			rm_c13.c13_numero_oc)
	RETURNING r_c10.*
{--
CALL fl_lee_auxiliares_taller(rm_c13.c13_compania, rm_c13.c13_localidad, 
				r_t01.t01_grupo_linea, r_c10.c10_porc_impto)
	RETURNING rm_auxv.*
--}
INITIALIZE rm_auxv.* TO NULL
DECLARE q_b43 CURSOR FOR
	SELECT * FROM ctbt043
		WHERE b43_compania   = rm_c13.c13_compania
		  AND b43_localidad  = rm_c13.c13_localidad
		  AND b43_porc_impto = r_c10.c10_porc_impto
OPEN q_b43
FETCH q_b43 INTO rm_auxv.*
IF rm_auxv.b43_compania IS NULL THEN
	CLOSE q_b43
	FREE q_b43
	LET mensaje = 'No hay configuración de auxiliares contables taller para grupo línea: ', r_t01.t01_grupo_linea CLIPPED, ' en O/C: ', rm_c13.c13_numero_oc CLIPPED
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
CLOSE q_b43
CALL fl_retorna_aux_ventas_tal(rm_c13.c13_compania, rm_c13.c13_localidad,
				rm_auxv.b43_grupo_linea, r_c10.c10_porc_impto,
				r_t23.t23_cod_cliente)
	RETURNING rm_auxv.*

IF r_c01.c01_bien_serv = 'B' THEN
	LET cuenta = rm_auxv.b43_pro_rp_tal
ELSE	
	IF r_p02.p02_int_ext = 'I' THEN
		LET cuenta = rm_auxv.b43_pro_mo_cti
	ELSE
		LET cuenta = rm_auxv.b43_pro_mo_ext
	END IF
END IF

OPEN qu_dcomp
FETCH qu_dcomp INTO r_c14.*
IF status = NOTFOUND THEN
	LET mensaje = 'Compra no tiene detalle: ', rm_c10.c10_numero_oc CLIPPED
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
--CALL fl_genera_detalle_compras(vm_tipo_comp, subtipo, cuenta, 'D',
CALL fl_genera_detalle_compras(vm_tipo_comp, subtipo, r_c01.c01_aux_ot_proc,'D',
        rm_c13.c13_tot_bruto, glosa, rm_c13.c13_numero_oc, rm_c13.c13_num_recep,
	rm_c13.c13_factura)
LET tributa = 'S'
IF rm_c13.c13_tot_impto = 0 THEN
	LET tributa = 'N'
END IF
CALL fl_obtener_aux_cont_sust(rm_c13.c13_compania,rm_c10.c10_tipo_orden,tributa)
	RETURNING r_s23.*
IF r_s23.s23_aux_cont IS NOT NULL THEN
	LET r_c01.c01_aux_cont = r_s23.s23_aux_cont
END IF
IF r_c01.c01_aux_cont IS NOT NULL THEN 
	LET rm_auxg.b42_iva_compra = r_c01.c01_aux_cont
END IF
IF rm_c10.c10_sustento_sri = 'S' THEN
	CALL fl_genera_detalle_compras(vm_tipo_comp, subtipo, rm_auxg.b42_iva_compra, 
		'D', rm_c13.c13_tot_impto, glosa, rm_c13.c13_numero_oc, 
		rm_c13.c13_num_recep, rm_c13.c13_factura)
END IF
IF rm_c10.c10_moneda <> rg_gen.g00_moneda_base THEN
	LET r_p02.p02_aux_prov_mb = r_p02.p02_aux_prov_ma
END IF
CALL fl_genera_detalle_compras(vm_tipo_comp, subtipo, r_p02.p02_aux_prov_mb,
        'H', val_prov, glosa, rm_c13.c13_numero_oc, rm_c13.c13_num_recep, 
        rm_c13.c13_factura)

END FUNCTION



FUNCTION fl_genera_comprobantes_compras()
DEFINE tipo_comp	CHAR(2)
DEFINE num_comp		CHAR(8)
DEFINE subtipo		SMALLINT
DEFINE num_oc		LIKE ordt013.c13_numero_oc
DEFINE num_recep	LIKE ordt013.c13_num_recep
DEFINE factura		LIKE ordt013.c13_factura
DEFINE num_tran		DECIMAL(15,0)
DEFINE cuenta		CHAR(12)
DEFINE glosa		LIKE ctbt013.b13_glosa
DEFINE tipo_mov		CHAR(1)
DEFINE valor		DECIMAL(14,2)
DEFINE indice, i	SMALLINT
DEFINE r_ccomp		RECORD LIKE ctbt012.*
DEFINE r_dcomp		RECORD LIKE ctbt013.*
        
DECLARE q_seno CURSOR FOR SELECT UNIQUE te_tipo_comp, te_subtipo, te_indice 
	FROM te_master
	ORDER BY 3
FOREACH q_seno INTO tipo_comp, subtipo, indice
	INITIALIZE r_ccomp.* TO NULL
	LET r_ccomp.b12_num_comp = fl_numera_comprobante_contable(rm_c13.c13_compania,
		tipo_comp, YEAR(rm_c13.c13_fecha_recep), MONTH(rm_c13.c13_fecha_recep))
	IF r_ccomp.b12_num_comp = '-1' THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
    	LET r_ccomp.b12_compania 	= rm_c13.c13_compania
    	LET r_ccomp.b12_tipo_comp 	= tipo_comp
    	LET r_ccomp.b12_estado 		= 'A'
    	LET r_ccomp.b12_subtipo 	= subtipo
	IF vm_compra IS NOT NULL THEN
    		LET r_ccomp.b12_fec_proceso = rm_c13.c13_fecha_recep
    		LET r_ccomp.b12_glosa	= 'COMPRA: ', rm_c10.c10_numero_oc 
			USING '<<<<<<',
            	        ',  FAC.: ', rm_c13.c13_factura CLIPPED,
			',  # REC.: ', rm_c13.c13_num_recep USING '<<<<<<'
	ELSE
    		LET r_ccomp.b12_fec_proceso = vm_fecha_fin
    		LET r_ccomp.b12_glosa = 'COMPROBANTES ',
					'DEL ', vm_fecha_ini USING 'dd-mm-yyyy',
				        ' AL ', vm_fecha_fin USING 'dd-mm-yyyy'
		IF vm_fecha_ini = vm_fecha_fin THEN
    			LET r_ccomp.b12_fec_proceso = vm_fecha_ini
    			LET r_ccomp.b12_glosa = 'COMPROBANTES ',
				'DEL: ', vm_fecha_ini USING 'dd-mm-yyyy'
		END IF
	END IF		
    	LET r_ccomp.b12_origen 		= 'A'
    	LET r_ccomp.b12_moneda 		= rg_gen.g00_moneda_base
    	LET r_ccomp.b12_paridad 	= 1
    	LET r_ccomp.b12_modulo	 	= vm_modulo
    	LET r_ccomp.b12_usuario 	= vg_usuario
    	LET r_ccomp.b12_fecing 		= fl_current()
	INSERT INTO ctbt012 VALUES (r_ccomp.*)
	DECLARE q_fk1 CURSOR FOR SELECT * FROM te_master
		WHERE te_tipo_comp = tipo_comp AND 
		      te_subtipo   = subtipo
		ORDER BY te_tipo_mov, te_cuenta
	INITIALIZE r_dcomp.* TO NULL
	LET i = 0
	FOREACH q_fk1 INTO tipo_comp, num_comp, subtipo, num_oc, num_recep, 
		factura, cuenta, glosa, tipo_mov, valor, indice
		LET i = i + 1
    		LET r_dcomp.b13_compania 	= r_ccomp.b12_compania
    		LET r_dcomp.b13_tipo_comp 	= r_ccomp.b12_tipo_comp
    		LET r_dcomp.b13_num_comp 	= r_ccomp.b12_num_comp
    		LET r_dcomp.b13_secuencia 	= i
    		LET r_dcomp.b13_cuenta 		= cuenta
    		LET r_dcomp.b13_glosa 		= glosa
    		LET r_dcomp.b13_valor_base 	= valor
    		LET r_dcomp.b13_valor_aux 	= 0
    		LET r_dcomp.b13_fec_proceso 	= r_ccomp.b12_fec_proceso
    		LET r_dcomp.b13_num_concil  	= 0
    		LET r_dcomp.b13_codprov  	= rm_c10.c10_codprov
		INSERT INTO ctbt013 VALUES(r_dcomp.*)
	END FOREACH
	UPDATE te_master SET te_num_comp = r_ccomp.b12_num_comp
		WHERE te_tipo_comp = r_ccomp.b12_tipo_comp AND
		      te_subtipo   = r_ccomp.b12_subtipo 
END FOREACH
DECLARE q_pokemon CURSOR FOR 
	SELECT UNIQUE te_orden, te_num_recep, te_tipo_comp, te_num_comp 
	FROM te_master
FOREACH q_pokemon INTO num_oc, num_recep, tipo_comp, num_comp
	INSERT INTO ordt040 VALUES (rm_c13.c13_compania, rm_c13.c13_localidad,
	    num_oc, num_recep, tipo_comp, num_comp)
END FOREACH

END FUNCTION



FUNCTION fl_genera_detalle_compras(tipo_comp, subtipo, cuenta, tipo_mov, 
		valor, glosa, num_oc, num_recep, factura)
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE subtipo		LIKE ctbt012.b12_subtipo
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE tipo_mov		CHAR(1)
DEFINE glosa		LIKE ctbt013.b13_glosa
DEFINE valor		DECIMAL(14,2)
DEFINE num_oc		LIKE ordt013.c13_numero_oc
DEFINE num_recep	LIKE ordt013.c13_num_recep
DEFINE factura		LIKE ordt013.c13_factura

IF valor = 0 THEN
	RETURN
END IF
IF tipo_mov = 'H' THEN
	LET valor = valor * -1
END IF
SELECT * FROM te_master 
	WHERE te_tipo_comp = tipo_comp AND 
	      te_subtipo   = subtipo   AND
	      te_cuenta    = cuenta    AND
	      te_glosa     = glosa

IF status = NOTFOUND THEN
	INSERT INTO te_master VALUES (tipo_comp, NULL, subtipo, num_oc,
		num_recep, factura, cuenta, glosa, tipo_mov, valor, vm_indice)
ELSE
	UPDATE te_master SET te_valor = te_valor + valor
		WHERE te_tipo_comp = tipo_comp AND 
	              te_subtipo   = subtipo   AND
	              te_cuenta    = cuenta    AND
	              te_glosa     = glosa
END IF

END FUNCTION		



FUNCTION fl_obtener_aux_cont_sust(codcia, tipo_oc, tributa)
DEFINE codcia		LIKE srit023.s23_compania
DEFINE tipo_oc		LIKE srit023.s23_tipo_orden
DEFINE tributa		LIKE srit023.s23_tributa
DEFINE r_s23		RECORD LIKE srit023.*

INITIALIZE r_s23.* TO NULL
DECLARE q_s23 CURSOR FOR
	SELECT * FROM srit023
		WHERE s23_compania   = codcia
		  AND s23_tipo_orden = tipo_oc
		  AND s23_tributa    = tributa
OPEN q_s23
FETCH q_s23 INTO r_s23.*
CLOSE q_s23
FREE q_s23
RETURN r_s23.*

END FUNCTION
