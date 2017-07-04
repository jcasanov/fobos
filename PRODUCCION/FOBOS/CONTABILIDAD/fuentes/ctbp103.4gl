------------------------------------------------------------------------------
-- Titulo           : ctbp103.4gl - Mantenimiento de Tipos Comprob. Contables 
-- Elaboracion      : 20-sep-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun ctbp103 base módulo commpañía
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE rm_ctb		RECORD LIKE ctbt003.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY [50] OF INTEGER

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
--CALL startlog('../logs/errores')
CALL startlog('../logs/ctbp103.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'ctbp103'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
LET vm_max_rows	= 50
OPEN WINDOW wf AT 3,2 WITH 15 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_ctb FROM "../forms/ctbf103_1"
DISPLAY FORM f_ctb
INITIALIZE rm_ctb.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Bloquear/Activar'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
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
		CALL control_modificacion()		
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
 	COMMAND KEY('B') 'Bloquear/Activar' 'Bloquear o activar registro. '
                CALL bloquear_activar()
	COMMAND KEY('S') 'Salir' 'Salir del programa. '
		EXIT MENU
END MENU

END FUNCTION



FUNCTION control_ingreso()

CALL fl_retorna_usuario()
INITIALIZE rm_ctb.* TO NULL
LET rm_ctb.b03_compania = vg_codcia
LET rm_ctb.b03_usuario = vg_usuario
LET rm_ctb.b03_fecing = CURRENT
LET rm_ctb.b03_estado = 'A'
CLEAR tit_est
CLEAR tit_estado_com
CLEAR tit_modulo
CALL muestra_estado()
CALL leer_datos('I')
IF NOT int_flag THEN
	LET rm_ctb.b03_fecing = CURRENT
	INSERT INTO ctbt003 VALUES (rm_ctb.*)
	LET vm_num_rows = vm_num_rows + 1
	LET vm_row_current = vm_num_rows
	DISPLAY BY NAME rm_ctb.b03_fecing
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
IF rm_ctb.b03_estado = 'B' THEN
        CALL fl_mensaje_estado_bloqueado()
        RETURN
END IF
CALL mostrar_registro(vm_r_rows[vm_row_current])
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM ctbt003
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_ctb.*
IF STATUS < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
CALL leer_datos('M')
IF NOT int_flag THEN
	UPDATE ctbt003 SET b03_nombre = rm_ctb.b03_nombre,
			   b03_modulo = rm_ctb.b03_modulo
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
DEFINE cod_aux		LIKE ctbt003.b03_tipo_comp
DEFINE nom_aux		LIKE ctbt003.b03_nombre
DEFINE mcod_aux         LIKE gent050.g50_modulo
DEFINE mnom_aux         LIKE gent050.g50_nombre
DEFINE query		VARCHAR(400)
DEFINE expr_sql		VARCHAR(400)
DEFINE num_reg		INTEGER

LET int_flag = 0
CLEAR FORM
CONSTRUCT BY NAME expr_sql ON b03_tipo_comp, b03_nombre, b03_modulo
	ON KEY(F2)
	IF INFIELD(b03_tipo_comp) THEN
		CALL fl_ayuda_tipos_comprobantes(vg_codcia)
			RETURNING cod_aux, nom_aux
		LET int_flag = 0
		IF cod_aux IS NOT NULL THEN
			DISPLAY cod_aux TO b03_tipo_comp 
			DISPLAY nom_aux TO b03_nombre
		END IF 
	END IF
	IF INFIELD(b03_modulo) THEN
                CALL fl_ayuda_modulos()
                	RETURNING mcod_aux, mnom_aux
                LET int_flag = 0
                IF mcod_aux IS NOT NULL THEN
                        DISPLAY mcod_aux TO b03_modulo
                        DISPLAY mnom_aux TO tit_modulo
                END IF
        END IF
END CONSTRUCT
IF int_flag THEN
	IF vm_row_current > 0 THEN
		CALL mostrar_registro(vm_r_rows[vm_row_current])
	ELSE
		CLEAR FORM
	END IF
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM ctbt003 WHERE b03_compania = ' || 
		vg_codcia || ' AND ' || expr_sql || ' ORDER BY 2'
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_ctb.*, num_reg
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
DEFINE r_ctb_aux	RECORD LIKE ctbt003.*
DEFINE mcod_aux         LIKE gent050.g50_modulo
DEFINE mnom_aux         LIKE gent050.g50_nombre

LET int_flag = 0
INITIALIZE r_ctb_aux.* TO NULL
DISPLAY BY NAME rm_ctb.b03_usuario, rm_ctb.b03_fecing
INPUT BY NAME rm_ctb.b03_tipo_comp,
	rm_ctb.b03_nombre,
  	rm_ctb.b03_modulo
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        IF field_touched(rm_ctb.b03_tipo_comp,
		rm_ctb.b03_nombre,
  		rm_ctb.b03_modulo)
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
	ON KEY(F2)
	IF INFIELD(b03_modulo) THEN
                CALL fl_ayuda_modulos()
                	RETURNING mcod_aux, mnom_aux
                LET int_flag = 0
                IF mcod_aux IS NOT NULL THEN
			LET rm_ctb.b03_modulo = mcod_aux
                        DISPLAY BY NAME rm_ctb.b03_modulo
                        DISPLAY mnom_aux TO tit_modulo
                END IF
        END IF
	BEFORE FIELD b03_tipo_comp
		IF flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	AFTER FIELD b03_tipo_comp
		IF rm_ctb.b03_tipo_comp IS NOT NULL THEN
			IF length(rm_ctb.b03_tipo_comp) < 2 THEN
				CALL fgl_winmessage(vg_producto,'El tipo debe ser de 2 letras','info')
				NEXT FIELD b03_tipo_comp
			END IF
			CALL fl_lee_tipo_comprobante_contable(vg_codcia,rm_ctb.b03_tipo_comp)
                        	RETURNING r_ctb_aux.*
			IF r_ctb_aux.b03_compania IS NOT NULL THEN
				CALL fgl_winmessage(vg_producto,'Código de tipo de comprobante ya existe','exclamation')
				NEXT FIELD b03_tipo_comp
			END IF
		ELSE
			CLEAR b03_tipo_comp
		END IF
	AFTER FIELD b03_modulo
                IF rm_ctb.b03_modulo IS NOT NULL THEN
                        CALL fl_lee_modulo(rm_ctb.b03_modulo)
                                RETURNING rg_mod.*
                        IF rg_mod.g50_modulo IS NULL  THEN
                                CALL fgl_winmessage(vg_producto,'Módulo no existe
','exclamation')
                                NEXT FIELD b03_modulo
                        ELSE
                                DISPLAY rg_mod.g50_nombre TO tit_modulo
                        END IF
                ELSE
                        CLEAR tit_modulo
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
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
                                                                                
DISPLAY "" AT 1,1
DISPLAY row_current, " de ", num_rows AT 1, 69
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	INTEGER

IF vm_num_rows > 0 THEN
	SELECT * INTO rm_ctb.* FROM ctbt003 WHERE ROWID=num_registro	
	IF STATUS = NOTFOUND THEN
		CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
		RETURN
	END IF
	DISPLAY BY NAME rm_ctb.b03_tipo_comp,
			rm_ctb.b03_nombre,
  			rm_ctb.b03_modulo,
			rm_ctb.b03_usuario,
			rm_ctb.b03_fecing
	CALL fl_lee_modulo(rm_ctb.b03_modulo) RETURNING rg_mod.*
	DISPLAY rg_mod.g50_nombre TO tit_modulo
	CALL muestra_estado()
ELSE
	RETURN
END IF

END FUNCTION



FUNCTION bloquear_activar()
DEFINE confir	CHAR(6)

IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
LET int_flag = 0
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_ba CURSOR FOR SELECT * FROM ctbt003
	WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_ba
FETCH q_ba INTO rm_ctb.*
IF STATUS < 0 THEN
	COMMIT WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF	
CAll fl_mensaje_seguro_ejecutar_proceso()
RETURNING confir
IF confir = 'Yes' THEN
	LET int_flag = 1
	CALL bloquea_activa_registro()
END IF
COMMIT WORK
WHENEVER ERROR STOP

END FUNCTION



FUNCTION bloquea_activa_registro()
DEFINE estado   CHAR(1)
                                                                                
IF rm_ctb.b03_estado = 'A' THEN
        DISPLAY 'BLOQUEADO' TO tit_estado_com
        LET estado = 'B'
ELSE
        DISPLAY 'ACTIVO' TO tit_estado_com
        LET estado = 'A'
END IF
DISPLAY estado TO tit_est
UPDATE ctbt003 SET b03_estado = estado WHERE CURRENT OF q_ba
LET rm_ctb.b03_estado = estado
                                                                                
END FUNCTION



FUNCTION muestra_estado()
IF rm_ctb.b03_estado = 'A' THEN
        DISPLAY 'ACTIVO' TO tit_estado_com
ELSE
        DISPLAY 'BLOQUEADO' TO tit_estado_com
END IF
DISPLAY rm_ctb.b03_estado TO tit_est
                                                                                
END FUNCTION



FUNCTION no_validar_parametros()

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
