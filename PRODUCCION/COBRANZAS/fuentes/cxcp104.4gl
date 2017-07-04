--------------------------------------------------------------------------------
-- Titulo           : cxcp104.4gl - Mantenimiento de Zonas de Cobro
-- Elaboracion      : 02-sep-2001
-- Autor            : RCA
-- Formato Ejecucion: fglrun cxcp104 base modulo compañía
-- Ultima Correccion: 
-- Motivo Correccion:  
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_titprog	VARCHAR(50)
DEFINE vm_rows		ARRAY[1000] OF INTEGER -- ARREGLO ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows	SMALLINT	-- MAXIMO DE FILAS LEIDAS
DEFINE rm_zoncob	RECORD LIKE cxct006.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp104.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'cxcp104'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

LET vm_max_rows = 1000
OPEN WINDOW w_cia AT 3,2 WITH FORM '../forms/cxcf104_1'	
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST) 
INITIALIZE rm_zoncob.* TO NULL
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
			CALL control_modificacion()
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
		IF vm_row_current <= 1 THEN
                        HIDE OPTION 'Retroceder'
                END IF
	COMMAND KEY('B') 'Bloquear/Activar' 'Bloquear o Activar registro'
		CALL control_bloqueo()
	COMMAND KEY('A') 'Avanzar' 'Ver siguiente registro'
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
	COMMAND KEY('R') 'Retroceder'  'Ver anterior registro'
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
	COMMAND KEY('S') 'Salir' 'Salir del programa'
		EXIT MENU
END MENU

END FUNCTION

 
 
FUNCTION control_consulta()
DEFINE zona_cobro	LIKE cxct006.z06_zona_cobro
DEFINE nombre		LIKE cxct006.z06_nombre
DEFINE expr_sql		VARCHAR(500)
DEFINE query		VARCHAR(600)

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON z06_estado, z06_zona_cobro, z06_nombre,
		z06_comision, z06_usuario, z06_fecing
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT CONSTRUCT
	ON KEY(F2)
		IF INFIELD(z06_zona_cobro) THEN
			CALL fl_ayuda_zona_cobro('T', 'T')
				RETURNING zona_cobro, nombre
			IF zona_cobro IS NOT NULL THEN
				LET rm_zoncob.z06_zona_cobro = zona_cobro
				LET rm_zoncob.z06_nombre     = nombre
				DISPLAY BY NAME rm_zoncob.z06_zona_cobro,
						rm_zoncob.z06_nombre
			END IF
		END IF
		LET int_flag = 0
END CONSTRUCT
IF int_flag THEN
	IF vm_row_current > 0 THEN
		CALL lee_muestra_registro(vm_rows[vm_row_current])
	END IF
	RETURN
END IF
LET query = 'SELECT *, ROWID ',
		'FROM cxct006 ',
		'WHERE ', expr_sql CLIPPED,
		'ORDER BY z06_zona_cobro '
PREPARE cons FROM query
DECLARE q_zoncob CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_zoncob INTO rm_zoncob.*, vm_rows[vm_num_rows]
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
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL muestra_contadores()

END FUNCTION



FUNCTION control_modificacion()

IF rm_zoncob.z06_estado <> 'A' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM cxct006
		WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_zoncob.*
IF STATUS < 0 THEN
	WHENEVER ERROR STOP
	CALL fl_mensaje_bloqueo_otro_usuario()
	ROLLBACK WORK
	RETURN
END IF
WHENEVER ERROR STOP
CALL ingresa_datos('M')
IF int_flag THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF
UPDATE cxct006
	SET * = rm_zoncob.*
	WHERE CURRENT OF q_up
COMMIT WORK
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION

  

FUNCTION control_ingreso()
DEFINE max_zona		LIKE cxct006.z06_zona_cobro
DEFINE num_aux		INTEGER

CLEAR FORM
INITIALIZE rm_zoncob.* TO NULL
LET rm_zoncob.z06_estado   = 'A'
LET rm_zoncob.z06_comision = 'N'
LET rm_zoncob.z06_fecing   = CURRENT
LET rm_zoncob.z06_usuario  = vg_usuario 
DISPLAY 'ACTIVO' TO tit_estado
DISPLAY BY NAME rm_zoncob.z06_fecing, rm_zoncob.z06_usuario
CALL ingresa_datos('I')
IF NOT int_flag THEN
      	SELECT NVL(MAX(z06_zona_cobro) + 1, 1)
		INTO max_zona
		FROM cxct006
	IF max_zona IS NULL THEN 
		LET max_zona = 1
	END IF
      	LET rm_zoncob.z06_zona_cobro = max_zona
	LET rm_zoncob.z06_fecing     = CURRENT
      	INSERT INTO cxct006 VALUES (rm_zoncob.*)
	LET num_aux = SQLCA.SQLERRD[6] 
	IF vm_num_rows = vm_max_rows THEN
		LET vm_num_rows = 1
	ELSE
		LET vm_num_rows = vm_num_rows + 1
	END IF
	LET vm_row_current          = vm_num_rows
	LET vm_rows[vm_row_current] = num_aux
	CALL fl_mensaje_registro_ingresado()
END IF
CLEAR FORM
IF vm_num_rows > 0 THEN
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF
CALL muestra_contadores()

END FUNCTION



FUNCTION ingresa_datos(flag)
DEFINE flag		CHAR(1)
DEFINE resp   		CHAR(6)
DEFINE cuantos		INTEGER

LET int_flag = 0 
INPUT BY NAME rm_zoncob.z06_nombre, rm_zoncob.z06_comision
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_zoncob.z06_nombre, rm_zoncob.z06_comision)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
		ELSE
			CLEAR FORM
			EXIT INPUT
		END IF
	AFTER INPUT
		IF flag = 'I' THEN
			SELECT COUNT(*) INTO cuantos
				FROM cxct006
				WHERE z06_nombre = rm_zoncob.z06_nombre
			IF cuantos > 0 THEN
				CALL fl_mostrar_mensaje('Esta zona de cobro ya ha sido ingresada en la compañía.', 'exclamation')
				NEXT FIELD z06_nombre
			END IF
		END IF
END INPUT
                                                                                
END FUNCTION



FUNCTION control_bloqueo()
DEFINE resp		CHAR(6)
DEFINE mensaje		VARCHAR(40)
DEFINE estado		CHAR(1)

LET int_flag = 0
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_blo CURSOR FOR
	SELECT * FROM cxct006
		WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_blo
FETCH q_blo INTO rm_zoncob.*
IF STATUS < 0 THEN
	WHENEVER ERROR STOP
	CALL fl_mensaje_bloqueo_otro_usuario()
	ROLLBACK WORK
	RETURN
END IF
WHENEVER ERROR STOP
LET mensaje = 'Seguro de BLOQUEAR ?'
LET estado  = 'B'
IF rm_zoncob.z06_estado <> 'A' THEN
	LET mensaje = 'Seguro de ACTIVAR ?'
	LET estado  = 'A'
END IF	
LET int_flag = 0
CALL fl_hacer_pregunta(mensaje, 'No') RETURNING resp
IF resp <> 'Yes' THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF
UPDATE cxct006
	SET z06_estado = estado
	WHERE CURRENT OF q_blo
COMMIT WORK
CALL lee_muestra_registro(vm_rows[vm_row_current])
CASE rm_zoncob.z06_estado
	WHEN 'A' LET mensaje = 'Registro ha sido ACTIVADO. OK'
	WHEN 'B' LET mensaje = 'Registro ha sido BLOQUEADO. OK'
END CASE
CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION



FUNCTION lee_muestra_registro(num_row)
DEFINE num_row		INTEGER

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_zoncob.* FROM cxct006 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_zoncob.z06_zona_cobro THRU rm_zoncob.z06_fecing
IF rm_zoncob.z06_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado
ELSE
	DISPLAY 'BLOQUEADO' TO tit_estado
END IF

END FUNCTION



FUNCTION muestra_contadores() 

DISPLAY '' AT 1,1
DISPLAY vm_row_current, ' de ',vm_num_rows AT 1,70

END FUNCTION
