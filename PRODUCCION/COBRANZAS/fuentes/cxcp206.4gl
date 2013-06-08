------------------------------------------------------------------------------
-- Titulo           : cxcp206.4gl - Mantenimiento de cheques postfechados 
-- Elaboracion      : 12-dic-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun cxcp206 base módulo compañía localidad
--			[cliente] [banco] [numero_cuenta] [numero_cheque]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nuevoprog	CHAR(400)
DEFINE rm_z26		RECORD LIKE cxct026.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY[10000] OF INTEGER



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp206.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 8 THEN  -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'cxcp206'
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
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 20
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
	OPEN FORM f_cxc FROM "../forms/cxcf206_1"
ELSE
	OPEN FORM f_cxc FROM "../forms/cxcf206_1c"
END IF
DISPLAY FORM f_cxc
INITIALIZE rm_z26.* TO NULL
LET vm_num_rows    = 0
LET vm_row_current = 0
LET vm_max_rows	   = 10000
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Imprimir'
		HIDE OPTION 'Bloquear/Activar'
		IF num_args() = 8 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			SHOW OPTION 'Imprimir'
			CALL control_consulta()
			IF vm_num_rows = 0 THEN
                                EXIT PROGRAM
                        END IF
		END IF
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Bloquear/Activar'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
	COMMAND KEY('M') 'Modificar' 'Modifica un registro.'
		CALL control_modificacion()
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Bloquear/Activar'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Imprimir'
				HIDE OPTION 'Bloquear/Activar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Imprimir'
			SHOW OPTION 'Bloquear/Activar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('P') 'Imprimir' 'Imprime registro corriente. '
		CALL control_imprimir()
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro. '
		CALL muestra_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		CALL muestra_anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
     	COMMAND KEY('B') 'Bloquear/Activar' 'Bloquear o activar registro. '
		CALL bloquear_activar()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()

CALL fl_retorna_usuario()
INITIALIZE rm_z26.* TO NULL
CLEAR z26_estado, tit_estado_che, tit_nombre_cli, tit_banco, tit_tipo_doc,
	tit_area, tit_saldo
LET rm_z26.z26_compania  = vg_codcia
LET rm_z26.z26_localidad = vg_codloc
LET rm_z26.z26_estado    = 'A'
LET rm_z26.z26_valor     = 0
LET rm_z26.z26_usuario   = vg_usuario
LET rm_z26.z26_fecing    = CURRENT
CALL muestra_estado()
CALL leer_datos('I')
IF NOT int_flag THEN
	LET rm_z26.z26_fecing = CURRENT
	INSERT INTO cxct026 VALUES (rm_z26.*)
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	DISPLAY BY NAME rm_z26.z26_fecing
	LET vm_row_current = vm_num_rows
	LET vm_r_rows[vm_row_current] = SQLCA.SQLERRD[6] 
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL mostrar_registro(vm_r_rows[vm_num_rows])	
	CALL fl_mensaje_registro_ingresado()
ELSE
	CLEAR FORM
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
END IF

END FUNCTION



FUNCTION control_modificacion()
DEFINE done 		SMALLINT
DEFINE i    		SMALLINT

IF vm_num_rows = 0 THEN   
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
IF rm_z26.z26_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_upd CURSOR FOR
	SELECT * FROM cxct026 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_z26.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF  
WHENEVER ERROR STOP
CALL leer_datos('M')
IF int_flag THEN
	ROLLBACK WORK
	CALL mostrar_registro(vm_r_rows[vm_row_current])
	RETURN
END IF 
UPDATE cxct026 SET * = rm_z26.* WHERE CURRENT OF q_upd
COMMIT WORK
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_consulta()
DEFINE cod_aux		LIKE cxct002.z02_codcli
DEFINE nom_aux		LIKE cxct001.z01_nomcli
DEFINE codb_aux         LIKE gent008.g08_banco
DEFINE nomb_aux         LIKE gent008.g08_nombre
DEFINE tipo_aux         LIKE gent009.g09_tipo_cta
DEFINE num_aux          LIKE gent009.g09_numero_cta
DEFINE codt_aux		LIKE cxct004.z04_tipo_doc
DEFINE nomt_aux		LIKE cxct004.z04_nombre
DEFINE coda_aux		LIKE gent003.g03_areaneg
DEFINE noma_aux		LIKE gent003.g03_nombre
DEFINE r_cxc		RECORD LIKE cxct026.*
DEFINE saldo		LIKE cxct020.z20_saldo_cap
DEFINE mone		LIKE cxct020.z20_moneda
DEFINE abrevia		LIKE gent003.g03_abreviacion
DEFINE query		CHAR(800)
DEFINE expr_sql		CHAR(600)
DEFINE num_reg		INTEGER

CLEAR FORM
INITIALIZE cod_aux, codb_aux, codt_aux, coda_aux, r_cxc.* TO NULL
LET int_flag = 0
IF num_args() = 4 THEN
	CONSTRUCT BY NAME expr_sql ON z26_estado, z26_codcli, z26_banco,
	z26_num_cta, z26_num_cheque, z26_valor, z26_fecha_cobro, z26_referencia,
	z26_areaneg, z26_tipo_doc, z26_num_doc, z26_dividendo, z26_usuario
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(z26_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				DISPLAY cod_aux TO z26_codcli 
				DISPLAY nom_aux TO tit_nombre_cli
			END IF 
		END IF
		IF INFIELD(z26_banco) THEN
                        CALL fl_ayuda_bancos()
                                RETURNING codb_aux, nomb_aux
                        LET int_flag = 0
                        IF codb_aux IS NOT NULL THEN
                                DISPLAY codb_aux TO z26_banco
                                DISPLAY nomb_aux TO tit_banco
                        END IF
                END IF
		IF INFIELD(z26_areaneg) THEN
			CALL fl_ayuda_areaneg(vg_codcia)
				RETURNING coda_aux, noma_aux
			LET int_flag = 0
			IF coda_aux IS NOT NULL THEN
				DISPLAY coda_aux TO z26_areaneg
				DISPLAY noma_aux TO tit_area
			END IF 
		END IF
		IF INFIELD(z26_tipo_doc) THEN
			CALL fl_ayuda_tipo_documento_cobranzas('D')
				RETURNING codt_aux, nomt_aux
			LET int_flag = 0
			IF codt_aux IS NOT NULL THEN
				DISPLAY codt_aux TO z26_tipo_doc
				DISPLAY nomt_aux TO tit_tipo_doc
			END IF 
		END IF
		IF INFIELD(z26_num_doc) THEN
			CALL fl_ayuda_doc_deudores_cob(vg_codcia, vg_codloc,
					coda_aux, cod_aux, codt_aux)
				RETURNING nom_aux, r_cxc.z26_tipo_doc,
					r_cxc.z26_num_doc, r_cxc.z26_dividendo,
					saldo, mone, abrevia
			LET int_flag = 0
			IF r_cxc.z26_num_doc IS NOT NULL THEN
				DISPLAY BY NAME r_cxc.z26_dividendo
				DISPLAY BY NAME r_cxc.z26_num_doc
				DISPLAY saldo TO tit_saldo
			END IF 
		END IF
		BEFORE CONSTRUCT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
	END CONSTRUCT
	IF int_flag THEN
		IF vm_row_current > 0 THEN
			CALL muestra_contadores(vm_row_current, vm_num_rows)
			CALL mostrar_registro(vm_r_rows[vm_row_current])
		ELSE
			CLEAR FORM
		END IF
		RETURN
	END IF
ELSE
	LET expr_sql = ' z26_codcli     = ' || arg_val(5) ||
		   ' AND z26_banco      = ' || arg_val(6) ||
		   ' AND z26_num_cta    = ' || '"' || arg_val(7) || '"' ||
		   ' AND z26_num_cheque = ' || '"' || arg_val(8) || '"'
END IF
LET query = 'SELECT *, ROWID FROM cxct026 ' ||
		'WHERE z26_compania   = ' || vg_codcia ||
		'  AND z26_localidad  = ' || vg_codloc ||
		'  AND ' || expr_sql CLIPPED||
		' ORDER BY 3, 4, 5, 6'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_z26.*, num_reg
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		LET vm_num_rows = vm_num_rows - 1
                EXIT FOREACH
        END IF
	LET vm_r_rows[vm_num_rows] = num_reg
END FOREACH
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	CLEAR FORM
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
ELSE  
	LET vm_row_current = 1
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION leer_datos(flag)
DEFINE resp		CHAR(6)
DEFINE r_cxc_aux	RECORD LIKE cxct026.*
DEFINE r_doc		RECORD LIKE cxct020.*
DEFINE r_cli		RECORD LIKE cxct002.*
DEFINE r_cli_gen	RECORD LIKE cxct001.*
DEFINE r_bco_gen	RECORD LIKE gent008.*
DEFINE r_tip		RECORD LIKE cxct004.*
DEFINE r_are		RECORD LIKE gent003.*
DEFINE cod_aux		LIKE cxct002.z02_codcli
DEFINE nom_aux		LIKE cxct001.z01_nomcli
DEFINE codb_aux         LIKE gent008.g08_banco
DEFINE nomb_aux         LIKE gent008.g08_nombre
DEFINE tipo_aux         LIKE gent009.g09_tipo_cta
DEFINE num_aux          LIKE gent009.g09_numero_cta
DEFINE codt_aux		LIKE cxct004.z04_tipo_doc
DEFINE nomt_aux		LIKE cxct004.z04_nombre
DEFINE coda_aux		LIKE gent003.g03_areaneg
DEFINE noma_aux		LIKE gent003.g03_nombre
DEFINE r_cxc		RECORD LIKE cxct026.*
DEFINE saldo		LIKE cxct020.z20_saldo_cap
DEFINE mone		LIKE cxct020.z20_moneda
DEFINE abrevia		LIKE gent003.g03_abreviacion
DEFINE valor		LIKE cxct026.z26_valor
DEFINE flag		CHAR(1)

INITIALIZE r_cxc_aux.*, r_cli.*, r_cli_gen.*, r_bco_gen, r_tip.*, r_are.*,
	cod_aux, codb_aux, codt_aux, coda_aux, r_cxc.* TO NULL
DISPLAY BY NAME rm_z26.z26_usuario, rm_z26.z26_fecing
LET int_flag = 0
INPUT BY NAME rm_z26.z26_codcli, rm_z26.z26_banco, rm_z26.z26_num_cta,
	rm_z26.z26_num_cheque, rm_z26.z26_valor, rm_z26.z26_fecha_cobro,
	rm_z26.z26_referencia, rm_z26.z26_areaneg, rm_z26.z26_tipo_doc,
	rm_z26.z26_num_doc, rm_z26.z26_dividendo
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
	        IF field_touched(rm_z26.z26_codcli, rm_z26.z26_banco,
			rm_z26.z26_num_cta, rm_z26.z26_num_cheque,
			rm_z26.z26_valor, rm_z26.z26_fecha_cobro,
			rm_z26.z26_referencia, rm_z26.z26_areaneg,
			rm_z26.z26_tipo_doc, rm_z26.z26_num_doc,
			rm_z26.z26_dividendo)
	        THEN
	               	LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                		RETURNING resp
	              	IF resp = 'Yes' THEN
				LET int_flag = 1
                	       	CLEAR FORM
                       		RETURN
	                END IF
		ELSE
			RETURN
		END IF
       	ON KEY(F1,CONTROL-W)
		CALL control_visor_teclas_caracter_1() 
	ON KEY(F2)
		IF INFIELD(z26_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_z26.z26_codcli = cod_aux
				DISPLAY BY NAME rm_z26.z26_codcli 
				DISPLAY nom_aux TO tit_nombre_cli
			END IF 
		END IF
		IF INFIELD(z26_banco) THEN
                        CALL fl_ayuda_bancos()
                                RETURNING codb_aux, nomb_aux
                        LET int_flag = 0
                        IF codb_aux IS NOT NULL THEN
				LET rm_z26.z26_banco = codb_aux
                                DISPLAY BY NAME rm_z26.z26_banco
                                DISPLAY nomb_aux TO tit_banco
                        END IF
                END IF
		IF INFIELD(z26_areaneg) THEN
			CALL fl_ayuda_areaneg(vg_codcia)
				RETURNING coda_aux, noma_aux
			LET int_flag = 0
			IF coda_aux IS NOT NULL THEN
				LET rm_z26.z26_areaneg = coda_aux
				DISPLAY BY NAME rm_z26.z26_areaneg
				DISPLAY noma_aux TO tit_area
			END IF 
		END IF
		IF INFIELD(z26_tipo_doc) THEN
			CALL fl_ayuda_tipo_documento_cobranzas('D')
				RETURNING codt_aux, nomt_aux
			LET int_flag = 0
			IF codt_aux IS NOT NULL THEN
				LET rm_z26.z26_tipo_doc = codt_aux
				DISPLAY BY NAME rm_z26.z26_tipo_doc
				DISPLAY nomt_aux TO tit_tipo_doc
			END IF 
		END IF
		IF INFIELD(z26_num_doc) THEN
			CALL fl_ayuda_doc_deudores_cob(vg_codcia, vg_codloc,
					rm_z26.z26_areaneg, rm_z26.z26_codcli,
					rm_z26.z26_tipo_doc)
				RETURNING nom_aux, r_cxc.z26_tipo_doc,
					r_cxc.z26_num_doc, r_cxc.z26_dividendo,
					saldo, mone, abrevia
			LET int_flag = 0
			IF r_cxc.z26_num_doc IS NOT NULL THEN
				LET rm_z26.z26_num_doc = r_cxc.z26_num_doc
				LET rm_z26.z26_dividendo = r_cxc.z26_dividendo
				DISPLAY BY NAME rm_z26.z26_dividendo
				DISPLAY BY NAME rm_z26.z26_num_doc
				DISPLAY saldo TO tit_saldo
			END IF 
		END IF
	ON KEY(F5)
		CALL ver_documento_deudor()
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD z26_valor
		LET valor = rm_z26.z26_valor
	AFTER FIELD z26_codcli
		IF rm_z26.z26_codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_z26.z26_codcli)
		 		RETURNING r_cli_gen.*
			IF r_cli_gen.z01_codcli IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Cliente no existe.','exclamation')
				CALL fl_mostrar_mensaje('Cliente no existe.','exclamation')
				NEXT FIELD z26_codcli
			END IF
			DISPLAY r_cli_gen.z01_nomcli TO tit_nombre_cli
			IF r_cli_gen.z01_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD z26_codcli
                        END IF		 
			CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc,
							rm_z26.z26_codcli)
		 		RETURNING r_cli.*
			IF r_cli.z02_compania IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Cliente no está activado para la compañía.','exclamation')
				CALL fl_mostrar_mensaje('Cliente no está activado para la compañía.','exclamation')
				NEXT FIELD z26_codcli
			END IF
		ELSE
			CLEAR tit_nombre_cli
		END IF
	AFTER FIELD z26_banco
                IF rm_z26.z26_banco IS NOT NULL THEN
                        CALL fl_lee_banco_general(rm_z26.z26_banco)
                                RETURNING r_bco_gen.*
			IF r_bco_gen.g08_banco IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Banco no existe.','exclamation')
				CALL fl_mostrar_mensaje('Banco no existe.','exclamation')
				NEXT FIELD z26_banco
			END IF
			DISPLAY r_bco_gen.g08_nombre TO tit_banco
		ELSE
			CLEAR tit_banco
                END IF
	AFTER FIELD z26_valor
		IF rm_z26.z26_valor IS NULL THEN
			LET rm_z26.z26_valor = valor
			DISPLAY BY NAME rm_z26.z26_valor
		END IF
	AFTER FIELD z26_areaneg
		IF rm_z26.z26_areaneg IS NOT NULL THEN
			CALL fl_lee_area_negocio(vg_codcia,rm_z26.z26_areaneg)
				RETURNING r_are.*
			IF r_are.g03_areaneg IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Area de Negocio no existe.','exclamation')
				CALL fl_mostrar_mensaje('Area de Negocio no existe.','exclamation')
				NEXT FIELD z26_areaneg
			END IF
			DISPLAY r_are.g03_nombre TO tit_area
		ELSE
			CLEAR tit_area
		END IF
	AFTER FIELD z26_tipo_doc 
		IF rm_z26.z26_tipo_doc IS NOT NULL THEN
			CALL fl_lee_tipo_doc(rm_z26.z26_tipo_doc)
				RETURNING r_tip.* 
			IF r_tip.z04_tipo_doc IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Tipo de documento no existe.','exclamation')
				CALL fl_mostrar_mensaje('Tipo de documento no existe.','exclamation')
				NEXT FIELD z26_tipo_doc
			END IF
			DISPLAY r_tip.z04_nombre TO tit_tipo_doc
			IF r_tip.z04_tipo <> 'D' THEN
				--CALL fgl_winmessage(vg_producto,'Tipo de documento debe ser deudor.','exclamation')
				CALL fl_mostrar_mensaje('Tipo de documento debe ser deudor.','exclamation')
				NEXT FIELD z26_tipo_doc
			END IF
			IF rm_z26.z26_tipo_doc <> 'DO'
			AND rm_z26.z26_tipo_doc <> 'DI'
			AND rm_z26.z26_tipo_doc <> 'FA'
			AND rm_z26.z26_tipo_doc <> 'ND' THEN
				--CALL fgl_winmessage(vg_producto,'Tipo de documento debe ser deudor.','exclamation')
				CALL fl_mostrar_mensaje('Tipo de documento debe ser de cobro a clientes.','exclamation')
				NEXT FIELD z26_tipo_doc
			END IF
			IF r_tip.z04_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD z26_tipo_doc
			END IF
		ELSE
			CLEAR tit_tipo_doc
		END IF
	AFTER FIELD z26_fecha_cobro
		IF rm_z26.z26_fecha_cobro IS NOT NULL THEN
			IF rm_z26.z26_fecha_cobro < TODAY THEN
				--CALL fgl_winmessage(vg_producto,'La fecha de cobro no puede ser menor a la fecha de hoy.','exclamation')
				CALL fl_mostrar_mensaje('La fecha de cobro no puede ser menor a la fecha de hoy.','exclamation')
				NEXT FIELD z26_fecha_cobro
			END IF
		END IF
	AFTER INPUT
		IF rm_z26.z26_valor = 0 THEN
			--CALL fgl_winmessage(vg_producto,'El valor del cheque debe ser mayor a cero.','exclamation')
			CALL fl_mostrar_mensaje('El valor del cheque debe ser mayor a cero.','exclamation')
			NEXT FIELD z26_valor
		END IF
		CALL fl_lee_cheque_fecha_cxc(vg_codcia, vg_codloc,
				rm_z26.z26_codcli, rm_z26.z26_banco,
				rm_z26.z26_num_cta, rm_z26.z26_num_cheque)
			RETURNING r_cxc_aux.*
		IF r_cxc_aux.z26_compania IS NOT NULL AND flag = 'I' THEN
			--CALL fgl_winmessage(vg_producto,'Cheque ya ha sido ingresado.','exclamation')
			CALL fl_mostrar_mensaje('Cheque ya ha sido ingresado.','exclamation')
			NEXT FIELD z26_num_cheque
		END IF
		IF rm_z26.z26_tipo_doc IS NOT NULL THEN
			CALL fl_lee_documento_deudor_cxc(vg_codcia, vg_codloc,
				rm_z26.z26_codcli, rm_z26.z26_tipo_doc,
				rm_z26.z26_num_doc, rm_z26.z26_dividendo)
				RETURNING r_doc.*
			IF r_doc.z20_compania IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Documento no existe.','exclamation')
				CALL fl_mostrar_mensaje('Documento no existe.','exclamation')
				NEXT FIELD z26_tipo_doc
			END IF
		END IF
		{
		IF r_doc.z20_saldo_cap + r_doc.z20_saldo_int > rm_z26.z26_valor
		THEN
			--CALL fgl_winmessage(vg_producto,'El saldo del documento no puede ser mayor al valor del cheque.','exclamation')
			CALL fl_mostrar_mensaje('El saldo del documento no puede ser mayor al valor del cheque.','exclamation')
			NEXT FIELD z26_valor
		END IF
		}
END INPUT

END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL mostrar_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL mostrar_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION muestra_contadores(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	INTEGER
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_z04		RECORD LIKE cxct004.*
DEFINE r_z20		RECORD LIKE cxct020.*
DEFINE saldo		DECIMAL(14,2)

IF vm_num_rows < 1 THEN
	RETURN
END IF
SELECT * INTO rm_z26.* FROM cxct026 WHERE ROWID = num_registro
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || vm_row_current, 'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_z26.z26_codcli, rm_z26.z26_banco, rm_z26.z26_num_cta,
		rm_z26.z26_num_cheque, rm_z26.z26_valor,
		rm_z26.z26_fecha_cobro, rm_z26.z26_referencia,
		rm_z26.z26_areaneg, rm_z26.z26_tipo_doc,
		rm_z26.z26_num_doc, rm_z26.z26_dividendo,
		rm_z26.z26_usuario, rm_z26.z26_fecing
CALL fl_lee_cliente_general(rm_z26.z26_codcli) RETURNING r_z01.*
DISPLAY r_z01.z01_nomcli TO tit_nombre_cli
CALL fl_lee_tipo_doc(rm_z26.z26_tipo_doc) RETURNING r_z04.* 
DISPLAY r_z04.z04_nombre TO tit_tipo_doc
CALL fl_lee_area_negocio(vg_codcia,rm_z26.z26_areaneg) RETURNING r_g03.*
DISPLAY r_g03.g03_nombre TO tit_area
CALL fl_lee_banco_general(rm_z26.z26_banco) RETURNING r_g08.*
DISPLAY r_g08.g08_nombre TO tit_banco
CALL fl_lee_documento_deudor_cxc(vg_codcia, vg_codloc, rm_z26.z26_codcli,
				rm_z26.z26_tipo_doc, rm_z26.z26_num_doc,
				rm_z26.z26_dividendo)
	RETURNING r_z20.*
LET saldo = r_z20.z20_saldo_cap + r_z20.z20_saldo_int
DISPLAY saldo TO tit_saldo
CALL muestra_estado()

END FUNCTION



FUNCTION bloquear_activar()
DEFINE confir		CHAR(6)

CALL mostrar_registro(vm_r_rows[vm_row_current])
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET int_flag = 0
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_ba CURSOR FOR
	SELECT * FROM cxct026 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_ba
FETCH q_ba INTO rm_z26.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF	
WHENEVER ERROR STOP
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING confir
IF confir <> 'Yes' THEN
	ROLLBACK WORK
	RETURN
END IF
LET int_flag = 1
CALL bloquea_activa_registro()
COMMIT WORK
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION bloquea_activa_registro()
DEFINE estado		CHAR(1)

IF rm_z26.z26_estado = 'A' THEN
	DISPLAY 'BLOQUEADO' TO tit_estado_che
	LET estado = 'B'
ELSE 
	DISPLAY 'ACTIVO' TO tit_estado_che
	LET estado = 'A'
END IF
DISPLAY estado TO z26_estado
UPDATE cxct026 SET z26_estado = estado WHERE CURRENT OF q_ba
LET rm_z26.z26_estado = estado

END FUNCTION



FUNCTION retorna_estado()

IF rm_z26.z26_estado = 'A' THEN
	RETURN 'ACTIVO'
ELSE
	RETURN 'BLOQUEADO'
END IF

END FUNCTION



FUNCTION muestra_estado()
DEFINE tit_estado_che	VARCHAR(15)

IF rm_z26.z26_estado = 'A' THEN
	LET tit_estado_che = 'ACTIVO'
ELSE
	LET tit_estado_che = 'BLOQUEADO'
END IF
DISPLAY BY NAME rm_z26.z26_estado, tit_estado_che

END FUNCTION



FUNCTION ver_documento_deudor()
DEFINE run_prog		CHAR(10)

IF rm_z26.z26_tipo_doc IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'Ingrese primero el tipo de documento.','exclamation')
	CALL fl_mostrar_mensaje('Ingrese primero el tipo de documento.','exclamation')
	RETURN
END IF
IF rm_z26.z26_num_doc IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'Ingrese el número de documento.','exclamation')
	CALL fl_mostrar_mensaje('Ingrese el número de documento.','exclamation')
	RETURN
END IF
IF rm_z26.z26_dividendo IS NULL THEN
	--CALL fgl_winmessage(vg_producto,'Ingrese el dividendo de documento.','exclamation')
	CALL fl_mostrar_mensaje('Ingrese el dividendo de documento.','exclamation')
	RETURN
END IF
LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
	vg_separador, 'fuentes', vg_separador, run_prog, 'cxcp200 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ', rm_z26.z26_codcli,
	' ', rm_z26.z26_tipo_doc, ' ', rm_z26.z26_num_doc, ' ',
	rm_z26.z26_dividendo 
RUN vm_nuevoprog

END FUNCTION



FUNCTION control_imprimir()
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT reporte_cheque_postfechado TO PIPE comando
OUTPUT TO REPORT reporte_cheque_postfechado()
FINISH REPORT reporte_cheque_postfechado

END FUNCTION



REPORT reporte_cheque_postfechado()
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_z04		RECORD LIKE cxct004.*
DEFINE r_z20		RECORD LIKE cxct020.*
DEFINE saldo		DECIMAL(14,2)
DEFINE usuario		VARCHAR(20)
DEFINE modulo		VARCHAR(20)
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_10cpi	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	132
	BOTTOM MARGIN	4
	PAGE LENGTH	44

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresión
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario     = "USUARIO: ", vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	CALL fl_lee_cliente_general(rm_z26.z26_codcli) RETURNING r_z01.*
	CALL fl_lee_banco_general(rm_z26.z26_banco) RETURNING r_g08.*
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_10cpi
	PRINT COLUMN 001, r_g01.g01_razonsocial
	SKIP 2 LINES
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 052, "COMPROBANTE CHEQUE POSTFECHADO" CLIPPED,
	      COLUMN 125, UPSHIFT(vg_proceso) CLIPPED
	SKIP 3 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 113, usuario
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	SKIP 1 LINES
	PRINT COLUMN 114, "ESTADO: ",  rm_z26.z26_estado, " ", retorna_estado()
	SKIP 1 LINES
	PRINT COLUMN 001, "CLIENTE       : ", rm_z26.z26_codcli USING "&&&&&&",
	      COLUMN 024, r_z01.z01_nomcli CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 001, "BANCO         : ", rm_z26.z26_banco USING "&&&&",
	      COLUMN 024, r_g08.g08_nombre CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 001, "CUENTA        : ", rm_z26.z26_num_cta,
	      COLUMN 090, "No. CHEQUE   : ", rm_z26.z26_num_cheque
	SKIP 1 LINES
	PRINT COLUMN 001, "VALOR CHEQUE  : ",
			rm_z26.z26_valor USING "###,##&.##",
	      COLUMN 090, "FECHA COBRO  : ",
			rm_z26.z26_fecha_cobro USING "dd-mm-yyyy"
	SKIP 1 LINES
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	CALL fl_lee_tipo_doc(rm_z26.z26_tipo_doc) RETURNING r_z04.* 
	CALL fl_lee_area_negocio(vg_codcia,rm_z26.z26_areaneg) RETURNING r_g03.*
	CALL fl_lee_documento_deudor_cxc(vg_codcia, vg_codloc,rm_z26.z26_codcli,
					rm_z26.z26_tipo_doc, rm_z26.z26_num_doc,
					rm_z26.z26_dividendo)
		RETURNING r_z20.*
	LET saldo = r_z20.z20_saldo_cap + r_z20.z20_saldo_int
	SKIP 2 LINES
	PRINT COLUMN 001, "REFERENCIA    : ", rm_z26.z26_referencia CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 001, "AREA NEGOCIO  : ", rm_z26.z26_areaneg USING "<<<&",
	      COLUMN 024, r_g03.g03_nombre CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 001, "TIPO DOCUMENTO: ", rm_z26.z26_tipo_doc,
	      COLUMN 024, r_z04.z04_nombre CLIPPED,
	      COLUMN 090, "No. DOCUMENTO: ", rm_z26.z26_num_doc
	SKIP 1 LINES
	PRINT COLUMN 001, "DIVIDENDO     : ",rm_z26.z26_dividendo USING "<<<&&",
	      COLUMN 090, "SALDO        : ", saldo USING "----,--&.##"
	SKIP 7 LINES

PAGE TRAILER
	SKIP 2 LINES
	PRINT COLUMN 029, "------------------------",
	      COLUMN 081, "------------------------"
	PRINT COLUMN 029, "    RECIBI  CONFORME",
	      COLUMN 081, "   ENTREGUE  CONFORME";
	print ASCII escape;
	print ASCII desact_comp

END REPORT



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
DISPLAY '<F5>      Documento Deudor'         AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
