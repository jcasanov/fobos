--------------------------------------------------------------------------------
-- Titulo               : actp106.4gl -- Mantenimiento Tipo Trans. Activos Fijos
-- Elaboracion          : 23-Nov-2009
-- Autor                : NPC
-- Formato de Ejecucion : fglrun actp106 Base Modulo Compañía
-- Ultima Correcion     : 
-- Motivo Correccion    : 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_a04   	RECORD LIKE actt004.*
DEFINE rm_a05   	RECORD LIKE actt005.*
DEFINE vm_r_rows	ARRAY[1000] OF INTEGER
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_flag_mant     CHAR(1)



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/actp106.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'actp106'
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
LET vm_max_rows = 1000
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 17
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_actf106_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_actf106_1 FROM '../forms/actf106_1'
ELSE
	OPEN FORM f_actf106_1 FROM '../forms/actf106_1c'
END IF
DISPLAY FORM f_actf106_1
INITIALIZE rm_a04.*, rm_a05.* TO NULL
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Bloquear/Activar'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		CALL control_ingreso()
		IF vm_num_rows = 1 THEN
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
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
			SHOW OPTION 'Bloquear/Activar'
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
				HIDE OPTION 'Bloquear/Activar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Modificar'
			SHOW OPTION 'Bloquear/Activar'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
        COMMAND KEY('B') 'Bloquear/Activar' 'Activa o Bloquea registro actual. '
		CALL control_bloquear_activar()
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro'
		CALL lee_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		CALL lee_anterior_registro()
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
CLOSE WINDOW w_actf106_1

END FUNCTION



FUNCTION control_ingreso()
DEFINE aux_num		INTEGER

CLEAR FORM
INITIALIZE rm_a04.*, rm_a05.* TO NULL
LET vm_flag_mant          = 'I'
LET rm_a05.a05_compania   = vg_codcia
LET rm_a04.a04_estado     = 'A'
LET rm_a04.a04_periocidad = 'M'
LET rm_a05.a05_numero     = 0
LET rm_a04.a04_fecing     = CURRENT
LET rm_a04.a04_usuario    = vg_usuario
DISPLAY BY NAME rm_a04.a04_fecing, rm_a04.a04_usuario
CALL muestra_estado()
CALL lee_datos()
IF int_flag THEN
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	RETURN
END IF
BEGIN WORK
	LET rm_a04.a04_fecing = CURRENT
	INSERT INTO actt004 VALUES (rm_a04.*)
	LET aux_num = SQLCA.SQLERRD[6] 
	LET rm_a05.a05_codigo_tran = rm_a04.a04_codigo_proc
	INSERT INTO actt005 VALUES (rm_a05.*)
COMMIT WORK
IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_r_rows[vm_num_rows] = aux_num
LET vm_row_current         = vm_num_rows
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

IF rm_a04.a04_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
LET vm_flag_mant = 'M'
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM actt004
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_a04.*
IF STATUS < 0 THEN
	WHENEVER ERROR STOP
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN
END IF
WHENEVER ERROR STOP
CALL lee_datos()
IF int_flag THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	RETURN
END IF
UPDATE actt004
	SET * = rm_a04.*
	WHERE CURRENT OF q_up
UPDATE actt005
	SET * = rm_a05.*
	WHERE a05_compania    = rm_a05.a05_compania
	  AND a05_codigo_tran = rm_a05.a05_codigo_tran
COMMIT WORK
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(800)
DEFINE query		CHAR(1500)
DEFINE r_a04		RECORD LIKE actt004.*

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON a04_estado, a04_codigo_proc, a04_nombre,
	a04_periocidad, a05_numero, a04_usuario, a04_fecing
	ON KEY(F2)
		IF INFIELD(a04_codigo_proc) THEN
			CALL fl_ayuda_tipo_trans_act('T')
				RETURNING r_a04.a04_codigo_proc,
					  r_a04.a04_nombre
			IF r_a04.a04_codigo_proc IS NOT NULL THEN
				LET rm_a04.a04_codigo_proc =
							r_a04.a04_codigo_proc
				LET rm_a04.a04_nombre  = r_a04.a04_nombre
				DISPLAY BY NAME rm_a04.a04_codigo_proc,
						rm_a04.a04_nombre
			END IF
		END IF
		LET int_flag = 0
END CONSTRUCT
IF int_flag THEN
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	RETURN
END IF
LET query = 'SELECT actt004.*, actt005.*, actt004.ROWID ',
		' FROM actt004, actt005 ',
		' WHERE a05_codigo_tran = a04_codigo_proc ',
		'   AND a05_compania    = ', vg_codcia,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 2 '
PREPARE cons FROM query
DECLARE q_uni CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_uni INTO rm_a04.*, rm_a05.*, vm_r_rows[vm_num_rows]
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
CALL lee_muestra_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION lee_datos()
DEFINE r_a04		RECORD LIKE actt004.*
DEFINE r_a05		RECORD LIKE actt005.*
DEFINE resp      	CHAR(6)

LET int_flag = 0 
INPUT BY NAME rm_a04.a04_codigo_proc, rm_a04.a04_nombre, rm_a04.a04_periocidad,
	rm_a05.a05_numero
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_a04.a04_codigo_proc, rm_a04.a04_nombre,
				 rm_a04.a04_periocidad, rm_a05.a05_numero)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
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
	BEFORE FIELD a04_codigo_proc
		IF vm_flag_mant = 'M' THEN
			LET r_a04.a04_codigo_proc = rm_a04.a04_codigo_proc
		END IF
	BEFORE FIELD a05_numero
		LET r_a05.a05_numero = rm_a05.a05_numero
	AFTER FIELD a04_codigo_proc
		IF vm_flag_mant = 'M' THEN
			LET rm_a04.a04_codigo_proc = r_a04.a04_codigo_proc
			CALL fl_lee_tipo_tran_act(rm_a04.a04_codigo_proc)
				RETURNING r_a04.*
			DISPLAY BY NAME rm_a04.a04_codigo_proc
			CONTINUE INPUT
		END IF
		IF rm_a04.a04_codigo_proc IS NOT NULL THEN
			CALL fl_lee_tipo_tran_act(rm_a04.a04_codigo_proc)
				RETURNING r_a04.*
			IF r_a04.a04_codigo_proc IS NOT NULL THEN
				CALL fl_mostrar_mensaje('Tipo transaccion ya existe en la Companía.', 'exclamation')
				NEXT FIELD a04_codigo_proc
			END IF
			IF r_a04.a04_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD a04_codigo_proc
			END IF
		END IF
	AFTER FIELD a05_numero
		IF rm_a05.a05_numero IS NULL THEN
			LET rm_a05.a05_numero = r_a05.a05_numero
			DISPLAY BY NAME rm_a05.a05_numero
		END IF
	AFTER INPUT
		IF vm_flag_mant = 'I' THEN
			INITIALIZE r_a04.* TO NULL
			SELECT * INTO r_a04.*
				FROM actt004
				WHERE a04_nombre = rm_a04.a04_nombre
			IF r_a04.a04_codigo_proc IS NOT NULL THEN
				CALL fl_mostrar_mensaje('Ya existe configurado un registro para esta descripcion de transaccion.', 'exclamation')
				CONTINUE INPUT
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION control_bloquear_activar()
DEFINE confir		CHAR(6)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET int_flag = 0
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_ba CURSOR FOR
	SELECT * FROM actt004
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_ba
FETCH q_ba INTO rm_a04.*
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
CALL fl_mostrar_mensaje('Se cambió el estado de esta configuracion Ok.', 'info')

END FUNCTION



FUNCTION bloquea_activa_registro()
DEFINE estado		LIKE actt004.a04_estado

IF rm_a04.a04_estado = 'A' THEN
	LET estado = 'B'
END IF
IF rm_a04.a04_estado = 'B' THEN
	LET estado = 'A'
END IF
LET rm_a04.a04_estado = estado
UPDATE actt004
	SET a04_estado = estado
	WHERE CURRENT OF q_ba
CALL muestra_estado()

END FUNCTION



FUNCTION muestra_estado()
DEFINE r_a06		RECORD LIKE actt006.*

CALL fl_lee_estado_activos(vg_codcia, rm_a04.a04_estado) RETURNING r_a06.*
IF r_a06.a06_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Estado no existe.', 'exclamation')
END IF
DISPLAY BY NAME rm_a04.a04_estado, r_a06.a06_descripcion

END FUNCTION



FUNCTION lee_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1 
END IF	
CALL lee_muestra_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION lee_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1 
END IF
CALL lee_muestra_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n30		RECORD LIKE rolt030.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_a04.*, rm_a05.*
	FROM actt004, actt005
	WHERE actt004.ROWID   = num_row
	  AND a05_compania    = vg_codcia
	  AND a05_codigo_tran = a04_codigo_proc
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || num_row,'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_a04.a04_estado, rm_a04.a04_codigo_proc, rm_a04.a04_nombre,
	rm_a04.a04_periocidad, rm_a05.a05_numero, rm_a04.a04_usuario,
	rm_a04.a04_fecing
CALL muestra_estado()
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION


                                                                                
FUNCTION muestra_contadores(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION
