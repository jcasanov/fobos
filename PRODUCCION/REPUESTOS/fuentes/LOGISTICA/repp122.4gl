--------------------------------------------------------------------------------
-- Titulo           : repp122.4gl - Mantenimiento de Choferes
-- Elaboracion      : 18-jul-2013
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp122 base modulo compania localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_rows		ARRAY[1000] OF INTEGER
DEFINE vm_row_current	SMALLINT
DEFINE vm_num_rows	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE rm_r111		RECORD LIKE rept111.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp122.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN	-- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp122'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
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
LET lin_menu    = 0
LET row_ini     = 3
LET num_rows    = 16
LET num_cols    = 80
IF vg_gui = 0 THEN        
	LET lin_menu = 1
	LET row_ini  = 2
	LET num_rows = 22
	LET num_cols = 78
END IF                  
OPEN WINDOW w_repp122_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,   
		  BORDER, MESSAGE LINE LAST - 1)                                
IF vg_gui = 1 THEN
	OPEN FORM f_repf122_1 FROM '../forms/repf122_1'
ELSE
	OPEN FORM f_repf122_1 FROM '../forms/repf122_1c'
END IF
DISPLAY FORM f_repf122_1
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU	
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Bloquear/Activar'
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
	COMMAND KEY('I') 'Ingresar' 	'Ingresar nuevos registros.'
		CALL control_ingreso()
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
        COMMAND KEY('M') 'Modificar'	'Modifica el registro actual.'
		CALL control_modificacion()
        COMMAND KEY('C') 'Consultar'    'Consultar un registro.'
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
        COMMAND KEY('B') 'Bloquear/Activar'	'Bloquea o Activa un registro.'
		CALL control_bloquear_activar()
	COMMAND KEY('A') 'Avanzar' 	'Ver siguiente registro.'
		CALL siguiente_registro()
		IF vm_row_current = vm_num_rows THEN
			HIDE OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
			NEXT OPTION 'Retroceder'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('R') 'Retroceder' 	'Ver anterior registro.'
		CALL anterior_registro()
		IF vm_row_current = 1 THEN
			HIDE OPTION 'Retroceder'
			SHOW OPTION 'Avanzar'
			NEXT OPTION 'Avanzar'
		ELSE
			SHOW OPTION 'Avanzar'
			SHOW OPTION 'Retroceder'
		END IF
	COMMAND KEY('S') 'Salir'    	'Salir del programa.'
		EXIT MENU
END MENU
CLOSE WINDOW w_repp122_1
EXIT PROGRAM

END FUNCTION



FUNCTION muestra_contadores(num_reg, max_reg)
DEFINE num_reg, max_reg	SMALLINT

DISPLAY BY NAME num_reg, max_reg

END FUNCTION



FUNCTION control_ingreso()
DEFINE num_aux		INTEGER

CLEAR FORM
INITIALIZE rm_r111.* TO NULL
LET rm_r111.r111_compania  = vg_codcia
LET rm_r111.r111_localidad = vg_codloc
LET rm_r111.r111_estado    = "A"
LET rm_r111.r111_usuario   = vg_usuario
LET rm_r111.r111_fecing    = CURRENT
DISPLAY BY NAME rm_r111.r111_usuario, rm_r111.r111_fecing
CALL muestra_estado()
CALL lee_cabecera('I')
IF int_flag THEN
	CALL muestra_salir()
	RETURN
END IF
BEGIN WORK
WHILE TRUE
	SELECT NVL(MAX(r111_cod_chofer) + 1, 1)
		INTO rm_r111.r111_cod_chofer
		FROM rept111
		WHERE r111_compania  = rm_r111.r111_compania
		  AND r111_localidad = rm_r111.r111_localidad
		  AND r111_cod_trans = rm_r111.r111_cod_trans
	LET rm_r111.r111_fecing = CURRENT
	WHENEVER ERROR CONTINUE
	INSERT INTO rept111 VALUES (rm_r111.*)
	IF STATUS = 0 THEN
		LET num_aux = SQLCA.SQLERRD[6]
		WHENEVER ERROR STOP
		EXIT WHILE
	END IF
END WHILE
COMMIT WORK
IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows  = 1
ELSE
	LET vm_num_rows  = vm_num_rows + 1
END IF
LET vm_row_current       = vm_num_rows
LET vm_rows[vm_num_rows] = num_aux
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()

CALL lee_muestra_registro(vm_rows[vm_row_current])
IF rm_r111.r111_estado <> 'A' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_modif CURSOR FOR
	SELECT * FROM rept111
		WHERE ROWID = vm_rows[vm_row_current]
		FOR UPDATE
OPEN q_modif
FETCH q_modif INTO rm_r111.*
IF STATUS <> 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe el registro de este chofer. Por favor LLAME AL ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
CALL lee_cabecera('M')
IF int_flag THEN
	ROLLBACK WORK
	CALL muestra_salir()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR CONTINUE
UPDATE rept111
	SET * = rm_r111.*
	WHERE CURRENT OF q_modif
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo MODIFICAR el registro de este chofer. Por favor LLAME AL ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
COMMIT WORK
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(1000)
DEFINE query		CHAR(2000)
DEFINE r_r110		RECORD LIKE rept110.*
DEFINE r_r111		RECORD LIKE rept111.*
DEFINE r_n30		RECORD LIKE rolt030.*

CLEAR FORM
INITIALIZE rm_r111.*, r_r110.*, r_r111.*, r_n30.* TO NULL
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON r111_estado, r111_cod_trans, r111_cod_chofer,
	r111_nombre, r111_cod_trab, r111_usuario, r111_fecing
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT CONSTRUCT
	ON KEY(F2)
		IF INFIELD(r111_cod_trans) THEN
			CALL fl_ayuda_transporte(vg_codcia, vg_codloc, "T")
				RETURNING r_r110.r110_cod_trans,
					  r_r110.r110_descripcion
		      	IF r_r110.r110_cod_trans IS NOT NULL THEN
				DISPLAY r_r110.r110_cod_trans TO r111_cod_trans
				DISPLAY BY NAME r_r110.r110_descripcion
		      	END IF
		END IF
		IF INFIELD(r111_cod_chofer) AND
		   r_r110.r110_cod_trans IS NOT NULL
		THEN
			CALL fl_ayuda_chofer(vg_codcia, vg_codloc,
						r_r110.r110_cod_trans, "T")
				RETURNING r_r111.r111_cod_chofer,
					  r_r111.r111_nombre
		      	IF r_r111.r111_cod_chofer IS NOT NULL THEN
				DISPLAY BY NAME r_r111.r111_cod_chofer,
						r_r111.r111_nombre
		      	END IF
		END IF
		IF INFIELD(r111_cod_trab) THEN
			CALL fl_ayuda_codigo_empleado(vg_codcia)
				RETURNING r_n30.n30_cod_trab, r_n30.n30_nombres
		      	IF r_n30.n30_cod_trab IS NOT NULL THEN
				DISPLAY r_n30.n30_cod_trab TO r111_cod_trab
		      	END IF
		END IF
		LET int_flag = 0
	AFTER FIELD r111_cod_trans
		LET rm_r111.r111_cod_trans = GET_FLDBUF(r111_cod_trans)
		IF rm_r111.r111_cod_trans IS NOT NULL THEN
			CALL fl_lee_transporte(vg_codcia, vg_codloc,
						rm_r111.r111_cod_trans)
				RETURNING r_r110.*
			IF r_r110.r110_cod_trans IS NULL THEN
				CALL fl_mostrar_mensaje('Esta transporte no existe en la compañía.', 'exclamation')
				NEXT FIELD r111_cod_trans
			END IF
			LET rm_r111.r111_cod_trans = r_r110.r110_cod_trans
		ELSE
			INITIALIZE r_r110.*, r_r111.*, rm_r111.r111_cod_chofer
				TO NULL
		END IF
		DISPLAY BY NAME r_r110.r110_descripcion,
				rm_r111.r111_cod_chofer,
				r_r111.r111_nombre
	AFTER FIELD r111_cod_chofer
		LET rm_r111.r111_cod_chofer = GET_FLDBUF(r111_cod_chofer)
		IF rm_r111.r111_cod_chofer IS NOT NULL THEN
			CALL fl_lee_chofer(vg_codcia, vg_codloc,
						rm_r111.r111_cod_trans,
						rm_r111.r111_cod_chofer)
				RETURNING r_r111.*
			IF r_r111.r111_cod_trans IS NULL THEN
				CALL fl_mostrar_mensaje('Este chofer no existe en la compañía.', 'exclamation')
				NEXT FIELD r111_cod_chofer
			END IF
			LET rm_r111.r111_cod_chofer = r_r111.r111_cod_chofer
		ELSE
			INITIALIZE r_r111.* TO NULL
		END IF
		DISPLAY BY NAME r_r111.r111_nombre
	AFTER FIELD r111_cod_trab
		LET rm_r111.r111_cod_trab = GET_FLDBUF(r111_cod_trab)
		IF rm_r111.r111_cod_trab IS NOT NULL THEN
			CALL fl_lee_trabajador_roles(vg_codcia,
							rm_r111.r111_cod_trab)
				RETURNING r_n30.*
			IF r_n30.n30_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Este código de rol no existe en la compañía.', 'exclamation')
				NEXT FIELD r111_cod_trab
			END IF
			LET rm_r111.r111_cod_trab = r_n30.n30_cod_trab
		ELSE
			INITIALIZE r_n30.* TO NULL
		END IF
END CONSTRUCT
IF int_flag THEN
	CALL muestra_salir()
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM rept111 ',
		' WHERE r111_compania  = ', vg_codcia,
		'   AND r111_localidad = ', vg_codloc,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 3 ' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_r111.*, vm_rows[vm_num_rows]
	LET vm_num_rows = vm_num_rows + 1
        IF vm_num_rows > vm_max_rows THEN
		EXIT FOREACH
	END IF	
END FOREACH 
LET vm_num_rows = vm_num_rows - 1
IF vm_num_rows = 0 THEN 
	CALL fl_mensaje_consulta_sin_registros()
	LET vm_num_rows    = 0
	LET vm_row_current = 0
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	CLEAR FORM
	RETURN
END IF
LET vm_row_current = 1
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION control_bloquear_activar()
DEFINE resp		CHAR(6)
DEFINE mensaje		VARCHAR(100)
DEFINE estado		LIKE rept111.r111_estado

CALL lee_muestra_registro(vm_rows[vm_row_current])
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_bloact CURSOR FOR
	SELECT * FROM rept111
		WHERE ROWID = vm_rows[vm_row_current]
		FOR UPDATE
OPEN q_bloact
FETCH q_bloact INTO rm_r111.*
IF STATUS <> 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe el registro de esta sub-transporte. Por favor LLAME AL ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
LET estado  = 'B'
LET mensaje = 'Seguro de BLOQUEAR'
IF rm_r111.r111_estado <> 'A' THEN
	LET mensaje = 'Seguro de ACTIVAR'
	LET estado  = 'A'
END IF
LET mensaje = mensaje CLIPPED, ' de este registro ?'
CALL fl_hacer_pregunta(mensaje, 'No') RETURNING resp
IF resp <> 'Yes' THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR CONTINUE
UPDATE rept111
	SET r111_estado = estado
	WHERE CURRENT OF q_bloact
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo BLOQUEAR/ACTIVAR el registro de esta sub-transporte. Por favor LLAME AL ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
COMMIT WORK
CALL lee_muestra_registro(vm_rows[vm_row_current])
LET mensaje = 'El registro ha sido ACTIVADO OK.'
IF rm_r111.r111_estado <> 'A' THEN
	LET mensaje = 'El registro ha sido BLOQUEADO OK.'
END IF
CALL fl_mostrar_mensaje(mensaje, 'info')

END FUNCTION



FUNCTION siguiente_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF
IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION anterior_registro()

IF vm_num_rows = 0 THEN
	RETURN
END IF
IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION muestra_estado()
DEFINE tit_estado	VARCHAR(15)

LET tit_estado = NULL
CASE rm_r111.r111_estado
	WHEN 'A' LET tit_estado = 'ACTIVO'
	WHEN 'B' LET tit_estado = 'BLOQUEADO'
END CASE
DISPLAY BY NAME rm_r111.r111_estado, tit_estado

END FUNCTION



FUNCTION lee_cabecera(flag)
DEFINE flag		CHAR(1)
DEFINE r_r110		RECORD LIKE rept110.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE cod_chofer	LIKE rept111.r111_cod_chofer
DEFINE resp		CHAR(6)

INITIALIZE r_n30.*, r_r110.* TO NULL
LET int_flag = 0
INPUT BY NAME rm_r111.r111_cod_trans, rm_r111.r111_nombre, rm_r111.r111_cod_trab
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF FIELD_TOUCHED(rm_r111.r111_cod_trans,rm_r111.r111_nombre,
				 rm_r111.r111_cod_trab)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
		ELSE
			LET int_flag = 1
			EXIT INPUT
		END IF
	ON KEY(F2)
		IF INFIELD(r111_cod_trans) AND flag = 'I' THEN
			CALL fl_ayuda_transporte(vg_codcia, vg_codloc, "A")
				RETURNING r_r110.r110_cod_trans,
					  r_r110.r110_descripcion
		      	IF r_r110.r110_cod_trans IS NOT NULL THEN
				LET rm_r111.r111_cod_trans =
							r_r110.r110_cod_trans
				DISPLAY BY NAME rm_r111.r111_cod_trans,
						r_r110.r110_descripcion
		      	END IF
		END IF
		IF INFIELD(r111_cod_trab) THEN
			CALL fl_ayuda_codigo_empleado(vg_codcia)
				RETURNING r_n30.n30_cod_trab, r_n30.n30_nombres
		      	IF r_n30.n30_cod_trab IS NOT NULL THEN
				LET rm_r111.r111_cod_trab = r_n30.n30_cod_trab
				DISPLAY BY NAME rm_r111.r111_cod_trab
		      	END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD r111_cod_trans
		IF flag = 'M' THEN
			LET r_r110.r110_cod_trans = rm_r111.r111_cod_trans
		END IF
	AFTER FIELD r111_cod_trans
		IF flag = 'M' THEN
			LET rm_r111.r111_cod_trans = r_r110.r110_cod_trans
			DISPLAY BY NAME rm_r111.r111_cod_trans
			CONTINUE INPUT
		END IF
		IF rm_r111.r111_cod_trans IS NOT NULL THEN
			CALL fl_lee_transporte(vg_codcia, vg_codloc,
						rm_r111.r111_cod_trans)
				RETURNING r_r110.*
			IF r_r110.r110_cod_trans IS NULL THEN
				CALL fl_mostrar_mensaje('Esta transporte no existe en la compañía.', 'exclamation')
				NEXT FIELD r111_cod_trans
			END IF
			IF r_r110.r110_estado = 'B' THEN
				CALL fl_mostrar_mensaje('Esta transporte esta con estado BLOQUEADO.', 'exclamation')
				NEXT FIELD r111_cod_trans
			END IF
		ELSE
			INITIALIZE r_r110.* TO NULL
		END IF
		DISPLAY BY NAME r_r110.r110_descripcion
	AFTER FIELD r111_nombre
		IF rm_r111.r111_nombre IS NOT NULL THEN
			IF r_n30.n30_nombres IS NOT NULL THEN
				LET rm_r111.r111_nombre = r_n30.n30_nombres
				DISPLAY BY NAME rm_r111.r111_nombre
			END IF
		END IF
	AFTER FIELD r111_cod_trab
		IF rm_r111.r111_cod_trab IS NOT NULL THEN
			CALL fl_lee_trabajador_roles(vg_codcia,
							rm_r111.r111_cod_trab)
				RETURNING r_n30.*
			IF r_n30.n30_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Este código de rol no existe en la compañía.', 'exclamation')
				NEXT FIELD r111_cod_trab
			END IF
			IF r_n30.n30_estado = 'I' THEN
				CALL fl_mostrar_mensaje('Esta código de rol esta con estado INACTIVO.', 'exclamation')
				NEXT FIELD r111_cod_trab
			END IF
			IF ((vg_codloc = 1 AND r_n30.n30_cod_depto <> 13) OR
			    (vg_codloc = 3 AND r_n30.n30_cod_depto <> 8))
			THEN
				CALL fl_mostrar_mensaje('Esta código de rol no pertenece al departmento de Choferes/Transporte.', 'exclamation')
				--NEXT FIELD r111_cod_trab
			END IF
			LET rm_r111.r111_nombre = r_n30.n30_nombres
			DISPLAY BY NAME rm_r111.r111_nombre
		ELSE
			INITIALIZE r_n30.* TO NULL
		END IF
	AFTER INPUT
		LET cod_chofer = NULL
		SELECT r111_cod_chofer
			INTO cod_chofer
			FROM rept111
			WHERE r111_compania   = vg_codcia
			  AND r111_localidad  = vg_codloc
			  AND r111_cod_trans  = rm_r111.r111_cod_trans
			  AND r111_nombre     = rm_r111.r111_nombre
			  AND r111_estado     = 'A'
		IF (cod_chofer IS NOT NULL AND
		    (rm_r111.r111_cod_chofer IS NULL OR
		     cod_chofer <> rm_r111.r111_cod_chofer))
		THEN
			CALL fl_mostrar_mensaje('Ya fue asignado este Chofer a éste Transporte en la compañía.', 'exclamation')
			NEXT FIELD r111_nombre
		END IF
END INPUT

END FUNCTION



FUNCTION muestra_salir()

IF vm_num_rows = 0 THEN
	CLEAR FORM
	RETURN
END IF
CALL lee_muestra_registro(vm_rows[vm_row_current])

END FUNCTION



FUNCTION lee_muestra_registro(row)
DEFINE row		INTEGER
DEFINE r_r110		RECORD LIKE rept110.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_r111.* FROM rept111 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', row
END IF
DISPLAY BY NAME rm_r111.r111_estado, rm_r111.r111_cod_trans,
		rm_r111.r111_cod_chofer, rm_r111.r111_nombre,
		rm_r111.r111_cod_trab, rm_r111.r111_usuario, rm_r111.r111_fecing
CALL fl_lee_transporte(vg_codcia, vg_codloc, rm_r111.r111_cod_trans)
	RETURNING r_r110.*
DISPLAY BY NAME r_r110.r110_descripcion
CALL muestra_estado()
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION
