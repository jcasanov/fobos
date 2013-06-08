-------------------------------------------------------------------------------
-- Titulo               : talp103.4gl -- Mantenimiento de Tecnicos
-- Elaboraci�n          : 7-sep-2001
-- Autor                : GVA
-- Formato de Ejecuci�n : fglrun talp103.4gl base TA 1
-- Ultima Correci�n     : 7-sep-2001
-- Motivo Correcci�n    : 1
--------------------------------------------------------------------------------
                                                                                
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_mec 	RECORD LIKE talt003.*
DEFINE rm_rol 	RECORD LIKE rolt030.*
DEFINE rm_sec 	RECORD LIKE talt002.*
DEFINE rm_mar 	RECORD LIKE talt001.*
DEFINE vm_r_rows ARRAY[1000] OF INTEGER -- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows      SMALLINT        -- MAXIMO DE FILAS LEIDAS
DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_flag_mant     CHAR(1)

MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
     	--CALL fgl_winmessage(vg_producto,'N�mero de par�metros incorrecto','stop')
	CALL fl_mostrar_mensaje('N�mero de par�metros incorrecto.','stop')
     	EXIT PROGRAM
END IF
LET vg_base	= arg_val(1)
LET vg_modulo	= arg_val(2)
LET vg_codcia	= arg_val(3)
LET vg_proceso	= 'talp103'
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
LET num_rows = 22
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_mec AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
	OPEN FORM f_mec FROM '../forms/talf103_1'
ELSE
	OPEN FORM f_mec FROM '../forms/talf103_1c'
END IF
DISPLAY FORM f_mec
INITIALIZE rm_mec.* TO NULL
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
	COMMAND KEY('M') 'Modificar' 'Modificar registro corriente'
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
        COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro. '
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
DEFINE codrol		LIKE talt003.t03_codrol
DEFINE tecnico		LIKE talt003.t03_mecanico
DEFINE nombre		LIKE talt003.t03_nombres
DEFINE nomrol		LIKE rolt030.n30_nombres
DEFINE expr_sql		CHAR(500)
DEFINE query		CHAR(600)
DEFINE tipo		LIKE talt003.t03_tipo

CLEAR FORM
LET int_flag = 0
INITIALIZE tecnico TO NULL
CONSTRUCT BY NAME expr_sql ON t03_mecanico,t03_nombres,t03_iniciales,t03_codrol,  			      t03_tipo, t03_seccion ,t03_linea, 
			      t03_usuario, t03_fecing
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(t03_mecanico) THEN
			LET tipo = 'T'
			CALL fl_ayuda_mecanicos(vg_codcia, tipo)
				RETURNING tecnico, nombre
			IF tecnico IS NOT NULL THEN
			    LET rm_mec.t03_mecanico = tecnico
			    LET rm_mec.t03_nombres  = nombre
			    DISPLAY BY NAME rm_mec.t03_mecanico,
			                    rm_mec.t03_nombres
			END IF
		END IF
		IF INFIELD(t03_codrol) THEN
			CALL fl_ayuda_codigo_empleado(vg_codcia)
			 RETURNING rm_rol.n30_cod_trab, rm_rol.n30_nombres
			IF rm_rol.n30_cod_trab IS NOT NULL THEN
			    LET rm_mec.t03_codrol = rm_rol.n30_cod_trab
			    DISPLAY BY NAME rm_mec.t03_codrol
			    DISPLAY rm_rol.n30_nombres TO nom_rol
			END IF
		END IF
		IF INFIELD(t03_seccion) THEN
		   	CALL fl_ayuda_secciones_taller(vg_codcia)
				RETURNING rm_sec.t02_seccion, rm_sec.t02_nombre
			IF rm_sec.t02_seccion IS NOT NULL THEN
			    LET rm_mec.t03_seccion = rm_sec.t02_seccion
			    DISPLAY BY NAME rm_mec.t03_seccion
			    DISPLAY rm_sec.t02_nombre TO nom_sec
			END IF
		END IF
		IF INFIELD(t03_linea) THEN
			CALL fl_ayuda_marcas_taller(vg_codcia)
				RETURNING rm_mar.t01_linea, rm_mar.t01_nombre
			IF rm_mar.t01_linea IS NOT NULL THEN
			    LET rm_mec.t03_linea = rm_mar.t01_linea
			    DISPLAY BY NAME rm_mec.t03_linea
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
LET query = 'SELECT *, ROWID FROM talt003 WHERE t03_compania = ',
	     vg_codcia, ' AND ', expr_sql CLIPPED, ' ORDER BY 3'
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_mec.*, vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
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

LET vm_flag_mant = 'I'
CLEAR FORM
INITIALIZE rm_mec.* TO NULL
LET rm_mec.t03_fecing   = CURRENT
LET rm_mec.t03_usuario  = vg_usuario
LET rm_mec.t03_compania = vg_codcia
LET rm_mec.t03_tipo     = 'M'

-- Los nuevo campos que se ingresaron en la tabla de t�cnicos

LET rm_mec.t03_hora_ini = '00:00'
LET rm_mec.t03_hora_fin = '00:00'

LET rm_mec.t03_cost_hvn = 0
LET rm_mec.t03_cost_hve = 0
LET rm_mec.t03_cost_htn = 0
LET rm_mec.t03_cost_hte = 0

LET rm_mec.t03_fact_hvn = 0
LET rm_mec.t03_fact_hve = 0
LET rm_mec.t03_fact_htn = 0
LET rm_mec.t03_fact_hte = 0

DISPLAY BY NAME rm_mec.t03_fecing, rm_mec.t03_usuario
SELECT MAX(t03_mecanico) + 1 INTO rm_mec.t03_mecanico FROM talt003
        WHERE t03_compania = vg_codcia
        IF rm_mec.t03_mecanico IS NULL THEN
        	LET rm_mec.t03_mecanico = 1
        END IF
CALL lee_datos()
IF NOT int_flag THEN
	BEGIN WORK
	WHENEVER ERROR CONTINUE
	INSERT INTO talt003 VALUES (rm_mec.*)
	WHENEVER ERROR STOP
	IF status < 0 THEN
	    SELECT MAX(t03_mecanico) + 1 INTO rm_mec.t03_mecanico FROM talt003
                   WHERE t03_compania = vg_codcia
            IF rm_mec.t03_mecanico IS NULL THEN
                 LET rm_mec.t03_mecanico = 1
            END IF
	    INSERT INTO talt003 VALUES (rm_mec.*)
	END IF 
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

LET vm_flag_mant = 'M'
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR SELECT * FROM talt003 WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_mec.*
IF status < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL lee_datos()
IF NOT int_flag THEN
   	UPDATE talt003	
	SET t03_nombres = rm_mec.t03_nombres,
	    t03_iniciales = rm_mec.t03_iniciales, t03_tipo = rm_mec.t03_tipo,
	    t03_codrol = rm_mec.t03_codrol, t03_seccion = rm_mec.t03_seccion,
	    t03_linea = rm_mec.t03_linea, 
	    t03_hora_ini = rm_mec.t03_hora_ini,
	    t03_hora_fin = rm_mec.t03_hora_fin,
	    t03_cost_hvn = rm_mec.t03_cost_hvn,
	    t03_cost_hve = rm_mec.t03_cost_hve,
	    t03_cost_htn = rm_mec.t03_cost_htn,
	    t03_cost_hte = rm_mec.t03_cost_hte,
	    t03_fact_hvn = rm_mec.t03_fact_hvn,
	    t03_fact_hve = rm_mec.t03_fact_hve,
	    t03_fact_htn = rm_mec.t03_fact_htn,
	    t03_fact_hte = rm_mec.t03_fact_hte 
		WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	COMMIT WORK
	CALL lee_muestra_registro(vm_r_rows[vm_row_current])
END IF
CLOSE q_up

END FUNCTION



FUNCTION lee_datos()
DEFINE  resp    	CHAR(6)
DEFINE 	serial 	 	LIKE talt003.t03_mecanico
DEFINE nomrol		LIKE rolt030.n30_nombres
DEFINE 	iniciales	LIKE talt003.t03_iniciales
DEFINE 	codrol    	LIKE talt003.t03_codrol

OPTIONS INPUT WRAP
LET int_flag = 0
INPUT BY NAME rm_mec.t03_nombres, rm_mec.t03_iniciales, rm_mec.t03_codrol,  		      rm_mec.t03_seccion ,rm_mec.t03_linea, rm_mec.t03_tipo,
	      rm_mec.t03_hora_ini, rm_mec.t03_hora_fin,
	      rm_mec.t03_cost_hvn, rm_mec.t03_cost_hve,
	      rm_mec.t03_cost_htn, rm_mec.t03_cost_hte,
	      rm_mec.t03_fact_hvn, rm_mec.t03_fact_hve,
	      rm_mec.t03_fact_htn, rm_mec.t03_fact_hte 
	      WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	 IF field_touched( rm_mec.t03_nombres, rm_mec.t03_iniciales,
				   rm_mec.t03_codrol, rm_mec.t03_seccion, 
				   rm_mec.t03_linea, rm_mec.t03_hora_ini, 
				   rm_mec.t03_hora_fin,
	      			   rm_mec.t03_cost_hvn, rm_mec.t03_cost_hve,
	  			   rm_mec.t03_cost_htn, rm_mec.t03_cost_hte,
	      			   rm_mec.t03_fact_hvn, rm_mec.t03_fact_hve,
	      			   rm_mec.t03_fact_htn, rm_mec.t03_fact_hte)
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
		IF INFIELD(t03_codrol) THEN
			CALL fl_ayuda_codigo_empleado(vg_codcia)
			 RETURNING rm_rol.n30_cod_trab, rm_rol.n30_nombres
			IF rm_rol.n30_cod_trab IS NOT NULL THEN
			    LET rm_mec.t03_codrol = rm_rol.n30_cod_trab
			    DISPLAY BY NAME rm_mec.t03_codrol
			    DISPLAY rm_rol.n30_nombres TO nom_rol
			END IF
		END IF
		IF INFIELD(t03_seccion) THEN
		   	CALL fl_ayuda_secciones_taller(vg_codcia)
				RETURNING rm_sec.t02_seccion, rm_sec.t02_nombre
			IF rm_sec.t02_seccion IS NOT NULL THEN
			    LET rm_mec.t03_seccion = rm_sec.t02_seccion
			    DISPLAY BY NAME rm_mec.t03_seccion
			    DISPLAY rm_sec.t02_nombre TO nom_sec
			END IF
		END IF
		IF INFIELD(t03_linea) THEN
			CALL fl_ayuda_marcas_taller(vg_codcia)
				RETURNING rm_mar.t01_linea, rm_mar.t01_nombre
			IF rm_mar.t01_linea IS NOT NULL THEN
			    LET rm_mec.t03_linea = rm_mar.t01_linea
			    DISPLAY BY NAME rm_mec.t03_linea
			    DISPLAY rm_mar.t01_nombre TO nom_linea
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD t03_codrol
	    IF rm_mec.t03_codrol IS NOT NULL THEN
		CALL fl_lee_trabajador_roles(vg_codcia, rm_mec.t03_codrol)
			RETURNING rm_rol.*
		IF rm_rol.n30_nombres IS NULL THEN
	        	--CALL fgl_winmessage(vg_producto,'No existe c�digo de rol','exclamation')
			CALL fl_mostrar_mensaje('No existe c�digo de rol.','exclamation')
		     	CLEAR nom_rol
		     	NEXT FIELD t03_codrol
		END IF
		LET rm_mec.t03_codrol = rm_rol.n30_cod_trab
		DISPLAY BY NAME rm_mec.t03_codrol
		DISPLAY rm_rol.n30_nombres TO nom_rol
	    ELSE
		CLEAR nom_rol
	    END IF 
	AFTER FIELD t03_seccion
	    IF rm_mec.t03_seccion IS NOT NULL THEN
		CALL fl_lee_cod_seccion(vg_codcia, rm_mec.t03_seccion)
			RETURNING rm_sec.*
		IF rm_sec.t02_seccion IS NULL THEN
	             	--CALL fgl_winmessage(vg_producto,'No existe la seccion','exclamation')
			CALL fl_mostrar_mensaje('No existe la secci�n.','exclamation')
		     	CLEAR nom_sec
		     	NEXT FIELD t03_seccion
		END IF
		LET rm_mec.t03_seccion = rm_sec.t02_seccion
		DISPLAY BY NAME rm_mec.t03_seccion
		DISPLAY rm_sec.t02_nombre TO nom_sec
	    ELSE 
		CLEAR nom_sec
	    END IF 
	AFTER FIELD t03_linea
	    IF rm_mec.t03_linea IS NOT NULL THEN
		CALL fl_lee_linea_taller(vg_codcia, rm_mec.t03_linea)
			RETURNING rm_mar.*
		IF rm_mar.t01_linea IS NULL THEN
	             	--CALL fgl_winmessage(vg_producto,'No existe la linea de taller', 'exclamation')
			CALL fl_mostrar_mensaje('No existe la l�nea de taller.', 'exclamation')
		     	CLEAR nom_linea
		     	NEXT FIELD t03_linea
		END IF
		LET rm_mec.t03_linea = rm_mar.t01_linea
		DISPLAY BY NAME rm_mec.t03_linea
		DISPLAY rm_mar.t01_nombre TO nom_linea
	    ELSE
		CLEAR nom_linea
	    END IF 
	AFTER INPUT
		IF rm_mec.t03_hora_ini IS NULL THEN
			NEXT FIELD t03_hora_ini
		END IF
		IF rm_mec.t03_hora_fin IS NULL THEN
			NEXT FIELD t03_hora_fin
		END IF
		IF rm_mec.t03_cost_hvn IS NULL THEN
			NEXT FIELD t03_cost_hvn
		END IF
		IF rm_mec.t03_cost_hve IS NULL THEN
			NEXT FIELD t03_cost_hve
		END IF
		IF rm_mec.t03_cost_htn IS NULL THEN
			NEXT FIELD t03_cost_htn
		END IF
		IF rm_mec.t03_cost_hte IS NULL THEN
			NEXT FIELD t03_cost_hte
		END IF
		IF rm_mec.t03_fact_hvn IS NULL THEN
			NEXT FIELD t03_fact_hvn
		END IF
		IF rm_mec.t03_fact_hve IS NULL THEN
			NEXT FIELD t03_fact_hve
		END IF
		IF rm_mec.t03_fact_htn IS NULL THEN
			NEXT FIELD t03_fact_htn
		END IF
		IF rm_mec.t03_fact_hte IS NULL THEN
			NEXT FIELD t03_fact_hte
		END IF
		IF rm_mec.t03_hora_fin < rm_mec.t03_hora_ini THEN
			--CALL fgl_winmessage(vg_producto,'La Hora de salida del t�cnico debe ser mayor a la hora de ingreso.','exclamation')
			CALL fl_mostrar_mensaje('La Hora de salida del t�cnico debe ser mayor a la hora de ingreso.','exclamation')
			NEXT FIELD t03_hora_fin
		END IF

		INITIALIZE serial TO NULL
		SELECT t03_mecanico INTO serial		 FROM talt003
      		 WHERE t03_compania  = vg_codcia 
		 AND   t03_iniciales = rm_mec.t03_iniciales	
		IF status <> NOTFOUND THEN
		   IF vm_flag_mant = 'I' OR
		      (vm_flag_mant = 'M' AND rm_mec.t03_mecanico <> serial)
		   THEN
		   	--CALL fgl_winmessage(vg_producto,'Las iniciales ya fueron asignadas al t�cnico de c�digo  '|| serial,'exclamation')
			CALL fl_mostrar_mensaje('Las iniciales ya fueron asignadas al t�cnico de c�digo '|| serial,'exclamation')
		      	NEXT FIELD t03_iniciales
		   END IF
		END IF
END INPUT

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_mec.* FROM talt003 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_mec.t03_mecanico, rm_mec.t03_nombres, rm_mec.t03_iniciales, 
		rm_mec.t03_seccion, rm_mec.t03_linea, rm_mec.t03_tipo,
		rm_mec.t03_codrol, 
		rm_mec.t03_hora_ini, rm_mec.t03_hora_fin,
		rm_mec.t03_cost_hvn, rm_mec.t03_cost_hve,
		rm_mec.t03_cost_htn, rm_mec.t03_cost_hte,
		rm_mec.t03_fact_hvn, rm_mec.t03_fact_hve,
		rm_mec.t03_fact_htn, rm_mec.t03_fact_hte,
		rm_mec.t03_usuario, rm_mec.t03_fecing 
CALL fl_lee_linea_taller(vg_codcia, rm_mec.t03_linea)
	RETURNING rm_mar.*
CALL fl_lee_trabajador_roles(vg_codcia, rm_mec.t03_codrol)
	RETURNING rm_rol.*
CALL fl_lee_cod_seccion(vg_codcia, rm_mec.t03_seccion)
	RETURNING rm_sec.*
DISPLAY rm_rol.n30_nombres TO nom_rol
DISPLAY rm_sec.t02_nombre  TO nom_sec
DISPLAY rm_mar.t01_nombre  TO nom_linea

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current              SMALLINT
DEFINE num_rows                 SMALLINT
                                                                                
IF vg_gui = 1 THEN
	DISPLAY "" AT 1,1
	DISPLAY row_current, " de ", num_rows AT 1, 67
END IF
                                                                                
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
