------------------------------------------------------------------------------
-- Titulo           : cxcp103.4gl - Mantenimiento de Ejecutivos de Cuentas
-- Elaboracion      : 03-sep-2001
-- Autor            : RCA
-- Formato Ejecucion: fglrun cxcp103 base modulo compañía
-- Ultima Correccion: 
-- Motivo Correccion:  
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_titprog	VARCHAR(50)
DEFINE vm_rows		ARRAY[1000] OF INTEGER -- ARREGLO ROWID DE FILAS LEIDAS
DEFINE vm_row_current	SMALLINT	-- FILA CORRIENTE DEL ARREGLO
DEFINE vm_num_rows	SMALLINT	-- CANTIDAD DE FILAS LEIDAS
DEFINE vm_max_rows	SMALLINT	-- MAXIMO DE FILAS LEIDAS
DEFINE rm_cobra		RECORD LIKE cxct005.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cxcp103.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'cxcp103'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

LET vm_max_rows = 1000
OPEN WINDOW w_cia AT 3,2 WITH FORM '../forms/cxcf103_1'	
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
			MESSAGE LINE LAST) 
INITIALIZE rm_cobra.* TO NULL
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
	COMMAND KEY('B') 'Bloquear/Activar' 'Bloquear o Activar registro'
            CALL control_bloqueo()
	COMMAND KEY('S') 'Salir' 'Salir del programa'
		EXIT MENU
END MENU

END FUNCTION

 
  
FUNCTION control_consulta()
DEFINE codigo		LIKE cxct005.z05_codigo
DEFINE nombres		LIKE cxct005.z05_nombres
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE nom_trab		LIKE rolt030.n30_nombres
DEFINE expr_sql		VARCHAR(600)
DEFINE query		VARCHAR(1000)

CLEAR FORM
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON z05_estado, z05_codigo, z05_nombres, z05_tipo,
	z05_comision, z05_codrol 
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT CONSTRUCT
	ON KEY(F2)
		IF INFIELD(z05_codigo) THEN
			CALL fl_ayuda_cobradores(vg_codcia, 'T', 'T', 'T')
				RETURNING codigo, nombres
			IF codigo IS NOT NULL THEN
				LET rm_cobra.z05_codigo  = codigo
				LET rm_cobra.z05_nombres = nombres
				DISPLAY BY NAME rm_cobra.z05_codigo,
						rm_cobra.z05_nombres
			END IF
		END IF
		IF INFIELD(z05_codrol) THEN
			CALL fl_ayuda_codigo_empleado(vg_codcia)
				RETURNING cod_trab, nom_trab
			IF cod_trab IS NOT NULL THEN
				LET rm_cobra.z05_codrol = cod_trab
				DISPLAY BY NAME rm_cobra.z05_codrol
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
		'FROM cxct005 ',
		'WHERE z05_compania = ', vg_codcia,
		'  AND ', expr_sql CLIPPED,
		'ORDER BY z05_codigo '
PREPARE cons FROM query
DECLARE q_cobra CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cobra INTO rm_cobra.*, vm_rows[vm_num_rows]
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
DEFINE flag		CHAR(1)

IF rm_cobra.z05_estado <> 'A' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM cxct005 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_cobra.*
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
UPDATE cxct005
	SET * = rm_cobra.*
	WHERE CURRENT OF q_up
COMMIT WORK
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION

   

FUNCTION control_ingreso()
DEFINE max_cobra	LIKE cxct005.z05_codigo
DEFINE num_aux		INTEGER

CLEAR FORM
INITIALIZE rm_cobra.* TO NULL
LET rm_cobra.z05_compania =  vg_codcia
LET rm_cobra.z05_estado   = 'A'
LET rm_cobra.z05_comision = 'N'
LET rm_cobra.z05_tipo     = 'C'
LET rm_cobra.z05_fecing   = CURRENT
LET rm_cobra.z05_usuario  = vg_usuario 
DISPLAY 'ACTIVO' TO tit_estado
LET rm_cobra.z05_codigo   = 1
DISPLAY BY NAME rm_cobra.z05_fecing, rm_cobra.z05_usuario
CALL ingresa_datos('I')
IF NOT int_flag THEN
      	SELECT NVL(MAX(z05_codigo) + 1, 1)
		INTO max_cobra
		FROM cxct005
	IF max_cobra IS NULL THEN 
		LET max_cobra = 1
	END IF
	LET rm_cobra.z05_codigo = max_cobra  
	LET rm_cobra.z05_fecing = CURRENT
      	INSERT INTO cxct005 VALUES (rm_cobra.*)
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
IF vm_num_rows > 0 THEN
	CALL lee_muestra_registro(vm_rows[vm_row_current])
END IF
CALL muestra_contadores()

END FUNCTION




FUNCTION ingresa_datos(flag)
DEFINE flag		CHAR(1)
DEFINE resp   		CHAR(6)
DEFINE codigo		LIKE cxct005.z05_codigo
DEFINE nombres		LIKE cxct005.z05_nombres
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE nom_trab		LIKE rolt030.n30_nombres
DEFINE r		RECORD LIKE cxct005.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE cuantos		INTEGER

LET int_flag = 0 
INPUT BY NAME rm_cobra.z05_nombres, rm_cobra.z05_tipo, rm_cobra.z05_comision,
	rm_cobra.z05_codrol
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF FIELD_TOUCHED(rm_cobra.z05_nombres, rm_cobra.z05_tipo,
				 rm_cobra.z05_comision, rm_cobra.z05_codrol)
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
	ON KEY(F2)
		IF INFIELD(z05_codrol) THEN
			CALL fl_ayuda_codigo_empleado(vg_codcia)
				RETURNING cod_trab, nom_trab
			IF cod_trab IS NOT NULL THEN
				LET rm_cobra.z05_codrol = cod_trab
				DISPLAY BY NAME rm_cobra.z05_codrol
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD z05_codrol
		IF rm_cobra.z05_codrol IS NOT NULL THEN
			CALL fl_lee_trabajador_roles(vg_codcia,
							rm_cobra.z05_codrol)
				RETURNING r_n30.*
			IF r_n30.n30_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Código de Rol no existe en la compañía.', 'exclamation')
				NEXT FIELD z05_codrol
			END IF
			IF r_n30.n30_estado = 'I' THEN
				CALL fl_mostrar_mensaje('Código de Rol esta Inactivo en la compañía.', 'exclamation')
				NEXT FIELD z05_codrol
			END IF
		END IF
	AFTER INPUT
		IF flag = 'I' THEN
			SELECT COUNT(*) INTO cuantos
				FROM cxct005
				WHERE z05_compania = vg_codcia
				  AND z05_nombres  = rm_cobra.z05_nombres
			IF cuantos > 0 THEN
				CALL fl_mostrar_mensaje('Este cobrador ya ha sido ingresado en la compañía.', 'exclamation')
				NEXT FIELD z05_nombres
			END IF
		END IF
END INPUT
                                                                                
END FUNCTION



FUNCTION control_bloqueo()
DEFINE resp		CHAR(6)
DEFINE i		SMALLINT
DEFINE mensaje		VARCHAR(20)
DEFINE estado		CHAR(1)

LET int_flag = 0
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_blo CURSOR FOR
	SELECT * FROM cxct005 WHERE ROWID = vm_rows[vm_row_current]
	FOR UPDATE
OPEN q_blo
FETCH q_blo INTO rm_cobra.*
IF STATUS < 0 THEN
	WHENEVER ERROR STOP
	CALL fl_mensaje_bloqueo_otro_usuario()
	ROLLBACK WORK
	RETURN
END IF
WHENEVER ERROR STOP
LET mensaje = 'Seguro de bloquear ?'
LET estado  = 'B'
IF rm_cobra.z05_estado <> 'A' THEN
      LET mensaje = 'Seguro de activar ?'
      LET estado  = 'A'
END IF	
LET int_flag = 0
CALL fl_hacer_pregunta(mensaje, 'No') RETURNING resp
IF resp <> 'Yes' THEN
	ROLLBACK WORK
	CALL lee_muestra_registro(vm_rows[vm_row_current])
	RETURN
END IF
UPDATE cxct005
	SET z05_estado = estado
	WHERE CURRENT OF q_blo
COMMIT WORK
CALL lee_muestra_registro(vm_rows[vm_row_current])
CASE rm_cobra.z05_estado
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
SELECT * INTO rm_cobra.* FROM cxct005 WHERE ROWID = num_row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', num_row
END IF
DISPLAY BY NAME rm_cobra.z05_codigo THRU rm_cobra.z05_fecing
IF rm_cobra.z05_estado = 'A' THEN
	DISPLAY 'ACTIVO' TO tit_estado
ELSE
	DISPLAY 'BLOQUEADO' TO tit_estado
END IF

END FUNCTION



FUNCTION muestra_contadores() 

DISPLAY '' AT 1,1
DISPLAY vm_row_current, ' de ',vm_num_rows AT 1,70

END FUNCTION
