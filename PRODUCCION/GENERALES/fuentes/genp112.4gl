                                                                                
-------------------------------------------------------------------------------
-- Titulo               : Genp112.4gl -- Mantenimiento de factores
--					 de conversion entre moneda
-- Elaboración          : 20-ago-2001
-- Autor                : GVA
-- Formato de Ejecución : fglrun -o Genp112.42r Genp112.4gl base GE 
-- Ultima Correción     : 23-ago-2001
-- Motivo Corrección    : standares
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_mon  RECORD LIKE gent013.*
DEFINE rm_cmon  RECORD LIKE gent014.*
DEFINE vm_r_rows ARRAY[1000] OF INTEGER -- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_demonios      VARCHAR(12)
                                                                                
MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 2 THEN
     CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto','stop')
     EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_proceso = 'genp112'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPEN WINDOW w_cmon AT 3,2 WITH 15 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_cmon FROM "../forms/genf112_1"
DISPLAY FORM f_cmon
INITIALIZE rm_cmon.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores()
MENU "OPCIONES"
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
	COMMAND KEY("I") "Ingresar" "Ingresar nuevos registros. "
		CALL control_ingreso()
		IF vm_row_current > 1 THEN
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
		END IF
        COMMAND KEY('C') 'Consultar' 'Consultar un registro. '
                CALL control_consulta()
		IF vm_num_rows <= 1 THEN
			HIDE OPTION 'Avanzar'
			HIDE OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
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
        COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)
DEFINE codigo		LIKE gent013.g13_moneda
DEFINE nombre		LIKE gent013.g13_nombre
DEFINE estado 		LIKE gent013.g13_estado
DEFINE decimales	LIKE gent013.g13_decimales

CLEAR FORM
LET int_flag = 0
INITIALIZE codigo TO NULL
CONSTRUCT BY NAME expr_sql ON g14_moneda_ori, g14_moneda_des,g14_tasa,
				 g14_usuario, g14_fecing
	ON KEY(F2)
		IF INFIELD(g14_moneda_ori) THEN
		     CALL fl_ayuda_monedas()RETURNING codigo, nombre, decimales
		     IF codigo IS NOT NULL THEN
			    LET rm_cmon.g14_moneda_ori = codigo
			    DISPLAY BY NAME rm_cmon.g14_moneda_ori
			    DISPLAY nombre TO mon_ori
		     END IF
		END IF
		IF INFIELD(g14_moneda_des) THEN
		     CALL fl_ayuda_monedas()RETURNING codigo, nombre, decimales
                     IF codigo IS NOT NULL THEN
                            LET rm_cmon.g14_moneda_des = codigo
			    DISPLAY BY NAME rm_cmon.g14_moneda_des
			    DISPLAY nombre TO mon_des
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
LET query = 'SELECT *, ROWID FROM gent014 WHERE ', expr_sql CLIPPED, 
		' ORDER BY 2, 3, 6 DESC'
PREPARE cons FROM query
DECLARE q_cmon CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cmon INTO rm_cmon.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows +  1
	IF vm_num_rows > 1000 THEN 
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
INITIALIZE rm_cmon.* TO NULL
LET rm_cmon.g14_fecing = CURRENT
LET rm_cmon.g14_usuario = vg_usuario
LET rm_cmon.g14_serial = 0
DISPLAY BY NAME rm_cmon.g14_fecing, rm_cmon.g14_usuario
CALL lee_datos('I')
IF NOT int_flag THEN
	INSERT INTO gent014 VALUES (rm_cmon.*)
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
	IF vm_num_rows > 0 THEN
		CALL lee_muestra_registro(vm_r_rows[vm_row_current])
	END IF
END IF

END FUNCTION



FUNCTION lee_datos(flag)
DEFINE  resp    	CHAR(6)
DEFINE 	flag 	 	CHAR(1)
DEFINE 	codigo	 	LIKE gent013.g13_moneda
DEFINE 	serial	 	LIKE gent014.g14_serial
DEFINE 	estado	 	LIKE gent013.g13_estado
DEFINE 	nombre		LIKE gent013.g13_nombre
DEFINE 	decimales	LIKE gent013.g13_decimales

OPTIONS INPUT WRAP
LET int_flag = 0
INPUT BY NAME rm_cmon.g14_moneda_ori, rm_cmon.g14_moneda_des, rm_cmon.g14_tasa
	      WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(g14_moneda_ori, g14_moneda_des, g14_tasa)
                 THEN
                        LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
                        	RETURNING resp
                        IF resp = 'Yes' THEN
                                LET int_flag = 1
                               IF flag = 'I' THEN
                                   CLEAR FORM
                               END IF
                               RETURN
                        END IF
                ELSE
                       IF flag = 'I' THEN
                                CLEAR FORM
                       END IF
		       RETURN
                END IF
        ON KEY(F2)
                IF INFIELD(g14_moneda_ori) THEN
                     CALL fl_ayuda_monedas()RETURNING codigo, nombre, decimales
                     IF codigo IS NOT NULL THEN
                            LET rm_cmon.g14_moneda_ori = codigo
                            DISPLAY BY NAME rm_cmon.g14_moneda_ori
			    DISPLAY nombre TO mon_ori
                     END IF
                END IF
                IF INFIELD(g14_moneda_des) THEN
                     CALL fl_ayuda_monedas()RETURNING codigo, nombre, decimales
                     IF codigo IS NOT NULL THEN
                            LET rm_cmon.g14_moneda_des = codigo
                            DISPLAY BY NAME rm_cmon.g14_moneda_des
			    DISPLAY nombre TO mon_des
                     END IF
                END IF
		LET int_flag = 0
	AFTER FIELD g14_moneda_ori
         	IF rm_cmon.g14_moneda_ori IS NOT NULL THEN
		   CALL fl_lee_moneda(rm_cmon.g14_moneda_ori) RETURNING rm_mon.*
		   DISPLAY rm_mon.g13_nombre TO mon_ori
                   IF rm_mon.g13_moneda IS NULL THEN
                             CALL fgl_winmessage(vg_producto,'Moneda no existe',						 'exclamation')
                    	     NEXT FIELD g14_moneda_ori
                   END IF
		   IF rm_mon.g13_estado = 'B' THEN
 		        CALL fgl_winmessage(vg_producto,'Moneda está bloqueada',					    'exclamation')
                        NEXT FIELD g14_moneda_ori			
	           END IF
		ELSE
		   CLEAR mon_ori
	  	END IF
		IF rm_cmon.g14_moneda_ori = rm_cmon.g14_moneda_des THEN
                    CALL fgl_winmessage(vg_producto,'La moneda origen no puede ser la misma de la moneda destino','exclamation')
                    NEXT FIELD g14_moneda_ori
            	END IF
	AFTER FIELD rm_cmon.g14_moneda_des
             IF rm_cmon.g14_moneda_des IS NOT NULL THEN
                   CALL fl_lee_moneda(rm_cmon.g14_moneda_des) RETURNING rm_mon.*
                   DISPLAY rm_mon.g13_nombre TO mon_des
                   IF rm_mon.g13_moneda IS NULL THEN
                             CALL fgl_winmessage(vg_producto,'Moneda no existe',
                                                 'exclamation')
                             NEXT FIELD g14_moneda_des
                   END IF
                   IF rm_mon.g13_estado = 'B' THEN
                        CALL fgl_winmessage(vg_producto,'Moneda está bloqueada',					    'exclamation')
                        NEXT FIELD g14_moneda_des
                   END IF
               ELSE
                   CLEAR mon_des
             END IF
             IF rm_cmon.g14_moneda_des = rm_cmon.g14_moneda_ori THEN
                CALL fgl_winmessage(vg_producto,'La moneda origen no puede ser la misma de la moneda destino','exclamation')
                     NEXT FIELD g14_moneda_des
             END IF
END INPUT

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER
DEFINE nombre	LIKE gent013.g13_nombre
DEFINE 	estado	 	LIKE gent013.g13_estado

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_cmon.* FROM gent014 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_cmon.*
CALL fl_lee_moneda(rm_cmon.g14_moneda_ori) RETURNING  rm_mon.*
DISPLAY rm_mon.g13_nombre TO mon_ori
CALL fl_lee_moneda(rm_cmon.g14_moneda_des) RETURNING  rm_mon.*
DISPLAY rm_mon.g13_nombre TO mon_des

CALL muestra_contadores()

END FUNCTION



FUNCTION muestra_contadores()
                                                                                
DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 69
                                                                                
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

