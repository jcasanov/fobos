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

DEFINE rm_cxc		RECORD LIKE cxct026.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY [1000] OF INTEGER

DEFINE vm_page		SMALLINT	-- PAGE   LENGTH
DEFINE vm_top		SMALLINT	-- TOP    MARGIN
DEFINE vm_left		SMALLINT	-- LEFT   MARGIN
DEFINE vm_right		SMALLINT	-- RIGHT  MARGIN
DEFINE vm_bottom	SMALLINT	-- BOTTOM MARGIN

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp206.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 8 THEN  -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'cxcp206'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
LET vm_max_rows	= 1000
OPEN WINDOW wf AT 3,2 WITH 20 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_cxc FROM "../forms/cxcf206_1"
DISPLAY FORM f_cxc
INITIALIZE rm_cxc.* TO NULL
LET vm_num_rows    = 0
LET vm_row_current = 0
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
			HIDE OPTION 'Modificar'
			HIDE OPTION 'Consultar'

		   IF fl_control_permiso_opcion('Imprimir') THEN			
			SHOW OPTION 'Imprimir'
		   END IF 
			
			CALL control_consulta()
			IF vm_num_rows = 0 THEN
               EXIT PROGRAM
            END IF
		END IF
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 
		   IF fl_control_permiso_opcion('Imprimir') THEN
			   SHOW OPTION 'Imprimir'
		   END IF
		   
		   IF fl_control_permiso_opcion('Bloquear') THEN
			SHOW OPTION 'Bloquear/Activar'
	  	   END IF
		
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
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 
		   IF fl_control_permiso_opcion('Imprimir') THEN
			   SHOW OPTION 'Imprimir'
		   END IF
		   
		   IF fl_control_permiso_opcion('Bloquear') THEN
			SHOW OPTION 'Bloquear/Activar'
	  	   END IF

			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
		
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Imprimir'
				HIDE OPTION 'Bloquear/Activar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
		   IF fl_control_permiso_opcion('Modificar') THEN			
			SHOW OPTION 'Modificar'
		   END IF 
		   IF fl_control_permiso_opcion('Imprimir') THEN
			   SHOW OPTION 'Imprimir'
		   END IF
		   
		   IF fl_control_permiso_opcion('Bloquear') THEN
			SHOW OPTION 'Bloquear/Activar'
	  	   END IF
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('P') 'Imprimir' 'Imprime comprobante.'
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
INITIALIZE rm_cxc.* TO NULL
CLEAR z26_estado, tit_estado_che, tit_nombre_cli, tit_banco, tit_tipo_doc,
	tit_area, tit_saldo
LET rm_cxc.z26_compania  = vg_codcia
LET rm_cxc.z26_localidad = vg_codloc
LET rm_cxc.z26_estado    = 'A'
LET rm_cxc.z26_valor     = 0
LET rm_cxc.z26_usuario   = vg_usuario
LET rm_cxc.z26_fecing    = CURRENT
CALL muestra_estado()
CALL leer_datos('I')
IF NOT int_flag THEN
	LET rm_cxc.z26_fecing = CURRENT
	INSERT INTO cxct026 VALUES (rm_cxc.*)
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	DISPLAY BY NAME rm_cxc.z26_fecing
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

IF rm_cxc.z26_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF

CALL mostrar_registro(vm_r_rows[vm_row_current])

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_upd CURSOR FOR 
	SELECT * FROM cxct026 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_upd
FETCH q_upd INTO rm_cxc.*
WHENEVER ERROR STOP
IF STATUS < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	ROLLBACK WORK
	RETURN
END IF  

CALL leer_datos('M')
IF INT_FLAG THEN
	ROLLBACK WORK
	CALL mostrar_registro(vm_r_rows[vm_row_current])
	CLOSE q_upd
	RETURN
END IF 

UPDATE cxct026 SET * = rm_cxc.* WHERE CURRENT OF q_upd

COMMIT WORK
CLOSE q_upd
FREE  q_upd
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
DEFINE query		VARCHAR(800)
DEFINE expr_sql		VARCHAR(600)
DEFINE num_reg		INTEGER

CLEAR FORM
INITIALIZE cod_aux, codb_aux, codt_aux, coda_aux, r_cxc.* TO NULL
LET int_flag = 0
IF num_args() = 4 THEN
	CONSTRUCT BY NAME expr_sql ON z26_estado, z26_codcli, z26_banco,
	z26_num_cta, z26_num_cheque, z26_valor, z26_fecha_cobro, z26_referencia,
	z26_areaneg, z26_tipo_doc, z26_num_doc, z26_dividendo, z26_usuario
	ON KEY(F2)
		IF infield(z26_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				DISPLAY cod_aux TO z26_codcli 
				DISPLAY nom_aux TO tit_nombre_cli
			END IF 
		END IF
		IF infield(z26_banco) THEN
                        CALL fl_ayuda_bancos()
                                RETURNING codb_aux, nomb_aux
                        LET int_flag = 0
                        IF codb_aux IS NOT NULL THEN
                                DISPLAY codb_aux TO z26_banco
                                DISPLAY nomb_aux TO tit_banco
                        END IF
                END IF
		IF infield(z26_areaneg) THEN
			CALL fl_ayuda_areaneg(vg_codcia)
				RETURNING coda_aux, noma_aux
			LET int_flag = 0
			IF coda_aux IS NOT NULL THEN
				DISPLAY coda_aux TO z26_areaneg
				DISPLAY noma_aux TO tit_area
			END IF 
		END IF
		IF infield(z26_tipo_doc) THEN
			CALL fl_ayuda_tipo_documento_cobranzas('D')
				RETURNING codt_aux, nomt_aux
			LET int_flag = 0
			IF codt_aux IS NOT NULL THEN
				DISPLAY codt_aux TO z26_tipo_doc
				DISPLAY nomt_aux TO tit_tipo_doc
			END IF 
		END IF
		IF infield(z26_num_doc) THEN
			CALL fl_ayuda_doc_deudores_cob(vg_codcia, vg_codloc,
					coda_aux, cod_aux, codt_aux, 0)
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
		'WHERE z26_compania  = ' || vg_codcia ||
		'  AND z26_localidad = ' || vg_codloc ||
		'  AND ' || expr_sql CLIPPED||
		' ORDER BY 3,4,5,6'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_cxc.*, num_reg
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



FUNCTION leer_datos (flag)
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
DISPLAY BY NAME rm_cxc.z26_usuario, rm_cxc.z26_fecing
LET int_flag = 0
INPUT BY NAME rm_cxc.z26_codcli, rm_cxc.z26_banco, rm_cxc.z26_num_cta,
	rm_cxc.z26_num_cheque, rm_cxc.z26_valor, rm_cxc.z26_fecha_cobro,
	rm_cxc.z26_referencia, rm_cxc.z26_areaneg, rm_cxc.z26_tipo_doc,
	rm_cxc.z26_num_doc, rm_cxc.z26_dividendo
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
	        IF field_touched(rm_cxc.z26_codcli, rm_cxc.z26_banco,
			rm_cxc.z26_num_cta, rm_cxc.z26_num_cheque,
			rm_cxc.z26_valor, rm_cxc.z26_fecha_cobro,
			rm_cxc.z26_referencia, rm_cxc.z26_areaneg,
			rm_cxc.z26_tipo_doc, rm_cxc.z26_num_doc,
			rm_cxc.z26_dividendo)
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
	ON KEY(F2)
		IF infield(z26_codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia,vg_codloc)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				LET rm_cxc.z26_codcli = cod_aux
				DISPLAY BY NAME rm_cxc.z26_codcli 
				DISPLAY nom_aux TO tit_nombre_cli
			END IF 
		END IF
		IF infield(z26_banco) THEN
                        CALL fl_ayuda_bancos()
                                RETURNING codb_aux, nomb_aux
                        LET int_flag = 0
                        IF codb_aux IS NOT NULL THEN
				LET rm_cxc.z26_banco = codb_aux
                                DISPLAY BY NAME rm_cxc.z26_banco
                                DISPLAY nomb_aux TO tit_banco
                        END IF
                END IF
		IF infield(z26_areaneg) THEN
			CALL fl_ayuda_areaneg(vg_codcia)
				RETURNING coda_aux, noma_aux
			LET int_flag = 0
			IF coda_aux IS NOT NULL THEN
				LET rm_cxc.z26_areaneg = coda_aux
				DISPLAY BY NAME rm_cxc.z26_areaneg
				DISPLAY noma_aux TO tit_area
			END IF 
		END IF
		IF infield(z26_tipo_doc) THEN
			CALL fl_ayuda_tipo_documento_cobranzas('D')
				RETURNING codt_aux, nomt_aux
			LET int_flag = 0
			IF codt_aux IS NOT NULL THEN
				LET rm_cxc.z26_tipo_doc = codt_aux
				DISPLAY BY NAME rm_cxc.z26_tipo_doc
				DISPLAY nomt_aux TO tit_tipo_doc
			END IF 
		END IF
		IF infield(z26_num_doc) THEN
			CALL fl_ayuda_doc_deudores_cob(vg_codcia, vg_codloc,
					rm_cxc.z26_areaneg, rm_cxc.z26_codcli,
					rm_cxc.z26_tipo_doc, 1)
				RETURNING nom_aux, r_cxc.z26_tipo_doc,
					r_cxc.z26_num_doc, r_cxc.z26_dividendo,
					saldo, mone, abrevia
			LET int_flag = 0
			IF r_cxc.z26_num_doc IS NOT NULL THEN
				LET rm_cxc.z26_num_doc = r_cxc.z26_num_doc
				LET rm_cxc.z26_dividendo = r_cxc.z26_dividendo
				DISPLAY BY NAME rm_cxc.z26_dividendo
				DISPLAY BY NAME rm_cxc.z26_num_doc
				DISPLAY saldo TO tit_saldo
			END IF 
		END IF
	ON KEY(F5)
		CALL ver_documento_deudor()
	BEFORE FIELD z26_valor
		LET valor = rm_cxc.z26_valor
	AFTER FIELD z26_codcli
		IF rm_cxc.z26_codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_cxc.z26_codcli)
		 		RETURNING r_cli_gen.*
			IF r_cli_gen.z01_codcli IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Cliente no existe.','exclamation')
				NEXT FIELD z26_codcli
			END IF
			DISPLAY r_cli_gen.z01_nomcli TO tit_nombre_cli
			IF r_cli_gen.z01_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD z26_codcli
                        END IF		 
			CALL fl_lee_cliente_localidad(vg_codcia, vg_codloc,
							rm_cxc.z26_codcli)
		 		RETURNING r_cli.*
			IF r_cli.z02_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Cliente no está activado para la compañía.','exclamation')
				NEXT FIELD z26_codcli
			END IF
		ELSE
			CLEAR tit_nombre_cli
		END IF
	AFTER FIELD z26_banco
                IF rm_cxc.z26_banco IS NOT NULL THEN
                        CALL fl_lee_banco_general(rm_cxc.z26_banco)
                                RETURNING r_bco_gen.*
			IF r_bco_gen.g08_banco IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Banco no existe.','exclamation')
				NEXT FIELD z26_banco
			END IF
			DISPLAY r_bco_gen.g08_nombre TO tit_banco
		ELSE
			CLEAR tit_banco
                END IF
	AFTER FIELD z26_valor
		IF rm_cxc.z26_valor IS NULL THEN
			LET rm_cxc.z26_valor = valor
			DISPLAY BY NAME rm_cxc.z26_valor
		END IF
	AFTER FIELD z26_areaneg
		IF rm_cxc.z26_areaneg IS NOT NULL THEN
			CALL fl_lee_area_negocio(vg_codcia,rm_cxc.z26_areaneg)
				RETURNING r_are.*
			IF r_are.g03_areaneg IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Area de Negocio no existe.','exclamation')
				NEXT FIELD z26_areaneg
			END IF
			DISPLAY r_are.g03_nombre TO tit_area
		ELSE
			CLEAR tit_area
		END IF
	AFTER FIELD z26_tipo_doc 
		IF rm_cxc.z26_tipo_doc IS NOT NULL THEN
			CALL fl_lee_tipo_doc(rm_cxc.z26_tipo_doc)
				RETURNING r_tip.* 
			IF r_tip.z04_tipo_doc IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Tipo de documento no existe.','exclamation')
				NEXT FIELD z26_tipo_doc
			END IF
			DISPLAY r_tip.z04_nombre TO tit_tipo_doc
			IF r_tip.z04_tipo <> 'D' THEN
				CALL fgl_winmessage(vg_producto,'Tipo de documento debe ser deudor.','exclamation')
				NEXT FIELD z26_tipo_doc
			END IF
			IF rm_cxc.z26_tipo_doc <> 'DO'
			AND rm_cxc.z26_tipo_doc <> 'FA'
			AND rm_cxc.z26_tipo_doc <> 'ND' THEN
				CALL fgl_winmessage(vg_producto,'Tipo de documento debe ser deudor.','exclamation')
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
		IF rm_cxc.z26_fecha_cobro IS NOT NULL THEN
			IF rm_cxc.z26_fecha_cobro < TODAY THEN
				CALL fgl_winmessage(vg_producto,'La fecha de cobro no puede ser menor a la fecha de hoy.','exclamation')
				NEXT FIELD z26_fecha_cobro
			END IF
		END IF
	AFTER INPUT
		IF rm_cxc.z26_valor = 0 THEN
			CALL fgl_winmessage(vg_producto,'El valor del cheque debe ser mayor a cero.','exclamation')
			NEXT FIELD z26_valor
		END IF
		CALL fl_lee_cheque_fecha_cxc(vg_codcia, vg_codloc,
				rm_cxc.z26_codcli, rm_cxc.z26_banco,
				rm_cxc.z26_num_cta, rm_cxc.z26_num_cheque)
			RETURNING r_cxc_aux.*
		IF r_cxc_aux.z26_compania IS NOT NULL AND flag = 'I' THEN
			CALL fgl_winmessage(vg_producto,'Cheque ya ha sido ingresado.','exclamation')
			NEXT FIELD z26_num_cheque
		END IF
		IF rm_cxc.z26_tipo_doc IS NOT NULL THEN
			CALL fl_lee_documento_deudor_cxc(vg_codcia, vg_codloc,
				rm_cxc.z26_codcli, rm_cxc.z26_tipo_doc,
				rm_cxc.z26_num_doc, rm_cxc.z26_dividendo)
				RETURNING r_doc.*
			IF r_doc.z20_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'Documento no existe.','exclamation')
				NEXT FIELD z26_tipo_doc
			END IF
		END IF
		{
		IF r_doc.z20_saldo_cap + r_doc.z20_saldo_int > rm_cxc.z26_valor
		THEN
			CALL fgl_winmessage(vg_producto,'El saldo del documento no puede ser mayor al valor del cheque.','exclamation')
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



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
                                                                                
DISPLAY "" AT 1, 1 
DISPLAY row_current, " de ", num_rows AT 1, 66

END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	INTEGER
DEFINE r_cli_gen	RECORD LIKE cxct001.*
DEFINE r_bco_gen	RECORD LIKE gent008.*
DEFINE r_tip		RECORD LIKE cxct004.*
DEFINE r_are		RECORD LIKE gent003.*
DEFINE r_doc		RECORD LIKE cxct020.*

IF vm_num_rows > 0 THEN
	SELECT * INTO rm_cxc.* FROM cxct026 WHERE ROWID = num_registro
	IF STATUS = NOTFOUND THEN
		CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
		RETURN
	END IF
	DISPLAY BY NAME rm_cxc.z26_codcli, rm_cxc.z26_banco, rm_cxc.z26_num_cta,
			rm_cxc.z26_num_cheque, rm_cxc.z26_valor,
			rm_cxc.z26_fecha_cobro, rm_cxc.z26_referencia,
			rm_cxc.z26_areaneg, rm_cxc.z26_tipo_doc,
			rm_cxc.z26_num_doc, rm_cxc.z26_dividendo,
			rm_cxc.z26_usuario, rm_cxc.z26_fecing
	CALL fl_lee_cliente_general(rm_cxc.z26_codcli) RETURNING r_cli_gen.*
	DISPLAY r_cli_gen.z01_nomcli TO tit_nombre_cli
	CALL fl_lee_tipo_doc(rm_cxc.z26_tipo_doc) RETURNING r_tip.* 
	DISPLAY r_tip.z04_nombre TO tit_tipo_doc
	CALL fl_lee_area_negocio(vg_codcia,rm_cxc.z26_areaneg) RETURNING r_are.*
	DISPLAY r_are.g03_nombre TO tit_area
        CALL fl_lee_banco_general(rm_cxc.z26_banco) RETURNING r_bco_gen.*
	DISPLAY r_bco_gen.g08_nombre TO tit_banco
	CALL fl_lee_documento_deudor_cxc(vg_codcia, vg_codloc,
				rm_cxc.z26_codcli, rm_cxc.z26_tipo_doc,
				rm_cxc.z26_num_doc, rm_cxc.z26_dividendo)
		RETURNING r_doc.*
	DISPLAY r_doc.z20_saldo_cap + r_doc.z20_saldo_int TO tit_saldo
	CALL muestra_estado()
ELSE
	RETURN
END IF

END FUNCTION



FUNCTION bloquear_activar()
DEFINE confir		CHAR(6)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET int_flag = 0
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_ba CURSOR FOR SELECT * FROM cxct026
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_ba
FETCH q_ba INTO rm_cxc.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF	
CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING confir
IF confir = 'Yes' THEN
	LET int_flag = 1
	CALL bloquea_activa_registro()
END IF
COMMIT WORK
WHENEVER ERROR STOP

END FUNCTION



FUNCTION bloquea_activa_registro()
DEFINE estado		CHAR(1)

IF rm_cxc.z26_estado = 'A' THEN
	DISPLAY 'BLOQUEADO' TO tit_estado_che
	LET estado = 'B'
ELSE 
	DISPLAY 'ACTIVO' TO tit_estado_che
	LET estado = 'A'
END IF
DISPLAY estado TO z26_estado
UPDATE cxct026 SET z26_estado = estado WHERE CURRENT OF q_ba
LET rm_cxc.z26_estado = estado

END FUNCTION



FUNCTION muestra_estado()
IF rm_cxc.z26_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado_che
ELSE
	DISPLAY 'BLOQUEADO' TO tit_estado_che
END IF
DISPLAY BY NAME rm_cxc.z26_estado

END FUNCTION



FUNCTION ver_documento_deudor()
DEFINE vm_nuevoprog	VARCHAR(400)

IF rm_cxc.z26_tipo_doc IS NULL THEN
	CALL fgl_winmessage(vg_producto,'Ingrese primero el tipo de documento.','exclamation')
	RETURN
END IF
IF rm_cxc.z26_num_doc IS NULL THEN
	CALL fgl_winmessage(vg_producto,'Ingrese el número de documento.','exclamation')
	RETURN
END IF
IF rm_cxc.z26_dividendo IS NULL THEN
	CALL fgl_winmessage(vg_producto,'Ingrese el dividendo de documento.','exclamation')
	RETURN
END IF
LET vm_nuevoprog = 'cd ..', vg_separador, '..', vg_separador, 'COBRANZAS',
	vg_separador, 'fuentes', vg_separador, '; fglrun cxcp200 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', vg_codloc, ' ', rm_cxc.z26_codcli,
	' ', rm_cxc.z26_tipo_doc, ' ', rm_cxc.z26_num_doc, ' ',
	rm_cxc.z26_dividendo 
RUN vm_nuevoprog

END FUNCTION



FUNCTION control_imprimir()
DEFINE comando		VARCHAR(100)

LET vm_top    = 1
LET vm_left   =	2
LET vm_right  =	132
LET vm_bottom =	2
LET vm_page   = 66

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	LET int_flag = 0
	RETURN
END IF

START REPORT report_comprobante TO PIPE comando
	OUTPUT TO REPORT report_comprobante()
FINISH REPORT report_comprobante

END FUNCTION



REPORT report_comprobante()

DEFINE i		SMALLINT

DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_g03		RECORD LIKE gent003.*
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g10		RECORD LIKE gent010.*

OUTPUT
	TOP    MARGIN	vm_top
	LEFT   MARGIN	vm_left
	RIGHT  MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE   LENGTH	vm_page

FORMAT
PAGE HEADER
	print '@';
	print 'EDITECA - KOMATSUF'
--	SKIP 1 LINES
	PRINT COLUMN 40, '  COMPROBANTE DE RECIBO DE CHEQUE POST-FECHADO '
	PRINT COLUMN 40, '================================================'
	SKIP 1 LINES

ON EVERY ROW
	CALL fl_lee_cliente_general(rm_cxc.z26_codcli) RETURNING r_z01.*

	PRINT COLUMN 10, fl_justifica_titulo('I', 'Cliente', 15), ': ',
		         r_z01.z01_nomcli CLIPPED ,
	      COLUMN 84, fl_justifica_titulo('I', 'Fecha', 6), ': ', 
			 DATE(rm_cxc.z26_fecing) USING 'dd-mm-yyyy', 
                         1 SPACES, TIME 
	SKIP 1 LINES
	PRINT COLUMN 10, fl_justifica_titulo('I', 'Referencia: ', 15),
		         rm_cxc.z26_referencia CLIPPED

	SKIP 1 LINES
	PRINT COLUMN 40, '           DATOS DEL CHEQUE'
	PRINT COLUMN 40, '======================================'
	CALL fl_lee_banco_general(rm_cxc.z26_banco) RETURNING r_g08.*
	PRINT COLUMN 10, fl_justifica_titulo('I', 'Banco', 15), ': ',
			 r_g08.g08_nombre
	PRINT COLUMN 10, fl_justifica_titulo('I', 'No. de Cuenta', 15), ': ',
		         rm_cxc.z26_num_cta CLIPPED,
	      COLUMN 84, fl_justifica_titulo('I', 'Cheque', 6), ': ', 
			 rm_cxc.z26_num_cheque
	PRINT COLUMN 10, fl_justifica_titulo('I', 'Valor',  6), ': ',
			 rm_cxc.z26_valor USING '#,###,###,##&.##',
	      COLUMN 84, fl_justifica_titulo('I', 'Fecha Cobro', 15), ': ', 
			 rm_cxc.z26_fecha_cobro USING 'dd-mm-yyyy'

	SKIP 1 LINES
	PRINT COLUMN 40, '              OTROS DATOS '
	PRINT COLUMN 40, '======================================'

	CALL fl_lee_area_negocio(vg_codcia,rm_cxc.z26_areaneg) RETURNING r_g03.*
	PRINT COLUMN 10, fl_justifica_titulo('I', 'Area Negocio', 15), ': ',
		         fl_justifica_titulo('I', rm_cxc.z26_areaneg, 5),
			 r_g03.g03_nombre

	PRINT COLUMN 10, fl_justifica_titulo('I', 'Documento', 15), ': ',
		         rm_cxc.z26_tipo_doc CLIPPED, '-', 
                         rm_cxc.z26_num_doc CLIPPED, '-',
                         rm_cxc.z26_dividendo


	SKIP 5 LINES

	PRINT COLUMN 50, '-------------------------'
	PRINT COLUMN 50, '     RECIBI CONFORME     '

END REPORT



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
