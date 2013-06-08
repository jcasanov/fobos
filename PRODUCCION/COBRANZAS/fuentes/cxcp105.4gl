------------------------------------------------------------------------------
-- Titulo           : cxcp105.4gl - MAntenimiento de Plazos para Crédito
-- Elaboracion      : 04-sep-2001
-- Autor            : RCA
-- Formato Ejecucion: fglrun programa.4gl base modulo 
-- Ultima Correccion: 24-ago-2001
-- Motivo Correccion: Standarización 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_titprog	VARCHAR(50)
DEFINE vm_rows ARRAY[1000] OF INTEGER  	-- ARREGLO DE ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows	SMALLINT	-- MAXIMO DE FILAS LEIDAS
DEFINE rm_cred		RECORD LIKE cxct007.*
MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'cxcp105'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

LET vm_max_rows = 1000
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
OPEN WINDOW  w_cia AT 4, 3 WITH FORM '../forms/cxcf105_1'	
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
INITIALIZE rm_cred.* TO NULL
LET vm_num_rows = 0
LET vm_row_current = 0
CALL muestra_contadores()
MENU 'PROCESOS'
	BEFORE MENU
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Bloquear/Activar'
	COMMAND KEY('I') 'Ingresar' 'Ingresar nuevos registos'
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
	COMMAND KEY('M') 'Modificar' 'Modificar registro corriente'
		IF vm_num_rows > 0 THEN
--			CALL control_modificacion()
		ELSE
			CALL fl_mensaje_consultar_primero()
		END IF	
	COMMAND KEY('C') 'Consultar' 'Consultar un registro'
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
	COMMAND KEY('S') 'Avanzar' 'Ver siguiente registro'
		IF vm_row_current < vm_num_rows THEN
			LET vm_row_current = vm_row_current + 1 
		END IF	
		CALL lee_muestra_registro(vm_rows[vm_row_current])
		CALL muestra_contadores()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('A') 'Retroceder'  'Ver anterior registro'
		IF vm_row_current > 1 THEN
			LET vm_row_current = vm_row_current - 1 
		END IF
		CALL lee_muestra_registro(vm_rows[vm_row_current])
		CALL muestra_contadores()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('B') 'Bloquear/Activar' 'Bloquear o activar registro'
--		CALL control_bloqueo()
	COMMAND KEY('S') 'Salir' 'Salir del programa'
		EXIT MENU
END MENU

END FUNCTION


 
FUNCTION control_consulta()
DEFINE codigo		LIKE cxct007.z07_serial
DEFINE monto_ini	LIKE cxct007.z07_monto_ini
DEFINE monto_fin	LIKE cxct007.z07_monto_fin
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON   z07_serial,
				z07_monto_ini,
				z07_monto_fin,
				z07_plazo_dias 
	ON KEY(F2)
		IF INFIELD(z07_serial) THEN
			CALL fl_ayuda_plazos_credito(vg_codcia)RETURNING codigo, monto_ini, monto_fin
			IF codigo IS NOT NULL THEN
				LET rm_cred.z07_serial = codigo
				DISPLAY BY NAME rm_cred.z07_serial
			END IF
		END IF
	ON KEY(interrupt)
		IF vm_row_current > 0 THEN
			CALL lee_muestra_registro(vm_rows[vm_row_current])
		END IF
		RETURN
END CONSTRUCT
IF int_flag THEN
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	CALL muestra_contadores()
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM cxct007 WHERE ', expr_sql CLIPPED
PREPARE cons FROM query
DECLARE q_cred CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cred INTO rm_cred.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
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
CLOSE q_cred
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL muestra_contadores()

END FUNCTION


{

FUNCTION control_modificacion()
DEFINE     	flag   CHAR(1)

WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_up CURSOR FOR SELECT * FROM gent001 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_cia.*
IF status < 0 THEN
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	COMMIT WORK
	RETURN
END IF
CALL ingresa_datos()
IF NOT int_flag THEN
    	UPDATE gent001 SET * = rm_cia.*
		WHERE CURRENT OF q_up
	CALL fl_mensaje_registro_modificado()
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF
COMMIT WORK

END FUNCTION

}

FUNCTION control_ingreso()

OPTIONS INPUT WRAP
CLEAR FORM
INITIALIZE rm_cred.* TO NULL

CALL ingresa_datos()
IF NOT int_flag THEN
	LET rm_cred.z07_serial = 0
	LET rm_cred.z07_compania = vg_codcia
	INSERT INTO cxct007 VALUES (rm_cred.*)
	LET rm_cred.z07_serial = SQLCA.SQLERRD[2]
	DISPLAY BY  NAME rm_cred.z07_serial
	CALL fl_mensaje_registro_ingresado()
	LET vm_num_rows = vm_num_rows + 1
	LET vm_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
	LET vm_row_current = vm_num_rows
END IF
IF vm_num_rows > 0 THEN
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF
CALL muestra_contadores()

END FUNCTION


{

FUNCTION control_bloqueo()
DEFINE resp    	CHAR(6)
DEFINE i		SMALLINT
DEFINE mensaje	VARCHAR(20)
DEFINE estado 	CHAR(1)

LET int_flag = 0
IF rm_cia.g01_compania IS NULL OR vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
WHENEVER ERROR CONTINUE
BEGIN WORK
DECLARE q_blo CURSOR FOR SELECT * FROM gent001 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_blo
FETCH q_blo INTO rm_cia.*
IF status < 0 THEN
        CALL fgl_winmessage(vg_producto,'Registro está bloquedo por otro usuario','exclamation')
	WHENEVER ERROR STOP
	COMMIT WORK
	RETURN
END IF
LET mensaje = 'Seguro de bloquear'
LET estado = 'B'
IF rm_cia.g01_estado <> 'A' THEN
	LET mensaje = 'Seguro de activar'
      	LET estado = 'A'
END IF	
CALL fl_mensaje_seguro_ejecutar_proceso()
	RETURNING resp
IF resp = 'Yes' THEN
	UPDATE gent001 set g01_estado = estado WHERE CURRENT OF q_blo
	DISPLAY 'BLOQUEADO' TO tit_estado
	DISPLAY 'B' TO g01_estado
	LET int_flag = 1
	CALL fl_mensaje_registro_modificado()
	WHENEVER ERROR STOP	
	COMMIT WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF
CALL muestra_contadores()

END FUNCTION

}



FUNCTION ingresa_datos()
DEFINE           	resp    CHAR(6)
DEFINE cia		LIKE gent001.g01_compania
OPTIONS INPUT WRAP
LET int_flag = 0 
INPUT BY NAME 	rm_cred.z07_monto_ini, 	rm_cred.z07_monto_fin,
		rm_cred.z07_plazo_dias 
		WITHOUT DEFAULTS                                                           
	ON KEY (INTERRUPT)
		IF field_touched(rm_cred.z07_monto_ini,	
				rm_cred.z07_monto_fin,
				rm_cred.z07_plazo_dias
				) THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
				RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				RETURN
			END IF
		ELSE
			RETURN
		END IF
END INPUT
                                                                                
END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_cred.* FROM cxct007 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_cred.z07_serial, rm_cred.z07_monto_ini THRU rm_cred.z07_plazo_dias
END FUNCTION



FUNCTION muestra_contadores() 

DISPLAY '' AT 1,1
DISPLAY vm_row_current, ' de ',vm_num_rows AT 1,70

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




