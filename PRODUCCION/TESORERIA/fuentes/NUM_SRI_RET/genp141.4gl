--------------------------------------------------------------------------------
-- Titulo           : genp141.4gl - Mantenimiento de Doc. del Sri
-- Elaboracion      : 09-Jun-2004
-- Autor            : NPC
-- Formato Ejecucion: fglrun genp141 base modulo compania localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_g39   	RECORD LIKE gent039.*
DEFINE vm_r_rows	ARRAY[1000] OF INTEGER
DEFINE vm_row_current   SMALLINT        	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT		-- MAXIMO DE FILAS LEIDAS



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/genp141.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'genp141'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 18
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_forma AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST - 1) 
IF vg_gui = 1 THEN
	OPEN FORM f_genf141_1 FROM '../forms/genf141_1'
ELSE
	OPEN FORM f_genf141_1 FROM '../forms/genf141_1c'
END IF
DISPLAY FORM f_genf141_1
INITIALIZE rm_g39.* TO NULL
LET vm_max_rows    = 1000
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Otros Datos'
	COMMAND KEY('I') 'Ingresar' 'Ingresa un nuevo registro.'
		CALL control_ingreso()
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
		IF vm_num_rows >= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Otros Datos'
		END IF
	COMMAND KEY('M') 'Modificar' 'Modificar el registro corriente. '
		CALL control_modificacion()
	COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
		CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Otros Datos'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
                        IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Otros Datos'
			END IF
		ELSE
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Otros Datos'
			SHOW OPTION 'Avanzar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('O') 'Otros Datos' 'Datos control sec. del documento'
		CALL muestra_otros_datos()
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

END FUNCTION



FUNCTION control_ingreso()

CLEAR FORM
OPTIONS INPUT WRAP
INITIALIZE rm_g39.* TO NULL
LET rm_g39.g39_compania     = vg_codcia
LET rm_g39.g39_localidad    = vg_codloc
LET rm_g39.g39_fec_entrega  = TODAY
LET rm_g39.g39_num_dias_col = 20
LET rm_g39.g39_usuario      = vg_usuario
LET rm_g39.g39_fecing       = CURRENT
DISPLAY BY NAME rm_g39.g39_fec_entrega, rm_g39.g39_num_dias_col,
		rm_g39.g39_fecing, rm_g39.g39_usuario
CALL leer_parametros('I')
IF NOT int_flag THEN
	IF rm_g39.g39_secuencia IS NULL THEN
		SELECT NVL(MAX(g39_secuencia), 1) INTO rm_g39.g39_secuencia
			FROM gent039
			WHERE g39_compania  = vg_codcia
			  AND g39_localidad = rm_g39.g39_localidad
			  AND g39_tipo_doc  = rm_g39.g39_tipo_doc
	END IF
	LET rm_g39.g39_fecing = CURRENT
       	INSERT INTO gent039 VALUES (rm_g39.*)
	IF vm_num_rows = vm_max_rows THEN
                LET vm_num_rows = 1
        ELSE
                LET vm_num_rows = vm_num_rows + 1
        END IF
	LET vm_r_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
	LET vm_row_current         = vm_num_rows
	CALL fl_mensaje_registro_ingresado()
END IF
IF vm_num_rows > 0 THEN
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_modificacion()
DEFINE secuencia	LIKE gent039.g39_secuencia

CALL lee_muestra_registro(vm_r_rows[vm_row_current])
SELECT MAX(g39_secuencia) INTO secuencia
	FROM gent039
	WHERE g39_compania  = vg_codcia
	  AND g39_localidad = rm_g39.g39_localidad
	  AND g39_tipo_doc  = rm_g39.g39_tipo_doc
IF secuencia <> rm_g39.g39_secuencia THEN
	CALL fl_mostrar_mensaje('No puede modificar un registro que no es el último de la secuencia de control del SRI.', 'exclamation')
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM gent039 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_g39.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL leer_parametros('M')
IF int_flag THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	RETURN
END IF
UPDATE gent039 SET * = rm_g39.* WHERE CURRENT OF q_up
COMMIT WORK
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(800)
DEFINE query		CHAR(1200)
DEFINE r_z04		RECORD LIKE cxct004.*
DEFINE r_g02		RECORD LIKE gent002.*

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON g39_tipo_doc, g39_localidad, g39_secuencia,
	g39_fec_entrega, g39_num_sri_ini, g39_num_sri_fin, g39_num_dias_col,
	g39_usuario
        ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT CONSTRUCT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(g39_tipo_doc) THEN
			CALL fl_ayuda_tipo_documento_cobranzas('0')
				RETURNING r_z04.z04_tipo_doc, r_z04.z04_nombre
			LET int_flag = 0
			IF r_z04.z04_tipo_doc IS NOT NULL THEN
				LET rm_g39.g39_tipo_doc = r_z04.z04_tipo_doc
				DISPLAY BY NAME rm_g39.g39_tipo_doc,
						r_z04.z04_nombre
			END IF
		END IF
		IF INFIELD(g39_localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
                        LET int_flag = 0
			IF r_g02.g02_localidad IS NOT NULL THEN
				LET rm_g39.g39_localidad = r_g02.g02_localidad
				DISPLAY BY NAME rm_g39.g39_localidad,
						r_g02.g02_nombre
			END IF
                END IF
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
LET query = 'SELECT *, ROWID FROM gent039 ',
		' WHERE g39_compania  = ', vg_codcia,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY g39_tipo_doc, g39_secuencia, g39_fec_entrega'
PREPARE cons FROM query
DECLARE q_uni CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_uni INTO rm_g39.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
        CLEAR FORM
        RETURN
END IF
LET vm_row_current = 1
CALL muestra_contadores(vm_row_current, vm_num_rows)
CALL lee_muestra_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION leer_parametros(flag)
DEFINE flag		CHAR(1)
DEFINE resp		CHAR(6)
DEFINE r_z04		RECORD LIKE cxct004.*
DEFINE r_g37		RECORD LIKE gent037.*
DEFINE r_g39		RECORD LIKE gent039.*

LET int_flag = 0
INPUT BY NAME rm_g39.g39_tipo_doc, rm_g39.g39_fec_entrega,
	rm_g39.g39_num_sri_ini, rm_g39.g39_num_sri_fin,	rm_g39.g39_num_dias_col
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_g39.g39_tipo_doc, rm_g39.g39_fec_entrega,
				 rm_g39.g39_num_sri_ini, rm_g39.g39_num_sri_fin,
				 rm_g39.g39_num_dias_col)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				CLEAR FORM
				LET int_flag = 1
				--#RETURN
				EXIT INPUT
			END IF
		ELSE
			CLEAR FORM
			--#RETURN
			EXIT INPUT
		END IF
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(g39_tipo_doc) THEN
			CALL fl_ayuda_tipo_documento_cobranzas('0')
				RETURNING r_z04.z04_tipo_doc, r_z04.z04_nombre
			IF r_z04.z04_tipo_doc IS NOT NULL THEN
				LET rm_g39.g39_tipo_doc = r_z04.z04_tipo_doc
				DISPLAY BY NAME rm_g39.g39_tipo_doc,
						r_z04.z04_nombre
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD g39_tipo_doc, g39_fec_entrega
		IF flag = 'M' THEN
			LET r_g39.g39_tipo_doc    = rm_g39.g39_tipo_doc
			LET r_g39.g39_fec_entrega = rm_g39.g39_fec_entrega
		END IF
	AFTER FIELD g39_tipo_doc
		IF flag = 'M' THEN
			LET rm_g39.g39_tipo_doc    = r_g39.g39_tipo_doc
			LET rm_g39.g39_fec_entrega = r_g39.g39_fec_entrega
			DISPLAY BY NAME rm_g39.g39_tipo_doc,
					rm_g39.g39_fec_entrega
			CALL mostar_nombres_eti()
			CONTINUE INPUT
		END IF
		IF rm_g39.g39_tipo_doc IS NOT NULL THEN
			INITIALIZE r_g37.* TO NULL
			SELECT * INTO r_g37.* FROM gent037
				WHERE g37_compania  = vg_codcia
				  AND g37_localidad = vg_codloc
				  AND g37_tipo_doc  = rm_g39.g39_tipo_doc
				  AND g37_secuencia IN
				(SELECT MAX(g37_secuencia) FROM gent037
					WHERE g37_compania  = vg_codcia
					  AND g37_localidad = vg_codloc
					  AND g37_tipo_doc =rm_g39.g39_tipo_doc)
			IF r_g37.g37_compania IS NULL THEN
				LET rm_g39.g39_localidad = vg_codloc
				LET rm_g39.g39_secuencia = NULL
				DISPLAY BY NAME rm_g39.g39_localidad,
						rm_g39.g39_secuencia
				CALL mostar_nombres_eti()
				CONTINUE INPUT
			END IF
			CALL fl_lee_tipo_doc(rm_g39.g39_tipo_doc)
				RETURNING r_z04.* 
			IF r_z04.z04_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD g39_tipo_doc
			END IF
			LET rm_g39.g39_tipo_doc  = r_g37.g37_tipo_doc
			LET rm_g39.g39_localidad = r_g37.g37_localidad
			LET rm_g39.g39_secuencia = r_g37.g37_secuencia
			DISPLAY BY NAME rm_g39.g39_tipo_doc,
					rm_g39.g39_localidad,
					rm_g39.g39_secuencia
			CALL mostar_nombres_eti()
		ELSE
			CLEAR z04_nombre, g39_localidad, g02_nombre,
				g39_secuencia
		END IF
	AFTER FIELD g39_fec_entrega
		IF flag = 'M' THEN
			LET rm_g39.g39_tipo_doc    = r_g39.g39_tipo_doc
			LET rm_g39.g39_fec_entrega = r_g39.g39_fec_entrega
			DISPLAY BY NAME rm_g39.g39_tipo_doc,
					rm_g39.g39_fec_entrega
			CALL mostar_nombres_eti()
			CONTINUE INPUT
		END IF
		IF rm_g39.g39_fec_entrega > TODAY THEN
			CALL fl_mostrar_mensaje('La Fecha de Entrega no puede ser mayor a la de hoy.', 'exclamation')
			NEXT FIELD g39_fec_entrega
		END IF
	AFTER FIELD g39_num_sri_fin
		IF rm_g39.g39_num_sri_fin < 1 THEN
			CALL fl_mostrar_mensaje('El Número Final del SRI debe ser mayor 0.', 'exclamation')
			NEXT FIELD g39_num_sri_fin
		END IF
	AFTER INPUT
		IF rm_g39.g39_num_sri_fin < rm_g39.g39_num_sri_ini THEN
			CALL fl_mostrar_mensaje('El Número Final debe ser mayor al Número Inicial del SRI.', 'exclamation')
			NEXT FIELD g39_num_sri_fin
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
SELECT * INTO rm_g39.* FROM gent039 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con Indice: ' || num_row,
				'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_g39.g39_tipo_doc, rm_g39.g39_localidad,
		rm_g39.g39_fec_entrega, rm_g39.g39_secuencia,
		rm_g39.g39_num_sri_ini, rm_g39.g39_num_sri_fin,
		rm_g39.g39_num_dias_col, rm_g39.g39_usuario, rm_g39.g39_fecing
CALL mostar_nombres_eti()

END FUNCTION



FUNCTION mostar_nombres_eti()
DEFINE r_z04		RECORD LIKE cxct004.*
DEFINE r_g02		RECORD LIKE gent002.*

CALL fl_lee_tipo_doc(rm_g39.g39_tipo_doc) RETURNING r_z04.* 
CALL fl_lee_localidad(vg_codcia, rm_g39.g39_localidad) RETURNING r_g02.*
DISPLAY BY NAME r_z04.z04_nombre, r_g02.g02_nombre

END FUNCTION



FUNCTION muestra_otros_datos()
DEFINE run_prog		CHAR(10)
DEFINE comando		CHAR(400)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'GENERALES',
	vg_separador, 'fuentes', vg_separador, run_prog, ' genp142 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', rm_g39.g39_localidad, ' "',
	rm_g39.g39_tipo_doc, '" ', rm_g39.g39_secuencia
RUN comando

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
