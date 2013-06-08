--------------------------------------------------------------------------------
-- Titulo           : genp142.4gl - Mantenimiento Control Sec. del Sri
-- Elaboracion      : 27-Jul-2004
-- Autor            : NPC
-- Formato Ejecucion: fglrun genp142 base modulo compañia localidad
--			[tipo_doc] [secuencia]
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_g37   	RECORD LIKE gent037.*
DEFINE vm_r_rows	ARRAY[1000] OF INTEGER
DEFINE vm_row_current   SMALLINT        	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT		-- MAXIMO DE FILAS LEIDAS
DEFINE vm_flag_mant     CHAR(1)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/genp142.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 6 THEN
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'genp142'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
EXIT PROGRAM

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
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
OPEN WINDOW w_genf142_1 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_genf142_1 FROM '../forms/genf142_1'
ELSE
	OPEN FORM f_genf142_1 FROM '../forms/genf142_1c'
END IF
DISPLAY FORM f_genf142_1
INITIALIZE rm_g37.* TO NULL
LET vm_max_rows    = 1000
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		IF num_args() <> 4 THEN
			HIDE OPTION 'Ingresar'
			HIDE OPTION 'Consultar'
			CALL control_consulta()
			--EXIT MENU
		END IF
	COMMAND KEY('I') 'Ingresar' 'Ingresa un nuevo registro.'
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
		END IF
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
        COMMAND KEY('M') 'Modificar' 'Modificar registro corriente. '
                IF vm_num_rows > 0 THEN
                        CALL control_modificacion()
                ELSE
			CALL fl_mensaje_consultar_primero()
		END IF
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro'
		CALL control_muestra_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		CALL control_muestra_anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU
CLOSE WINDOW w_genf142_1

END FUNCTION



FUNCTION control_ingreso()

CLEAR FORM
OPTIONS INPUT WRAP
INITIALIZE rm_g37.* TO NULL
LET vm_flag_mant         = 'I'
LET rm_g37.g37_compania  = vg_codcia
LET rm_g37.g37_localidad = vg_codloc
LET rm_g37.g37_cont_cred = 'N'
LET rm_g37.g37_fecha_emi = TODAY
CALL obtener_fecha_exp(rm_g37.g37_fecha_emi) RETURNING rm_g37.g37_fecha_exp
LET rm_g37.g37_usuario   = vg_usuario
LET rm_g37.g37_fecing    = CURRENT
DISPLAY BY NAME rm_g37.g37_localidad, rm_g37.g37_cont_cred,rm_g37.g37_fecha_emi,
		rm_g37.g37_fecha_exp, rm_g37.g37_fecing, rm_g37.g37_usuario
CALL mostar_nombres_eti()
CALL leer_parametros()
IF int_flag THEN
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	RETURN
END IF
CALL obtener_secuencia() RETURNING rm_g37.g37_secuencia
LET rm_g37.g37_fecing = CURRENT
BEGIN WORK
INSERT INTO gent037 VALUES (rm_g37.*)
IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_r_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
{--
IF rm_g37.g37_secuencia > 1 THEN
	WHENEVER ERROR CONTINUE
	UPDATE gent037
		SET g37_fecha_exp = rm_g37.g37_fecha_emi - 1 UNITS DAY
		WHERE g37_compania  = rm_g37.g37_compania
		  AND g37_localidad = rm_g37.g37_localidad
		  AND g37_tipo_doc  = rm_g37.g37_tipo_doc
		  AND g37_secuencia = rm_g37.g37_secuencia - 1
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No puede actualizar la fecha de expiracion del registro anterior. LLAME AL ADMINISTRADOR.', 'stop')
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
	WHENEVER ERROR STOP
END IF
--}
COMMIT WORK
LET vm_row_current         = vm_num_rows
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

LET vm_flag_mant = 'M'
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM gent037
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_g37.*
IF STATUS < 0 THEN
	WHENEVER ERROR STOP
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN
END IF
CALL leer_parametros()
IF int_flag THEN
	WHENEVER ERROR STOP
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	RETURN
END IF
WHENEVER ERROR CONTINUE
UPDATE gent037
	SET * = rm_g37.*
	WHERE CURRENT OF q_up
{--
IF rm_g37.g37_secuencia > 1 THEN
	WHENEVER ERROR CONTINUE
	UPDATE gent037
		SET g37_fecha_exp = rm_g37.g37_fecha_emi - 1 UNITS DAY
		WHERE g37_compania  = rm_g37.g37_compania
		  AND g37_localidad = rm_g37.g37_localidad
		  AND g37_tipo_doc  = rm_g37.g37_tipo_doc
		  AND g37_secuencia = rm_g37.g37_secuencia - 1
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No puede actualizar la fecha de expiracion del registro anterior. LLAME AL ADMINISTRADOR.', 'stop')
		WHENEVER ERROR STOP
		RETURN
	END IF
END IF
--}
WHENEVER ERROR STOP
COMMIT WORK
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(1000)
DEFINE query		CHAR(1500)
DEFINE r_z04		RECORD LIKE cxct004.*
DEFINE r_g02		RECORD LIKE gent002.*

IF num_args() <> 6 THEN
	CLEAR FORM
	LET int_flag = 0
	CONSTRUCT BY NAME expr_sql ON g37_localidad, g37_tipo_doc,g37_cont_cred,
		g37_secuencia, g37_pref_sucurs, g37_pref_pto_vta,
		g37_sec_num_sri, g37_num_dig_sri, g37_fecha_emi, g37_fecha_exp,
		g37_autorizacion, g37_usuario
	        ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT CONSTRUCT
	        ON KEY(F1,CONTROL-W)
			CALL llamar_visor_teclas()
		ON KEY(F2)
			IF INFIELD(g37_localidad) THEN
				CALL fl_ayuda_localidad(vg_codcia)
					RETURNING r_g02.g02_localidad,
						  r_g02.g02_nombre
				IF r_g02.g02_localidad IS NOT NULL THEN
					LET rm_g37.g37_localidad =
							r_g02.g02_localidad
					DISPLAY BY NAME rm_g37.g37_localidad,
							r_g02.g02_nombre
				END IF
	                END IF
			IF INFIELD(g37_tipo_doc) THEN
				CALL fl_ayuda_tipo_documento_cobranzas('0')
					RETURNING r_z04.z04_tipo_doc,
						  r_z04.z04_nombre
				IF r_z04.z04_tipo_doc IS NOT NULL THEN
					LET rm_g37.g37_tipo_doc =
							r_z04.z04_tipo_doc
					DISPLAY BY NAME rm_g37.g37_tipo_doc,
							r_z04.z04_nombre
				END IF
			END IF
			LET int_flag = 0
		BEFORE CONSTRUCT
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
	END CONSTRUCT
	IF int_flag THEN
		CLEAR FORM
		IF vm_num_rows > 0 THEN
			CALL lee_muestra_registro(vm_r_rows[vm_row_current])
		END IF
		CALL muestra_contadores(vm_row_current, vm_num_rows)
		RETURN
	END IF
ELSE
	LET expr_sql = 'g37_localidad = ', vg_codloc,
			'    AND g37_tipo_doc  = "', arg_val(5), '"',
			'    AND g37_secuencia = ', arg_val(6)
END IF
LET query = 'SELECT *, ROWID FROM gent037 ',
		' WHERE g37_compania  = ', vg_codcia,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY g37_secuencia DESC, g37_tipo_doc, g37_fecha_emi'
PREPARE cons FROM query
DECLARE q_uni CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_uni INTO rm_g37.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	IF num_args() = 6 THEN
		EXIT PROGRAM
	END IF
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
        CLEAR FORM
        RETURN
END IF
LET vm_row_current = 1
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION leer_parametros()
DEFINE resp		CHAR(6)
DEFINE resul		SMALLINT
DEFINE r_z04, r_z04_2	RECORD LIKE cxct004.*
DEFINE r_p04		RECORD LIKE cxpt004.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE r_g37_a		RECORD LIKE gent037.*
DEFINE loc_aux		LIKE gent037.g37_localidad
DEFINE doc_aux		LIKE gent037.g37_tipo_doc
DEFINE sec_aux		LIKE gent037.g37_secuencia

LET int_flag = 0
INPUT BY NAME rm_g37.g37_localidad, rm_g37.g37_tipo_doc, rm_g37.g37_cont_cred,
	rm_g37.g37_pref_sucurs, rm_g37.g37_pref_pto_vta, rm_g37.g37_sec_num_sri,
	rm_g37.g37_num_dig_sri, rm_g37.g37_fecha_emi, rm_g37.g37_fecha_exp,
	rm_g37.g37_autorizacion
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_g37.g37_localidad, rm_g37.g37_tipo_doc,
				 rm_g37.g37_cont_cred, rm_g37.g37_pref_sucurs,
				 rm_g37.g37_pref_pto_vta,rm_g37.g37_sec_num_sri,
				 rm_g37.g37_num_dig_sri, rm_g37.g37_fecha_emi,
				 rm_g37.g37_fecha_exp, rm_g37.g37_autorizacion)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				CLEAR FORM
				LET int_flag = 1
				IF vm_flag_mant = 'I' THEN
					CLEAR FORM
				END IF
				EXIT INPUT
			END IF
		ELSE
			IF vm_flag_mant = 'I' THEN
				CLEAR FORM
			END IF
			EXIT INPUT
		END IF
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF vm_flag_mant = 'M' THEN
			CONTINUE INPUT
		END IF
		IF INFIELD(g37_localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
			IF r_g02.g02_localidad IS NOT NULL THEN
				LET rm_g37.g37_localidad = r_g02.g02_localidad
				DISPLAY BY NAME rm_g37.g37_localidad,
						r_g02.g02_nombre
			END IF
                END IF
		IF INFIELD(g37_tipo_doc) THEN
			CALL fl_ayuda_tipo_documento_cobranzas('0')
				RETURNING r_z04.z04_tipo_doc, r_z04.z04_nombre
			IF r_z04.z04_tipo_doc IS NOT NULL THEN
				LET rm_g37.g37_tipo_doc = r_z04.z04_tipo_doc
				DISPLAY BY NAME rm_g37.g37_tipo_doc,
						r_z04.z04_nombre
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD g37_localidad
		IF vm_flag_mant = 'M' THEN
			LET loc_aux = rm_g37.g37_localidad
		END IF
		LET r_g37.g37_localidad = rm_g37.g37_localidad
	BEFORE FIELD g37_tipo_doc
		IF vm_flag_mant = 'M' THEN
			LET doc_aux = rm_g37.g37_tipo_doc
			LET sec_aux = rm_g37.g37_secuencia
		END IF
	BEFORE FIELD g37_pref_sucurs
		LET r_g37.g37_pref_sucurs = rm_g37.g37_pref_sucurs
		IF rm_g37.g37_localidad IS NULL OR rm_g37.g37_tipo_doc IS NULL
		THEN
			CONTINUE INPUT
		END IF
		IF rm_g37.g37_pref_sucurs IS NULL THEN
			CALL obtener_reg_anterior() RETURNING r_g37_a.*
			IF r_g37_a.g37_compania IS NOT NULL THEN
				LET rm_g37.g37_pref_sucurs =
							r_g37_a.g37_pref_sucurs
				DISPLAY BY NAME rm_g37.g37_pref_sucurs
			END IF
		END IF
	BEFORE FIELD g37_pref_pto_vta
		LET r_g37.g37_pref_pto_vta = rm_g37.g37_pref_pto_vta
		IF rm_g37.g37_localidad IS NULL OR rm_g37.g37_tipo_doc IS NULL
		THEN
			CONTINUE INPUT
		END IF
		IF rm_g37.g37_pref_pto_vta IS NULL THEN
			CALL obtener_reg_anterior() RETURNING r_g37_a.*
			IF r_g37_a.g37_compania IS NOT NULL THEN
				LET rm_g37.g37_pref_pto_vta =
							r_g37_a.g37_pref_pto_vta
				DISPLAY BY NAME rm_g37.g37_pref_pto_vta
			END IF
		END IF
	BEFORE FIELD g37_fecha_emi
		LET r_g37.g37_fecha_emi = rm_g37.g37_fecha_emi
	BEFORE FIELD g37_fecha_exp
		LET r_g37.g37_fecha_exp = rm_g37.g37_fecha_exp
	AFTER FIELD g37_localidad
		IF vm_flag_mant = 'M' THEN
			LET rm_g37.g37_localidad = loc_aux
			CALL fl_lee_localidad(vg_codcia, rm_g37.g37_localidad)
				RETURNING r_g02.*
			DISPLAY BY NAME rm_g37.g37_localidad
			CONTINUE INPUT
		END IF
		IF rm_g37.g37_localidad IS NOT NULL THEN
			CALL fl_lee_localidad(vg_codcia, rm_g37.g37_localidad)
				RETURNING r_g02.*
			IF r_g02.g02_localidad IS NULL THEN
				CALL fl_mostrar_mensaje('No existe esta Localidad.', 'exclamation')
				NEXT FIELD g37_localidad
			END IF
			IF r_g02.g02_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD g37_localidad
			END IF
		ELSE
			LET rm_g37.g37_localidad = r_g37.g37_localidad
			DISPLAY BY NAME rm_g37.g37_localidad
		END IF
		CALL mostar_nombres_eti()
	AFTER FIELD g37_tipo_doc
		IF vm_flag_mant = 'M' THEN
			LET rm_g37.g37_tipo_doc = doc_aux
			IF rm_g37.g37_tipo_doc <> 'RT' THEN
				CALL fl_lee_tipo_doc(rm_g37.g37_tipo_doc)
					RETURNING r_z04.*
			ELSE
				CALL fl_lee_tipo_doc_tesoreria(rm_g37.g37_tipo_doc)
					RETURNING r_p04.*
			END IF
			DISPLAY BY NAME rm_g37.g37_tipo_doc
			CALL mostar_nombres_eti()
			LET rm_g37.g37_secuencia = sec_aux
			DISPLAY BY NAME rm_g37.g37_secuencia
			CONTINUE INPUT
		END IF
		IF rm_g37.g37_tipo_doc IS NOT NULL THEN
			IF rm_g37.g37_tipo_doc <> 'RT' THEN
				CALL fl_lee_tipo_doc(rm_g37.g37_tipo_doc)
					RETURNING r_z04.*
				IF r_z04.z04_tipo_doc IS NULL THEN
					CALL fl_mostrar_mensaje('No existe este Tipo de Documento.', 'exclamation')
					NEXT FIELD g37_tipo_doc
				END IF
				IF r_z04.z04_estado = 'B' THEN
        	                        CALL fl_mensaje_estado_bloqueado()
					NEXT FIELD g37_tipo_doc
				END IF
			ELSE
				CALL fl_lee_tipo_doc_tesoreria(rm_g37.g37_tipo_doc)
					RETURNING r_p04.*
				IF r_p04.p04_tipo_doc IS NULL THEN
					CALL fl_mostrar_mensaje('No existe este Tipo de Documento Retencion.', 'exclamation')
					NEXT FIELD g37_tipo_doc
				END IF
				IF r_p04.p04_estado = 'B' THEN
        	                        CALL fl_mensaje_estado_bloqueado()
					NEXT FIELD g37_tipo_doc
				END IF
			END IF
			CALL retorna_datos_ult_reg_act()
			CALL mostar_nombres_eti()
		ELSE
			CLEAR z04_nombre
		END IF
	AFTER FIELD g37_pref_sucurs
		IF rm_g37.g37_pref_sucurs IS NULL THEN
			LET rm_g37.g37_pref_sucurs = r_g37.g37_pref_sucurs
			DISPLAY BY NAME rm_g37.g37_pref_sucurs
		END IF
	AFTER FIELD g37_pref_pto_vta
		IF rm_g37.g37_pref_pto_vta IS NULL THEN
			LET rm_g37.g37_pref_pto_vta = r_g37.g37_pref_pto_vta
			DISPLAY BY NAME rm_g37.g37_pref_pto_vta
		END IF
	AFTER FIELD g37_sec_num_sri
		IF rm_g37.g37_sec_num_sri IS NOT NULL THEN
			IF rm_g37.g37_sec_num_sri < 0 THEN
				CALL fl_mostrar_mensaje('No puede ingresar un numero negativo.', 'exclamation')
				NEXT FIELD g37_sec_num_sri
			END IF
		END IF
	AFTER FIELD g37_num_dig_sri
		IF rm_g37.g37_num_dig_sri IS NOT NULL THEN
			IF rm_g37.g37_num_dig_sri < 0 THEN
				CALL fl_mostrar_mensaje('No puede ingresar un numero negativo.', 'exclamation')
				NEXT FIELD g37_num_dig_sri
			END IF
		END IF
	AFTER FIELD g37_fecha_emi
		{--
		IF vm_flag_mant = 'M' THEN
			LET rm_g37.g37_fecha_emi = r_g37.g37_fecha_emi
			DISPLAY BY NAME rm_g37.g37_fecha_emi
			CONTINUE INPUT
		END IF
		--}
		IF rm_g37.g37_localidad IS NULL OR rm_g37.g37_tipo_doc IS NULL
		THEN
			LET rm_g37.g37_fecha_emi = r_g37.g37_fecha_emi
			DISPLAY BY NAME rm_g37.g37_fecha_emi
			CONTINUE INPUT
		END IF
		IF rm_g37.g37_fecha_emi IS NOT NULL THEN
			LET rm_g37.g37_fecha_emi =
					MDY(MONTH(rm_g37.g37_fecha_emi), 01,
						YEAR(rm_g37.g37_fecha_emi))
			DISPLAY BY NAME rm_g37.g37_fecha_emi
			CALL validar_fec_emi() RETURNING resul
			IF resul THEN
				NEXT FIELD g37_fecha_emi
			END IF
			CALL obtener_fecha_exp(rm_g37.g37_fecha_emi)
				RETURNING rm_g37.g37_fecha_exp
		ELSE
			LET rm_g37.g37_fecha_emi = r_g37.g37_fecha_emi
		END IF
		DISPLAY BY NAME rm_g37.g37_fecha_emi
	AFTER FIELD g37_fecha_exp
		{--
		IF vm_flag_mant = 'M' THEN
			LET rm_g37.g37_fecha_exp = r_g37.g37_fecha_exp
			DISPLAY BY NAME rm_g37.g37_fecha_exp
			CONTINUE INPUT
		END IF
		--}
		IF rm_g37.g37_localidad IS NULL OR rm_g37.g37_tipo_doc IS NULL
		   OR rm_g37.g37_fecha_exp IS NULL
		THEN
			LET rm_g37.g37_fecha_exp = r_g37.g37_fecha_exp
		END IF
		LET rm_g37.g37_fecha_exp = MDY(MONTH(rm_g37.g37_fecha_exp), 01,
						YEAR(rm_g37.g37_fecha_exp))
						+ 1 UNITS MONTH - 1 UNITS DAY
		DISPLAY BY NAME rm_g37.g37_fecha_exp
	AFTER FIELD g37_autorizacion
		IF rm_g37.g37_autorizacion IS NOT NULL THEN
			IF LENGTH(rm_g37.g37_autorizacion) <> 10 THEN
				CALL fl_mostrar_mensaje('Numero de Autorizacion no tiene completo el numero de digitos.', 'exclamation')
				NEXT FIELD g37_autorizacion
			END IF
			IF rm_g37.g37_autorizacion[1, 1] <> '1' THEN
				CALL fl_mostrar_mensaje('Numero de Autorizacion es incorrecto.', 'exclamation')
				NEXT FIELD g37_autorizacion
			END IF
			IF NOT fl_valida_numeros(rm_g37.g37_autorizacion) THEN
				NEXT FIELD g37_autorizacion
			END IF
		END IF
	AFTER INPUT
		IF rm_g37.g37_cont_cred IS NULL THEN
			LET rm_g37.g37_cont_cred = 'N'
			DISPLAY BY NAME rm_g37.g37_cont_cred
		END IF
		CALL validar_fec_emi() RETURNING resul
		IF resul THEN
			NEXT FIELD g37_fecha_emi
		END IF
		IF rm_g37.g37_fecha_exp <= rm_g37.g37_fecha_emi THEN
			CALL fl_mostrar_mensaje('La Fecha de Expiracion no puede ser menor o igual que la Fecha de Emision.', 'exclamation')
			NEXT FIELD g37_fecha_exp
		END IF
		IF rm_g37.g37_cont_cred <> 'N' THEN
			IF rm_g37.g37_tipo_doc <> 'FA' AND 
			   rm_g37.g37_tipo_doc <> 'GR'
			THEN
				CALL fl_lee_tipo_doc('FA') RETURNING r_z04.* 
				CALL fl_lee_tipo_doc('GR') RETURNING r_z04_2.* 
				CALL fl_mostrar_mensaje('La Forma de Pago solo es utilizado en '|| r_z04.z04_nombre CLIPPED || ' o ' || r_z04_2.z04_nombre CLIPPED || '.', 'info')
				LET rm_g37.g37_cont_cred = 'N'
				DISPLAY BY NAME rm_g37.g37_cont_cred
			END IF
		END IF
		INITIALIZE r_g37.* TO NULL
		DECLARE q_g37 CURSOR FOR
			SELECT * FROM gent037
				WHERE g37_compania     = rm_g37.g37_compania
				  AND g37_localidad    = rm_g37.g37_localidad
				  AND g37_tipo_doc     = rm_g37.g37_tipo_doc
				  AND g37_fecha_emi    < rm_g37.g37_fecha_emi
				  AND g37_fecha_exp   <= rm_g37.g37_fecha_exp
				  AND g37_autorizacion = rm_g37.g37_autorizacion
		OPEN q_g37
		FETCH q_g37 INTO r_g37.*
		IF r_g37.g37_compania IS NOT NULL THEN
			CALL fl_mostrar_mensaje('Ya se encuentra ingresada esta secuencia SRI con este No. de autorizacion.', 'exclamation')
			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



FUNCTION control_muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1 
END IF	
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1 
END IF
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION


                                                                                
FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT

DISPLAY BY NAME row_current, num_rows

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_g37.* FROM gent037 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con Indice: ' || num_row,
				'exclamation')
	RETURN
END IF
CALL muestra_datos()

END FUNCTION



FUNCTION muestra_datos()

DISPLAY BY NAME rm_g37.g37_localidad, rm_g37.g37_tipo_doc, rm_g37.g37_cont_cred,
		rm_g37.g37_secuencia, rm_g37.g37_pref_sucurs,
		rm_g37.g37_pref_pto_vta, rm_g37.g37_sec_num_sri,
		rm_g37.g37_num_dig_sri, rm_g37.g37_fecha_emi,
		rm_g37.g37_fecha_exp, rm_g37.g37_autorizacion,
		rm_g37.g37_usuario, rm_g37.g37_fecing
CALL mostar_nombres_eti()

END FUNCTION



FUNCTION mostar_nombres_eti()
DEFINE r_z04		RECORD LIKE cxct004.*
DEFINE r_p04		RECORD LIKE cxpt004.*
DEFINE r_g02		RECORD LIKE gent002.*

CALL fl_lee_tipo_doc(rm_g37.g37_tipo_doc) RETURNING r_z04.* 
CALL fl_lee_localidad(vg_codcia, rm_g37.g37_localidad) RETURNING r_g02.*
DISPLAY BY NAME r_z04.z04_nombre, r_g02.g02_nombre
IF rm_g37.g37_tipo_doc = 'RT' THEN
	CALL fl_lee_tipo_doc_tesoreria(rm_g37.g37_tipo_doc) RETURNING r_p04.*
	DISPLAY r_p04.p04_nombre TO z04_nombre
END IF

END FUNCTION



FUNCTION obtener_fecha_exp(fecha_emi)
DEFINE fecha_emi	LIKE gent037.g37_fecha_emi
DEFINE fecha_exp	LIKE gent037.g37_fecha_exp

LET fecha_exp = fecha_emi + 1 UNITS YEAR + 1 UNITS MONTH
LET fecha_exp = fecha_exp - DAY(fecha_exp) UNITS DAY
RETURN fecha_exp

END FUNCTION



FUNCTION obtener_secuencia()
DEFINE secuencia	LIKE gent037.g37_secuencia

SQL
	SELECT NVL(MAX(g37_secuencia), 0) + 1
		INTO $secuencia
		FROM gent037
		WHERE g37_compania  = $rm_g37.g37_compania
		  AND g37_localidad = $rm_g37.g37_localidad
		  AND g37_tipo_doc  = $rm_g37.g37_tipo_doc
END SQL
RETURN secuencia

END FUNCTION



FUNCTION obtener_reg_anterior()
DEFINE r_g37		RECORD LIKE gent037.*

CALL obtener_secuencia() RETURNING r_g37.g37_secuencia
CALL fl_lee_num_sri_gen(rm_g37.g37_compania, rm_g37.g37_localidad,
			rm_g37.g37_tipo_doc, r_g37.g37_secuencia - 1)
	RETURNING r_g37.*
RETURN r_g37.*

END FUNCTION



FUNCTION validar_fec_emi()
DEFINE r_z04		RECORD LIKE cxct004.*
DEFINE r_p04		RECORD LIKE cxpt004.*
DEFINE r_g37_a		RECORD LIKE gent037.*
DEFINE mensaje		VARCHAR(200)

IF vm_flag_mant = 'M' THEN
	RETURN 0
END IF
CALL obtener_reg_anterior() RETURNING r_g37_a.*
IF r_g37_a.g37_compania IS NOT NULL THEN
	--IF rm_g37.g37_fecha_emi <= r_g37_a.g37_fecha_exp THEN
	IF rm_g37.g37_fecha_emi <= r_g37_a.g37_fecha_emi THEN
		CALL fl_lee_tipo_doc(r_g37_a.g37_tipo_doc) RETURNING r_z04.* 
		IF rm_g37.g37_tipo_doc = 'RT' THEN
			CALL fl_lee_tipo_doc_tesoreria(rm_g37.g37_tipo_doc)
				RETURNING r_p04.*
			LET r_z04.z04_nombre = r_p04.p04_nombre
		END IF
		LET mensaje = 'La Fecha de Emision no puede ser menor o igual',
				' que la fecha de emision (',
				r_g37_a.g37_fecha_emi USING "dd-mm-yyyy",
				') del ultimo registro de ',
				r_z04.z04_nombre CLIPPED, '.'
		CALL fl_mostrar_mensaje(mensaje CLIPPED, 'exclamation')
		--LET rm_g37.g37_fecha_emi = r_g37_a.g37_fecha_exp + 1 UNITS DAY
		LET rm_g37.g37_fecha_emi = r_g37_a.g37_fecha_emi + 1 UNITS DAY
		RETURN 1
	END IF
END IF
RETURN 0

END FUNCTION



FUNCTION retorna_datos_ult_reg_act()
DEFINE r_g37		RECORD LIKE gent037.*

CALL obtener_reg_anterior() RETURNING r_g37.*
IF r_g37.g37_compania IS NULL THEN
	RETURN
END IF
LET rm_g37.*             = r_g37.*
LET rm_g37.g37_secuencia = NULL
LET rm_g37.g37_fecha_emi = r_g37.g37_fecha_exp + 1 UNITS DAY
CALL obtener_fecha_exp(rm_g37.g37_fecha_emi) RETURNING rm_g37.g37_fecha_exp
LET rm_g37.g37_usuario   = vg_usuario
LET rm_g37.g37_fecing    = CURRENT
CALL muestra_datos()

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
