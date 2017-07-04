--------------------------------------------------------------------------------
-- Titulo               : rolp113.4gl -- Mantenimiento de Conf. Adicional Nomina
-- Elaboración          : 06-Mar-2007
-- Autor                : NPC
-- Formato de Ejecución : fglrun rolp113 Base Modulo Compañía
-- Ultima Correción     : 
-- Motivo Corrección    : 
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_n90   	RECORD LIKE rolt090.*
DEFINE vm_r_rows	ARRAY[10] OF INTEGER
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_flag_mant     CHAR(1)



MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp113.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp113'
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
LET vm_max_rows = 10
LET lin_menu    = 0
LET row_ini     = 3
LET num_rows    = 22
LET num_cols    = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rolf113_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST)
IF vg_gui = 1 THEN
	OPEN FORM f_rolf113_1 FROM '../forms/rolf113_1'
ELSE
	OPEN FORM f_rolf113_1 FROM '../forms/rolf113_1c'
END IF
DISPLAY FORM f_rolf113_1
INITIALIZE rm_n90.* TO NULL
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

END FUNCTION



FUNCTION control_ingreso()
DEFINE r_g01		RECORD LIKE gent001.*

CLEAR FORM
INITIALIZE rm_n90.* TO NULL
LET vm_flag_mant            = 'I'
LET rm_n90.n90_compania     = vg_codcia
LET rm_n90.n90_dias_anio    = (MDY(12, 31, YEAR(TODAY)) -
				MDY(01, 01, YEAR(TODAY))) + 1
LET rm_n90.n90_tiem_max_vac = 3
LET rm_n90.n90_dias_min_par = 0
LET rm_n90.n90_gen_cont_vac = 'S'
LET rm_n90.n90_gen_cont_ant = 'S'
LET rm_n90.n90_porc_int_ant = 0
LET rm_n90.n90_mes_gra_ant  = 0
LET rm_n90.n90_gen_cont_ut  = 'N'
LET rm_n90.n90_fecing       = CURRENT
LET rm_n90.n90_usuario      = vg_usuario
CALL fl_lee_compania(rm_n90.n90_compania) RETURNING r_g01.*
DISPLAY BY NAME r_g01.g01_razonsocial, rm_n90.n90_fecing, rm_n90.n90_usuario
CALL lee_datos()
IF int_flag THEN
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	RETURN
END IF
INSERT INTO rolt090 VALUES (rm_n90.*)
IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_r_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
LET vm_row_current         = vm_num_rows
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

LET vm_flag_mant = 'M'
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM rolt090 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_n90.*
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
UPDATE rolt090 SET * = rm_n90.* WHERE CURRENT OF q_up
COMMIT WORK
CALL lee_muestra_registro(vm_r_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(800)
DEFINE query		CHAR(1200)
DEFINE r_g01		RECORD LIKE gent001.*

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON n90_compania, n90_dias_anio, n90_tiem_max_vac,
	n90_dias_ano_vac, n90_dias_min_par, n90_anio_ini_vac, n90_gen_cont_vac,
	n90_dias_ano_ant, n90_porc_int_ant, n90_anio_ini_ant, n90_gen_cont_ant,
	n90_mes_gra_ant, n90_dias_ano_ut, n90_anio_ini_ut, n90_gen_cont_ut,
	n90_usuario
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(n90_compania) THEN
			CALL fl_ayuda_companias_roles()
				RETURNING r_g01.g01_compania,
					  r_g01.g01_razonsocial
			IF r_g01.g01_compania IS NOT NULL THEN
				DISPLAY r_g01.g01_compania TO n90_compania
				DISPLAY BY NAME r_g01.g01_razonsocial
			END IF
		END IF
                LET int_flag = 0
	BEFORE CONSTRUCT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
END CONSTRUCT
IF int_flag THEN
	CLEAR FORM
	IF vm_num_rows >0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM rolt090 ',
		' WHERE ', expr_sql CLIPPED,
		' ORDER BY 1 '
PREPARE cons FROM query
DECLARE q_uni CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_uni INTO rm_n90.*, vm_r_rows[vm_num_rows]
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
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_n90		RECORD LIKE rolt090.*
DEFINE resp      	CHAR(6)

LET int_flag = 0 
INPUT BY NAME rm_n90.n90_compania, rm_n90.n90_dias_anio,rm_n90.n90_tiem_max_vac,
	rm_n90.n90_dias_ano_vac,rm_n90.n90_dias_min_par,rm_n90.n90_anio_ini_vac,
	rm_n90.n90_gen_cont_vac,rm_n90.n90_dias_ano_ant,rm_n90.n90_porc_int_ant,
	rm_n90.n90_anio_ini_ant,rm_n90.n90_gen_cont_ant, rm_n90.n90_mes_gra_ant,
	rm_n90.n90_dias_ano_ut, rm_n90.n90_anio_ini_ut, rm_n90.n90_gen_cont_ut
	WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_n90.n90_compania, rm_n90.n90_dias_anio,
				rm_n90.n90_tiem_max_vac,rm_n90.n90_dias_ano_vac,
				rm_n90.n90_dias_min_par,rm_n90.n90_anio_ini_vac,
				rm_n90.n90_gen_cont_vac,rm_n90.n90_dias_ano_ant,
				rm_n90.n90_porc_int_ant,rm_n90.n90_anio_ini_ant,
				rm_n90.n90_gen_cont_ant,rm_n90.n90_mes_gra_ant,
				rm_n90.n90_dias_ano_ut, rm_n90.n90_anio_ini_ut,
				rm_n90.n90_gen_cont_ut)
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
	ON KEY(F2)
		IF INFIELD(n90_compania) THEN
			IF vm_flag_mant = 'M' THEN
				CONTINUE INPUT
			END IF
			CALL fl_ayuda_companias_roles()
				RETURNING r_g01.g01_compania,
					  r_g01.g01_razonsocial
			IF r_g01.g01_compania IS NOT NULL THEN
				LET rm_n90.n90_compania = r_g01.g01_compania
				DISPLAY r_g01.g01_compania TO n90_compania
				DISPLAY BY NAME r_g01.g01_razonsocial
			END IF
		END IF
                LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD n90_compania
		IF vm_flag_mant = 'M' THEN
			LET r_g01.g01_compania = rm_n90.n90_compania
		END IF
	 AFTER FIELD n90_compania
		IF vm_flag_mant = 'M' THEN
			LET rm_n90.n90_compania = r_g01.g01_compania
			CALL fl_lee_compania(rm_n90.n90_compania)
				RETURNING r_g01.*
			DISPLAY BY NAME rm_n90.n90_compania,
					r_g01.g01_razonsocial
			CONTINUE INPUT
		END IF
		IF rm_n90.n90_compania IS NOT NULL THEN
			CALL fl_lee_compania(rm_n90.n90_compania)
				RETURNING r_g01.*
			IF r_g01.g01_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Compania no existe', 'exclamation')
				NEXT FIELD n90_compania
			END IF
			DISPLAY BY NAME r_g01.g01_razonsocial
			IF r_g01.g01_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD n90_compania
			END IF
			CALL fl_lee_conf_adic_rol(rm_n90.n90_compania)
				RETURNING r_n90.*
			IF rm_n90.n90_compania = r_n90.n90_compania THEN
				CALL fl_mostrar_mensaje('Compania ya ha sido asignada para configuracion adicional de nomina.', 'exclamation')
				NEXT FIELD n90_compania
			END IF
		ELSE
			CLEAR g01_razonsocial
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
DEFINE r_g01		RECORD LIKE gent001.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_n90.* FROM rolt090 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con indice: ' || num_row,'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_n90.n90_compania, rm_n90.n90_dias_anio,
	rm_n90.n90_tiem_max_vac,rm_n90.n90_dias_ano_vac,rm_n90.n90_dias_min_par,
	rm_n90.n90_anio_ini_vac,rm_n90.n90_gen_cont_vac,rm_n90.n90_dias_ano_ant,
	rm_n90.n90_porc_int_ant,rm_n90.n90_anio_ini_ant,rm_n90.n90_gen_cont_ant,
	rm_n90.n90_mes_gra_ant, rm_n90.n90_dias_ano_ut, rm_n90.n90_anio_ini_ut,
	rm_n90.n90_gen_cont_ut, rm_n90.n90_usuario, rm_n90.n90_fecing
CALL fl_lee_compania(rm_n90.n90_compania) RETURNING r_g01.*
DISPLAY BY NAME r_g01.g01_razonsocial
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION


                                                                                
FUNCTION muestra_contadores(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

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
