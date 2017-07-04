-------------------------------------------------------------------------------
-- Titulo               : rolp132.4gl -- Mantenimiento de Rubros del Club
-- Elaboración          : 22-Oct-2003
-- Autor                : NPC
-- Formato de Ejecución : fglrun rolp132 Base Modulo Compañía
-- Ultima Correción     : 
-- Motivo Corrección    : 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_n67   	RECORD LIKE rolt067.*
DEFINE vm_r_rows	ARRAY[1000] OF INTEGER
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_flag_mant     CHAR(1)



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp132'
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
LET num_rows = 14
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rol AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_rolf132 FROM '../forms/rolf132_1'
ELSE
	OPEN FORM f_rolf132 FROM '../forms/rolf132_1c'
END IF
DISPLAY FORM f_rolf132
INITIALIZE rm_n67.* TO NULL
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
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro'
		CALL mostrar_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		CALL mostrar_anterior_registro()
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



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(500)
DEFINE query		CHAR(700)
DEFINE r_n67		RECORD LIKE rolt067.*

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON n67_estado, n67_cod_rubro, n67_nombre,
	n67_flag_ident, n67_usuario
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(n67_cod_rubro) THEN
			CALL fl_ayuda_rubros_club('T')
				RETURNING r_n67.n67_cod_rubro,
					  r_n67.n67_nombre
			IF r_n67.n67_cod_rubro IS NOT NULL THEN
				DISPLAY r_n67.n67_cod_rubro TO n67_cod_rubro
				DISPLAY BY NAME r_n67.n67_nombre
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD n67_estado
		LET rm_n67.n67_estado = get_fldbuf(n67_estado)
		IF rm_n67.n67_estado IS NOT NULL THEN
			CALL muestra_estado()
		ELSE
			CLEAR tit_estado
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
LET query = 'SELECT *, ROWID FROM rolt067 WHERE ', expr_sql CLIPPED,
		' ORDER BY 1'
PREPARE cons FROM query
DECLARE q_uni CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_uni INTO rm_n67.*, vm_r_rows[vm_num_rows]
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



FUNCTION control_ingreso()

OPTIONS INPUT WRAP
CLEAR FORM
LET vm_flag_mant = 'I'
INITIALIZE rm_n67.* TO NULL
LET rm_n67.n67_estado     = 'A'
LET rm_n67.n67_flag_ident = 'I'
LET rm_n67.n67_usuario    = vg_usuario
LET rm_n67.n67_fecing     = CURRENT
DISPLAY BY NAME rm_n67.n67_usuario, rm_n67.n67_fecing
CALL muestra_estado()
CALL lee_datos()
IF NOT int_flag THEN
	LET rm_n67.n67_fecing = CURRENT
        INSERT INTO rolt067 VALUES(rm_n67.*)
        IF vm_num_rows = vm_max_rows THEN
                LET vm_num_rows = 1
        ELSE
                LET vm_num_rows = vm_num_rows + 1
        END IF
	LET vm_r_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
	LET vm_row_current = vm_num_rows
	CALL fl_mensaje_registro_ingresado()
END IF
IF vm_num_rows > 0 THEN
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_modificacion()

LET vm_flag_mant = 'M'
IF rm_n67.n67_estado = 'B' THEN
	CALL fl_mostrar_mensaje('No puede modificar un código de seguro que esté bloqueado.', 'exclamation')
	RETURN
END IF
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM rolt067
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_n67.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL lee_datos()
IF NOT int_flag THEN
    	UPDATE rolt067 SET * = rm_n67.* WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION lee_datos()
DEFINE resp      	CHAR(6)
DEFINE r_n67		RECORD LIKE rolt067.*

LET int_flag = 0 
INPUT BY NAME rm_n67.n67_cod_rubro, rm_n67.n67_nombre, rm_n67.n67_flag_ident
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_n67.n67_cod_rubro, rm_n67.n67_nombre,
				 rm_n67.n67_flag_ident)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				IF vm_flag_mant = 'I' THEN
					CLEAR FORM
				END IF
				RETURN
			END IF
		ELSE
			IF vm_flag_mant = 'I' THEN
				CLEAR FORM
			END IF
			RETURN
		END IF       	
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD n67_cod_rubro
		IF vm_flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	AFTER INPUT
		IF vm_flag_mant = 'I' THEN
			CALL fl_lee_rubros_club(rm_n67.n67_cod_rubro)
				RETURNING r_n67.*
			IF r_n67.n67_cod_rubro IS NOT NULL THEN
				CALL fl_mostrar_mensaje('Este código de rubro del club ya existe en esta compañía.','exclamation')
				NEXT FIELD n67_cod_rubro
               		END IF
              	END IF
END INPUT

END FUNCTION



FUNCTION mostrar_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1 
END IF	
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION mostrar_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1 
END IF
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_n67.* FROM rolt067 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || num_row, 'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_n67.n67_cod_rubro, rm_n67.n67_nombre, rm_n67.n67_flag_ident,
		rm_n67.n67_usuario, rm_n67.n67_fecing
CALL muestra_estado()

END FUNCTION



FUNCTION bloquear_activar()
DEFINE confir		CHAR(6)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
LET int_flag = 0
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_ba CURSOR FOR
	SELECT * FROM rolt067
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_ba
FETCH q_ba INTO rm_n67.*
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
CALL fl_mostrar_mensaje('Se cambió el estado de este Código de Rubro del Club Ok.', 'info')
CALL muestra_estado()

END FUNCTION



FUNCTION bloquea_activa_registro()
DEFINE estado		LIKE rolt067.n67_estado

IF rm_n67.n67_estado = 'A' THEN
	LET estado = 'B'
END IF
IF rm_n67.n67_estado = 'B' THEN
	LET estado = 'A'
END IF
LET rm_n67.n67_estado = estado
UPDATE rolt067 SET n67_estado = estado WHERE CURRENT OF q_ba

END FUNCTION


                                                                                
FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current              SMALLINT
DEFINE num_rows                 SMALLINT
DEFINE nrow                     SMALLINT
                                                                                
LET nrow = 17
IF vg_gui = 1 THEN
	LET nrow = 1
END IF
DISPLAY "" AT nrow, 1
DISPLAY row_current, " de ", num_rows AT nrow, 67

END FUNCTION



FUNCTION muestra_estado()
DEFINE estado		LIKE rolt067.n67_estado

DISPLAY BY NAME rm_n67.n67_estado
LET estado = rm_n67.n67_estado
CASE estado
	WHEN 'A'
		DISPLAY 'ACTIVO'    TO tit_estado
	WHEN 'B'
		DISPLAY 'BLOQUEADO' TO tit_estado
	OTHERWISE
		CLEAR n67_estado, tit_estado
END CASE

END FUNCTION

                                                                                
                                                                                
FUNCTION llamar_visor_teclas()
DEFINE a		SMALLINT

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION
