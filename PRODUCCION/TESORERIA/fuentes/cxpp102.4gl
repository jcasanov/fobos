------------------------------------------------------------------------------
-- Titulo           : cxpp102.4gl - Mantenimiento de Tipos de Doc. y Transacc. 
-- Elaboracion      : 28-sep-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun programa.4gl base modulo compañía
-- Ultima Correccion: 
-- Motivo Correccion:  
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE rm_cxp		RECORD LIKE cxpt004.*
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows	SMALLINT	-- MAXIMO DE FILAS LEIDAS
DEFINE vm_r_rows 	ARRAY[50] OF INTEGER -- ARREGLO DE ROWID DE FILAS LEIDAS

MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'cxpp102'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
LET vm_max_rows = 50
OPEN WINDOW  w_f AT 3,2 WITH 17 ROWS, 80 COLUMNS	
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
        ACCEPT KEY      F12
OPEN FORM f_cxp FROM "../forms/cxpf102_1"
DISPLAY FORM f_cxp
INITIALIZE rm_cxp.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Bloquear/Activar'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registos. '
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso()
		END IF
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
	COMMAND KEY('B') 'Bloquear/Activar' 'Bloquear o Activar registro'
            	CALL bloquear_activar()
	COMMAND KEY('S') 'Salir' 'Salir del programa'
		EXIT MENU
END MENU

END FUNCTION


 
FUNCTION control_ingreso()

CALL fl_retorna_usuario()
INITIALIZE rm_cxp.* TO NULL
LET rm_cxp.p04_tipo    = 'D'
LET rm_cxp.p04_fecing  = CURRENT
LET rm_cxp.p04_usuario = vg_usuario 
LET rm_cxp.p04_estado  = 'A'
CLEAR tit_est
CLEAR tit_estado_tip
CALL muestra_estado()
CALL leer_datos('I')
IF NOT int_flag THEN
	LET rm_cxp.p04_fecing  = CURRENT
      	INSERT INTO cxpt004 VALUES (rm_cxp.*)
	LET vm_num_rows = vm_num_rows + 1
	LET vm_row_current = vm_num_rows
        DISPLAY BY NAME rm_cxp.p04_fecing
	LET vm_r_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
	CALL mostrar_registro(vm_r_rows[vm_num_rows])
        CALL muestra_contadores(vm_row_current, vm_num_rows)
	CALL fl_mensaje_registro_ingresado()
ELSE
	CLEAR FORM
	IF vm_num_rows > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
END IF

END FUNCTION



FUNCTION control_modificacion()

IF vm_num_rows = 0 THEN
        CALL fl_mensaje_consultar_primero()
        RETURN
END IF
IF rm_cxp.p04_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM cxpt004
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_cxp.*
IF status < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
CALL leer_datos('M')
IF NOT int_flag THEN
    	UPDATE cxpt004 SET p04_nombre = rm_cxp.p04_nombre,
			p04_tipo = rm_cxp.p04_tipo
		WHERE CURRENT OF q_up
	CALL fl_mensaje_registro_modificado()
ELSE
        CLEAR FORM
        IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	END IF
END IF
COMMIT WORK
WHENEVER ERROR STOP

END FUNCTION
  


FUNCTION control_consulta()
DEFINE tipo_doc		LIKE cxpt004.p04_tipo_doc
DEFINE nombre		LIKE cxpt004.p04_nombre
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)
DEFINE num_reg          INTEGER

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON p04_tipo_doc, p04_nombre, p04_tipo
	ON KEY(F2)
		IF INFIELD(p04_tipo_doc) THEN
			CALL fl_ayuda_tipo_documento_tesoreria('0')
				RETURNING tipo_doc, nombre  
			IF tipo_doc IS NOT NULL THEN
				DISPLAY tipo_doc TO p04_tipo_doc
				DISPLAY nombre TO p04_nombre
			END IF
		END IF
END CONSTRUCT
IF int_flag THEN
	IF vm_row_current > 0 THEN
		CALL muestra_contadores(vm_row_current, vm_num_rows)
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	ELSE
                CLEAR FORM
        END IF
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM cxpt004 WHERE ' ||  expr_sql || ' ORDER BY 2'
PREPARE cons FROM query
DECLARE q_tipdoc CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_tipdoc INTO rm_cxp.*, num_reg
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
      	LET vm_row_current = 0
      	CLEAR FORM
      	RETURN
ELSE
        LET vm_row_current = 1
        CALL mostrar_registro(vm_r_rows[vm_row_current])
END IF
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION



FUNCTION leer_datos(flag_mant)
DEFINE flag_mant        CHAR(1)
DEFINE resp   		CHAR(6)
DEFINE tipo_doc		LIKE cxpt004.p04_tipo_doc
DEFINE nombre		LIKE cxpt004.p04_nombre
DEFINE r_cxp_aux	RECORD LIKE cxpt004.*


LET int_flag = 0 
INITIALIZE r_cxp_aux.* TO NULL
DISPLAY BY NAME rm_cxp.p04_fecing, rm_cxp.p04_usuario
INPUT BY NAME rm_cxp.p04_tipo_doc,
	rm_cxp.p04_nombre,
	rm_cxp.p04_tipo
	WITHOUT DEFAULTS                                                        
	ON KEY (INTERRUPT)
		IF field_touched(rm_cxp.p04_tipo_doc,
 				 rm_cxp.p04_nombre,
 				 rm_cxp.p04_tipo)
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
	BEFORE FIELD p04_tipo_doc 
		IF flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF	
	AFTER FIELD p04_tipo_doc
		IF rm_cxp.p04_tipo_doc IS NOT NULL THEN
			CALL fl_lee_tipo_doc_tesoreria(rm_cxp.p04_tipo_doc) 
				RETURNING r_cxp_aux.*
			IF r_cxp_aux.p04_tipo_doc IS NOT NULL THEN
              			CALL fgl_winmessage(vg_producto,'Ya existe ese Tipo de Documento','exclamation')
				NEXT FIELD p04_tipo_doc
        		END IF
		ELSE
			CLEAR p04_tipo_doc   
		END IF
END INPUT
                                                                                
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
DEFINE row_current      SMALLINT
DEFINE num_rows         SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 69
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro     INTEGER
                                                                                
IF vm_num_rows > 0 THEN
        SELECT * INTO rm_cxp.* FROM cxpt004 WHERE ROWID=num_registro
        IF STATUS = NOTFOUND THEN
                CALL fgl_winmessage (vg_producto,'No existe registro con índice:
 ' || vm_row_current,'exclamation')
                RETURN
        END IF
        DISPLAY BY NAME rm_cxp.p04_tipo_doc,
                        rm_cxp.p04_nombre,
                        rm_cxp.p04_tipo,
                        rm_cxp.p04_usuario,
                        rm_cxp.p04_fecing
        CALL muestra_estado()
ELSE
        RETURN
END IF
                                                                                
END FUNCTION



FUNCTION bloquear_activar()
DEFINE resp    		CHAR(6)

IF vm_num_rows = 0 THEN
        CALL fl_mensaje_consultar_primero()
        RETURN
END IF
LET int_flag = 0
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_blo CURSOR FOR SELECT * FROM cxpt004
	WHERE ROWID = vm_r_rows[vm_row_current]
      	FOR UPDATE
OPEN q_blo
FETCH q_blo INTO rm_cxp.*
IF status < 0 THEN
      	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
CALL fl_mensaje_seguro_ejecutar_proceso()
      RETURNING resp
IF resp = 'Yes' THEN
	LET int_flag = 1
        CALL bloquea_activa_registro()
END IF
COMMIT WORK
WHENEVER ERROR STOP	

END FUNCTION



FUNCTION bloquea_activa_registro()
DEFINE estado   CHAR(1)
                                                                                
IF rm_cxp.p04_estado = 'A' THEN
        DISPLAY 'BLOQUEADO' TO tit_estado_tip
        LET estado = 'B'
ELSE
        DISPLAY 'ACTIVO' TO tit_estado_tip
        LET estado = 'A'
END IF
DISPLAY estado TO tit_est
UPDATE cxpt004 SET p04_estado = estado WHERE CURRENT OF q_blo
LET rm_cxp.p04_estado = estado
                                                                                
END FUNCTION



FUNCTION muestra_estado()
IF rm_cxp.p04_estado = 'A' THEN
        DISPLAY 'ACTIVO' TO tit_estado_tip
ELSE
        DISPLAY 'BLOQUEADO' TO tit_estado_tip
END IF
DISPLAY rm_cxp.p04_estado TO tit_est
                                                                                
END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION




