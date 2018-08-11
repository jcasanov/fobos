-------------------------------------------------------------------------------
-- Titulo               : rolp109.4gl -- Mantenimiento de Sectoriales
-- Elaboraci�n          : 08-Sep-2003
-- Autor                : NPC
-- Formato de Ejecuci�n : fglrun rolp109 Base Modulo Compa��a
-- Ultima Correci�n     : 
-- Motivo Correcci�n    : 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_n17   	RECORD LIKE rolt017.*
DEFINE rm_n00		RECORD LIKE rolt000.*
DEFINE vm_r_rows	ARRAY[1000] OF INTEGER
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_flag_mant     CHAR(1)



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp109.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
	CALL fl_mostrar_mensaje('N�mero de par�metros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp109'
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
CALL fl_lee_parametro_general_roles() RETURNING rm_n00.*
IF rm_n00.n00_serial IS NULL THEN
        CALL fl_mostrar_mensaje('No existe configuraci�n general para este m�dulo.', 'stop')
	EXIT PROGRAM
END IF
LET vm_max_rows = 1000
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 15
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rol AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_rolf109 FROM '../forms/rolf109_1'
ELSE
	OPEN FORM f_rolf109 FROM '../forms/rolf109_1c'
END IF
DISPLAY FORM f_rolf109
INITIALIZE rm_n17.* TO NULL
LET vm_num_rows = 0
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
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(600)
DEFINE query		CHAR(800)
DEFINE r_n17		RECORD LIKE rolt017.*

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON n17_ano_sect, n17_sectorial, n17_descripcion,
	n17_valor, n17_usuario, n17_fecing
        ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT CONSTRUCT
	ON KEY(F2)
		IF INFIELD(n17_sectorial) THEN
			CALL fl_ayuda_sectorial(vg_codcia, 2003, 'C')
				RETURNING r_n17.n17_ano_sect,
					  r_n17.n17_sectorial,
					  r_n17.n17_descripcion
			IF r_n17.n17_sectorial IS NOT NULL THEN
				DISPLAY BY NAME r_n17.n17_ano_sect,
						r_n17.n17_sectorial,
						r_n17.n17_descripcion
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
LET query = 'SELECT *, ROWID FROM rolt017 ',
		'WHERE n17_compania = ', vg_codcia,
		'  AND ', expr_sql CLIPPED,
		' ORDER BY 2, 3'
PREPARE cons FROM query
DECLARE q_uni CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_uni INTO rm_n17.*, vm_r_rows[vm_num_rows]
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
INITIALIZE rm_n17.* TO NULL
LET rm_n17.n17_compania = vg_codcia
LET rm_n17.n17_valor    = 0
LET rm_n17.n17_usuario  = vg_usuario
LET rm_n17.n17_fecing   = CURRENT
DISPLAY BY NAME rm_n17.n17_usuario, rm_n17.n17_fecing
CALL lee_datos()
IF NOT int_flag THEN
	LET rm_n17.n17_fecing = CURRENT
        INSERT INTO rolt017 VALUES (rm_n17.*)
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
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM rolt017
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_n17.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL lee_datos()
IF int_flag THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	RETURN
END IF
UPDATE rolt017 SET * = rm_n17.* WHERE CURRENT OF q_up
COMMIT WORK
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION lee_datos()
DEFINE resp      	CHAR(6)
DEFINE r_n17		RECORD LIKE rolt017.*
DEFINE ano_aux		LIKE rolt017.n17_ano_sect
DEFINE sect_aux		LIKE rolt017.n17_sectorial
DEFINE val_aux		LIKE rolt017.n17_valor
DEFINE mensaje		VARCHAR(200)

LET int_flag = 0 
INPUT BY NAME rm_n17.n17_ano_sect, rm_n17.n17_sectorial, rm_n17.n17_descripcion,
	rm_n17.n17_valor
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_n17.n17_ano_sect, rm_n17.n17_sectorial,
				 rm_n17.n17_descripcion, rm_n17.n17_valor)
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
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD n17_ano_sect
		IF vm_flag_mant = 'M' THEN
			LET ano_aux = rm_n17.n17_ano_sect
		END IF
	BEFORE FIELD n17_sectorial
		IF vm_flag_mant = 'M' THEN
			LET sect_aux = rm_n17.n17_sectorial
		END IF
	BEFORE FIELD n17_valor
		IF rm_n17.n17_valor IS NOT NULL THEN
			LET val_aux = rm_n17.n17_valor
		END IF
	AFTER FIELD n17_ano_sect
		IF vm_flag_mant = 'M' THEN
			LET rm_n17.n17_ano_sect = ano_aux
			DISPLAY BY NAME rm_n17.n17_ano_sect
		END IF
	AFTER FIELD n17_sectorial
		IF vm_flag_mant = 'M' THEN
			LET rm_n17.n17_sectorial = sect_aux
			DISPLAY BY NAME rm_n17.n17_sectorial
		END IF
	AFTER FIELD n17_valor
		IF rm_n17.n17_valor IS NULL THEN
			LET rm_n17.n17_valor = val_aux
			DISPLAY BY NAME rm_n17.n17_valor
		END IF
		IF rm_n17.n17_valor < rm_n00.n00_salario_min THEN
			LET mensaje = 'El valor del c�digo sectorial no puede',
					' ser menor que ',
				rm_n00.n00_salario_min USING '##,##&.##',
					' que es el salario basico unificado.'
			CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			NEXT FIELD n17_valor
		END IF
	AFTER INPUT
		IF vm_flag_mant = 'I' THEN
			CALL fl_lee_cod_sectorial(vg_codcia,
						rm_n17.n17_ano_sect,
						rm_n17.n17_sectorial)
				RETURNING r_n17.*
			IF r_n17.n17_sectorial IS NOT NULL THEN
				CALL fl_mostrar_mensaje('Este c�digo de sectorial ya existe en esta compa��a.','exclamation')
				CONTINUE INPUT
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
SELECT * INTO rm_n17.* FROM rolt017 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con �ndice: ' || num_row,'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_n17.n17_ano_sect, rm_n17.n17_sectorial,
		rm_n17.n17_descripcion, rm_n17.n17_valor,
		rm_n17.n17_usuario, rm_n17.n17_fecing

END FUNCTION


                                                                                
FUNCTION muestra_contadores(num_rows, max_rows)
DEFINE num_rows		SMALLINT
DEFINE max_rows		SMALLINT

DISPLAY BY NAME num_rows, max_rows

END FUNCTION
