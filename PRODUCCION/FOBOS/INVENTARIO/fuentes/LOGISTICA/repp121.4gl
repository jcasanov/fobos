--------------------------------------------------------------------------------
-- Titulo           : repp121.4gl - Mantenimiento de Transporte
-- Elaboracion      : 18-jul-2013
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp121 base modulo compania localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_rows		ARRAY[1000] OF INTEGER
DEFINE vm_row_current	SMALLINT
DEFINE vm_num_rows	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE rm_r110		RECORD LIKE rept110.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp121.err')
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
LET vg_proceso = 'repp121'
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
LET num_rows    = 14
LET num_cols    = 80
IF vg_gui = 0 THEN        
	LET lin_menu = 1
	LET row_ini  = 2
	LET num_rows = 22
	LET num_cols = 78
END IF                  
OPEN WINDOW w_repp121_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,   
		  BORDER, MESSAGE LINE LAST - 1)                                
IF vg_gui = 1 THEN
	OPEN FORM f_repf121_1 FROM '../forms/repf121_1'
ELSE
	OPEN FORM f_repf121_1 FROM '../forms/repf121_1c'
END IF
DISPLAY FORM f_repf121_1
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
CLOSE WINDOW w_repp121_1
EXIT PROGRAM

END FUNCTION



FUNCTION muestra_contadores(num_reg, max_reg)
DEFINE num_reg, max_reg	SMALLINT

DISPLAY BY NAME num_reg, max_reg

END FUNCTION



FUNCTION control_ingreso()
DEFINE num_aux		INTEGER

CLEAR FORM
INITIALIZE rm_r110.* TO NULL
LET rm_r110.r110_compania  = vg_codcia
LET rm_r110.r110_localidad = vg_codloc
LET rm_r110.r110_estado    = "A"
LET rm_r110.r110_usuario   = vg_usuario
LET rm_r110.r110_fecing    = CURRENT
DISPLAY BY NAME rm_r110.r110_usuario, rm_r110.r110_fecing
CALL muestra_estado()
CALL lee_cabecera('I')
IF int_flag THEN
	CALL muestra_salir()
	RETURN
END IF
BEGIN WORK
WHILE TRUE
	SELECT NVL(MAX(r110_cod_trans) + 1, 1)
		INTO rm_r110.r110_cod_trans
		FROM rept110
		WHERE r110_compania  = rm_r110.r110_compania
		  AND r110_localidad = rm_r110.r110_localidad
	LET rm_r110.r110_fecing = CURRENT
	WHENEVER ERROR CONTINUE
	INSERT INTO rept110 VALUES (rm_r110.*)
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
IF rm_r110.r110_estado <> 'A' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_modif CURSOR FOR
	SELECT * FROM rept110
		WHERE ROWID = vm_rows[vm_row_current]
		FOR UPDATE
OPEN q_modif
FETCH q_modif INTO rm_r110.*
IF STATUS <> 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe el registro de este transporte. Por favor LLAME AL ADMINISTRADOR.', 'stop')
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
UPDATE rept110
	SET * = rm_r110.*
	WHERE CURRENT OF q_modif
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo MODIFICAR el registro de este transporte. Por favor LLAME AL ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
COMMIT WORK
CALL lee_muestra_registro(vm_rows[vm_row_current])
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION control_consulta()
DEFINE expr_sql		CHAR(800)
DEFINE query		CHAR(1500)
DEFINE r_r110		RECORD LIKE rept110.*

CLEAR FORM
INITIALIZE r_r110.* TO NULL
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON r110_estado, r110_cod_trans, r110_descripcion,
	r110_placa, r110_usuario, r110_fecing
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT CONSTRUCT
	ON KEY(F2)
		IF INFIELD(r110_cod_trans) THEN
			CALL fl_ayuda_transporte(vg_codcia, vg_codloc, "T")
				RETURNING r_r110.r110_cod_trans,
					  r_r110.r110_descripcion
		      	IF r_r110.r110_cod_trans IS NOT NULL THEN
				DISPLAY BY NAME r_r110.r110_cod_trans,
						r_r110.r110_descripcion
		      	END IF
		END IF
		LET int_flag = 0
	AFTER FIELD r110_cod_trans
		LET rm_r110.r110_cod_trans = GET_FLDBUF(r110_cod_trans)
		IF rm_r110.r110_cod_trans IS NOT NULL THEN
			CALL fl_lee_transporte(vg_codcia, vg_codloc,
						rm_r110.r110_cod_trans)
				RETURNING r_r110.*
			IF r_r110.r110_cod_trans IS NULL THEN
				CALL fl_mostrar_mensaje('Este transporte no existe en la compañía.', 'exclamation')
				NEXT FIELD r110_cod_trans
			END IF
			LET rm_r110.r110_cod_trans = r_r110.r110_cod_trans
		ELSE
			INITIALIZE r_r110.* TO NULL
		END IF
		DISPLAY BY NAME r_r110.r110_descripcion
END CONSTRUCT
IF int_flag THEN
	CALL muestra_salir()
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM rept110 ',
		' WHERE r110_compania  = ', vg_codcia,
		'   AND r110_localidad = ', vg_codloc,
		'   AND ', expr_sql CLIPPED,
		' ORDER BY 3 ' 
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 1
FOREACH q_cons INTO rm_r110.*, vm_rows[vm_num_rows]
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
DEFINE estado		LIKE rept110.r110_estado

CALL lee_muestra_registro(vm_rows[vm_row_current])
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_bloact CURSOR FOR
	SELECT * FROM rept110
		WHERE ROWID = vm_rows[vm_row_current]
		FOR UPDATE
OPEN q_bloact
FETCH q_bloact INTO rm_r110.*
IF STATUS <> 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
IF STATUS = NOTFOUND THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No existe el registro de este transporte. Por favor LLAME AL ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
LET estado  = 'B'
LET mensaje = 'Seguro de BLOQUEAR'
IF rm_r110.r110_estado <> 'A' THEN
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
UPDATE rept110
	SET r110_estado = estado
	WHERE CURRENT OF q_bloact
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('No se pudo BLOQUEAR/ACTIVAR el registro de este transporte. Por favor LLAME AL ADMINISTRADOR.', 'stop')
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
COMMIT WORK
CALL lee_muestra_registro(vm_rows[vm_row_current])
LET mensaje = 'El registro ha sido ACTIVADO OK.'
IF rm_r110.r110_estado <> 'A' THEN
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
CASE rm_r110.r110_estado
	WHEN 'A' LET tit_estado = 'ACTIVO'
	WHEN 'B' LET tit_estado = 'BLOQUEADO'
END CASE
DISPLAY BY NAME rm_r110.r110_estado, tit_estado

END FUNCTION



FUNCTION lee_cabecera(flag)
DEFINE flag		CHAR(1)
DEFINE cod_trans	LIKE rept110.r110_cod_trans
DEFINE resp		CHAR(6)

LET int_flag = 0
INPUT BY NAME rm_r110.r110_descripcion, rm_r110.r110_placa
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF FIELD_TOUCHED(rm_r110.r110_descripcion, rm_r110.r110_placa)
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
	AFTER FIELD r110_placa
		IF rm_r110.r110_placa IS NOT NULL THEN
			LET cod_trans = NULL
			SELECT r110_cod_trans
				INTO cod_trans
				FROM rept110
				WHERE r110_compania  = vg_codcia
				  AND r110_localidad = vg_codloc
				  AND r110_placa     = rm_r110.r110_placa
				  AND r110_estado    = 'A'
			IF (cod_trans IS NOT NULL AND
			   (rm_r110.r110_cod_trans IS NULL OR
			    cod_trans <> rm_r110.r110_cod_trans))
			THEN
				CALL fl_mostrar_mensaje('Ya existe esta placa de Transporte en la compañía.', 'exclamation')
				NEXT FIELD r110_placa
			END IF
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

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_r110.* FROM rept110 WHERE ROWID = row
IF STATUS = NOTFOUND THEN
	ERROR 'No existe registro con rowid: ', row
END IF
DISPLAY BY NAME rm_r110.r110_estado, rm_r110.r110_cod_trans,
		rm_r110.r110_descripcion, rm_r110.r110_placa,
		rm_r110.r110_usuario, rm_r110.r110_fecing
CALL muestra_estado()
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION
