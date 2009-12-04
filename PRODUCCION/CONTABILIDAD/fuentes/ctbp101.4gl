------------------------------------------------------------------------------
-- Titulo           : ctbp101.4gl - Mantenimiento Niveles del Plan de Cuentas 
-- Elaboracion      : 18-sep-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun ctbp101 base módulo commpañía
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE rm_ctb		RECORD LIKE ctbt001.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY [50] OF INTEGER

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
LET vg_proceso = 'ctbp101'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()

CALL fl_nivel_isolation()
LET vm_max_rows	= 50
OPEN WINDOW wf AT 3,2 WITH 14 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_ctb FROM "../forms/ctbf101_1"
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
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registros. '
		IF vm_num_rows = vm_max_rows THEN
			CALL fl_mensaje_arreglo_lleno()
		ELSE
			CALL control_ingreso()
		END IF
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

CALL fl_retorna_usuario()
INITIALIZE rm_ctb.* TO NULL
LET rm_ctb.b01_usuario = vg_usuario
LET rm_ctb.b01_fecing = CURRENT
CALL leer_datos('I')
IF NOT int_flag THEN
	-- Hay que obtener el nivel de la cuenta
	SELECT MAX(b01_nivel) INTO rm_ctb.b01_nivel FROM ctbt001
	IF rm_ctb.b01_nivel IS NULL THEN
		LET rm_ctb.b01_nivel = 0
	END IF
	LET rm_ctb.b01_nivel = rm_ctb.b01_nivel + 1

	LET rm_ctb.b01_fecing = CURRENT
	INSERT INTO ctbt001 VALUES (rm_ctb.*)
	LET vm_num_rows = vm_num_rows + 1
	LET vm_row_current = vm_num_rows
        DISPLAY BY NAME rm_ctb.b01_fecing
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
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM ctbt001
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
	UPDATE ctbt001 SET b01_nombre = rm_ctb.b01_nombre,
			   b01_posicion_i = rm_ctb.b01_posicion_i,
			   b01_posicion_f = rm_ctb.b01_posicion_f
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
DEFINE cod_aux		LIKE ctbt001.b01_nivel
DEFINE nom_aux		LIKE ctbt001.b01_nombre
DEFINE psi_aux		LIKE ctbt001.b01_posicion_i
DEFINE psf_aux		LIKE ctbt001.b01_posicion_f
DEFINE query		VARCHAR(400)
DEFINE expr_sql		VARCHAR(400)
DEFINE num_reg		INTEGER

LET int_flag = 0
CLEAR FORM
CONSTRUCT BY NAME expr_sql ON b01_nivel, b01_nombre, b01_posicion_i,
	   b01_posicion_f
	ON KEY(F2)
	IF infield(b01_nivel) THEN
		CALL fl_ayuda_nivel_cuentas()
			RETURNING cod_aux, nom_aux, psi_aux, psf_aux
		LET int_flag = 0
		IF cod_aux IS NOT NULL THEN
			DISPLAY cod_aux TO b01_nivel 
			DISPLAY nom_aux TO b01_nombre
			DISPLAY psi_aux TO b01_posicion_i 
			DISPLAY psf_aux TO b01_posicion_f
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
LET query = 'SELECT *, ROWID FROM ctbt001 WHERE ' || expr_sql || ' ORDER BY 1'
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
DEFINE r_val_maxi	SMALLINT
DEFINE r_val_maxf	SMALLINT
DEFINE r_ctb_aux	RECORD LIKE ctbt001.*

LET int_flag = 0
LET r_val_maxi = 0
LET r_val_maxf = 0
INITIALIZE r_ctb_aux.* TO NULL
DISPLAY BY NAME rm_ctb.b01_usuario, rm_ctb.b01_fecing
INPUT BY NAME rm_ctb.b01_nivel,
	rm_ctb.b01_nombre,
  	rm_ctb.b01_posicion_i,
	rm_ctb.b01_posicion_f
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        IF field_touched(rm_ctb.b01_nivel,
		rm_ctb.b01_nombre,
  		rm_ctb.b01_posicion_i,
		rm_ctb.b01_posicion_f)
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
	BEFORE FIELD b01_nivel
		IF flag_mant = 'M' THEN
			NEXT FIELD NEXT
		END IF
	AFTER FIELD b01_nivel
		IF rm_ctb.b01_nivel IS NOT NULL THEN
			CALL fl_lee_nivel_cuenta(rm_ctb.b01_nivel)
                        	RETURNING r_ctb_aux.*
			IF rm_ctb.b01_nivel = r_ctb_aux.b01_nivel THEN
				CALL fgl_winmessage(vg_producto,'Nivel ya ha sido asignado','exclamation')
				NEXT FIELD b01_nivel
			END IF
		ELSE
			CLEAR b01_nivel
			CLEAR b01_nombre
		END IF
	AFTER FIELD b01_posicion_i
		IF rm_ctb.b01_posicion_i IS NOT NULL THEN
			SELECT MAX(b01_posicion_i) INTO r_val_maxi FROM ctbt001
			SELECT MAX(b01_posicion_f) INTO r_val_maxf FROM ctbt001
			IF r_val_maxi >= rm_ctb.b01_posicion_i OR
			r_val_maxf >= rm_ctb.b01_posicion_i THEN
				CALL fgl_winmessage(vg_producto,'Posición inicial no válida','exclamation')
				LET r_val_maxi = 0
				LET r_val_maxf = 0
				NEXT FIELD b01_posicion_i
			END IF
		ELSE
			CLEAR b01_posicion_i
		END IF
	AFTER FIELD b01_posicion_f
		IF rm_ctb.b01_posicion_f IS NOT NULL THEN
			SELECT MAX(b01_posicion_f) INTO r_val_maxf FROM ctbt001
			IF (r_val_maxf >= rm_ctb.b01_posicion_f OR
			rm_ctb.b01_posicion_f <= rm_ctb.b01_posicion_i) AND
			rm_ctb.b01_nivel > 2 THEN
				CALL fgl_winmessage(vg_producto,'Posición final no válida','exclamation')
				LET r_val_maxi = 0
				LET r_val_maxf = 0
				NEXT FIELD b01_posicion_f
			END IF
		ELSE
			CLEAR b01_posicion_f
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
	SELECT * INTO rm_ctb.* FROM ctbt001 WHERE ROWID=num_registro	
	IF STATUS = NOTFOUND THEN
		CALL fgl_winmessage (vg_producto,'No existe registro con índice: ' || vm_row_current,'exclamation')
		RETURN
	END IF
	DISPLAY BY NAME rm_ctb.b01_nivel,
			rm_ctb.b01_nombre,
  			rm_ctb.b01_posicion_i,
			rm_ctb.b01_posicion_f,
			rm_ctb.b01_usuario,
			rm_ctb.b01_fecing
ELSE
	RETURN
END IF

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
