--------------------------------------------------------------------------------
-- Titulo               : actp107.4gl -- Mantenimiento Estados Activos Fijos
-- Elaboracion          : 23-Nov-2009
-- Autor                : NPC
-- Formato de Ejecucion : fglrun actp107 Base Modulo Compañía
-- Ultima Correcion     : 
-- Motivo Correccion    : 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_a06   	RECORD LIKE actt006.*
DEFINE vm_r_rows	ARRAY[1000] OF INTEGER
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_flag_mant     CHAR(1)



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/actp107.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'actp107'
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
LET num_rows = 8
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_actf107_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_actf107_1 FROM '../forms/actf107_1'
ELSE
	OPEN FORM f_actf107_1 FROM '../forms/actf107_1c'
END IF
DISPLAY FORM f_actf107_1
INITIALIZE rm_a06.* TO NULL
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
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
CLOSE WINDOW w_actf107_1

END FUNCTION



FUNCTION control_ingreso()
DEFINE aux_num		INTEGER

CLEAR FORM
INITIALIZE rm_a06.* TO NULL
LET vm_flag_mant          = 'I'
LET rm_a06.a06_compania   = vg_codcia
LET rm_a06.a06_fecing     = CURRENT
LET rm_a06.a06_usuario    = vg_usuario
DISPLAY BY NAME rm_a06.a06_fecing, rm_a06.a06_usuario
CALL lee_datos()
IF int_flag THEN
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	RETURN
END IF
LET rm_a06.a06_fecing = CURRENT
INSERT INTO actt006 VALUES (rm_a06.*)
LET aux_num = SQLCA.SQLERRD[6] 
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

LET vm_flag_mant = 'M'
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM actt006
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_a06.*
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
UPDATE actt006
	SET * = rm_a06.*
	WHERE CURRENT OF q_up
COMMIT WORK
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(800)
DEFINE query		CHAR(1500)
DEFINE r_a06		RECORD LIKE actt006.*

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON a06_estado, a06_descripcion, a06_usuario,
	a06_fecing
	ON KEY(F2)
		IF INFIELD(a06_estado) THEN
			CALL fl_ayuda_estado_activos(vg_codcia, 0)
				RETURNING r_a06.a06_estado,r_a06.a06_descripcion
			IF r_a06.a06_estado IS NOT NULL THEN
				LET rm_a06.a06_estado      = r_a06.a06_estado
				LET rm_a06.a06_descripcion =
							r_a06.a06_descripcion
				DISPLAY BY NAME rm_a06.a06_estado,
						rm_a06.a06_descripcion
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
LET query = 'SELECT *, ROWID ',
		' FROM actt006 ',
		' WHERE a06_compania = ', vg_codcia,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 2 '
PREPARE cons FROM query
DECLARE q_uni CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_uni INTO rm_a06.*, vm_r_rows[vm_num_rows]
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
DEFINE r_a06		RECORD LIKE actt006.*
DEFINE resp      	CHAR(6)

LET int_flag = 0 
INPUT BY NAME rm_a06.a06_estado, rm_a06.a06_descripcion
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_a06.a06_estado, rm_a06.a06_descripcion) THEN
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
	BEFORE FIELD a06_estado
		IF vm_flag_mant = 'M' THEN
			LET r_a06.a06_estado = rm_a06.a06_estado
		END IF
	AFTER FIELD a06_estado
		IF vm_flag_mant = 'M' THEN
			LET rm_a06.a06_estado = r_a06.a06_estado
			DISPLAY BY NAME rm_a06.a06_estado
			CONTINUE INPUT
		END IF
		IF rm_a06.a06_estado IS NOT NULL THEN
			CALL fl_lee_estado_activos(vg_codcia, rm_a06.a06_estado)
				RETURNING r_a06.*
			IF r_a06.a06_estado IS NOT NULL THEN
				CALL fl_mostrar_mensaje('Estado ya existe en la Companía.', 'exclamation')
				NEXT FIELD a06_estado
			END IF
		END IF
	AFTER INPUT
		IF vm_flag_mant = 'I' THEN
			INITIALIZE r_a06.* TO NULL
			SELECT * INTO r_a06.*
				FROM actt006
				WHERE a06_descripcion = rm_a06.a06_descripcion
			IF r_a06.a06_estado IS NOT NULL THEN
				CALL fl_mostrar_mensaje('Ya existe configurado un registro para esta descripcion de estado.', 'exclamation')
				CONTINUE INPUT
			END IF
		END IF
END INPUT

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
SELECT * INTO rm_a06.* FROM actt006 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || num_row,'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_a06.a06_estado, rm_a06.a06_descripcion, rm_a06.a06_usuario,
		rm_a06.a06_fecing
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION


                                                                                
FUNCTION muestra_contadores(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION
