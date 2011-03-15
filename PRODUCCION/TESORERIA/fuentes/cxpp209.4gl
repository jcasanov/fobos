{*
 * Titulo           : cxpp209.4gl - Transf. Bancaria por Orden de Pago a 
 *				    Proveedores
 * Elaboracion      : 05-mar-2009
 * Autor            : YEC
 * Formato Ejecucion: fglrun cxpp209 base módulo compañía localidad
 *		      fglrun cxpp209 base módulo compañía localidad orden_pago
 *}
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det	SMALLINT
DEFINE vm_tot_db	DECIMAL(14,2)
DEFINE vm_tot_cr	DECIMAL(14,2)
DEFINE rm_ordp		RECORD LIKE cxpt024.*
DEFINE rm_prov		RECORD LIKE cxpt001.*
DEFINE rm_mon		RECORD LIKE gent013.*
DEFINE rm_bco		RECORD LIKE gent009.*
DEFINE rm_ccomp		RECORD LIKE ctbt012.*
DEFINE rm_ciacon	RECORD LIKE ctbt000.*
DEFINE rm_ciapag	RECORD LIKE cxpt000.*
DEFINE rm_pago		RECORD LIKE cxpt022.*
DEFINE rm_fav		RECORD LIKE cxpt021.*
DEFINE rm_ret		RECORD LIKE cxpt027.*
DEFINE rm_orden ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_cod_pago	LIKE cxpt022.p22_tipo_trn
DEFINE vm_cod_aju	LIKE cxpt022.p22_tipo_trn
DEFINE vm_cod_fav	LIKE cxpt021.p21_tipo_doc
DEFINE vm_cod_cont	LIKE ctbt012.b12_tipo_comp
DEFINE vm_num_pago	INTEGER
DEFINE rm_rows	ARRAY [1000] OF INTEGER
DEFINE rm_tran		ARRAY [200] OF RECORD
		b13_cuenta	LIKE ctbt013.b13_cuenta,
		b10_descripcion	LIKE ctbt010.b10_descripcion,
		valor_debito	LIKE ctbt013.b13_valor_base,
		valor_credito	LIKE ctbt013.b13_valor_base
	END RECORD

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxpp209.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN    -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'cxpp209'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
CALL fl_chequeo_mes_proceso_cxp(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN
END IF
CREATE TEMP TABLE temp_pago 
	(te_serial		SERIAL,
	 te_cuenta		CHAR(12),
	 te_glosa		VARCHAR(35),
	 te_valor_db		DECIMAL(14,2),
	 te_valor_cr		DECIMAL(14,2))
LET vm_max_rows	= 1000
LET vm_max_det  = 200
OPEN WINDOW wf AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_ordp FROM "../forms/cxpf209_1"
DISPLAY FORM f_ordp
LET vm_num_rows = 0
LET vm_row_current = 0
MENU 'OPCIONES'
	BEFORE MENU
		CALL control_proceso_orden_pago()
		IF num_args() = 5 THEN
			EXIT PROGRAM
		END IF
	COMMAND KEY('O') 'Orden Pago'
		CALL control_proceso_orden_pago()
	COMMAND KEY('S') 'Salir'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_proceso_orden_pago()
DEFINE r		RECORD LIKE gent013.*

LET vm_cod_pago	= 'PG'
LET vm_cod_aju	= 'AJ'
LET vm_cod_fav	= 'PA'
LET vm_cod_cont	= 'ND'
DELETE FROM temp_pago
CLEAR FORM
CALL muestra_titulos()
LET int_flag = 0
INITIALIZE rm_ordp.* TO NULL
IF num_args() = 5 THEN
	LET rm_ordp.p24_orden_pago = arg_val(5)
	DISPLAY BY NAME rm_ordp.p24_orden_pago
	IF NOT valida_orden_pago(rm_ordp.p24_orden_pago) THEN
		EXIT PROGRAM
	END IF
ELSE
	CALL lee_orden_pago()
END IF
IF int_flag THEN
	EXIT PROGRAM
END IF
CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING rm_ciacon.*
IF rm_ciacon.b00_compania IS NULL OR rm_ciacon.b00_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no existe o está bloqueada', 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania_tesoreria(vg_codcia) RETURNING rm_ciapag.*
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_ordp CURSOR FOR
	SELECT * FROM cxpt024 
		WHERE p24_compania   = vg_codcia AND 
		      p24_localidad  = vg_codloc AND 
		      p24_orden_pago = rm_ordp.p24_orden_pago
		FOR UPDATE
OPEN q_ordp
FETCH q_ordp INTO rm_ordp.*
IF status < 0 THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN
END IF
WHENEVER ERROR STOP
CALL fl_lee_proveedor(rm_ordp.p24_codprov) RETURNING rm_prov.*
IF fl_validar_cedruc_dig_ver(rm_prov.p01_tipo_doc, rm_prov.p01_num_doc) = 0 THEN
	WHENEVER ERROR STOP
	ROLLBACK WORK
	RETURN
END IF

INITIALIZE rm_ccomp.* TO NULL
LET rm_ccomp.b12_modulo      = vg_modulo
LET rm_ccomp.b12_tipo_comp   = vm_cod_cont
LET rm_ccomp.b12_fec_proceso = TODAY
LET rm_ccomp.b12_glosa   = 'PROVEEDOR : ', rm_prov.p01_nomprov CLIPPED
IF rm_ccomp.b12_glosa IS NULL THEN
-- OJO
	LET rm_ccomp.b12_glosa   = 'PROVEEDOR : ', rm_prov.p01_nomprov CLIPPED
--	LET rm_ccomp.b12_glosa   = 'ORDEN DE PAGO # ', rm_ordp.p24_orden_pago
END IF
LET rm_ccomp.b12_moneda      = rm_ordp.p24_moneda
LET rm_ccomp.b12_paridad     = rm_ordp.p24_paridad
CALL fl_lee_moneda(rm_ordp.p24_moneda) RETURNING r.*
DISPLAY BY NAME rm_ccomp.b12_tipo_comp, rm_ccomp.b12_fec_proceso,
		rm_ccomp.b12_glosa,
		rm_ccomp.b12_moneda,    rm_ccomp.b12_paridad
DISPLAY r.g13_nombre TO tit_moneda
CALL prepara_arreglo()
IF vm_tot_db <> vm_tot_cr OR vm_tot_db + vm_tot_cr = 0 THEN
	CALL fgl_winmessage(vg_producto, 'Comprobante descuadrado o sin valor', 'stop')
	CLEAR FORM
	ROLLBACK WORK
	CALL muestra_titulos()
END IF
IF vm_tot_db <> rm_ordp.p24_total_cap + rm_ordp.p24_total_int OR 
	vm_tot_cr <> rm_ordp.p24_total_ret + rm_ordp.p24_total_che THEN
	CALL fgl_winmessage(vg_producto, 'No cuadran valores de cabecera con detalle en la orden de pago', 'stop')
	CLEAR FORM
	ROLLBACK WORK
	CALL muestra_titulos()
END IF
CALL ubicarse_en_detalle()
IF int_flag THEN
	CLEAR FORM
	ROLLBACK WORK
	CALL muestra_titulos()
	RETURN
END IF
CALL genera_comprobante_contable()
DISPLAY BY NAME rm_ccomp.b12_tipo_comp, rm_ccomp.b12_num_comp
IF rm_ordp.p24_tipo = 'P' THEN 
	CALL genera_transaccion(vm_cod_pago)
ELSE
	CALL genera_documento_favor()
END IF
IF rm_ordp.p24_total_ret > 0 THEN
	CALL genera_retencion()
	CALL genera_transaccion(vm_cod_aju)
END IF
UPDATE cxpt024 SET p24_estado       = 'P',
		   p24_medio_pago           = 'T', 
		   p24_tip_contable = rm_ccomp.b12_tipo_comp,
		   p24_num_contable = rm_ccomp.b12_num_comp
	WHERE CURRENT OF q_ordp
CALL fl_genera_saldos_proveedor(vg_codcia, vg_codloc, rm_ordp.p24_codprov)
COMMIT WORK
CALL fl_mayoriza_comprobante(vg_codcia, rm_ccomp.b12_tipo_comp, 
			     rm_ccomp.b12_num_comp, 'M')

CALL imprimir()

CALL fl_mensaje_registro_ingresado()
IF num_args() = 5 THEN
	EXIT PROGRAM
END IF

END FUNCTION
	
	

FUNCTION lee_orden_pago()
DEFINE orden		LIKE cxpt024.p24_orden_pago

LET int_flag = 0
OPTIONS INPUT NO WRAP
INPUT BY NAME rm_ordp.p24_orden_pago WITHOUT DEFAULTS
	ON KEY(F2)
		IF infield(p24_orden_pago) THEN
			CALL fl_ayuda_ordenes_pago_prov(vg_codcia, 
							vg_codloc, 'A')
				RETURNING orden
			IF orden IS NOT NULL THEN
				LET rm_ordp.p24_orden_pago = orden
				DISPLAY BY NAME rm_ordp.p24_orden_pago
			END IF
			LET int_flag = 0
		END IF
	AFTER FIELD p24_orden_pago
		IF rm_ordp.p24_orden_pago IS NOT NULL THEN
			IF NOT valida_orden_pago(rm_ordp.p24_orden_pago) THEN
				NEXT FIELD p24_orden_pago
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION muestra_titulos()

DISPLAY 'Cuenta'        TO tit_col1
DISPLAY 'Descripción'   TO tit_col2
DISPLAY 'Valor Débito'  TO tit_col3
DISPLAY 'Valor Crédito' TO tit_col4

END FUNCTION



FUNCTION prepara_arreglo()
DEFINE valor		DECIMAL(14,2)
DEFINE tot_pag		DECIMAL(14,2)
DEFINE tot_ret		DECIMAL(14,2)
DEFINE r		RECORD LIKE cxpt002.*
DEFINE r_pdoc		RECORD LIKE cxpt025.*
DEFINE r_dret		RECORD LIKE cxpt026.*
DEFINE r_ret		RECORD LIKE ordt002.*
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE i		SMALLINT
DEFINE label		VARCHAR(35)

CALL fl_lee_proveedor_localidad(vg_codcia, vg_codloc, rm_ordp.p24_codprov)
	RETURNING r.*
LET cuenta = r.p02_aux_prov_mb
IF rm_ordp.p24_moneda <> rm_ciacon.b00_moneda_base THEN
	LET cuenta = r.p02_aux_prov_ma
END IF
DECLARE q_det CURSOR FOR 
	SELECT * FROM cxpt025
		WHERE p25_compania  = vg_codcia AND 
		      p25_localidad = vg_codloc AND 
		      p25_orden_pago = rm_ordp.p24_orden_pago
		ORDER BY p25_secuencia
LET vm_tot_db = 0
LET vm_tot_cr = 0
LET tot_pag   = 0
LET tot_ret   = 0
FOREACH q_det INTO r_pdoc.*
LET label = rm_prov.p01_nomprov[1,15], '/', r_pdoc.p25_tipo_doc, '-', r_pdoc.p25_num_doc CLIPPED
	LET valor = r_pdoc.p25_valor_cap + r_pdoc.p25_valor_int
	LET tot_pag = tot_pag + valor
{
	LET label = r_pdoc.p25_tipo_doc, '-', r_pdoc.p25_num_doc CLIPPED,
		    '-', r_pdoc.p25_dividendo USING '&&&'
}
	CALL inserta_tabla_temporal(cuenta, valor, label, 'D')
	LET vm_tot_db = vm_tot_db + valor
	IF r_pdoc.p25_valor_ret > 0 THEN
		DECLARE q_ret CURSOR FOR 
			SELECT * FROM cxpt026
				WHERE p26_compania   = vg_codcia AND 
				      p26_localidad  = vg_codloc AND 
				      p26_orden_pago = rm_ordp.p24_orden_pago AND 
				      p26_secuencia  = r_pdoc.p25_secuencia
		FOREACH q_ret INTO r_dret.*
			LET tot_ret = tot_ret + r_dret.p26_valor_ret
			CALL fl_lee_tipo_retencion(vg_codcia, r_dret.p26_codigo_sri, r_dret.p26_tipo_ret,
						   r_dret.p26_porcentaje)
				RETURNING r_ret.*
			CALL inserta_tabla_temporal(r_ret.c02_aux_cont, r_dret.p26_valor_ret, label, 'C')
			LET vm_tot_cr = vm_tot_cr + r_dret.p26_valor_ret
		END FOREACH
	END IF
END FOREACH
IF rm_ordp.p24_tipo = 'P' AND 
       (rm_ordp.p24_total_cap + rm_ordp.p24_total_int <> tot_pag OR
	rm_ordp.p24_total_ret <> tot_ret) THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto, 'No cuadran valores de cabecera contra detalle de la orden de pago', 'stop')
	EXIT PROGRAM
END IF
IF rm_ordp.p24_tipo = 'A' THEN
	LET cuenta = r.p02_aux_ant_mb
	IF rm_ordp.p24_moneda <> rm_ciacon.b00_moneda_base THEN
		LET cuenta = r.p02_aux_ant_ma
	END IF
	LET tot_pag = rm_ordp.p24_total_cap + rm_ordp.p24_total_int
	LET vm_tot_db = tot_pag
	CALL inserta_tabla_temporal(cuenta, tot_pag, label, 'D')
END IF
LET valor = tot_pag - tot_ret
CALL fl_lee_banco_compania(vg_codcia, rm_ordp.p24_banco, rm_ordp.p24_numero_cta)
	RETURNING rm_bco.*
CALL inserta_tabla_temporal(rm_bco.g09_aux_cont, valor, label, 'C')
LET vm_tot_cr = vm_tot_cr + valor
DECLARE q_cont CURSOR FOR 
	SELECT te_serial, te_cuenta, b10_descripcion, te_valor_db, te_valor_cr
		FROM temp_pago, ctbt010
		WHERE b10_compania = vg_codcia AND 
		      te_cuenta    = b10_cuenta
		ORDER BY 1
LET i = 1
FOREACH q_cont INTO valor, rm_tran[i].*
	LET i = i + 1
	IF i > vm_max_det THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_det = i - 1
FOR i = 1 TO fgl_scr_size('rm_tran')
	IF i <= vm_num_det THEN
		DISPLAY rm_tran[i].* TO rm_tran[i].*
	END IF
END FOR
DISPLAY BY NAME vm_tot_db, vm_tot_cr

END FUNCTION



FUNCTION inserta_tabla_temporal(cuenta, valor, glosa, tipo_mov)
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE valor		DECIMAL(14,2)
DEFINE tipo_mov		CHAR(1)
DEFINE valor_db		DECIMAL(14,2)
DEFINE valor_cr		DECIMAL(14,2)
DEFINE glosa		VARCHAR(35)

LET valor_db = 0
LET valor_cr = 0
IF tipo_mov = 'D' THEN
	LET valor_db = valor
ELSE
	LET valor_cr = valor
END IF
IF rm_ciapag.p00_tipo_egr_gen = 'D' THEN
	INSERT INTO temp_pago VALUES (0, cuenta, glosa, valor_db, valor_cr)
ELSE
	SELECT * FROM temp_pago WHERE te_cuenta = cuenta
	IF status = NOTFOUND THEN
		INSERT INTO temp_pago VALUES (0, cuenta, NULL, valor_db, valor_cr)
	ELSE
		UPDATE temp_pago SET te_valor_db = te_valor_db + valor_db,
		                     te_valor_cr = te_valor_cr + valor_cr
			WHERE te_cuenta = cuenta
	END IF
END IF

END FUNCTION



FUNCTION ubicarse_en_detalle()
DEFINE comando		VARCHAR(100)
DEFINE resp		VARCHAR(6)

LET int_flag = 0
CALL set_count(vm_num_det)
DISPLAY ARRAY rm_tran TO rm_tran.*
	ON KEY(INTERRUPT)
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT DISPLAY
		END IF
		LET int_flag = 0
	ON KEY(F5)
		IF rm_ordp.p24_tipo = 'P' THEN
			LET comando = 'fglrun cxpp204 ', vg_base, ' ', 
				       vg_modulo, ' ', vg_codcia, ' ', 
				       vg_codloc, ' ', rm_ordp.p24_orden_pago
		ELSE
			display 'EN CXCP206 ANTES DEL RUN .. '
			LET comando = 'fglrun cxpp205 ', vg_base, ' ', 
				       vg_modulo, ' ', vg_codcia, ' ', 
				       vg_codloc, ' ', rm_ordp.p24_orden_pago
		END IF
		RUN comando	
END DISPLAY

END FUNCTION



FUNCTION genera_transaccion(cod_trn)
DEFINE cod_trn		LIKE cxpt022.p22_tipo_trn
DEFINE r_dpag		RECORD LIKE cxpt023.*
DEFINE r_doc		RECORD LIKE cxpt020.*
DEFINE r_pdoc		RECORD LIKE cxpt025.*
DEFINE i		SMALLINT
DEFINE label		VARCHAR(100)
DEFINE tot_cap		DECIMAL(14,2)
DEFINE tot_int		DECIMAL(14,2)
DEFINE tot_mora		DECIMAL(14,2)

SET LOCK MODE TO WAIT 5
INITIALIZE rm_pago.* TO NULL
LET rm_pago.p22_num_trn = fl_actualiza_control_secuencias(vg_codcia, vg_codloc,
		vg_modulo, 'AA', cod_trn)
IF rm_pago.p22_num_trn <= 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
IF cod_trn = vm_cod_pago THEN
	LET vm_num_pago = rm_pago.p22_num_trn
END IF
LET rm_pago.p22_compania 	= vg_codcia
LET rm_pago.p22_localidad 	= vg_codloc
LET rm_pago.p22_codprov 	= rm_ordp.p24_codprov
LET rm_pago.p22_tipo_trn	= cod_trn
LET rm_pago.p22_referencia 	= rm_ordp.p24_referencia
IF rm_pago.p22_referencia IS NULL OR rm_pago.p22_referencia = '' THEN
	LET rm_pago.p22_referencia = 'ORDEN DE PAGO # ', rm_ordp.p24_orden_pago
				      USING '####&'
END IF	
IF cod_trn = vm_cod_aju THEN
	LET rm_pago.p22_referencia = 'RETENCIONES ORDEN DE PAGO # ', rm_ordp.p24_orden_pago
				      USING '####&'
END IF	
LET rm_pago.p22_fecha_emi 	= TODAY
LET rm_pago.p22_moneda 		= rm_ordp.p24_moneda
LET rm_pago.p22_paridad 	= rm_ordp.p24_paridad
LET rm_pago.p22_tasa_mora 	= 0
IF cod_trn = vm_cod_pago THEN
	LET rm_pago.p22_tasa_mora 	= rm_ordp.p24_tasa_mora
	LET rm_pago.p22_total_cap 	= (rm_ordp.p24_total_cap - 
					  rm_ordp.p24_total_ret) * -1
	LET rm_pago.p22_total_int 	= rm_ordp.p24_total_int * -1
	LET rm_pago.p22_total_mora 	= rm_ordp.p24_total_mora * -1
ELSE
	LET rm_pago.p22_total_cap 	= rm_ordp.p24_total_ret * -1
	LET rm_pago.p22_total_int 	= 0
	LET rm_pago.p22_total_mora 	= 0
END IF
LET rm_pago.p22_subtipo 	= rm_ordp.p24_subtipo
LET rm_pago.p22_origen 		= 'A'
LET rm_pago.p22_orden_pago	= rm_ordp.p24_orden_pago
LET rm_pago.p22_usuario 	= vg_usuario
LET rm_pago.p22_fecing 		= CURRENT
INSERT INTO cxpt022 VALUES (rm_pago.*)
LET tot_cap  = 0
LET tot_int  = 0
LET tot_mora = 0
LET i = 0
FOREACH q_det INTO r_pdoc.*
	IF cod_trn = vm_cod_aju THEN
		IF r_pdoc.p25_valor_ret = 0 THEN
			CONTINUE FOREACH
		END IF
		LET r_pdoc.p25_valor_cap  = r_pdoc.p25_valor_ret
		LET r_pdoc.p25_valor_int  = 0
		LET r_pdoc.p25_valor_mora = 0
	ELSE
		LET r_pdoc.p25_valor_cap  = r_pdoc.p25_valor_cap - 
					    r_pdoc.p25_valor_ret
	END IF
	INITIALIZE r_dpag.* TO NULL
	CALL fl_lee_documento_deudor_cxp(vg_codcia, vg_codloc, 
		rm_pago.p22_codprov, r_pdoc.p25_tipo_doc, r_pdoc.p25_num_doc,
		r_pdoc.p25_dividendo)
		RETURNING r_doc.*
	IF r_doc.p20_saldo_cap < r_pdoc.p25_valor_cap THEN
		LET label = 'Saldo capital de documento: ', 
			     r_pdoc.p25_tipo_doc, '-',
			     r_pdoc.p25_num_doc CLIPPED,  '-',
			     r_pdoc.p25_dividendo USING '&&'
		IF cod_trn = vm_cod_aju THEN
			LET label = label CLIPPED, ' menor que valor retenido'
		ELSE
			LET label = label CLIPPED, ' menor que valor pagado'
		END IF
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, label, 'stop')
		EXIT PROGRAM
	END IF
	IF r_doc.p20_saldo_int < r_pdoc.p25_valor_int THEN
		LET label = 'Saldo interés de documento: ', 
			     r_pdoc.p25_tipo_doc, '-',
			     r_pdoc.p25_num_doc CLIPPED,  '-',
			     r_pdoc.p25_dividendo USING '&&'
		IF cod_trn = vm_cod_aju THEN
			LET label = label CLIPPED, ' menor que valor retenido'
		ELSE
			LET label = label CLIPPED, ' menor que valor pagado'
		END IF
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, label, 'stop')
		EXIT PROGRAM
	END IF
	LET i = i + 1
    	LET r_dpag.p23_compania 	= vg_codcia
    	LET r_dpag.p23_localidad 	= vg_codloc
    	LET r_dpag.p23_codprov 		= rm_pago.p22_codprov
    	LET r_dpag.p23_tipo_trn 	= rm_pago.p22_tipo_trn
    	LET r_dpag.p23_num_trn 		= rm_pago.p22_num_trn
    	LET r_dpag.p23_orden 		= i
    	LET r_dpag.p23_tipo_doc 	= r_pdoc.p25_tipo_doc
    	LET r_dpag.p23_num_doc 		= r_pdoc.p25_num_doc
    	LET r_dpag.p23_div_doc 		= r_pdoc.p25_dividendo
    	LET r_dpag.p23_valor_cap 	= r_pdoc.p25_valor_cap * -1
    	LET r_dpag.p23_valor_int 	= r_pdoc.p25_valor_int * -1
    	LET r_dpag.p23_valor_mora 	= r_pdoc.p25_valor_mora * -1
    	LET r_dpag.p23_saldo_cap 	= r_doc.p20_saldo_cap
    	LET r_dpag.p23_saldo_int 	= r_doc.p20_saldo_int
	LET tot_cap  = tot_cap  + r_pdoc.p25_valor_cap
	LET tot_int  = tot_int  + r_pdoc.p25_valor_int
	LET tot_mora = tot_mora + r_pdoc.p25_valor_mora
	INSERT INTO cxpt023 VALUES (r_dpag.*)
	UPDATE cxpt020 SET p20_saldo_cap= p20_saldo_cap - r_pdoc.p25_valor_cap,
	                   p20_saldo_int= p20_saldo_int - r_pdoc.p25_valor_int
		WHERE p20_compania  = vg_codcia AND 
		      p20_localidad = vg_codloc AND 
		      p20_codprov   = r_doc.p20_codprov AND 
		      p20_tipo_doc  = r_doc.p20_tipo_doc AND 
		      p20_num_doc   = r_doc.p20_num_doc AND 
		      p20_dividendo = r_doc.p20_dividendo 
END FOREACH

END FUNCTION



FUNCTION genera_retencion()
DEFINE r_dpag		RECORD LIKE cxpt023.*
DEFINE r_doc		RECORD LIKE cxpt020.*
DEFINE r_pdoc		RECORD LIKE cxpt025.*
DEFINE r_pret		RECORD LIKE cxpt026.*
DEFINE r_dret		RECORD LIKE cxpt028.*
DEFINE i		SMALLINT
DEFINE tot_ret		DECIMAL(14,2)

SET LOCK MODE TO WAIT 5
INITIALIZE rm_ret.* TO NULL
LET rm_ret.p27_num_ret = fl_actualiza_control_secuencias(vg_codcia, vg_codloc,
		vg_modulo, 'AA', 'RT')
IF rm_ret.p27_num_ret <= 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
LET rm_ret.p27_compania     = vg_codcia
LET rm_ret.p27_localidad    = vg_codloc
LET rm_ret.p27_estado       = 'A'
LET rm_ret.p27_codprov 	    = rm_ordp.p24_codprov
LET rm_ret.p27_moneda 	    = rm_ordp.p24_moneda
LET rm_ret.p27_paridad 	    = rm_ordp.p24_paridad
LET rm_ret.p27_total_ret    = rm_ordp.p24_total_ret
LET rm_ret.p27_tip_contable = rm_ccomp.b12_tipo_comp
LET rm_ret.p27_num_contable = rm_ccomp.b12_num_comp
LET rm_ret.p27_origen 	    = 'A'
LET rm_ret.p27_usuario 	    = vg_usuario
LET rm_ret.p27_fecing 	    = CURRENT
INSERT INTO cxpt027 VALUES (rm_ret.*)
LET i = 0
FOREACH q_det INTO r_pdoc.*
	IF r_pdoc.p25_valor_ret = 0 THEN
		CONTINUE FOREACH
	END IF
	CALL fl_lee_documento_deudor_cxp(vg_codcia, vg_codloc, 
		r_pdoc.p25_codprov, r_pdoc.p25_tipo_doc, r_pdoc.p25_num_doc,
		r_pdoc.p25_dividendo)
		RETURNING r_doc.*
	DECLARE q_dret CURSOR FOR SELECT * FROM cxpt026
		WHERE p26_compania   = vg_codcia AND 
		      p26_localidad  = vg_codloc AND 
		      p26_orden_pago = r_pdoc.p25_orden_pago AND 
		      p26_secuencia  = r_pdoc.p25_secuencia
	LET tot_ret = 0
	FOREACH q_dret INTO r_pret.*
		INITIALIZE r_dret.* TO NULL
		LET i = i + 1
		LET tot_ret = tot_ret + r_pret.p26_valor_ret 
    		LET r_dret.p28_compania 	= vg_codcia
    		LET r_dret.p28_localidad 	= vg_codloc
    		LET r_dret.p28_num_ret 		= rm_ret.p27_num_ret
    		LET r_dret.p28_secuencia 	= i
    		LET r_dret.p28_codprov 		= rm_ret.p27_codprov
    		LET r_dret.p28_tipo_doc 	= r_pdoc.p25_tipo_doc
    		LET r_dret.p28_num_doc 		= r_pdoc.p25_num_doc
    		LET r_dret.p28_dividendo 	= r_pdoc.p25_dividendo
    		LET r_dret.p28_valor_fact 	= r_doc.p20_valor_fact
    		LET r_dret.p28_tipo_ret 	= r_pret.p26_tipo_ret
    		LET r_dret.p28_porcentaje 	= r_pret.p26_porcentaje
    		LET r_dret.p28_valor_base 	= r_pret.p26_valor_base
    		LET r_dret.p28_valor_ret 	= r_pret.p26_valor_ret
		INSERT INTO cxpt028 VALUES (r_dret.*)
	END FOREACH
	IF tot_ret <> r_pdoc.p25_valor_ret THEN
		ROLLBACK WORK
		CALL fgl_winmessage(vg_producto, 'Descuadre en retención de cabecera y detalle', 'stop')
		EXIT PROGRAM
	END IF
END FOREACH

END FUNCTION



FUNCTION genera_documento_favor()

INITIALIZE rm_fav.* TO NULL
LET rm_fav.p21_num_doc = fl_actualiza_control_secuencias(vg_codcia, vg_codloc,
		vg_modulo, 'AA', vm_cod_fav)
IF rm_fav.p21_num_doc <= 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
LET rm_fav.p21_compania 		= vg_codcia
LET rm_fav.p21_localidad		= vg_codloc
LET rm_fav.p21_codprov 		= rm_ordp.p24_codprov
LET rm_fav.p21_tipo_doc 		= vm_cod_fav
LET rm_fav.p21_referencia 	= rm_ordp.p24_referencia
IF rm_ordp.p24_referencia IS NULL THEN
	LET rm_fav.p21_referencia = '.'
END IF	
LET rm_fav.p21_fecha_emi 	= TODAY
LET rm_fav.p21_moneda 		= rm_ordp.p24_moneda
LET rm_fav.p21_paridad 		= rm_ordp.p24_paridad
LET rm_fav.p21_valor 		= rm_ordp.p24_total_cap
LET rm_fav.p21_saldo 		= rm_ordp.p24_total_cap
LET rm_fav.p21_subtipo 		= rm_ordp.p24_subtipo
LET rm_fav.p21_origen 		= 'A'
LET rm_fav.p21_orden_pago	= rm_ordp.p24_orden_pago
LET rm_fav.p21_usuario 		= vg_usuario
LET rm_fav.p21_fecing 		= CURRENT
INSERT INTO cxpt021 VALUES (rm_fav.*)

END FUNCTION



FUNCTION genera_comprobante_contable()
DEFINE r		RECORD LIKE ctbt013.*
DEFINE i		SMALLINT
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE glosa		LIKE ctbt013.b13_glosa
DEFINE valor_db		LIKE ctbt013.b13_valor_base
DEFINE valor_cr		LIKE ctbt013.b13_valor_base

LET rm_ccomp.b12_compania 	= vg_codcia
LET rm_ccomp.b12_tipo_comp 	= vm_cod_cont
LET rm_ccomp.b12_num_comp 	= fl_numera_comprobante_contable(vg_codcia, 
					vm_cod_cont, YEAR(TODAY), MONTH(TODAY)) 
IF rm_ccomp.b12_num_comp <= 0 THEN
	ROLLBACK WORK
	EXIT PROGRAM
END IF
LET rm_ccomp.b12_estado 	= 'A'
LET rm_ccomp.b12_origen 	= 'A'
LET rm_ccomp.b12_usuario 	= vg_usuario
LET rm_ccomp.b12_fecing 	= CURRENT

INSERT INTO ctbt012 VALUES (rm_ccomp.*) 
DECLARE q_dte CURSOR FOR SELECT * FROM temp_pago
	ORDER BY te_serial
--OJO ULTIMO ARREGLO
FOREACH q_dte INTO i, cuenta, glosa, valor_db, valor_cr
display 'EN CXPP206 ... GLOSA.. :' ,  glosa
	INITIALIZE r.* TO NULL 
    	LET r.b13_compania 	= vg_codcia
    	LET r.b13_tipo_comp 	= rm_ccomp.b12_tipo_comp
    	LET r.b13_num_comp      = rm_ccomp.b12_num_comp
    	LET r.b13_secuencia 	= i
    	LET r.b13_cuenta 	= cuenta
	IF cuenta = rm_bco.g09_aux_cont THEN
    		LET r.b13_tipo_doc 	= 'NDB'
	END IF
	IF glosa  IS NULL  THEN
		LET glosa   = 'PROVEEDOR : ', rm_prov.p01_nomprov CLIPPED
	END IF
    	LET r.b13_glosa 	= glosa
    	LET r.b13_valor_base 	= 0
    	LET r.b13_valor_aux 	= 0
	IF valor_db > 0 THEN
    		LET r.b13_valor_base = valor_db
	END IF
	IF valor_cr > 0 THEN
    		LET r.b13_valor_base = valor_cr * -1
	END IF
    	LET r.b13_fec_proceso 	= TODAY
    	LET r.b13_num_concil 	= 0
    	LET r.b13_codprov 	= rm_ordp.p24_codprov
	INSERT INTO ctbt013 VALUES (r.*) 
END FOREACH

END FUNCTION



FUNCTION valida_orden_pago(orden)
DEFINE orden		LIKE cxpt024.p24_orden_pago
DEFINE r		RECORD LIKE cxpt024.*
DEFINE icono		CHAR(12)

CALL fl_lee_orden_pago_cxp(vg_codcia, vg_codloc, orden) RETURNING r.*
LET icono = 'exclamation'
IF num_args() = 5 THEN
	LET icono = 'stop'
END IF
IF r.p24_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe orden de pago', icono)
	RETURN 0
END IF
LET rm_ordp.* = r.*
IF rm_ordp.p24_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Orden de pago no está activa', icono)
	RETURN 0
END IF
IF rm_ordp.p24_total_cap + rm_ordp.p24_total_int + rm_ordp.p24_total_ret +
	rm_ordp.p24_total_che = 0 THEN
	CALL fgl_winmessage(vg_producto, 'La orden de pago no tiene valor', icono)
	RETURN 0
END IF
{
IF rm_ordp.p24_medio_pago <> 'T' THEN
	CALL fgl_winmessage(vg_producto, 'La orden de pago no se cancela con transferencia.', icono)
	RETURN 0
END IF
}
RETURN 1

END FUNCTION



FUNCTION imprimir()

DEFINE resp			VARCHAR(10)
DEFINE retenciones		SMALLINT
DEFINE comando			VARCHAR(250)

LET comando = 'cd ..', vg_separador, '..', vg_separador,
	      'TESORERIA', vg_separador, 'fuentes', 
	      vg_separador, '; fglrun cxpp403 ', vg_base, ' ',
	      'TE', vg_codcia, ' ', vg_codloc, ' ', rm_ccomp.b12_tipo_comp, 
	      ' ', rm_ccomp.b12_num_comp

RUN comando

SELECT COUNT(*) INTO retenciones FROM cxpt028
WHERE p28_compania  = rm_ret.p27_compania
  AND p28_localidad = rm_ret.p27_localidad
  AND p28_num_ret   = rm_ret.p27_num_ret

IF retenciones = 0 THEN
	RETURN
END IF

CALL fgl_winquestion(vg_producto, 'Desea imprimir comprobante de retencion?', 
	'No', 'Yes|No', 'question', 1) RETURNING resp
IF resp = 'Yes' THEN
	LET comando = 'cd ..', vg_separador, '..', vg_separador,
		      'TESORERIA', vg_separador, 'fuentes', 
		      vg_separador, '; fglrun cxpp405 ', vg_base, ' ',
		      'TE', vg_codcia, ' ', vg_codloc,
		      ' ', rm_ret.p27_num_ret    

	RUN comando
END IF

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
