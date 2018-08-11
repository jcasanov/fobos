-------------------------------------------------------------------------------
-- Titulo               : genp111.4gl -- Mantenimiento de Monedas
-- Elaboración          : 15-ago-2001
-- Autor                : GVA
-- Formato de Ejecución : fglrun  genp111.4gl base GE 
-- Ultima Correción     : 31-ago-2001
-- Motivo Corrección    : standares
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_mon   RECORD LIKE gent013.*
DEFINE rm_mon2  RECORD LIKE gent013.*
DEFINE vm_r_rows ARRAY[1000] OF INTEGER -- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO NUMERO DE FILAS LEIDAS
DEFINE vm_demonios      VARCHAR(12)
DEFINE vm_flag_mant     CHAR(1)


MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 2 THEN
     CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
     EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_proceso = 'genp111'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPEN WINDOW wf AT 3,2 WITH 15 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_mon FROM '../forms/genf111_1'
DISPLAY FORM f_mon
INITIALIZE rm_mon.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores()
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
		IF vm_row_current < vm_num_rows THEN
			LET vm_row_current = vm_row_current + 1 
		END IF	
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
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
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('E') 'Bloquear/Activar' 'Bloquear o activar registro. '
		CALL control_bloqueo_activacion()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_consulta()
DEFINE codigo		LIKE gent013.g13_moneda
DEFINE nombre		LIKE gent013.g13_nombre
DEFINE decimales	LIKE gent013.g13_decimales
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

CLEAR FORM
LET int_flag = 0
INITIALIZE codigo TO NULL
CONSTRUCT BY NAME expr_sql ON g13_moneda, g13_nombre, g13_simbolo, 
			      g13_decimales, g13_usuario, g13_fecing
	ON KEY(F2)
		IF INFIELD(g13_moneda) THEN
		      CALL fl_ayuda_monedas()RETURNING codigo, nombre, decimales
		      IF codigo IS NOT NULL THEN
		            LET rm_mon.g13_moneda = codigo
			    LET rm_mon.g13_nombre = nombre
			    DISPLAY BY NAME rm_mon.g13_moneda, rm_mon.g13_nombre
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
LET query = 'SELECT *, ROWID FROM gent013 WHERE ', expr_sql CLIPPED,
		' ORDER BY 2'
PREPARE cons FROM query
DECLARE q_mon CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_mon INTO rm_mon.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_row_current = 0
	CALL muestra_contadores()
        CLEAR FORM
        RETURN
END IF
LET vm_row_current = 1
CALL lee_muestra_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION control_ingreso()

OPTIONS INPUT WRAP
CLEAR FORM
INITIALIZE rm_mon.* TO NULL
LET vm_flag_mant       = 'I'
LET rm_mon.g13_fecing  = fl_current()
LET rm_mon.g13_usuario = vg_usuario
LET rm_mon.g13_estado = 'A'
DISPLAY BY NAME rm_mon.g13_fecing, rm_mon.g13_usuario, rm_mon.g13_estado
DISPLAY 'ACTIVO' TO tit_estado

CALL lee_datos()
IF NOT int_flag THEN
	INSERT INTO gent013 VALUES (rm_mon.*)
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	LET vm_r_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
	LET vm_row_current = vm_num_rows
	CALL muestra_contadores()
	CALL fl_mensaje_registro_ingresado()
ELSE
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF

END IF

END FUNCTION



FUNCTION control_modificacion()
DEFINE     	flag   CHAR(1)

IF rm_mon.g13_estado <> 'A' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF

LET vm_flag_mant       = 'M'
DISPLAY 'ACTIVO' TO tit_estado

WHENEVER ERROR CONTINUE
BEGIN WORK

DECLARE q_up CURSOR FOR 
	SELECT * FROM gent013 
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_mon.*

WHENEVER ERROR STOP
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	RETURN
END IF

CALL lee_datos()
IF NOT int_flag THEN
    	UPDATE gent013 SET * = rm_mon.*
		WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CLOSE q_up

END FUNCTION



FUNCTION control_bloqueo_activacion()
DEFINE resp    	CHAR(6)
DEFINE i	SMALLINT
DEFINE mensaje	VARCHAR(20)
DEFINE estado	CHAR(1)

IF rm_mon.g13_moneda IS NULL OR vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF

LET int_flag = 0
CALL fl_mensaje_seguro_ejecutar_proceso()
	RETURNING resp
IF resp = 'Yes' THEN
WHENEVER ERROR CONTINUE
	BEGIN WORK
	DECLARE q_del CURSOR FOR SELECT * FROM gent013 
		WHERE ROWID = vm_r_rows[vm_row_current]
		FOR UPDATE
	OPEN q_del
	FETCH q_del INTO rm_mon.*

	WHENEVER ERROR STOP
	IF status < 0 THEN
		COMMIT WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		RETURN
	END IF
	LET estado = 'B'
	IF rm_mon.g13_estado <> 'A' THEN
		LET estado = 'A'
	END IF
	UPDATE gent013 SET g13_estado = estado WHERE CURRENT OF q_del
	COMMIT WORK
	LET int_flag = 1
	CALL fl_mensaje_registro_modificado()
	CLEAR FORM	
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION lee_datos()
DEFINE           resp      CHAR(6)
                                                                                
OPTIONS INPUT WRAP
LET int_flag = 0 
INPUT BY NAME rm_mon.g13_moneda, rm_mon.g13_nombre, rm_mon.g13_simbolo,
	      rm_mon.g13_decimales  WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
		 IF field_touched(g13_moneda, g13_nombre, g13_simbolo, 
				  g13_decimales)
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
                        CLEAR FORM
                        RETURN
                END IF       	
	 BEFORE FIELD g13_moneda
		IF vm_flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF	
	 AFTER FIELD g13_moneda
            IF vm_flag_mant = 'I' THEN    
		CALL fl_lee_moneda(rm_mon.g13_moneda)RETURNING rm_mon2.*
                IF rm_mon2.g13_moneda IS NOT NULL THEN
		    CALL fgl_winmessage (vg_producto, 'La moneda ya existe en la base de datos','exclamation')
                        NEXT FIELD g13_moneda
                END IF
            END IF
	
	AFTER INPUT
		IF NOT field_touched(g13_moneda, g13_nombre, g13_simbolo, 
			             g13_decimales)
                   THEN
			LET int_flag = 1
			RETURN
		END IF
END INPUT
                                                                                
END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_mon.* FROM gent013 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_mon.*
IF rm_mon.g13_estado = 'A' THEN
        DISPLAY 'ACTIVO' TO tit_estado
ELSE
        DISPLAY 'BLOQUEADO' TO tit_estado
END IF
CALL muestra_contadores()

END FUNCTION


                                                                                
FUNCTION muestra_contadores()
                                                                                
DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 69
                                                                                
END FUNCTION

                                                                                
                                                                                
FUNCTION no_validar_parametros()
                                                                                
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

