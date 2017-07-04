--------------------------------------------------------------------------------
-- Titulo           : cxpp206.4gl - Emisión de Cheque por Orden de Pago a 
--				    Proveedores
-- Elaboracion      : 30-Nov-2001
-- Autor            : YEC
-- Formato Ejecucion: fglrun cxpp206 base módulo compañía localidad
--		      fglrun cxpp206 base módulo compañía localidad orden_pago
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det	SMALLINT
DEFINE vm_tot_db	DECIMAL(14,2)
DEFINE vm_tot_cr	DECIMAL(14,2)
DEFINE rm_ordp		RECORD LIKE cxpt024.*
DEFINE rm_p29		RECORD LIKE cxpt029.*
DEFINE rm_prov		RECORD LIKE cxpt001.*
DEFINE rm_mon		RECORD LIKE gent013.*
DEFINE rm_bco		RECORD LIKE gent009.*
DEFINE rm_ccomp		RECORD LIKE ctbt012.*
DEFINE rm_ciacon	RECORD LIKE ctbt000.*
DEFINE rm_ciapag	RECORD LIKE cxpt000.*
DEFINE rm_pago		RECORD LIKE cxpt022.*
DEFINE rm_fav		RECORD LIKE cxpt021.*
DEFINE rm_ret		RECORD LIKE cxpt027.*
DEFINE rm_orden		ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_cod_pago	LIKE cxpt022.p22_tipo_trn
DEFINE vm_cod_aju	LIKE cxpt022.p22_tipo_trn
DEFINE vm_cod_fav	LIKE cxpt021.p21_tipo_doc
DEFINE vm_cod_cont	LIKE ctbt012.b12_tipo_comp
DEFINE vm_num_pago	INTEGER
DEFINE vm_aplicado	DECIMAL(12,2)
DEFINE rm_rows		ARRAY [1000] OF INTEGER
DEFINE rm_tran		ARRAY [500] OF RECORD
				b13_cuenta	LIKE ctbt013.b13_cuenta,
				b10_descripcion	LIKE ctbt010.b10_descripcion,
				valor_debito	LIKE ctbt013.b13_valor_base,
				valor_credito	LIKE ctbt013.b13_valor_base
			END RECORD



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxpp206.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN    -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxpp206'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
CALL fl_chequeo_mes_proceso_cxp(vg_codcia) RETURNING int_flag 
IF int_flag THEN
	RETURN
END IF
CREATE TEMP TABLE temp_pago 
	(te_serial		SERIAL,
	 te_cuenta		CHAR(12),
	 --te_glosa		VARCHAR(35),
	 te_glosa		VARCHAR(90),
	 te_valor_db		DECIMAL(14,2),
	 te_valor_cr		DECIMAL(14,2))
LET vm_max_rows	= 1000
LET vm_max_det  = 500
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 22
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW wf AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_ordp FROM "../forms/cxpf206_1"
ELSE
	OPEN FORM f_ordp FROM "../forms/cxpf206_1c"
END IF
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
LET vm_cod_cont	= 'EG'
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
	CALL fl_mostrar_mensaje('Compañía no existe o esta bloqueada.','stop')
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
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe la Orden de Pago.','stop')
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
IF rm_ordp.p24_banco = 0 THEN
	LET vm_cod_cont	= 'DC'
END IF
IF rm_ordp.p24_subtipo = 1 THEN
	LET vm_cod_cont	= 'DP'
END IF
CALL fl_lee_proveedor(rm_ordp.p24_codprov) RETURNING rm_prov.*
INITIALIZE rm_ccomp.* TO NULL
LET rm_ccomp.b12_modulo      = vg_modulo
LET rm_ccomp.b12_tipo_comp   = vm_cod_cont
LET rm_ccomp.b12_fec_proceso = TODAY
LET rm_ccomp.b12_benef_che   = rm_prov.p01_nomprov
IF rm_ordp.p24_banco = 0 THEN
	LET rm_ccomp.b12_benef_che = NULL
END IF
IF rm_ordp.p24_subtipo = 1 THEN
	LET rm_ccomp.b12_subtipo = 70
END IF
LET rm_ccomp.b12_glosa       = rm_ordp.p24_referencia
IF rm_ccomp.b12_glosa IS NULL THEN
	LET rm_ccomp.b12_glosa   = 'ORDEN DE PAGO # ', rm_ordp.p24_orden_pago
				    USING '####&'
END IF
LET rm_ccomp.b12_moneda      = rm_ordp.p24_moneda
LET rm_ccomp.b12_paridad     = rm_ordp.p24_paridad
CALL fl_lee_moneda(rm_ordp.p24_moneda) RETURNING r.*
DISPLAY BY NAME rm_ccomp.b12_tipo_comp, rm_ccomp.b12_fec_proceso,
		rm_ccomp.b12_benef_che, rm_ccomp.b12_glosa,
		rm_ccomp.b12_moneda,    rm_ccomp.b12_paridad
DISPLAY r.g13_nombre TO tit_moneda
CALL prepara_arreglo()
IF vm_tot_db <> vm_tot_cr OR vm_tot_db + vm_tot_cr = 0 THEN
	CALL fl_mostrar_mensaje('Comprobante descuadrado o sin valor.','stop')
	CLEAR FORM
	ROLLBACK WORK
	CALL muestra_titulos()
END IF
IF vm_tot_db - vm_aplicado <> rm_ordp.p24_total_cap + rm_ordp.p24_total_int OR 
	vm_tot_cr - vm_aplicado <> rm_ordp.p24_total_ret + rm_ordp.p24_total_che THEN
	CALL fl_mostrar_mensaje('No cuadran valores de cabecera con detalle en la orden de pago.','stop')
	CLEAR FORM
	ROLLBACK WORK
	CALL muestra_titulos()
	RETURN
END IF
CALL lee_cheque()
IF int_flag THEN
	CLEAR FORM
	ROLLBACK WORK
	CALL muestra_titulos()
	RETURN
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
	CALL genera_transaccion(vm_cod_pago, 0)
ELSE
	CALL genera_documento_favor()
END IF
IF rm_ordp.p24_total_ret > 0 THEN
	CALL genera_retencion()
	INITIALIZE rm_p29.* TO NULL
	IF validar_num_sri(1) <> 1 THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	CALL lee_num_ret_sri()
	IF int_flag THEN
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	CALL genera_num_ret_sri()
	CALL genera_transaccion(vm_cod_aju, 1)
END IF
UPDATE cxpt024 SET p24_estado       = 'P',
		   p24_numero_che   = rm_ccomp.b12_num_cheque,
		   p24_tip_contable = rm_ccomp.b12_tipo_comp,
		   p24_num_contable = rm_ccomp.b12_num_comp
	WHERE CURRENT OF q_ordp
CALL fl_genera_saldos_proveedor(vg_codcia, vg_codloc, rm_ordp.p24_codprov)
COMMIT WORK
CALL fl_mayoriza_comprobante(vg_codcia, rm_ccomp.b12_tipo_comp, 
			     rm_ccomp.b12_num_comp, 'M')

CALL control_imprimir_comprobante()

IF rm_ordp.p24_subtipo = 1 THEN
	CALL control_transferencia_banco()
END IF

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
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(p24_orden_pago) THEN
			CALL fl_ayuda_ordenes_pago_prov(vg_codcia, 
							vg_codloc, 'A')
				RETURNING orden
			IF orden IS NOT NULL THEN
				LET rm_ordp.p24_orden_pago = orden
				DISPLAY BY NAME rm_ordp.p24_orden_pago
			END IF
			LET int_flag = 0
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD p24_orden_pago
		IF rm_ordp.p24_orden_pago IS NOT NULL THEN
			IF NOT valida_orden_pago(rm_ordp.p24_orden_pago) THEN
				NEXT FIELD p24_orden_pago
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION lee_cheque()
DEFINE resp		VARCHAR(6)
DEFINE glosa		LIKE ctbt012.b12_glosa

LET int_flag = 0
INPUT BY NAME rm_ccomp.b12_num_cheque, rm_ccomp.b12_glosa
	WITHOUT DEFAULTS
        ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_1() 
	ON KEY(F5)
		CALL ver_orden()
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD b12_glosa
		LET glosa = rm_ccomp.b12_glosa
	AFTER FIELD b12_glosa
		IF rm_ccomp.b12_glosa IS NULL THEN
			LET rm_ccomp.b12_glosa = glosa
			DISPLAY BY NAME rm_ccomp.b12_glosa
		END IF
	AFTER FIELD b12_num_cheque
		IF rm_ordp.p24_banco = 0 OR rm_ordp.p24_subtipo = 1 THEN
			LET rm_ccomp.b12_num_cheque = NULL
			DISPLAY BY NAME rm_ccomp.b12_num_cheque
			CONTINUE INPUT
		END IF
		IF rm_ccomp.b12_num_cheque IS NULL THEN
			NEXT FIELD b12_num_cheque
		END IF
	AFTER INPUT
		IF int_flag THEN
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
			LET int_flag = 0
			NEXT FIELD b12_num_cheque
		END IF
		IF rm_ordp.p24_banco = 0 THEN
			LET rm_ccomp.b12_num_cheque = NULL
			DISPLAY BY NAME rm_ccomp.b12_num_cheque
		END IF
END INPUT

END FUNCTION



FUNCTION muestra_titulos()

--#DISPLAY 'Cuenta'        TO tit_col1
--#DISPLAY 'Descripción'   TO tit_col2
--#DISPLAY 'Valor Débito'  TO tit_col3
--#DISPLAY 'Valor Crédito' TO tit_col4

END FUNCTION



FUNCTION prepara_arreglo()
DEFINE valor		DECIMAL(14,2)
DEFINE tot_pag		DECIMAL(14,2)
DEFINE tot_ret		DECIMAL(14,2)
DEFINE r_p00		RECORD LIKE cxpt000.*
DEFINE r_p20		RECORD LIKE cxpt020.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r		RECORD LIKE cxpt002.*
DEFINE r_pdoc		RECORD LIKE cxpt025.*
DEFINE r_dret		RECORD LIKE cxpt026.*
DEFINE r_ret		RECORD LIKE ordt002.*
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE i		SMALLINT
DEFINE label		LIKE ctbt013.b13_glosa
DEFINE doc_fav		LIKE cxpt023.p23_tipo_favor 
DEFINE num_fav		LIKE cxpt023.p23_doc_favor 
DEFINE val_fav		LIKE cxpt023.p23_valor_cap
DEFINE aplicado		DECIMAL(12,2)

CALL fl_lee_proveedor_localidad(vg_codcia, vg_codloc, rm_ordp.p24_codprov)
	RETURNING r.*
IF r.p02_aux_prov_mb IS NULL THEN
	LET r.p02_aux_prov_mb = rm_ciapag.p00_aux_prov_mb	
	LET r.p02_aux_prov_ma = rm_ciapag.p00_aux_prov_ma	
	LET r.p02_aux_ant_mb  = rm_ciapag.p00_aux_ant_mb 	
	LET r.p02_aux_ant_ma  = rm_ciapag.p00_aux_ant_ma 
END IF
IF rm_ordp.p24_moneda <> rm_ciacon.b00_moneda_base THEN	
	LET r.p02_aux_prov_mb = r.p02_aux_prov_ma
	LET r.p02_aux_ant_mb  = r.p02_aux_ant_ma	
END IF
IF r.p02_aux_prov_mb IS NULL THEN
	ROLLBACK WORK                                                                                                  
	CALL fl_mostrar_mensaje('No se ha configurado auxiliar contable para el proveedor.','stop')           
	EXIT PROGRAM                                  
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
LET vm_aplicado = 0
FOREACH q_det INTO r_pdoc.*
	LET valor = r_pdoc.p25_valor_cap + r_pdoc.p25_valor_int
	LET tot_pag = tot_pag + valor
{
	LET label = r_pdoc.p25_tipo_doc, '-', r_pdoc.p25_num_doc CLIPPED,
		    '-', r_pdoc.p25_dividendo USING '&&&'
}
	DECLARE qu_osama CURSOR FOR 
		SELECT p23_tipo_favor, p23_doc_favor, p23_valor_cap * -1
			FROM cxpt023
			WHERE p23_compania  = r_pdoc.p25_compania  AND 
			      p23_localidad = r_pdoc.p25_localidad AND
			      p23_codprov   = rm_ordp.p24_codprov  AND
			      p23_tipo_doc  = r_pdoc.p25_tipo_doc  AND
			      p23_num_doc   = r_pdoc.p25_num_doc   AND
			      p23_div_doc   = r_pdoc.p25_dividendo AND
			      p23_tipo_favor IS NOT NULL 
	LET aplicado = 0
	FOREACH qu_osama INTO doc_fav, num_fav, val_fav
		LET aplicado = aplicado + val_fav
		IF doc_fav = 'PA' THEN
			LET cuenta = r.p02_aux_ant_mb
		ELSE
			LET cuenta = r.p02_aux_prov_mb
		END IF
		LET label = rm_prov.p01_nomprov[1,25] CLIPPED, ' ', doc_fav,
			    '-', num_fav USING '<<<<<<'
		CALL inserta_tabla_temporal(cuenta, val_fav, label, 'C')
		IF doc_fav = 'PA' THEN
			UPDATE temp_pago SET te_glosa = label
				WHERE te_cuenta = cuenta
		END IF
		LET vm_tot_cr = vm_tot_cr + val_fav
	END FOREACH
	LET vm_aplicado = vm_aplicado + aplicado
	LET label = rm_prov.p01_nomprov[1,25] CLIPPED, ' OP-',
			rm_ordp.p24_orden_pago USING '<<<<<'
	CALL fl_lee_compania_tesoreria(vg_codcia) RETURNING r_p00.*
	IF r_p00.p00_compania IS NULL THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No se ha configurado compañía en Tesorería.','stop')
		EXIT PROGRAM
	END IF
	LET valor = valor + aplicado					       
	IF r_p00.p00_tipo_egr_gen = 'D' AND aplicado <= 0 THEN
		LET label = rm_prov.p01_codprov USING '<<<<<&',
				' ', r_pdoc.p25_tipo_doc, '-',
				r_pdoc.p25_num_doc CLIPPED
		CALL fl_lee_documento_deudor_cxp(vg_codcia, vg_codloc,
				rm_prov.p01_codprov, r_pdoc.p25_tipo_doc, 
				r_pdoc.p25_num_doc, r_pdoc.p25_dividendo)
			RETURNING r_p20.*
		DECLARE q_r19 CURSOR FOR
			SELECT * FROM rept019
				WHERE r19_compania   = vg_codcia
				  AND r19_localidad  = vg_codloc
				  AND r19_oc_interna = r_p20.p20_numero_oc
		OPEN q_r19
		FOREACH q_r19 INTO r_r19.*
			IF r_r19.r19_cod_tran = 'CL' THEN
				LET label = label CLIPPED, ' ',
						r_r19.r19_cod_tran, '-',
						r_r19.r19_num_tran
						USING '<<<<<&'
				EXIT FOREACH
			END IF
		END FOREACH
	END IF
	CALL inserta_tabla_temporal(r.p02_aux_prov_mb, valor, label, 'D')
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
			CALL fl_lee_tipo_retencion(vg_codcia, r_dret.p26_tipo_ret,
						   r_dret.p26_porcentaje)
				RETURNING r_ret.*
			LET label  = 'RETENCION FACT # ',
					r_pdoc.p25_num_doc CLIPPED, ' RET #'
			CALL inserta_tabla_temporal(r_ret.c02_aux_cont, r_dret.p26_valor_ret, label, 'C')
			LET vm_tot_cr = vm_tot_cr + r_dret.p26_valor_ret
		END FOREACH
	END IF
END FOREACH
IF rm_ordp.p24_tipo = 'P' AND 
       (rm_ordp.p24_total_cap + rm_ordp.p24_total_int <> tot_pag OR
	rm_ordp.p24_total_ret <> tot_ret) THEN
	ROLLBACK WORK
	--CALL fgl_winmessage(vg_producto,'No cuadran valores de cabecera contra detalle de la orden de pago', 'stop')
	CALL fl_mostrar_mensaje('No cuadran valores de cabecera contra detalle de la orden de pago.','stop')
	EXIT PROGRAM
END IF
IF rm_ordp.p24_tipo = 'A' THEN
	LET cuenta = r.p02_aux_ant_mb
	IF rm_ordp.p24_moneda <> rm_ciacon.b00_moneda_base THEN
		LET cuenta = r.p02_aux_ant_ma
	END IF
	LET tot_pag   = rm_ordp.p24_total_cap + rm_ordp.p24_total_int
	LET vm_tot_db = tot_pag
	LET label     = rm_prov.p01_nomprov[1,10] CLIPPED, ' ',
			rm_ordp.p24_referencia CLIPPED
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
DEFINE glosa		LIKE ctbt013.b13_glosa

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
       	ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_1() 
	ON KEY(F5)
		CALL ver_orden()
	--#BEFORE DISPLAY
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
END DISPLAY

END FUNCTION



FUNCTION genera_transaccion(cod_trn, segundo)
DEFINE cod_trn		LIKE cxpt022.p22_tipo_trn
DEFINE segundo		SMALLINT
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
LET rm_pago.p22_fecing 		= CURRENT + segundo UNITS SECOND
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
		--CALL fgl_winmessage(vg_producto,label, 'stop')
		CALL fl_mostrar_mensaje(label, 'stop')
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
		--CALL fgl_winmessage(vg_producto, label, 'stop')
		CALL fl_mostrar_mensaje(label, 'stop')
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
    		LET r_dret.p28_codigo_sri       = r_pret.p26_codigo_sri
    		LET r_dret.p28_fecha_ini_porc   = r_pret.p26_fecha_ini_porc
    		LET r_dret.p28_valor_base 	= r_pret.p26_valor_base
    		LET r_dret.p28_valor_ret 	= r_pret.p26_valor_ret
		INSERT INTO cxpt028 VALUES (r_dret.*)
	END FOREACH
	IF tot_ret <> r_pdoc.p25_valor_ret THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('Descuadre en retención de cabecera y detalle', 'stop')
		EXIT PROGRAM
	END IF
END FOREACH

END FUNCTION



FUNCTION lee_num_ret_sri()
DEFINE aux_sri		LIKE cxpt029.p29_num_sri
DEFINE resp 		CHAR(6)
DEFINE resul		SMALLINT
DEFINE ini_rows 	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

LET ini_rows = 06
LET num_rows = 16
LET num_cols = 46
IF vg_gui = 0 THEN
	LET ini_rows = 05
	LET num_rows = 15
	LET num_cols = 47
END IF
OPEN WINDOW w_cxpf207_3 AT ini_rows, 17 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_cxpf207_3 FROM "../forms/cxpf207_3"
ELSE
	OPEN FORM f_cxpf207_3 FROM "../forms/cxpf207_3c"
END IF
DISPLAY FORM f_cxpf207_3
LET int_flag = 0
INPUT BY NAME rm_p29.p29_num_sri
	WITHOUT DEFAULTS
	ON KEY (INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_p29.p29_num_sri) THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
		LET int_flag = 0
		CALL fl_mensaje_abandonar_proceso() RETURNING resp
		IF resp = 'Yes' THEN
			LET int_flag = 1
			EXIT INPUT
		END IF
       	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD p29_num_sri
		LET aux_sri = rm_p29.p29_num_sri
		CALL validar_num_sri(0) RETURNING resul
		CASE resul
			WHEN -1
				ROLLBACK WORK
				EXIT PROGRAM
			WHEN 0
				NEXT FIELD p29_num_sri
		END CASE
	AFTER FIELD p29_num_sri
		IF rm_p29.p29_num_sri IS NOT NULL THEN
			CALL validar_num_sri(1) RETURNING resul
			CASE resul
				WHEN -1
					ROLLBACK WORK
					EXIT PROGRAM
				WHEN 0
					NEXT FIELD p29_num_sri
			END CASE
		ELSE
			LET rm_p29.p29_num_sri = aux_sri
			DISPLAY BY NAME rm_p29.p29_num_sri
		END IF
	AFTER INPUT
		IF rm_p29.p29_num_sri IS NOT NULL THEN
			CALL validar_num_sri(1) RETURNING resul
			CASE resul
				WHEN -1
					ROLLBACK WORK
					EXIT PROGRAM
				WHEN 0
					NEXT FIELD p29_num_sri
			END CASE
		ELSE
			LET rm_p29.p29_num_sri = aux_sri
			DISPLAY BY NAME rm_p29.p29_num_sri
		END IF
END INPUT
CLOSE WINDOW w_cxpf207_3
RETURN

END FUNCTION



FUNCTION validar_num_sri(validar)
DEFINE validar		SMALLINT
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE cont		INTEGER
DEFINE flag		SMALLINT

CALL fl_validacion_num_sri(vg_codcia, vg_codloc, 'RT', 'N', rm_p29.p29_num_sri)
	RETURNING r_g37.*, rm_p29.p29_num_sri, flag
CASE flag
	WHEN -1
		RETURN -1
	WHEN 0
		RETURN  0
END CASE
IF validar = 1 THEN
	SELECT COUNT(*) INTO cont FROM cxpt029
		WHERE p29_compania  = vg_codcia
		  AND p29_localidad = vg_codloc
  		  AND p29_num_sri   = rm_p29.p29_num_sri
	IF cont > 0 THEN
		CALL fl_mostrar_mensaje('La secuencia del SRI ' || rm_p29.p29_num_sri[9,15] || ' ya existe.','exclamation')
		RETURN 0
	END IF
END IF
RETURN 1

END FUNCTION



FUNCTION genera_num_ret_sri()
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE r_c02		RECORD LIKE ordt002.*
DEFINE r_p26		RECORD LIKE cxpt026.*
DEFINE sec_sri		LIKE gent037.g37_sec_num_sri
DEFINE glosa		LIKE ctbt013.b13_glosa
DEFINE cuantos		SMALLINT

WHENEVER ERROR CONTINUE
DECLARE q_sri CURSOR FOR
	SELECT * FROM gent037
		WHERE g37_compania   = vg_codcia
		  AND g37_localidad  = vg_codloc
		  AND g37_tipo_doc   = 'RT'
		{--
	  	  AND g37_fecha_emi <= DATE(TODAY)
	  	  AND g37_fecha_exp >= DATE(TODAY)
		--}
		  AND g37_secuencia IN
			(SELECT MAX(g37_secuencia)
				FROM gent037
				WHERE g37_compania  = vg_codcia
				  AND g37_localidad = vg_codloc
				  AND g37_tipo_doc  = 'RT')
		FOR UPDATE
OPEN q_sri
FETCH q_sri INTO r_g37.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Lo siento ahora no puede modificar este No. del SRI, porque ésta secuencia se encuentra bloqueada por otro usuario.', 'stop')
	WHENEVER ERROR STOP
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
LET cuantos = 8 + r_g37.g37_num_dig_sri
LET sec_sri = rm_p29.p29_num_sri[9, cuantos] USING "########"
UPDATE gent037
	SET g37_sec_num_sri = sec_sri
	WHERE g37_compania     = r_g37.g37_compania
	  AND g37_localidad    = r_g37.g37_localidad
	  AND g37_tipo_doc     = r_g37.g37_tipo_doc
	  AND g37_secuencia    = r_g37.g37_secuencia
	  AND g37_sec_num_sri <= sec_sri
INSERT INTO cxpt029
	VALUES (vg_codcia, vg_codloc, rm_ret.p27_num_ret, rm_p29.p29_num_sri)
INSERT INTO cxpt032
	VALUES (vg_codcia, vg_codloc, rm_ret.p27_num_ret, r_g37.g37_tipo_doc,
		r_g37.g37_secuencia)
DECLARE q_ret2 CURSOR FOR 
	SELECT cxpt026.*
		FROM cxpt025, cxpt026
		WHERE p25_compania   = vg_codcia
		  AND p25_localidad  = vg_codloc
		  AND p25_orden_pago = rm_ordp.p24_orden_pago
		  AND p26_compania   = p25_compania
		  AND p26_localidad  = p25_localidad
		  AND p26_orden_pago = p25_orden_pago
		  AND p26_secuencia  = p25_secuencia
		ORDER BY p25_secuencia
FOREACH q_ret2 INTO r_p26.*
	CALL fl_lee_tipo_retencion(vg_codcia, r_p26.p26_tipo_ret,
					r_p26.p26_porcentaje)
		RETURNING r_c02.*
	INITIALIZE glosa TO NULL
	DECLARE q_glo_ext CURSOR FOR
		SELECT b13_glosa
			FROM ctbt013
			WHERE b13_compania          = vg_codcia
			  AND b13_tipo_comp         = rm_ccomp.b12_tipo_comp
			  AND b13_num_comp          = rm_ccomp.b12_num_comp
			  AND b13_cuenta            = r_c02.c02_aux_cont
			  AND b13_valor_base * (-1) = r_p26.p26_valor_ret
	OPEN q_glo_ext
	FETCH q_glo_ext INTO glosa
	CLOSE q_glo_ext
	FREE q_glo_ext
	LET glosa = glosa, ' ', rm_p29.p29_num_sri CLIPPED
	UPDATE ctbt013
		SET b13_glosa = glosa
		WHERE b13_compania          = vg_codcia
		  AND b13_tipo_comp         = rm_ccomp.b12_tipo_comp
		  AND b13_num_comp          = rm_ccomp.b12_num_comp
		  AND b13_cuenta            = r_c02.c02_aux_cont
		  AND b13_valor_base * (-1) = r_p26.p26_valor_ret
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
DEFINE r_p02		RECORD LIKE cxpt002.*
DEFINE r_p20		RECORD LIKE cxpt020.*
DEFINE r_p25		RECORD LIKE cxpt025.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_aux		ARRAY[200] OF RECORD
				fact		LIKE cxpt025.p25_num_doc,
				cont		CHAR(1)
			END RECORD
DEFINE num, i, j	SMALLINT
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
CALL fl_lee_proveedor_localidad(vg_codcia, vg_codloc, rm_prov.p01_codprov)
	RETURNING r_p02.*
DECLARE q_dte CURSOR FOR SELECT * FROM temp_pago
	ORDER BY te_serial
DECLARE q_det_2 CURSOR FOR 
	SELECT * FROM cxpt025
		WHERE p25_compania   = vg_codcia
		  AND p25_localidad  = vg_codloc
		  AND p25_orden_pago = rm_ordp.p24_orden_pago
	ORDER BY p25_secuencia
LET num = 0
FOREACH q_det_2 INTO r_p25.*
	LET num             = num + 1
	LET r_aux[num].fact = r_p25.p25_num_doc
	LET r_aux[num].cont = 'N'
END FOREACH
FOREACH q_dte INTO i, cuenta, glosa, valor_db, valor_cr
	INITIALIZE r.* TO NULL 
    	LET r.b13_compania 	= vg_codcia
    	LET r.b13_tipo_comp 	= rm_ccomp.b12_tipo_comp
    	LET r.b13_num_comp      = rm_ccomp.b12_num_comp
    	LET r.b13_secuencia 	= i
    	LET r.b13_cuenta 	= cuenta
    	LET r.b13_glosa 	= glosa
	IF cuenta = r_p02.p02_aux_prov_mb THEN
		LET r.b13_glosa  = 'CANCELACION FACT # '
		INITIALIZE r_r19.* TO NULL
		FOR j = 1 TO num
			IF r_aux[j].cont = 'N' THEN
				LET r_p25.p25_num_doc = r_aux[j].fact
				IF valor_cr = 0 THEN
					LET r_aux[j].cont     = 'S'
				END IF
				EXIT FOR
			END IF
		END FOR
		CALL fl_lee_documento_deudor_cxp(vg_codcia, vg_codloc,
				rm_prov.p01_codprov, r_p25.p25_tipo_doc, 
				r_p25.p25_num_doc, r_p25.p25_dividendo)
			RETURNING r_p20.*
		LET r.b13_glosa  = r.b13_glosa CLIPPED, ' ',
					r_p20.p20_num_doc CLIPPED
		DECLARE q_r19_2 CURSOR FOR
			SELECT * FROM rept019
				WHERE r19_compania   = vg_codcia
				  AND r19_localidad  = vg_codloc
				  AND r19_oc_interna = r_p20.p20_numero_oc
		FOREACH q_r19_2 INTO r_r19.*
			IF r_r19.r19_cod_tran = 'CL' THEN
				LET r.b13_glosa = r.b13_glosa CLIPPED,
						' ', r_r19.r19_cod_tran, ' # ',
						r_r19.r19_num_tran
						USING '<<<<<<<<&'
				EXIT FOREACH
			END IF
		END FOREACH
		IF r_r19.r19_compania IS NULL THEN
			LET r.b13_glosa = r.b13_glosa CLIPPED, ' OC # ',
						r_p20.p20_numero_oc
						USING '<<<<<<<<&'
		END IF
	END IF
	IF cuenta = rm_bco.g09_aux_cont THEN
		LET r.b13_glosa = rm_prov.p01_nomprov[1,25] CLIPPED
		IF rm_ordp.p24_banco > 0 AND rm_ordp.p24_subtipo IS NULL THEN
    			LET r.b13_tipo_doc = 'CHE'
			LET r.b13_glosa = r.b13_glosa CLIPPED, ' Ch. ',
					rm_ccomp.b12_num_cheque USING '<<<&&&&#'
		END IF
		IF rm_ordp.p24_subtipo IS NOT NULL THEN
    			LET r.b13_tipo_doc = 'DEP'
			LET r.b13_glosa    = r.b13_glosa CLIPPED,
						'. TRANSFERENCIA '
		END IF
	END IF
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
	--CALL fgl_winmessage(vg_producto,'No existe orden de pago', icono)
	CALL fl_mostrar_mensaje('No existe orden de pago.',icono)
	RETURN 0
END IF
LET rm_ordp.* = r.*
IF rm_ordp.p24_estado <> 'A' THEN
	--CALL fgl_winmessage(vg_producto,'Orden de pago no está activa', icono)
	CALL fl_mostrar_mensaje('Orden de pago no está activa.',icono)
	RETURN 0
END IF
IF rm_ordp.p24_total_cap + rm_ordp.p24_total_int + rm_ordp.p24_total_ret +
	rm_ordp.p24_total_che = 0 THEN
	--CALL fgl_winmessage(vg_producto,'La orden de pago no tiene valor', icono)
	CALL fl_mostrar_mensaje('La orden de pago no tiene valor.',icono)
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION control_imprimir_comprobante()
DEFINE resp			VARCHAR(10)
DEFINE retenciones		SMALLINT
DEFINE comando			VARCHAR(250)
DEFINE run_prog			CHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador,
	      'TESORERIA', vg_separador, 'fuentes', 
	      vg_separador, run_prog, 'cxpp403 ', vg_base, ' ',
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

--CALL fgl_winquestion(vg_producto,'Desea imprimir comprobante de retencion?','No','Yes|No','question',1)
CALL fl_hacer_pregunta('Desea imprimir comprobante de retencion?','No')
	RETURNING resp
IF resp = 'Yes' THEN
	LET comando = 'cd ..', vg_separador, '..', vg_separador,
		      'TESORERIA', vg_separador, 'fuentes', 
		      vg_separador, run_prog, 'cxpp405 ', vg_base, ' ',
		      'TE', vg_codcia, ' ', vg_codloc,
		      ' ', rm_ret.p27_num_ret    

	RUN comando
END IF

END FUNCTION



FUNCTION ver_orden()
DEFINE comando		VARCHAR(100)
DEFINE run_prog		CHAR(10)

LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog = 'fglgo '
END IF
IF rm_ordp.p24_tipo = 'P' THEN
	LET comando = run_prog, 'cxpp204 ', vg_base, ' ', 
	       vg_modulo, ' ', vg_codcia, ' ', 
	       vg_codloc, ' ', rm_ordp.p24_orden_pago
ELSE
	LET comando = run_prog, 'cxpp205 ', vg_base, ' ', 
	       vg_modulo, ' ', vg_codcia, ' ', 
	       vg_codloc, ' ', rm_ordp.p24_orden_pago
END IF
RUN comando	

END FUNCTION



FUNCTION control_transferencia_banco()
DEFINE r_reg		RECORD
		tipo_reg		CHAR(5),	-- "BZDET"
		secuencia		INTEGER,	-- SEC.No.FILAS ARCH (6)
		cod_benefi		CHAR(18),	-- CODIGO PROV
		tipo_doc_id		CHAR(1),	-- C/R/P
		num_doc_id		CHAR(14),	-- CED/RUC/PAS
		nom_prov		CHAR(60),	-- p01_nomprov
		for_pago		CHAR(3),	-- CUE - CHE/COB/IMP/PEF
		cod_pais		CHAR(3),	-- SIEMPRE: 001
		cod_banco		CHAR(2),	-- 34
		tipo_cta		CHAR(2),	-- 03
		num_cta			CHAR(20),	-- PON CTA. COR. Y BLANC
		cod_mon			CHAR(1),	-- SIEMPRE: 1
		valor_pago		CHAR(15),	-- NO PONER CEROS
		concepto		CHAR(60),	-- REFERENCIA
		num_comprob		CHAR(15),	-- NUM. UNICO
		num_comp_ret		CHAR(15),	-- SIN GUIONES
		num_comp_iva		CHAR(15),	-- SIN GUIONES
		num_fact_sri		CHAR(20),	-- NORMAL
		cod_grupo		CHAR(10),	-- EN BLANCO
		desc_grupo		CHAR(50),	-- EN BLANCO
		dir_prov		CHAR(50),	-- p01_direccion1
		tel_prov		CHAR(20),	-- p01_telefono1
		cod_servicio		CHAR(3),	-- SIEMPRE: PRO
		autorizacion_sri	CHAR(10),	-- AUTORIZ. SRI
		fecha_validez		CHAR(10),	-- AAAAMMDD Y BLANCO
		referencia		CHAR(10),	-- EN BLANCO
		control_hor_ate		CHAR(1),	-- EN BLANCO
		cod_emp_bco		CHAR(5),	-- ASIGNADO POR EL BCO
		cod_sub_emp_bco		CHAR(6),	-- EN BLANCO
		sub_motivo_pag		CHAR(3)		-- SIEMPRE: RPA
			END RECORD
DEFINE query 		CHAR(6000)
DEFINE comando		VARCHAR(200)
DEFINE nom_arch		VARCHAR(100)
DEFINE mensaje		VARCHAR(200)
DEFINE secuen		INTEGER

CREATE TEMP TABLE tmp_arc_biz
	(
		tipo_reg		CHAR(5),	-- "BZDET"
		secuencia		SERIAL,		-- SEC.No.FILAS ARCH (6)
		cod_benefi		CHAR(18),	-- CODIGO PROV
		tipo_doc_id		CHAR(1),	-- C/R/P
		num_doc_id		CHAR(14),	-- CED/RUC/PAS
		nom_prov		CHAR(60),	-- p01_nomprov
		for_pago		CHAR(3),	-- CUE - CHE/COB/IMP/PEF
		cod_pais		CHAR(3),	-- SIEMPRE: 001
		cod_banco		CHAR(2),	-- 34
		tipo_cta		CHAR(2),	-- 03
		num_cta			CHAR(20),	-- PON CTA. COR. Y BLANC
		cod_mon			CHAR(1),	-- SIEMPRE: 1
		valor_pago		CHAR(15),	-- NO PONER CEROS
		concepto		CHAR(60),	-- REFERENCIA
		num_comprob		CHAR(15),	-- NUM. UNICO
		num_comp_ret		CHAR(15),	-- SIN GUIONES
		num_comp_iva		CHAR(15),	-- SIN GUIONES
		num_fact_sri		CHAR(20),	-- NORMAL
		cod_grupo		CHAR(10),	-- EN BLANCO
		desc_grupo		CHAR(50),	-- EN BLANCO
		dir_prov		CHAR(50),	-- p01_direccion1
		tel_prov		CHAR(20),	-- p01_telefono1
		cod_servicio		CHAR(3),	-- SIEMPRE: PRO
		autorizacion_sri	CHAR(10),	-- AUTORIZ. SRI
		fecha_validez		CHAR(10),	-- AAAAMMDD Y BLANCO
		referencia		CHAR(10),	-- EN BLANCO
		control_hor_ate		CHAR(1),	-- EN BLANCO
		cod_emp_bco		CHAR(5),	-- ASIGNADO POR EL BCO
		cod_sub_emp_bco		CHAR(6),	-- EN BLANCO
		sub_motivo_pag		CHAR(3)		-- SIEMPRE: RPA
	)

{--
LET query = 'SELECT "BZDET" AS tip_arch, ',
		'LPAD(p01_codprov, 18, 0) AS codprov, ',
		'p01_tipo_doc AS tip_d_id, ',
		--'LPAD(p01_num_doc, 15 + (14 - LENGTH(p01_num_doc)), 0) AS num_d_id, ',
		'RPAD(p01_num_doc, 14, " ") AS num_d_id, ',
		'RPAD(p01_nomprov[1, 60], 60, " ") AS nomprov, ',
		--'"CUE" AS for_pag, ',
		'CASE WHEN p02_cod_bco_tra = "34" ',
			'THEN "CUE" ',
			'ELSE "COB" ',
		'END AS for_pag, ',
		'"001" AS codpais, ',
		'RPAD(p02_cod_bco_tra, 2, " ") AS cod_bco, ',
		'CASE WHEN p02_tip_cta_prov = "C" THEN "03" ',
		'     WHEN p02_tip_cta_prov = "A" THEN "04" ',
		'     ELSE "  " ',
		'END AS tip_cta, ',
		--'LPAD(p02_cta_prov, 15 + (20 - LENGTH(p02_cta_prov)), " ") AS numcta, ',
		'LPAD(p02_cta_prov, 11, 0) AS numcta, ',
		'"1" AS codmon, ',
		'REPLACE(REPLACE(LPAD(p23_valor_cap, 16, 0), ".",',
			' ""), "-", "0") AS val_pago, ',
		--'LPAD(c10_referencia[1, 60], 60, " ") AS concep, ',
		'"                                                         +@." AS concep, ',
		--'LPAD(REPLACE(TRIM(c13_num_guia), "-", ""), 15, 0) AS num_com, ',
		'LPAD(TRIM("', rm_ccomp.b12_num_comp, '"), 15, 0) AS num_com, ',
		'NVL((SELECT LPAD(REPLACE(p29_num_sri, "-", ""), 15, 0) ',
			'FROM cxpt028, cxpt027, cxpt029 ',
			'WHERE p28_compania  = p20_compania ',
			'  AND p28_localidad = p20_localidad ',
			'  AND p28_codprov   = p20_codprov ',
			'  AND p28_tipo_doc  = p20_tipo_doc ',
			'  AND p28_num_doc   = p20_num_doc ',
			'  AND p28_dividendo = 1 ',
			'  AND p28_secuencia = 1 ',
			'  AND p28_tipo_ret  = "F" ',
			'  AND p27_compania  = p28_compania ',
			'  AND p27_localidad = p28_localidad ',
			'  AND p27_num_ret   = p28_num_ret ',
			'  AND p27_estado    = "A" ',
			'  AND p29_compania  = p27_compania ',
			'  AND p29_localidad = p27_localidad ',
			'  AND p29_num_ret   = p27_num_ret),0) AS numcompret, ',
		'NVL((SELECT LPAD(REPLACE(p29_num_sri, "-", ""), 15, 0) ',
			'FROM cxpt028, cxpt027, cxpt029 ',
			'WHERE p28_compania  = p20_compania ',
			'  AND p28_localidad = p20_localidad ',
			'  AND p28_codprov   = p20_codprov ',
			'  AND p28_tipo_doc  = p20_tipo_doc ',
			'  AND p28_num_doc   = p20_num_doc ',
			'  AND p28_dividendo = 1 ',
			'  AND p28_secuencia = 1 ',
			'  AND p28_tipo_ret  = "I" ',
			'  AND p27_compania  = p28_compania ',
			'  AND p27_localidad = p28_localidad ',
			'  AND p27_num_ret   = p28_num_ret ',
			'  AND p27_estado    = "A" ',
			'  AND p29_compania  = p27_compania ',
			'  AND p29_localidad = p27_localidad ',
			'  AND p29_num_ret   = p27_num_ret),0) AS numcompiva, ',
		'LPAD(REPLACE(TRIM(c13_factura), "-", ""), 15 + ',
			'(20 - LENGTH(REPLACE(TRIM(c13_factura), "-", ""))), ',
			'0) AS num_fac, ',
		'"       +@." AS cod_gr, ',
		'"                                               +@." AS des_gr, ',
		'RPAD(p01_direccion1[1, 60], 61, " ") AS dirprov, ',
		'RPAD(p01_telefono1, 11 + (20 - LENGTH(p01_telefono1)), ',
			'" ") AS telprov, ',
		'"PRO" AS cod_serv, ',
		'LPAD(c13_num_aut, 10, " ") AS autoriz, ',
		'LPAD(REPLACE(TO_CHAR(c13_fecha_cadu, "%Y/%m/%d") || "", "/",',
				' ""), 10, " ") AS fec_validez, ',
		'"       +@." AS referen, ',
		'"N" AS cont_hor_ate, ',
		'04607 AS codempbco, ',
		'"   +@." AS codsub_empbco, ',
		'"RPA" AS sub_mot_pag ',
		'FROM cxpt022, cxpt023, cxpt020, cxpt002, cxpt001, ordt010, ',
			'ordt013 ',
		'WHERE p22_compania   = ', vg_codcia,
		'  AND p22_localidad  = ', vg_codloc,
		'  AND p22_codprov    = ', rm_ordp.p24_codprov,
		'  AND p22_tipo_trn   = "PG" ',
		'  AND p22_orden_pago = ', rm_ordp.p24_orden_pago,
		'  AND p23_compania   = p22_compania ',
		'  AND p23_localidad  = p22_localidad ',
		'  AND p23_codprov    = p22_codprov ',
		'  AND p23_tipo_trn   = p22_tipo_trn ',
		'  AND p23_num_trn    = p22_num_trn ',
		'  AND p20_compania   = p23_compania ',
		'  AND p20_localidad  = p23_localidad ',
		'  AND p20_codprov    = p23_codprov ',
		'  AND p20_tipo_doc   = p23_tipo_doc ',
		'  AND p20_num_doc    = p23_num_doc ',
		'  AND p20_dividendo  = p23_div_doc ',
		'  AND p02_compania   = p20_compania ',
		'  AND p02_localidad  = p20_localidad ',
		'  AND p02_codprov    = p20_codprov ',
		'  AND p01_codprov    = p02_codprov ',
		'  AND c10_compania   = p20_compania ',
		'  AND c10_localidad  = p20_localidad ',
		'  AND c10_numero_oc  = p20_numero_oc ',
		'  AND c13_compania   = c10_compania ',
		'  AND c13_localidad  = c10_localidad ',
		'  AND c13_numero_oc  = c10_numero_oc ',
		'  AND c13_estado     = "A" ',
		'INTO TEMP t1 '
--}
LET query = 'SELECT "BZDET" AS tip_arch, ',
		'LPAD(p01_codprov, 18, 0) AS codprov, ',
		'p01_tipo_doc AS tip_d_id, ',
		'RPAD(p01_num_doc, 14, " ") AS num_d_id, ',
		'RPAD(p01_nomprov[1, 60], 60, " ") AS nomprov, ',
		'CASE WHEN p02_cod_bco_tra = "34" ',
			'THEN "CUE" ',
			'ELSE "COB" ',
		'END AS for_pag, ',
		'"001" AS codpais, ',
		'RPAD(p02_cod_bco_tra, 2, " ") AS cod_bco, ',
		'CASE WHEN p02_tip_cta_prov = "C" THEN "03" ',
		'     WHEN p02_tip_cta_prov = "A" THEN "04" ',
		'     ELSE "  " ',
		'END AS tip_cta, ',
		'LPAD(p02_cta_prov, 11, 0) AS numcta, ',
		'"1" AS codmon, ',
		'ROUND(SUM(NVL(p23_valor_cap, 0)), 2) AS val_pago, ',
		--'REPLACE(REPLACE(LPAD(p23_valor_cap, 16, 0), ".", ""), "-", "0") AS val_pago, ',
		'"                                                         +@." AS concep, ',
		'LPAD(TRIM("', rm_ccomp.b12_num_comp, '"), 15, 0) AS num_com, ',
		'"000000000000000" AS numcompret, ',
		'"000000000000000" AS numcompiva, ',
		'"000000000000000" AS num_fac, ',
		'"       +@." AS cod_gr, ',
		'"                                               +@." AS des_gr, ',
		'RPAD(p01_direccion1[1, 60], 61, " ") AS dirprov, ',
		'RPAD(p01_telefono1, 11 + (20 - LENGTH(p01_telefono1)), ',
			'" ") AS telprov, ',
		'"PRO" AS cod_serv, ',
		--'LPAD(c13_num_aut, 10, " ") AS autoriz, ',
		'"0000000000" AS autoriz, ',
		'LPAD(REPLACE(TO_CHAR(c13_fecha_cadu, "%Y/%m/%d") || "", "/",',
				' ""), 10, " ") AS fec_validez, ',
		'"       +@." AS referen, ',
		'"N" AS cont_hor_ate, ',
		'04607 AS codempbco, ',
		'"   +@." AS codsub_empbco, ',
		'"RPA" AS sub_mot_pag ',
		'FROM cxpt022, cxpt023, cxpt020, cxpt002, cxpt001, ordt010, ',
			'ordt013 ',
		'WHERE p22_compania   = ', vg_codcia,
		'  AND p22_localidad  = ', vg_codloc,
		'  AND p22_codprov    = ', rm_ordp.p24_codprov,
		'  AND p22_tipo_trn   = "PG" ',
		'  AND p22_orden_pago = ', rm_ordp.p24_orden_pago,
		'  AND p23_compania   = p22_compania ',
		'  AND p23_localidad  = p22_localidad ',
		'  AND p23_codprov    = p22_codprov ',
		'  AND p23_tipo_trn   = p22_tipo_trn ',
		'  AND p23_num_trn    = p22_num_trn ',
		'  AND p20_compania   = p23_compania ',
		'  AND p20_localidad  = p23_localidad ',
		'  AND p20_codprov    = p23_codprov ',
		'  AND p20_tipo_doc   = p23_tipo_doc ',
		'  AND p20_num_doc    = p23_num_doc ',
		'  AND p20_dividendo  = p23_div_doc ',
		'  AND p02_compania   = p20_compania ',
		'  AND p02_localidad  = p20_localidad ',
		'  AND p02_codprov    = p20_codprov ',
		'  AND p01_codprov    = p02_codprov ',
		'  AND c10_compania   = p20_compania ',
		'  AND c10_localidad  = p20_localidad ',
		'  AND c10_numero_oc  = p20_numero_oc ',
		'  AND c13_compania   = c10_compania ',
		'  AND c13_localidad  = c10_localidad ',
		'  AND c13_numero_oc  = c10_numero_oc ',
		'  AND c13_estado     = "A" ',
		'GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 14, 15, 16, ',
			'17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29 ',
		'INTO TEMP tmp_t1 '
PREPARE exec_dat FROM query
EXECUTE exec_dat
LET query = 'SELECT tip_arch, codprov, tip_d_id, num_d_id, nomprov, for_pag, ',
		'codpais, cod_bco, tip_cta, numcta, codmon, ',
		'REPLACE(REPLACE(LPAD(val_pago, 16, 0), ".", ""), "-",',
			' "0") AS val_pago, ',
		'concep, num_com, numcompret, numcompiva, num_fac, cod_gr, ',
		'des_gr, dirprov, telprov, cod_serv, autoriz, fec_validez, ',
		'referen, cont_hor_ate, codempbco, codsub_empbco, sub_mot_pag ',
		'FROM tmp_t1 ',
		'INTO TEMP t1 '
PREPARE exec_dat2 FROM query
EXECUTE exec_dat2
DROP TABLE tmp_t1
LET query = 'INSERT INTO tmp_arc_biz ',
		'(tipo_reg, secuencia, cod_benefi, tipo_doc_id, num_doc_id, ',
		'nom_prov, for_pago, cod_pais, cod_banco, tipo_cta, num_cta, ',
		'cod_mon, valor_pago, concepto, num_comprob, num_comp_ret, ',
		'num_comp_iva, num_fact_sri, cod_grupo, desc_grupo, dir_prov, ',
		'tel_prov, cod_servicio, autorizacion_sri, fecha_validez, ',
		'referencia, control_hor_ate, cod_emp_bco, cod_sub_emp_bco, ',
		'sub_motivo_pag) ',
		'SELECT tip_arch, 0, codprov, tip_d_id, num_d_id, nomprov, ',
			'for_pag, codpais, cod_bco, tip_cta, numcta, codmon, ',
			'val_pago, RPAD(concep, 60, " "), num_com, ',
			{--
			'CASE WHEN numcompret = "0" ',
				'THEN LPAD(numcompret, 15, 0) ',
				'ELSE ',
				'CASE WHEN LENGTH(numcompret) = 13 ',
					'THEN LPAD(numcompret, 17, 0) ',
					'ELSE LPAD(numcompret, 15, 0) ',
				'END ',
			'END AS numcompret, ',
			'CASE WHEN numcompiva = "0" ',
				'THEN LPAD(numcompiva, 15, 0) ',
				'ELSE ',
				'CASE WHEN LENGTH(numcompiva) = 13 ',
					'THEN LPAD(numcompiva, 17, 0) ',
					'ELSE LPAD(numcompiva, 15, 0) ',
				'END ',
			'END AS numcompiva, ',
			--}
			'"000000000000000", "000000000000000", ',
		--'num_fac, RPAD(cod_gr, 10, " "), RPAD(des_gr, 50, " "), ',
		'"000000000000000", RPAD(cod_gr, 10, " "), ',
		'RPAD(des_gr, 50, " "), ',
		'dirprov, telprov, cod_serv, autoriz, fec_validez, ',
		'RPAD(referen, 10, " "), cont_hor_ate, LPAD(codempbco, 5, 0), ',
		'RPAD(codsub_empbco, 6, " "), sub_mot_pag ',
		'FROM t1 '
PREPARE exec_ins_tab FROM query
EXECUTE exec_ins_tab
DROP TABLE t1
INITIALIZE r_reg.* TO NULL
DECLARE q_t1 CURSOR FOR
	SELECT * FROM tmp_arc_biz
		ORDER BY 2
FOREACH q_t1 INTO r_reg.*
	IF r_reg.nom_prov[58, 60] IS NULL OR r_reg.nom_prov[58, 60] = "   "
	THEN
		LET r_reg.nom_prov[58, 60] = "+@."
	END IF
	IF r_reg.dir_prov[48, 50] IS NULL OR r_reg.dir_prov[48, 50] = "   "
	THEN
		LET r_reg.dir_prov[48, 50] = "+@."
	END IF
	IF r_reg.tel_prov[18, 20] IS NULL OR r_reg.tel_prov[18, 20] = "   "
	THEN
		LET r_reg.tel_prov[18, 20] = "+@."
	END IF
	IF r_reg.num_cta[18, 20] IS NULL OR r_reg.num_cta[18, 20] = "   "
	THEN
		LET r_reg.num_cta[18, 20] = "+@."
	END IF
	IF r_reg.num_doc_id[12, 14] IS NULL OR r_reg.num_doc_id[12, 14] = "   "
	THEN
		LET r_reg.num_doc_id[12, 14] = "+@."
	END IF
	IF r_reg.num_doc_id[14, 14] IS NULL OR r_reg.num_doc_id[14, 14] = " "
	THEN
		LET r_reg.num_doc_id[14, 14] = "@"
	END IF
	{--
	IF r_reg.cod_banco[3, 3] IS NULL OR r_reg.cod_banco[3, 3] = " "
	THEN
		LET r_reg.cod_banco[3, 3] = "@"
	END IF
	--}
	UPDATE tmp_arc_biz
		SET nom_prov         = r_reg.nom_prov,
		    dir_prov         = r_reg.dir_prov,
		    tel_prov         = r_reg.tel_prov,
		    num_cta          = r_reg.num_cta,
		    num_doc_id       = r_reg.num_doc_id,
		    cod_banco        = r_reg.cod_banco,
		    autorizacion_sri = "       +@.",
		    fecha_validez    = "       +@."
		WHERE secuencia = r_reg.secuencia
END FOREACH
UNLOAD TO "../../../tmp/arch_tr_pago.txt" DELIMITER "|"
SELECT tipo_reg, LPAD(secuencia, 6, 0) AS secuencia, cod_benefi, tipo_doc_id,
	num_doc_id, nom_prov, for_pago, cod_pais, cod_banco, tipo_cta, num_cta,
	cod_mon, valor_pago, concepto, num_comprob, num_comp_ret,
	num_comp_iva, num_fact_sri, RPAD(cod_grupo, 10, " ") AS cod_grupo,
	RPAD(desc_grupo, 50, " ") AS desc_grupo, dir_prov, tel_prov,
	cod_servicio, autorizacion_sri, fecha_validez,
	RPAD(referencia, 10, " ") AS referencia, control_hor_ate,
	cod_emp_bco, RPAD(cod_sub_emp_bco, 6, " ") AS cod_sub_emp_bco,
	sub_motivo_pag
	FROM tmp_arc_biz
	--GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30
DROP TABLE tmp_arc_biz
SELECT COUNT(p24_subtipo)
	INTO secuen
	FROM cxpt024
	WHERE p24_compania      = vg_codcia
	  AND p24_localidad     = vg_codloc
	  AND p24_orden_pago   <= rm_ordp.p24_orden_pago
	  AND DATE(p24_fecing)  = DATE(rm_ordp.p24_fecing)
IF secuen = 0 THEN
	LET secuen = 1
END IF
LET nom_arch = "ACEROCOM", DATE(rm_ordp.p24_fecing) USING "yyyy",
		DATE(rm_ordp.p24_fecing) USING "mm",
		DATE(rm_ordp.p24_fecing) USING "dd",
		secuen USING "&&&&"
LET nom_arch = nom_arch CLIPPED, ".BIZ"
LET mensaje  = 'Archivo ', nom_arch CLIPPED, ' Generado ', FGL_GETENV("HOME"),
		'/tmp/  OK'
LET comando  = 'sed -e "s/+@./   /g" ../../../tmp/arch_tr_pago.txt > ../../../tmp/temporal.txt'
RUN comando
LET comando  = 'sed -e "s/@/ /g" ../../../tmp/temporal.txt > ../../../tmp/temporal2.txt'
RUN comando
LET comando  = 'sed -e "s/|//g" ../../../tmp/temporal2.txt > ../../../tmp/temporal.txt'
RUN comando
LET comando  = "mv ../../../tmp/temporal.txt ../../../tmp/temporal2.txt"
RUN comando
LET comando  = "mv ../../../tmp/temporal2.txt ../../../tmp/arch_tr_pago.txt"
RUN comando
LET comando  = "mv ../../../tmp/arch_tr_pago.txt $HOME/tmp/", nom_arch CLIPPED
RUN comando
LET comando  = "unix2dos $HOME/tmp/", nom_arch CLIPPED
RUN comando
CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION



FUNCTION llamar_visor_teclas()
DEFINE a		CHAR(1)

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION



FUNCTION control_visor_teclas_caracter_1() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Ver Orden'                AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
