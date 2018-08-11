--------------------------------------------------------------------------------
-- Titulo           : rolp102.4gl - Configuración Impuesto a la Renta
-- Elaboracion      : 29-sep-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp102 base módulo compañía
-- Ultima Correccion: 11-jun-2003
-- Motivo Correccion: (RCA) Revisión y corrección Aceros
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_rol		RECORD LIKE rolt015.*
DEFINE vm_num_rows	INTEGER
DEFINE vm_row_current	INTEGER
DEFINE vm_max_rows	INTEGER
DEFINE vm_max_elm       INTEGER
DEFINE vm_num_elm       INTEGER
DEFINE vm_r_rows	ARRAY [1000] OF LIKE rolt015.n15_ano 
DEFINE rm_impren	ARRAY [1000] OF RECORD
				n15_secuencia	 LIKE rolt015.n15_secuencia,
				n15_base_imp_ini LIKE rolt015.n15_base_imp_ini,
				n15_base_imp_fin LIKE rolt015.n15_base_imp_fin,
				n15_fracc_base	 LIKE rolt015.n15_fracc_base,
				n15_porc_ir	 LIKE rolt015.n15_porc_ir
			END RECORD

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp102.err')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso  = 'rolp102'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
LET vm_max_rows	= 1000
LET vm_max_elm  = 1000
OPEN WINDOW wf AT 03, 02 WITH 20 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0,
		  BORDER, MESSAGE LINE LAST) 
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rol FROM "../forms/rolf102_1"
DISPLAY FORM f_rol
CALL mostrar_botones_detalle()
INITIALIZE rm_rol.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Detalle'
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
		IF vm_num_elm > fgl_scr_size('rm_impren') THEN
                        SHOW OPTION 'Detalle'
                ELSE
                        HIDE OPTION 'Detalle'
                END IF
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro. '
		CALL muestra_siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_num_elm > fgl_scr_size('rm_impren') THEN
                        SHOW OPTION 'Detalle'
                ELSE
                        HIDE OPTION 'Detalle'
                END IF
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro. '
		CALL muestra_anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_num_elm > fgl_scr_size('rm_impren') THEN
                        SHOW OPTION 'Detalle'
                ELSE
                        HIDE OPTION 'Detalle'
                END IF
	COMMAND KEY('D') 'Detalle' 'Muestra siguiente detalles del registro. '
                CALL muestra_detalle_arr()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()
DEFINE num_elm          SMALLINT
DEFINE indice           SMALLINT

CALL fl_retorna_usuario()
INITIALIZE rm_rol.* TO NULL
LET vm_num_elm         = 0
FOR indice = 1 TO vm_max_elm
        INITIALIZE rm_impren[indice].* TO NULL
END FOR
FOR indice = 1 TO fgl_scr_size('rm_impren')
        CLEAR rm_impren[indice].*
END FOR
LET rm_rol.n15_usuario = vg_usuario
LET rm_rol.n15_fecing  = fl_current()
CALL leer_cabecera()
IF NOT int_flag THEN
	CALL leer_detalle() RETURNING num_elm
	IF NOT int_flag THEN
		LET rm_rol.n15_fecing   = fl_current()
		LET rm_rol.n15_compania = vg_codcia
		BEGIN WORK
		FOR indice = 1 TO num_elm
			INSERT INTO rolt015 VALUES (rm_rol.n15_compania,
						rm_rol.n15_ano,
						rm_impren[indice].n15_secuencia,
						rm_impren[indice].n15_base_imp_ini,
						rm_impren[indice].n15_base_imp_fin,
						rm_impren[indice].n15_fracc_base,
						rm_impren[indice].n15_porc_ir,
						rm_rol.n15_usuario,
						rm_rol.n15_fecing)
		END FOR
		COMMIT WORK
		IF vm_num_rows = vm_max_rows THEN
			LET vm_num_rows = 1
		ELSE
			LET vm_num_rows = vm_num_rows + 1
		END IF
		LET vm_row_current = vm_num_rows
		DISPLAY BY NAME rm_rol.n15_fecing
		LET rm_rol.n15_compania =	SQLCA.SQLERRD[2]
		LET vm_r_rows[vm_row_current] =	rm_rol.n15_ano
		CALL mostrar_registro(vm_r_rows[vm_num_rows])	
		CALL muestra_contadores(vm_row_current, vm_num_rows)
		CALL fl_mensaje_registro_ingresado()
	END IF
ELSE
	CLEAR FORM
	CALL mostrar_botones_detalle()
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
END IF

END FUNCTION



FUNCTION control_modificacion()
DEFINE num_elm          SMALLINT
DEFINE indice           SMALLINT

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR SELECT * FROM rolt015
	WHERE n15_ano = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_rol.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
IF rm_rol.n15_ano IS NULL THEN
	ROLLBACK WORK
	CALL fgl_winmessage(vg_producto,'Error: No hay registros que modificar','exclamation')
	RETURN
END IF

CALL leer_detalle() RETURNING num_elm

IF NOT int_flag THEN
	DELETE FROM rolt015 WHERE n15_ano = rm_rol.n15_ano
	LET rm_rol.n15_compania = 0
	FOR indice = 1 TO arr_count()
		INSERT INTO rolt015 VALUES (rm_rol.n15_compania,
					rm_rol.n15_ano,
					rm_impren[indice].n15_secuencia,
					rm_impren[indice].n15_base_imp_ini,
					rm_impren[indice].n15_base_imp_fin,
					rm_impren[indice].n15_fracc_base,
					rm_impren[indice].n15_porc_ir,
					rm_rol.n15_usuario,
					rm_rol.n15_fecing)
	END FOR
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	CLEAR FORM
	ROLLBACK WORK
	CALL mostrar_botones_detalle()
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
END IF
 
END FUNCTION



FUNCTION control_consulta()
DEFINE query		VARCHAR(400)
DEFINE expr_sql		VARCHAR(400)

LET int_flag = 0
CLEAR FORM
CALL mostrar_botones_detalle()
CONSTRUCT BY NAME expr_sql ON n15_ano
IF int_flag THEN
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	ELSE
		CLEAR FORM
		CALL mostrar_botones_detalle()
	END IF
	RETURN
END IF
LET query = 'SELECT UNIQUE n15_ano FROM rolt015
		WHERE ' || expr_sql CLIPPED || ' ORDER BY 1 DESC'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO vm_r_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
                EXIT FOREACH
        END IF
END FOREACH
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	CLEAR FORM
	CALL mostrar_botones_detalle()
	LET vm_row_current = 0
ELSE  
	LET vm_row_current = 1
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION leer_cabecera()
DEFINE resp		CHAR(6)
DEFINE r_rol_aux	RECORD LIKE rolt015.*
DEFINE ultimo_ano	LIKE rolt015.n15_ano

OPTIONS INPUT NO WRAP
INITIALIZE r_rol_aux.* TO NULL
INITIALIZE ultimo_ano  TO NULL
LET int_flag = 0
DISPLAY BY NAME rm_rol.n15_usuario, rm_rol.n15_fecing
INITIALIZE r_rol_aux.* TO NULL
INPUT BY NAME rm_rol.n15_ano
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(rm_rol.n15_ano) THEN
               		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
        	        	RETURNING resp
              		IF resp = 'Yes' THEN
				LET int_flag = 1
	                       	CLEAR FORM
				CALL mostrar_botones_detalle()
        	               	RETURN
                	END IF
		ELSE
			RETURN
		END IF
	AFTER FIELD n15_ano
		IF rm_rol.n15_ano IS NOT NULL THEN
			SELECT UNIQUE MAX(n15_ano) INTO ultimo_ano FROM rolt015
			IF rm_rol.n15_ano = ultimo_ano THEN
				CALL fgl_winmessage(vg_producto,'Este año ya ha sido ingresado','exclamation')
				NEXT FIELD n15_ano
			END IF
			IF rm_rol.n15_ano > YEAR(vg_fecha) THEN
				CALL fgl_winmessage(vg_producto,'Este año no existe todavía','exclamation')
				NEXT FIELD n15_ano
			END IF
		ELSE
			CLEAR n15_ano
		END IF
END INPUT

END FUNCTION



FUNCTION leer_detalle()
DEFINE resp             CHAR(6)
DEFINE i,j              SMALLINT
                                                                                
LET i = 1
CALL set_count(vm_num_elm)
LET int_flag = 0
INPUT ARRAY rm_impren WITHOUT DEFAULTS FROM rm_impren.*
	ON KEY(INTERRUPT)
               	LET int_flag = 0
               	CALL fl_mensaje_abandonar_proceso()
                       	RETURNING resp
               	IF resp = 'Yes' THEN
               		LET i = i - 1
               		LET int_flag = 1
               		CLEAR FORM
			CALL mostrar_botones_detalle()
                       	RETURN i
               	END IF
	BEFORE ROW
        	LET i = arr_curr()
        	LET j = scr_line()
		LET rm_impren[i].n15_secuencia = i
	AFTER FIELD n15_base_imp_ini
		IF rm_impren[i].n15_base_imp_ini IS NOT NULL THEN
			CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base,
                                                        rm_impren[i].n15_base_imp_ini)
                                RETURNING rm_impren[i].n15_base_imp_ini
--OJO
--                        DISPLAY rm_impren[i].n15_base_imp_ini TO rm_impren[j].n15_base_imp_ini
			IF i > 1 THEN 
				LET j = i - 1
				IF rm_impren[i].n15_base_imp_ini <= 
				rm_impren[j].n15_base_imp_fin THEN
					CALL fgl_winmessage(vg_producto,'El exceso debe ser mayor al valor base','exclamation')
					NEXT FIELD n15_base_imp_ini
				END IF
			END IF
			DISPLAY rm_impren[i].n15_secuencia
				TO rm_impren[j].n15_secuencia
		END IF
	AFTER FIELD n15_base_imp_fin
		IF rm_impren[i].n15_base_imp_fin IS NOT NULL THEN
			CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base,
                                                        rm_impren[i].n15_base_imp_fin)
                                RETURNING rm_impren[i].n15_base_imp_fin
--OJO
--                        DISPLAY rm_impren[i].n15_base_imp_fin TO rm_impren[j].n15_base_imp_fin
			IF j > 1 THEN
				LET i = j - 1
				IF rm_impren[j].n15_base_imp_fin <= 
				rm_impren[i].n15_base_imp_ini THEN
					CALL fgl_winmessage(vg_producto,'El exceso debe ser mayor al valor base','exclamation')
					NEXT FIELD n15_base_imp_fin
				END IF
			END IF
			DISPLAY rm_impren[i].n15_secuencia
				TO rm_impren[j].n15_secuencia
		END IF
	AFTER FIELD n15_fracc_base
		IF rm_impren[i].n15_fracc_base IS NOT NULL THEN
			CALL fl_retorna_precision_valor(rg_gen.g00_moneda_base,
                                                        rm_impren[i].n15_fracc_base)
                                RETURNING rm_impren[i].n15_fracc_base
--OJO
--                        DISPLAY rm_impren[i].n15_fracc_base TO rm_impren[j].n15_fracc_base
			DISPLAY rm_impren[i].n15_secuencia
				TO rm_impren[j].n15_secuencia
		END IF
END INPUT
LET i = arr_count()
RETURN i
                                                                                
END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 68
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE r_rol_aux	RECORD LIKE rolt015.*
DEFINE num_registro	LIKE rolt015.n15_ano

IF vm_num_rows > 0 THEN
	DECLARE q_dt CURSOR FOR SELECT * FROM rolt015 
                WHERE n15_ano = num_registro
        OPEN q_dt
        FETCH q_dt INTO rm_rol.*
	IF STATUS = NOTFOUND THEN
		CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
		RETURN
	END IF
	DISPLAY BY NAME	rm_rol.n15_ano,
		rm_rol.n15_usuario,
		rm_rol.n15_fecing
	CALL muestra_detalle(num_registro)
ELSE
	RETURN
END IF

END FUNCTION



FUNCTION muestra_detalle(num_reg)
DEFINE num_reg          LIKE rolt015.n15_ano
DEFINE query            VARCHAR(400)
DEFINE i                SMALLINT
                                                                                
LET int_flag = 0
FOR i = 1 TO fgl_scr_size('rm_impren')
        INITIALIZE rm_impren[i].* TO NULL
        CLEAR rm_impren[i].*
END FOR
LET i = 1
LET query = 'SELECT n15_secuencia, n15_base_imp_ini, n15_base_imp_fin, ',
			'n15_fracc_base,n15_porc_ir ',
		' FROM rolt015 ',
                ' WHERE n15_ano = ', num_reg,
		' ORDER BY 1'
PREPARE cons1 FROM query
DECLARE q_cons1 CURSOR FOR cons1
LET vm_num_elm = 0
FOREACH q_cons1 INTO rm_impren[i].*
        LET vm_num_elm = vm_num_elm + 1
        LET i = i + 1
        IF vm_num_elm > vm_max_elm THEN
        	LET vm_num_elm = vm_num_elm - 1
		CALL fl_mensaje_arreglo_incompleto()
		EXIT PROGRAM
                --EXIT FOREACH
        END IF
END FOREACH
IF vm_num_elm > 0 THEN
        LET int_flag = 0
        FOR i = 1 TO fgl_scr_size('rm_impren')
                DISPLAY rm_impren[i].* TO rm_impren[i].*
        END FOR
END IF
IF int_flag THEN
        INITIALIZE rm_impren[1].* TO NULL
        RETURN
END IF
                                                                                
END FUNCTION
                                                                                
                                                                                
                                                                                
FUNCTION muestra_detalle_arr()
CALL set_count(vm_num_elm)
DISPLAY ARRAY rm_impren TO rm_impren.*
	BEFORE DISPLAY
		CALL dialog.keysetlabel("ACCEPT","")
	AFTER DISPLAY
		CONTINUE DISPLAY
	ON KEY(INTERRUPT)
		EXIT DISPLAY
END DISPLAY
                                                                                
END FUNCTION
                                                                                
                                                                                
                                                                                
FUNCTION mostrar_botones_detalle()

DISPLAY 'Sec.'			TO tit_col1
DISPLAY 'Fraccion Basica'      	TO tit_col2
DISPLAY 'Exceso Hasta' 		TO tit_col3
DISPLAY 'Imp. Frac. Base' 	TO tit_col4
DISPLAY '% I.R.'		TO tit_col5

END FUNCTION
