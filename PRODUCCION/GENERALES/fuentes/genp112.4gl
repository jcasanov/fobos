-------------------------------------------------------------------------------
-- Titulo               : Genp112.4gl -- Mantenimiento de factores
--					 de conversion entre moneda
-- Elaboraci�n          : 20-ago-2001
-- Autor                : GVA
-- Formato de Ejecuci�n : fglrun -o Genp112.42r Genp112.4gl base GE 
-- Ultima Correci�n     : 23-ago-2001
-- Motivo Correcci�n    : standares
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'
                                                                                
DEFINE rm_g13		RECORD LIKE gent013.*
DEFINE rm_g14		RECORD LIKE gent014.*
DEFINE vm_r_rows	ARRAY[1000] OF INTEGER -- ARREGLO DE ROWID DE FILAS
DEFINE vm_row_current   SMALLINT        -- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows      SMALLINT        -- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS



MAIN
                                                                                
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 2 THEN
     CALL fgl_winmessage(vg_producto,'N�mero de par�metros incorrecto','stop')
     EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_proceso = 'genp112'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()
                                                                                
END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 1000
OPEN WINDOW w_cmon AT 3, 2 WITH 17 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_cmon FROM "../forms/genf112_1"
DISPLAY FORM f_cmon
INITIALIZE rm_g14.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores()
MENU "OPCIONES"
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
		CALL control_modificacion()
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
CONSTRUCT BY NAME expr_sql ON g14_moneda_ori, g14_moneda_des, g14_tasa,
				 g14_usuario
	ON KEY(F2)
		IF INFIELD(g14_moneda_ori) THEN
		     CALL fl_ayuda_monedas()RETURNING codigo, nombre, decimales
		     IF codigo IS NOT NULL THEN
			    LET rm_g14.g14_moneda_ori = codigo
			    DISPLAY BY NAME rm_g14.g14_moneda_ori
			    DISPLAY nombre TO mon_ori
		     END IF
		END IF
		IF INFIELD(g14_moneda_des) THEN
		     CALL fl_ayuda_monedas()RETURNING codigo, nombre, decimales
                     IF codigo IS NOT NULL THEN
                            LET rm_g14.g14_moneda_des = codigo
			    DISPLAY BY NAME rm_g14.g14_moneda_des
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
FOREACH q_cmon INTO rm_g14.*, vm_r_rows[vm_num_rows]
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
DEFINE num_aux		INTEGER
DEFINE paridad		LIKE gent014.g14_tasa

OPTIONS INPUT WRAP
CLEAR FORM
INITIALIZE rm_g14.* TO NULL
LET rm_g14.g14_fecing = CURRENT
LET rm_g14.g14_usuario = vg_usuario
LET rm_g14.g14_serial = 0
DISPLAY BY NAME rm_g14.g14_fecing, rm_g14.g14_usuario
CALL lee_datos('I')
IF NOT int_flag THEN
	BEGIN WORK
	LET paridad = 1 / rm_g14.g14_tasa
	LET rm_g14.g14_fecing = CURRENT
	INSERT INTO gent014 VALUES (rm_g14.*)
	LET num_aux = SQLCA.SQLERRD[6] 
	INSERT INTO gent014
		VALUES (0, rm_g14.g14_moneda_des, rm_g14.g14_moneda_ori,
			paridad, rm_g14.g14_usuario, rm_g14.g14_fecing)
	COMMIT WORK
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	LET vm_r_rows[vm_num_rows] = num_aux
	LET vm_row_current = vm_num_rows
	CALL muestra_contadores()
	CALL fl_mensaje_registro_ingresado()
END IF
IF vm_num_rows > 0 THEN
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF

END FUNCTION



FUNCTION control_modificacion()
DEFINE r_g14		RECORD LIKE gent014.*
DEFINE fecing		LIKE gent014.g14_fecing
DEFINE paridad		LIKE gent014.g14_tasa

CALL lee_muestra_registro(vm_r_rows[vm_row_current])
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM gent014
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_g14.*
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Este registro no existe. Ha ocurrido un error interno de la base de datos.', 'exclamation')
	WHENEVER ERROR STOP
	RETURN
END IF
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
DECLARE q_up2 CURSOR FOR
	SELECT * FROM gent014
		WHERE g14_moneda_ori = rm_g14.g14_moneda_des
		  AND g14_moneda_des = rm_g14.g14_moneda_ori
	FOR UPDATE
OPEN q_up2
FETCH q_up2 INTO r_g14.*
IF STATUS = NOTFOUND THEN
	{--
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Este registro no existe. Ha ocurrido un error interno de la base de datos.', 'exclamation')
	WHENEVER ERROR STOP
	RETURN
	--}
	LET paridad = 1 / rm_g14.g14_tasa
	LET fecing  = CURRENT
	INSERT INTO gent014
		VALUES (0, rm_g14.g14_moneda_des, rm_g14.g14_moneda_ori,
			paridad, rm_g14.g14_usuario, fecing)
	CLOSE q_up2
	OPEN q_up2
	FETCH q_up2 INTO r_g14.*
END IF
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL lee_datos('M')
IF int_flag THEN
	ROLLBACK WORK
	RETURN
END IF
UPDATE gent014 SET * = rm_g14.* WHERE CURRENT OF q_up
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Ha ocurrido un error interno de la base de datos al intentar actualizar el registro. Consulte con el Administrador.', 'exclamation')
	RETURN
END IF
LET paridad = 1 / rm_g14.g14_tasa
UPDATE gent014 SET g14_tasa = paridad WHERE CURRENT OF q_up2
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Ha ocurrido un error interno de la base de datos al intentar actualizar el registro. Consulte con el Administrador.', 'exclamation')
	RETURN
END IF
COMMIT WORK
CALL fl_mensaje_registro_modificado()
CALL lee_muestra_registro(vm_r_rows[vm_row_current])

END FUNCTION



FUNCTION lee_datos(flag)
DEFINE  resp    	CHAR(6)
DEFINE 	flag 	 	CHAR(1)
DEFINE  cont		SMALLINT
DEFINE 	codigo	 	LIKE gent013.g13_moneda
DEFINE 	serial	 	LIKE gent014.g14_serial
DEFINE 	estado	 	LIKE gent013.g13_estado
DEFINE 	nombre		LIKE gent013.g13_nombre
DEFINE 	decimales	LIKE gent013.g13_decimales
DEFINE 	mon_ori	 	LIKE gent014.g14_moneda_ori
DEFINE 	mon_des	 	LIKE gent014.g14_moneda_des

OPTIONS INPUT WRAP
LET int_flag = 0
INPUT BY NAME rm_g14.g14_moneda_ori, rm_g14.g14_moneda_des, rm_g14.g14_tasa
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
			IF flag = 'M' THEN
				CONTINUE INPUT
			END IF
                     CALL fl_ayuda_monedas()RETURNING codigo, nombre, decimales
                     IF codigo IS NOT NULL THEN
                            LET rm_g14.g14_moneda_ori = codigo
                            DISPLAY BY NAME rm_g14.g14_moneda_ori
			    DISPLAY nombre TO mon_ori
                     END IF
                END IF
                IF INFIELD(g14_moneda_des) THEN
			IF flag = 'M' THEN
				CONTINUE INPUT
			END IF
                     CALL fl_ayuda_monedas()RETURNING codigo, nombre, decimales
                     IF codigo IS NOT NULL THEN
                            LET rm_g14.g14_moneda_des = codigo
                            DISPLAY BY NAME rm_g14.g14_moneda_des
			    DISPLAY nombre TO mon_des
                     END IF
                END IF
		LET int_flag = 0
	BEFORE FIELD g14_moneda_ori, g14_moneda_des
		IF flag = 'M' THEN
			LET mon_ori = rm_g14.g14_moneda_ori
			LET mon_des = rm_g14.g14_moneda_des
		END IF
	AFTER FIELD g14_moneda_ori
		IF flag = 'M' THEN
			LET rm_g14.g14_moneda_ori = mon_ori
			DISPLAY BY NAME rm_g14.g14_moneda_ori
			CONTINUE INPUT
		END IF
         	IF rm_g14.g14_moneda_ori IS NOT NULL THEN
		   CALL fl_lee_moneda(rm_g14.g14_moneda_ori) RETURNING rm_g13.*
		   DISPLAY rm_g13.g13_nombre TO mon_ori
                   IF rm_g13.g13_moneda IS NULL THEN
                             CALL fgl_winmessage(vg_producto,'Moneda no existe',						 'exclamation')
                    	     NEXT FIELD g14_moneda_ori
                   END IF
		   IF rm_g13.g13_estado = 'B' THEN
 		        CALL fgl_winmessage(vg_producto,'Moneda est� bloqueada',					    'exclamation')
                        NEXT FIELD g14_moneda_ori			
	           END IF
		ELSE
		   CLEAR mon_ori
	  	END IF
		IF rm_g14.g14_moneda_ori = rm_g14.g14_moneda_des THEN
                    CALL fgl_winmessage(vg_producto,'La moneda origen no puede ser la misma de la moneda destino','exclamation')
                    NEXT FIELD g14_moneda_ori
            	END IF
		DISPLAY rm_g14.g14_moneda_ori TO tit_mon_ori
	AFTER FIELD g14_moneda_des
		IF flag = 'M' THEN
			LET rm_g14.g14_moneda_des = mon_des
			DISPLAY BY NAME rm_g14.g14_moneda_des
			CONTINUE INPUT
		END IF
             IF rm_g14.g14_moneda_des IS NOT NULL THEN
                   CALL fl_lee_moneda(rm_g14.g14_moneda_des) RETURNING rm_g13.*
                   DISPLAY rm_g13.g13_nombre TO mon_des
                   IF rm_g13.g13_moneda IS NULL THEN
                             CALL fgl_winmessage(vg_producto,'Moneda no existe',
                                                 'exclamation')
                             NEXT FIELD g14_moneda_des
                   END IF
                   IF rm_g13.g13_estado = 'B' THEN
                        CALL fgl_winmessage(vg_producto,'Moneda est� bloqueada',					    'exclamation')
                        NEXT FIELD g14_moneda_des
                   END IF
               ELSE
                   CLEAR mon_des
             END IF
             IF rm_g14.g14_moneda_des = rm_g14.g14_moneda_ori THEN
                CALL fgl_winmessage(vg_producto,'La moneda origen no puede ser la misma de la moneda destino','exclamation')
                     NEXT FIELD g14_moneda_des
             END IF
		DISPLAY rm_g14.g14_moneda_des TO tit_mon_des
	AFTER FIELD g14_tasa
		IF rm_g14.g14_tasa IS NOT NULL THEN
			DISPLAY (1 / rm_g14.g14_tasa) TO tit_paridad
		ELSE
			CLEAR tit_paridad
		END IF
	AFTER INPUT
		IF flag = 'I' THEN
			SELECT COUNT(*) INTO cont FROM gent014
				WHERE g14_moneda_ori = rm_g14.g14_moneda_ori
				  AND g14_moneda_des = rm_g14.g14_moneda_des
			IF cont > 0 THEN
				CALL fl_mostrar_mensaje('Este factor de conversi�n entre estas monedas ya existe. Modifique la paridad cambiaria si desea.', 'exclamation')
				CONTINUE INPUT
			END IF
		END IF
		IF rm_g14.g14_tasa = 0 THEN
			CALL fl_mostrar_mensaje('No puede grabar paridad cambiaria con valor 0.', 'exclamation')
			NEXT FIELD g14_tasa
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
SELECT * INTO rm_g14.* FROM gent014 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_g14.*
CALL fl_lee_moneda(rm_g14.g14_moneda_ori) RETURNING  rm_g13.*
DISPLAY rm_g13.g13_nombre TO mon_ori
CALL fl_lee_moneda(rm_g14.g14_moneda_des) RETURNING  rm_g13.*
DISPLAY rm_g13.g13_nombre TO mon_des
DISPLAY rm_g14.g14_moneda_ori TO tit_mon_ori
DISPLAY rm_g14.g14_moneda_des TO tit_mon_des
DISPLAY (1 / rm_g14.g14_tasa) TO tit_paridad
CALL muestra_contadores()

END FUNCTION



FUNCTION muestra_contadores()
                                                                                
DISPLAY "" AT 1,1
DISPLAY vm_row_current, " de ", vm_num_rows AT 1, 69
                                                                                
END FUNCTION
