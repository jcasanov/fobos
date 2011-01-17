-------------------------------------------------------------------------------
-- Titulo               : talp104.4gl -- Mantenimiento de Tipos de Vehiculos
-- Elaboración          : 7-sep-2001
-- Autor                : GVA
-- Formato de Ejecución : fglrun  talp104.4gl base TA 1 
-- Ultima Correción     : 8-sep-2001
-- Motivo Corrección    : 1
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_tveh   RECORD LIKE talt004.*
DEFINE rm_tveh2  RECORD LIKE talt004.*
DEFINE rm_mar    RECORD LIKE talt001.*
DEFINE vm_r_rows ARRAY[1000] OF INTEGER -- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_demonios      VARCHAR(12)
DEFINE vm_flag_mant     CHAR(1)

MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp104.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
     CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
     EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'talp104'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPEN WINDOW w_tveh AT 3,2 WITH 14 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_tveh FROM '../forms/talf104_1'
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
		   IF fl_control_permiso_opcion('Modificar') THEN		
			SHOW OPTION 'Modificar'
		   END IF
			
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
		    IF fl_control_permiso_opcion('Modificar') THEN		
			SHOW OPTION 'Modificar'
		    END IF
			
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
			IF vm_num_rows = 0 THEN
				HIDE OPTION 'Modificar'
			END IF
		ELSE
			SHOW OPTION 'Avanzar'
			IF fl_control_permiso_opcion('Modificar') THEN		
				SHOW OPTION 'Modificar'
			END IF
			
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
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON t04_modelo, t04_linea, t04_dificultad, 
		              t04_usuario, t04_fecing
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
END CONSTRUCT
IF int_flag THEN
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM talt004 WHERE ', expr_sql CLIPPED,
		' ORDER BY 2, 3'
PREPARE cons FROM query
DECLARE q_tveh CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_tveh INTO rm_tveh.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > 1000 THEN
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
	INSERT INTO talt004 VALUES (rm_tveh.*)
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
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM talt004 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_tveh.*
IF status < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
CALL lee_datos()
IF NOT int_flag THEN
    	UPDATE talt004 SET * = rm_tveh.*
		WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
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
	BEFORE  FIELD t04_modelo
		IF vm_flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	AFTER FIELD t04_dificultad
		IF  rm_tveh.t04_dificultad IS NOT NULL THEN
			IF rm_tveh.t04_dificultad < 1 OR 
			   rm_tveh.t04_dificultad > 10 THEN
				CALL fgl_winmessage(vg_producto,'El nivel de dificultad no es valido ','exclamation')
			     	NEXT FIELD t04_dificultad
			END IF 	
		END IF 	
	AFTER FIELD t04_linea
               IF rm_tveh.t04_linea IS NOT NULL THEN
		     CALL fl_lee_linea_taller(vg_codcia, rm_tveh.t04_linea)
		     	RETURNING rm_mar.*
		     IF rm_mar.t01_linea IS NULL THEN
			   CALL fgl_winmessage(vg_producto,'No existe la línea de taller','exclamation')
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
                                CALL fgl_winmessage (vg_producto, 'El tipo de vehículo ya existe en la compañia ','exclamation')
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
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 69
                                                                                
END FUNCTION

                                                                                
                                                                                
FUNCTION validar_parametros()
                                                                                
CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'sto
p')
        EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'st
op')
        EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
     CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 			 'stop')
     EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
        LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc,
			    'stop')
        EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
      CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 			  'stop')
      EXIT PROGRAM
END IF
                                                                                
END FUNCTION

