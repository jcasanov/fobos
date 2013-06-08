-------------------------------------------------------------------------------
-- Titulo               : talp104.4gl -- Mantenimiento de Tipos de Vehiculos
-- Elaboración          : 7-sep-2001
-- Autor                : GVA
-- Formato de Ejecución : fglrun  talp104.4gl base TA 1 
-- Ultima Correción     : 8-sep-2001
-- Motivo Corrección    : 1
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_tveh		RECORD LIKE talt004.*
DEFINE rm_tveh2		RECORD LIKE talt004.*
DEFINE rm_mar		RECORD LIKE talt001.*
DEFINE vm_r_rows	ARRAY[1000] OF INTEGER -- ARREGLO DE ROWID FILAS LEIDAS
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_flag_mant     CHAR(1)



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp104.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'talp104'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
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
OPEN WINDOW w_tveh AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_tveh FROM '../forms/talf104_1'
ELSE
	OPEN FORM f_tveh FROM '../forms/talf104_1c'
END IF
DISPLAY FORM f_tveh
INITIALIZE rm_tveh.* TO NULL
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
		IF vm_row_current < vm_num_rows THEN
			LET vm_row_current = vm_row_current + 1 
		END IF	
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
		CALL muestra_contadores(vm_row_current, vm_num_rows)
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		IF vm_row_current > 1 THEN
			LET vm_row_current = vm_row_current - 1 
		END IF
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
		CALL muestra_contadores(vm_row_current, vm_num_rows)
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
DEFINE expr_sql		CHAR(500)
DEFINE query		CHAR(600)

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON t04_modelo, t04_linea, t04_dificultad, 
		              t04_usuario, t04_fecing
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(t04_modelo) THEN
		     CALL fl_ayuda_tipos_vehiculos(vg_codcia)
		     	RETURNING rm_tveh2.t04_modelo, rm_tveh2.t04_linea
		     IF rm_tveh2.t04_modelo IS NOT NULL THEN
			LET rm_tveh.t04_modelo = rm_tveh2.t04_modelo
			LET rm_tveh.t04_linea = rm_tveh2.t04_linea
			DISPLAY BY NAME rm_tveh.t04_modelo, rm_tveh.t04_linea
		     END IF
		END IF
                IF INFIELD(t04_linea) THEN
			CALL fl_ayuda_marcas_taller(vg_codcia)
				RETURNING rm_mar.t01_linea, rm_mar.t01_nombre
			IF rm_mar.t01_linea IS NOT NULL THEN
			    LET rm_tveh.t04_linea = rm_mar.t01_linea
			    DISPLAY BY NAME rm_tveh.t04_linea
			    DISPLAY rm_mar.t01_nombre TO nom_linea
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
LET query = 'SELECT *, ROWID FROM talt004 ',
		' WHERE t04_compania = ', vg_codcia,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 2, 3'
PREPARE cons FROM query
DECLARE q_tveh CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_tveh INTO rm_tveh.*, vm_r_rows[vm_num_rows]
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
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION control_ingreso()
DEFINE r_t00		RECORD LIKE talt000.*

OPTIONS INPUT WRAP
CLEAR FORM
INITIALIZE rm_tveh.* TO NULL
LET vm_flag_mant          = 'I'
LET rm_tveh.t04_compania    = vg_codcia
LET rm_tveh.t04_fecing      = CURRENT
LET rm_tveh.t04_usuario     = vg_usuario
LET rm_tveh.t04_cod_mod_veh = 'N'
DISPLAY BY NAME rm_tveh.t04_fecing, rm_tveh.t04_usuario
CALL lee_datos()
IF NOT int_flag THEN
	BEGIN WORK
	INSERT INTO talt004 VALUES (rm_tveh.*)
	CALL fl_lee_configuracion_taller(vg_codcia)
		RETURNING r_t00.*
	COMMIT WORK
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

LET vm_flag_mant      = 'M'
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR SELECT * FROM talt004 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_tveh.*
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL lee_datos()
IF NOT int_flag THEN
    	UPDATE talt004 SET * = rm_tveh.*
		WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CLOSE q_up

END FUNCTION



FUNCTION lee_datos()
DEFINE           resp      CHAR(6)
DEFINE           codigo    LIKE talt004.t04_modelo
                                                                                
OPTIONS INPUT WRAP
LET int_flag = 0 
INPUT BY NAME rm_tveh.t04_modelo, rm_tveh.t04_linea, rm_tveh.t04_dificultad
	      WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
        	 IF field_touched(rm_tveh.t04_modelo, rm_tveh.t04_dificultad,
				  rm_tveh.t04_linea)
                 THEN
                        LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                        	RETURNING resp
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
                IF INFIELD(t04_linea) THEN
			CALL fl_ayuda_marcas_taller(vg_codcia)
				RETURNING rm_mar.t01_linea, rm_mar.t01_nombre
			IF rm_mar.t01_linea IS NOT NULL THEN
			    LET rm_tveh.t04_linea = rm_mar.t01_linea
			    DISPLAY BY NAME rm_tveh.t04_linea
			    DISPLAY rm_mar.t01_nombre TO nom_linea
			END IF
                END IF
                LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD t04_modelo
		IF vm_flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	AFTER FIELD t04_dificultad
		IF  rm_tveh.t04_dificultad IS NOT NULL THEN
			IF rm_tveh.t04_dificultad < 1 OR 
			   rm_tveh.t04_dificultad > 10 THEN
				--CALL fgl_winmessage(vg_producto,'El nivel de dificultad no es valido ','exclamation')
				CALL fl_mostrar_mensaje('El nivel de dificultad no es válido.','exclamation')
			     	NEXT FIELD t04_dificultad
			END IF 	
		END IF 	
	AFTER FIELD t04_linea
               IF rm_tveh.t04_linea IS NOT NULL THEN
		     CALL fl_lee_linea_taller(vg_codcia, rm_tveh.t04_linea)
		     	RETURNING rm_mar.*
		     IF rm_mar.t01_linea IS NULL THEN
			--CALL fgl_winmessage(vg_producto,'No existe la línea de taller','exclamation')
			CALL fl_mostrar_mensaje('No existe la línea de taller.','exclamation')
			NEXT FIELD t04_linea
		     END IF
		     DISPLAY rm_mar.t01_nombre TO nom_linea	
		ELSE
			CLEAR nom_linea
		END IF
	AFTER INPUT
               IF vm_flag_mant = 'I' THEN
                        CALL fl_lee_tipo_vehiculo(vg_codcia, rm_tveh.t04_modelo)
                                RETURNING rm_tveh2.*
                        IF rm_tveh2.t04_modelo IS NOT NULL THEN
                                --CALL fgl_winmessage (vg_producto,'El tipo de vehículo ya existe en la compañia ','exclamation')
				CALL fl_mostrar_mensaje('El tipo de vehículo ya existe en la compañia.','exclamation')
                                NEXT FIELD t04_modelo
                        END IF
             	END IF
END INPUT

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_tveh.* FROM talt004 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_tveh.t04_modelo, rm_tveh.t04_dificultad,
		rm_tveh.t04_linea, rm_tveh.t04_usuario,
	 	rm_tveh.t04_fecing
CALL fl_lee_linea_taller(vg_codcia, rm_tveh.t04_linea)
RETURNING rm_mar.*
DISPLAY rm_mar.t01_nombre TO nom_linea

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



FUNCTION llamar_visor_teclas()
DEFINE a		CHAR(1)

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION
