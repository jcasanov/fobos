------------------------------------------------------------------------------
-- Titulo           : cajp102.4gl - Mantenimiento de Cajas
-- Elaboracion      : 01-oct-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun cajp102 base módulo commpañía
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_caj		RECORD LIKE cajt002.*
DEFINE vm_nivel		LIKE ctbt001.b01_nivel
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY [1000] OF INTEGER



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cajp102.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto', 'stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'cajp102'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET vm_max_rows	= 1000
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 19
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW wf AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,BORDER,
	      MESSAGE LINE LAST - 1)
IF vg_gui = 1 THEN
        OPEN FORM f_caj FROM '../forms/cajf102_1'
ELSE
        OPEN FORM f_caj FROM '../forms/cajf102_1c'
END IF
DISPLAY FORM f_caj
INITIALIZE rm_caj.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
SELECT MAX(b01_nivel) INTO vm_nivel FROM ctbt001
IF vm_nivel IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ningun nivel de cuenta configurado en la compania.','stop')
	EXIT PROGRAM
END IF
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
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()
DEFINE codigo_caj	LIKE cajt002.j02_codigo_caja

CALL fl_retorna_usuario()
CLEAR j02_codigo_caja, tit_localidad, tit_usua_caja, tit_aux_cont
INITIALIZE rm_caj.*, codigo_caj TO NULL
LET rm_caj.j02_compania    = vg_codcia
LET rm_caj.j02_pre_ventas  = 'S'
LET rm_caj.j02_ordenes     = 'S'
LET rm_caj.j02_solicitudes = 'S'
CALL leer_datos('I')
IF NOT int_flag THEN
	SELECT MAX(j02_codigo_caja) INTO codigo_caj
		FROM cajt002
		WHERE j02_compania  = rm_caj.j02_compania
 		  AND j02_localidad = rm_caj.j02_localidad
	IF codigo_caj IS NOT NULL THEN
		LET rm_caj.j02_codigo_caja = codigo_caj + 1
	ELSE
		LET rm_caj.j02_codigo_caja = 1
	END IF
	INSERT INTO cajt002 VALUES (rm_caj.*)
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	LET vm_row_current = vm_num_rows 
	DISPLAY BY NAME rm_caj.j02_codigo_caja
	LET vm_r_rows[vm_row_current] = SQLCA.SQLERRD[6] 
	CALL mostrar_registro(vm_r_rows[vm_num_rows])	
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL fl_mensaje_registro_ingresado()
ELSE
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
END IF

END FUNCTION



FUNCTION control_modificacion()
	
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR SELECT * FROM cajt002
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_caj.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL leer_datos('M')
IF NOT int_flag THEN
	UPDATE cajt002 SET j02_nombre_caja = rm_caj.j02_nombre_caja,
			   j02_pre_ventas  = rm_caj.j02_pre_ventas,
			   j02_ordenes     = rm_caj.j02_ordenes,
			   j02_solicitudes = rm_caj.j02_solicitudes,
			   j02_usua_caja   = rm_caj.j02_usua_caja,
			   j02_aux_cont    = rm_caj.j02_aux_cont 
			WHERE CURRENT OF q_up
	COMMIT WORK
	CALL fl_mensaje_registro_modificado()
ELSE
	ROLLBACK WORK
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
END IF
 
END FUNCTION



FUNCTION control_consulta()
DEFINE cod_aux		LIKE cajt002.j02_codigo_caja
DEFINE nom_aux		LIKE cajt002.j02_nombre_caja
DEFINE codl_aux		LIKE gent002.g02_localidad
DEFINE noml_aux		LIKE gent002.g02_nombre
DEFINE codu_aux		LIKE gent005.g05_usuario
DEFINE nomu_aux		LIKE gent005.g05_nombres
DEFINE localidad	LIKE cajt002.j02_localidad
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE query		CHAR(800)
DEFINE expr_sql		CHAR(600)
DEFINE num_reg		INTEGER

CLEAR FORM
INITIALIZE cod_aux, codl_aux, codu_aux TO NULL
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON j02_localidad, j02_codigo_caja, j02_nombre_caja,
	j02_pre_ventas, j02_ordenes, j02_solicitudes, j02_aux_cont,j02_usua_caja
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(j02_localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING codl_aux, noml_aux
			LET int_flag = 0
			IF codl_aux IS NOT NULL THEN
				LET rm_caj.j02_localidad = codl_aux
				DISPLAY codl_aux TO j02_localidad 
				DISPLAY noml_aux TO tit_localidad
			END IF 
		END IF
		IF INFIELD(j02_codigo_caja) THEN
			LET localidad = vg_codloc
			IF rm_caj.j02_localidad IS NOT NULL THEN
				LET localidad = rm_caj.j02_localidad
			END IF
			CALL fl_ayuda_cajas(vg_codcia, localidad)
				RETURNING cod_aux, nom_aux
			LET int_flag = 0
			IF cod_aux IS NOT NULL THEN
				DISPLAY cod_aux TO j02_codigo_caja 
				DISPLAY nom_aux TO j02_nombre_caja
			END IF 
		END IF
		IF INFIELD(j02_aux_cont) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia,vm_nivel)
                                RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
                        LET int_flag = 0
                        IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_caj.j02_aux_cont = r_b10.b10_cuenta
                                DISPLAY BY NAME rm_caj.j02_aux_cont
                                DISPLAY r_b10.b10_descripcion TO tit_aux_cont
                        END IF
                END IF
		IF INFIELD(j02_usua_caja) THEN
			CALL fl_ayuda_usuarios("T")
				RETURNING codu_aux, nomu_aux
			LET int_flag = 0
			IF codu_aux IS NOT NULL THEN
				DISPLAY codu_aux TO j02_usua_caja 
				DISPLAY nomu_aux TO tit_usua_caja
			END IF 
		END IF
	BEFORE CONSTRUCT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD j02_localidad
		LET rm_caj.j02_localidad = GET_FLDBUF(j02_localidad)
END CONSTRUCT
IF int_flag THEN
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	ELSE
		CLEAR FORM
	END IF
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM cajt002 WHERE j02_compania = ' ||
		vg_codcia || ' AND ' || expr_sql CLIPPED || ' ORDER BY 2, 4'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_caj.*, num_reg
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		LET vm_num_rows = vm_num_rows - 1
                EXIT FOREACH
        END IF
	LET vm_r_rows[vm_num_rows] = num_reg
END FOREACH
IF vm_num_rows = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	CLEAR FORM
	LET vm_row_current = 0
ELSE  
	LET vm_row_current = 1
	CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION leer_datos (flag_mant)
DEFINE flag_mant	CHAR(1)
DEFINE resp		CHAR(6)
DEFINE resul		SMALLINT
DEFINE r_caj_aux	RECORD LIKE cajt002.*
DEFINE r_loc_aux	RECORD LIKE gent002.*
DEFINE r_usu		RECORD LIKE gent005.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE codl_aux		LIKE gent002.g02_localidad
DEFINE noml_aux		LIKE gent002.g02_nombre
DEFINE codu_aux		LIKE gent005.g05_usuario
DEFINE nomu_aux		LIKE gent005.g05_nombres

INITIALIZE r_caj_aux.*, r_loc_aux.*, codl_aux, codu_aux TO NULL
LET int_flag = 0
INPUT BY NAME rm_caj.j02_localidad, rm_caj.j02_nombre_caja,
	rm_caj.j02_pre_ventas, rm_caj.j02_ordenes, rm_caj.j02_solicitudes,
	rm_caj.j02_aux_cont, rm_caj.j02_usua_caja
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF field_touched(rm_caj.j02_localidad, rm_caj.j02_nombre_caja,
			rm_caj.j02_pre_ventas, rm_caj.j02_ordenes,
			rm_caj.j02_solicitudes, rm_caj.j02_aux_cont,
			rm_caj.j02_usua_caja)
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
			RETURN
		END IF
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(j02_localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia)
				RETURNING codl_aux, noml_aux
			LET int_flag = 0
			IF codl_aux IS NOT NULL THEN
				LET rm_caj.j02_localidad = codl_aux
				DISPLAY BY NAME rm_caj.j02_localidad 
				DISPLAY noml_aux TO tit_localidad
			END IF 
		END IF
		IF INFIELD(j02_aux_cont) THEN
                        CALL fl_ayuda_cuenta_contable(vg_codcia,vm_nivel)
                                RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
                        LET int_flag = 0
                        IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_caj.j02_aux_cont = r_b10.b10_cuenta
                                DISPLAY BY NAME rm_caj.j02_aux_cont
                                DISPLAY r_b10.b10_descripcion TO tit_aux_cont
                        END IF
                END IF
		IF INFIELD(j02_usua_caja) THEN
			CALL fl_ayuda_usuarios("A")
				RETURNING codu_aux, nomu_aux
			LET int_flag = 0
			IF codu_aux IS NOT NULL THEN
				LET rm_caj.j02_usua_caja = codu_aux
				DISPLAY BY NAME rm_caj.j02_usua_caja 
				DISPLAY nomu_aux TO tit_usua_caja
			END IF 
		END IF
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD j02_localidad
		IF flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	AFTER FIELD j02_localidad
		IF rm_caj.j02_localidad IS NOT NULL THEN
			CALL fl_lee_localidad(vg_codcia, rm_caj.j02_localidad)
                        	RETURNING r_loc_aux.*
			IF r_loc_aux.g02_localidad IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Localidad no existe.','exclamation')
				CALL fl_mostrar_mensaje('Localidad no existe.','exclamation')
				NEXT FIELD j02_localidad
			END IF
			DISPLAY r_loc_aux.g02_nombre TO tit_localidad
			IF r_loc_aux.g02_estado = 'B' THEN
        			CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD j02_localidad
			END IF
		ELSE
			CLEAR tit_localidad
		END IF
	AFTER FIELD j02_aux_cont
                IF rm_caj.j02_aux_cont IS NOT NULL THEN
			CALL validar_cuenta(rm_caj.j02_aux_cont, 1)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD j02_aux_cont
			END IF
		ELSE
			CLEAR tit_aux_cont
                END IF
	AFTER FIELD j02_usua_caja
		IF rm_caj.j02_usua_caja IS NOT NULL THEN
			CALL fl_lee_usuario(rm_caj.j02_usua_caja)
                        	RETURNING r_usu.*
			IF r_usu.g05_usuario IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Usuario no existe.','exclamation')
				CALL fl_mostrar_mensaje('Usuario no existe.','exclamation')
				NEXT FIELD j02_usua_caja
			END IF
			DISPLAY r_usu.g05_nombres TO tit_usua_caja
			IF r_usu.g05_estado = 'B' THEN
        			CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD j02_usua_caja
			END IF
		ELSE
			CLEAR tit_usua_caja
		END IF
	AFTER INPUT
		IF flag_mant <> 'M' THEN
			INITIALIZE r_caj_aux.* TO NULL
			SELECT * INTO r_caj_aux.* FROM cajt002
				WHERE j02_compania  = vg_codcia
				  AND j02_localidad = rm_caj.j02_localidad
				  AND j02_usua_caja = rm_caj.j02_usua_caja
			IF r_caj_aux.j02_usua_caja = rm_caj.j02_usua_caja THEN
				--CALL fgl_winmessage(vg_producto,'Un mismo usuario no puede estar con más de una caja.','exclamation')
				CALL fl_mostrar_mensaje('Un mismo usuario no puede estar con más de una caja.','exclamation')
				NEXT FIELD j02_usua_caja
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION validar_cuenta(aux_cont, flag)
DEFINE aux_cont		LIKE ctbt010.b10_cuenta
DEFINE flag		SMALLINT
DEFINE r_cta            RECORD LIKE ctbt010.*

CALL fl_lee_cuenta(vg_codcia, aux_cont) RETURNING r_cta.*
IF r_cta.b10_cuenta IS NULL THEN
	CALL fl_mostrar_mensaje('Cuenta no existe para esta compañía.','exclamation')
	RETURN 1
END IF
CASE flag
	WHEN 1
		DISPLAY r_cta.b10_descripcion TO tit_aux_cont
END CASE
IF r_cta.b10_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN 1
END IF
IF r_cta.b10_nivel <> vm_nivel THEN
	CALL fl_mostrar_mensaje('Nivel de cuenta debe ser solo del ultimo.','exclamation')
	RETURN 1
END IF
RETURN 0

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
DEFINE nrow             SMALLINT
                                                                                
LET nrow = 19
IF vg_gui = 1 THEN
	LET nrow = 1
END IF
DISPLAY "" AT nrow, 1
DISPLAY row_current, " de ", num_rows AT nrow, 67

END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	INTEGER
DEFINE r_loc_aux	RECORD LIKE gent002.*
DEFINE r_usu		RECORD LIKE gent005.*
DEFINE r_cta            RECORD LIKE ctbt010.*

IF vm_num_rows > 0 THEN
	SELECT * INTO rm_caj.* FROM cajt002 WHERE ROWID = num_registro	
	IF STATUS = NOTFOUND THEN
		--CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
		CALL fl_mostrar_mensaje('No existe registro con índice: ' || vm_row_current,'exclamation')
		RETURN
	END IF
	DISPLAY BY NAME rm_caj.j02_localidad, rm_caj.j02_codigo_caja,
			rm_caj.j02_nombre_caja, rm_caj.j02_pre_ventas,
			rm_caj.j02_ordenes, rm_caj.j02_solicitudes,
			rm_caj.j02_aux_cont, rm_caj.j02_usua_caja
	CALL fl_lee_localidad(vg_codcia,rm_caj.j02_localidad)
		RETURNING r_loc_aux.*
	DISPLAY r_loc_aux.g02_nombre TO tit_localidad
	CALL fl_lee_cuenta(vg_codcia, rm_caj.j02_aux_cont) RETURNING r_cta.*
	DISPLAY r_cta.b10_descripcion TO tit_aux_cont
	CALL fl_lee_usuario(rm_caj.j02_usua_caja)
		RETURNING r_usu.*
	DISPLAY r_usu.g05_nombres TO tit_usua_caja
ELSE
	RETURN
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
