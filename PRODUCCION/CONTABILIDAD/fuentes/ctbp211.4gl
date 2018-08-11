--------------------------------------------------------------------------------
-- Titulo           : ctbp211.4gl - Mantenimiento de aux. cont. de cobranzas
-- Elaboracion      : 03-Ago-2007
-- Autor            : NPC
-- Formato Ejecucion: fglrun ctbp211 base módulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_b41		RECORD LIKE ctbt041.*
DEFINE vm_num_rows	SMALLINT
DEFINE vm_row_current	SMALLINT
DEFINE vm_max_rows	SMALLINT
DEFINE vm_r_rows	ARRAY [1000] OF INTEGER
DEFINE vm_flag_mant	CHAR(1)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ctbp211.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parametros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'ctbp211'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE flag		CHAR(1)

CALL fl_nivel_isolation()
LET vm_max_rows	= 1000
OPEN WINDOW w_ctbf211_1 AT 3,2 WITH 20 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0, BORDER,
		MESSAGE LINE LAST)
OPEN FORM f_ctbf211_1 FROM "../forms/ctbf211_1"
DISPLAY FORM f_ctbf211_1
INITIALIZE rm_b41.* TO NULL
LET vm_num_rows    = 0
LET vm_row_current = 0
CALL muestra_contadores(vm_row_current, vm_num_rows)
MENU 'OPCIONES'
	BEFORE MENU
		HIDE OPTION 'Modificar'
		HIDE OPTION 'Avanzar'
		HIDE OPTION 'Retroceder'
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
DEFINE num_aux		INTEGER
DEFINE resul		SMALLINT
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*

CLEAR FORM
LET vm_flag_mant = 'I'
CALL fl_retorna_usuario()
LET num_aux = 0 
INITIALIZE rm_b41.* TO NULL
LET rm_b41.b41_compania   = vg_codcia
LET rm_b41.b41_localidad  = vg_codloc
CALL fl_lee_compania(rm_b41.b41_compania) RETURNING r_g01.*
CALL fl_lee_localidad(rm_b41.b41_compania, rm_b41.b41_localidad)
	RETURNING r_g02.*
DISPLAY r_g01.g01_razonsocial TO tit_compania
DISPLAY r_g02.g02_nombre      TO tit_localidad
CALL leer_datos()
IF int_flag THEN
	CLEAR FORM
	IF vm_row_current > 0 THEN
		CALL muestra_reg()
	END IF
	RETURN
END IF
INSERT INTO ctbt041 VALUES (rm_b41.*)
IF vm_num_rows = vm_max_rows THEN
	LET vm_num_rows = 1
ELSE
	LET vm_num_rows = vm_num_rows + 1
END IF
LET vm_r_rows[vm_num_rows] = SQLCA.SQLERRD[6] 
LET vm_row_current         = vm_num_rows
CALL muestra_reg()
CALL fl_mensaje_registro_ingresado()

END FUNCTION



FUNCTION control_modificacion()
	
IF vm_num_rows = 0 THEN
	CALL fl_mensaje_consultar_primero()
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM ctbt041
		WHERE ROWID = vm_r_rows[vm_row_current]
	FOR UPDATE
OPEN q_up
FETCH q_up INTO rm_b41.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mensaje_bloqueo_otro_usuario()
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
LET vm_flag_mant = 'M'
CALL leer_datos()
IF int_flag THEN
	ROLLBACK WORK
	CALL muestra_reg()
	RETURN
END IF
UPDATE ctbt041 SET * = rm_b41.* WHERE CURRENT OF q_up
COMMIT WORK
CALL muestra_reg()
CALL fl_mensaje_registro_modificado()
 
END FUNCTION



FUNCTION control_consulta()
DEFINE query		VARCHAR(1500)
DEFINE expr_sql		VARCHAR(800)
DEFINE num_reg		INTEGER
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g20		RECORD LIKE gent020.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad

CLEAR FORM
LET codcia   = vg_codcia
LET codloc   = vg_codloc
LET int_flag = 0
CONSTRUCT BY NAME expr_sql ON b41_compania, b41_localidad, b41_modulo,
	b41_grupo_linea, b41_caja_mb, b41_caja_me, b41_cxc_mb, b41_cxc_me,
	b41_ant_mb, b41_ant_me, b41_intereses
	ON KEY(F2)
		IF INFIELD(b41_compania) THEN
			CALL fl_ayuda_compania() RETURNING r_g01.g01_compania
			IF r_g01.g01_compania IS NOT NULL THEN
				CALL fl_lee_compania(r_g01.g01_compania)
					RETURNING r_g01.*
				DISPLAY r_g01.g01_compania    TO b41_compania
				DISPLAY r_g01.g01_razonsocial TO tit_compania
			END IF
		END IF
		IF INFIELD(b41_localidad) THEN
			CALL fl_ayuda_localidad(codcia)
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
			IF r_g02.g02_localidad IS NOT NULL THEN
				DISPLAY r_g02.g02_localidad TO b41_localidad
				DISPLAY r_g02.g02_nombre    TO tit_localidad
			END IF
		END IF
		IF INFIELD(b41_modulo) THEN
			CALL fl_ayuda_modulos()
				RETURNING r_g50.g50_modulo, r_g50.g50_nombre
			IF r_g50.g50_modulo IS NOT NULL THEN
				DISPLAY r_g50.g50_modulo TO b41_modulo
				DISPLAY r_g50.g50_nombre TO tit_modulo
			END IF
		END IF
		IF INFIELD(b41_grupo_linea) THEN
			CALL fl_ayuda_grupo_lineas(codcia)
				RETURNING r_g20.g20_grupo_linea,r_g20.g20_nombre
			IF r_g20.g20_grupo_linea IS NOT NULL THEN
				DISPLAY r_g20.g20_grupo_linea TO b41_grupo_linea
				DISPLAY r_g20.g20_nombre      TO tit_grupo_linea
			END IF 
		END IF
		IF INFIELD(b41_caja_mb) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b41_caja_mb
				DISPLAY r_b10.b10_descripcion TO tit_caja_mb
			END IF
		END IF
		IF INFIELD(b41_caja_me) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b41_caja_me
				DISPLAY r_b10.b10_descripcion TO tit_caja_me
			END IF
		END IF
		IF INFIELD(b41_cxc_mb) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b41_cxc_mb
				DISPLAY r_b10.b10_descripcion TO tit_cxc_mb
			END IF
		END IF
		IF INFIELD(b41_cxc_me) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b41_cxc_me
				DISPLAY r_b10.b10_descripcion TO tit_cxc_me
			END IF
		END IF
		IF INFIELD(b41_ant_mb) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b41_ant_mb
				DISPLAY r_b10.b10_descripcion TO tit_ant_mb
			END IF
		END IF
		IF INFIELD(b41_ant_me) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b41_ant_me
				DISPLAY r_b10.b10_descripcion TO tit_ant_me
			END IF
		END IF
		IF INFIELD(b41_intereses) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				DISPLAY r_b10.b10_cuenta      TO b41_intereses
				DISPLAY r_b10.b10_descripcion TO tit_intereses
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD b41_compania
		LET codcia = NULL
		LET codcia = GET_FLDBUF(b41_compania)
		IF codcia IS NULL THEN
			LET codcia = vg_codcia
		END IF
	AFTER FIELD b41_localidad
		LET codloc = NULL
		LET codloc = GET_FLDBUF(b41_localidad)
		IF codloc IS NULL THEN
			LET codloc = vg_codloc
		END IF
END CONSTRUCT
IF int_flag THEN
	IF vm_row_current > 0 THEN
		CALL muestra_reg()
	ELSE
		CLEAR FORM
	END IF
	RETURN
END IF
LET query = 'SELECT *, ROWID FROM ctbt041 ',
		' WHERE ', expr_sql CLIPPED,
		' ORDER BY 1, 2, 3, 4 '
PREPARE cons FROM query	
DECLARE q_cons CURSOR FOR cons
LET vm_num_rows = 0
FOREACH q_cons INTO rm_b41.*, num_reg
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
	CALL muestra_contadores(vm_row_current, vm_num_rows)
	RETURN
END IF
LET vm_row_current = 1
CALL muestra_reg()

END FUNCTION



FUNCTION leer_datos()
DEFINE resp		CHAR(6)
DEFINE resul		SMALLINT
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_b41		RECORD LIKE ctbt041.*
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g20		RECORD LIKE gent020.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE codcia		LIKE gent001.g01_compania

LET codcia   = vg_codcia
LET int_flag = 0
INPUT BY NAME rm_b41.b41_compania, rm_b41.b41_localidad, rm_b41.b41_modulo,
	rm_b41.b41_grupo_linea, rm_b41.b41_caja_mb, rm_b41.b41_caja_me,
	rm_b41.b41_cxc_mb, rm_b41.b41_cxc_me, rm_b41.b41_ant_mb,
	rm_b41.b41_ant_me, rm_b41.b41_intereses
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
        	IF FIELD_TOUCHED(rm_b41.b41_compania, rm_b41.b41_localidad,
				 rm_b41.b41_modulo, rm_b41.b41_grupo_linea,
				 rm_b41.b41_caja_mb, rm_b41.b41_caja_me,
				 rm_b41.b41_cxc_mb, rm_b41.b41_cxc_me,
				 rm_b41.b41_ant_mb, rm_b41.b41_ant_me,
				 rm_b41.b41_intereses)
		THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				CLEAR FORM
				RETURN
			END IF
		ELSE
			RETURN
		END IF
	ON KEY(F2)
		IF vm_flag_mant = 'I' THEN
			IF INFIELD(b41_compania) THEN
				CALL fl_ayuda_compania()
					RETURNING r_g01.g01_compania
				IF r_g01.g01_compania IS NOT NULL THEN
					CALL fl_lee_compania(r_g01.g01_compania)
						RETURNING r_g01.*
					LET rm_b41.b41_compania =
							r_g01.g01_compania
					LET codcia = rm_b41.b41_compania
					DISPLAY r_g01.g01_compania
						TO b41_compania
					DISPLAY r_g01.g01_razonsocial
						TO tit_compania
				END IF
			END IF
			IF INFIELD(b41_localidad) THEN
				CALL fl_ayuda_localidad(codcia)
					RETURNING r_g02.g02_localidad,
						  r_g02.g02_nombre
				IF r_g02.g02_localidad IS NOT NULL THEN
					LET rm_b41.b41_localidad =
							r_g02.g02_localidad
					DISPLAY r_g02.g02_localidad
						TO b41_localidad
					DISPLAY r_g02.g02_nombre
						TO tit_localidad
				END IF
			END IF
			IF INFIELD(b41_modulo) THEN
				CALL fl_ayuda_modulos()
					RETURNING r_g50.g50_modulo,
						  r_g50.g50_nombre
				IF r_g50.g50_modulo IS NOT NULL THEN
					LET rm_b41.b41_modulo = r_g50.g50_modulo
					DISPLAY r_g50.g50_modulo TO b41_modulo
					DISPLAY r_g50.g50_nombre TO tit_modulo
				END IF
			END IF
			IF INFIELD(b41_grupo_linea) THEN
				CALL fl_ayuda_grupo_lineas(codcia)
					RETURNING r_g20.g20_grupo_linea,
						  r_g20.g20_nombre
				IF r_g20.g20_grupo_linea IS NOT NULL THEN
					LET rm_b41.b41_grupo_linea =
							r_g20.g20_grupo_linea
					DISPLAY r_g20.g20_grupo_linea
						TO b41_grupo_linea
					DISPLAY r_g20.g20_nombre
						TO tit_grupo_linea
				END IF 
			END IF
		END IF
		IF INFIELD(b41_caja_mb) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b41.b41_caja_mb = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b41_caja_mb
				DISPLAY r_b10.b10_descripcion TO tit_caja_mb
			END IF
		END IF
		IF INFIELD(b41_caja_me) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b41.b41_caja_me = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b41_caja_me
				DISPLAY r_b10.b10_descripcion TO tit_caja_me
			END IF
		END IF
		IF INFIELD(b41_cxc_mb) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b41.b41_cxc_mb = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b41_cxc_mb
				DISPLAY r_b10.b10_descripcion TO tit_cxc_mb
			END IF
		END IF
		IF INFIELD(b41_cxc_me) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b41.b41_cxc_me = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b41_cxc_me
				DISPLAY r_b10.b10_descripcion TO tit_cxc_me
			END IF
		END IF
		IF INFIELD(b41_ant_mb) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b41.b41_ant_mb = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b41_ant_mb
				DISPLAY r_b10.b10_descripcion TO tit_ant_mb
			END IF
		END IF
		IF INFIELD(b41_ant_me) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b41.b41_ant_me = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b41_ant_me
				DISPLAY r_b10.b10_descripcion TO tit_ant_me
			END IF
		END IF
		IF INFIELD(b41_intereses) THEN
			CALL fl_ayuda_cuenta_contable(codcia, -1)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_b41.b41_intereses = r_b10.b10_cuenta
				DISPLAY r_b10.b10_cuenta      TO b41_intereses
				DISPLAY r_b10.b10_descripcion TO tit_intereses
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD b41_compania
		IF vm_flag_mant = 'M' THEN
			LET codcia = rm_b41.b41_compania
		END IF
	BEFORE FIELD b41_localidad
		IF vm_flag_mant = 'M' THEN
			LET r_g02.g02_localidad = rm_b41.b41_localidad
		END IF
	BEFORE FIELD b41_modulo
		IF vm_flag_mant = 'M' THEN
			LET r_g50.g50_modulo = rm_b41.b41_modulo
		END IF
	BEFORE FIELD b41_grupo_linea
		IF vm_flag_mant = 'M' THEN
			LET r_g20.g20_grupo_linea = rm_b41.b41_grupo_linea
		END IF
	AFTER FIELD b41_compania
		IF vm_flag_mant = 'M' THEN
			LET rm_b41.b41_compania = codcia
			CALL fl_lee_compania(rm_b41.b41_compania)
				RETURNING r_g01.*
			DISPLAY r_g01.g01_compania    TO b41_compania
			DISPLAY r_g01.g01_razonsocial TO tit_compania
			CONTINUE INPUT
		END IF
		IF rm_b41.b41_compania IS NULL THEN
			LET rm_b41.b41_compania = vg_codcia
		END IF
		CALL fl_lee_compania(rm_b41.b41_compania) RETURNING r_g01.*
		IF r_g01.g01_compania IS NULL THEN
			CALL fl_mostrar_mensaje('No existe esa compania.', 'exclamation')
			NEXT FIELD b41_compania
		END IF
		DISPLAY r_g01.g01_razonsocial TO tit_compania
		IF r_g01.g01_estado = 'B' THEN
			CALL fl_mensaje_estado_bloqueado()
			NEXT FIELD b41_compania
		END IF
	AFTER FIELD b41_localidad
		IF vm_flag_mant = 'M' THEN
			LET rm_b41.b41_localidad = r_g02.g02_localidad
			CALL fl_lee_localidad(rm_b41.b41_compania,
						rm_b41.b41_localidad)
				RETURNING r_g02.*
			DISPLAY r_g02.g02_localidad TO b41_localidad
			DISPLAY r_g02.g02_nombre    TO tit_localidad
			CONTINUE INPUT
		END IF
		IF rm_b41.b41_localidad IS NULL THEN
			LET rm_b41.b41_localidad = vg_codloc
		END IF
		CALL fl_lee_localidad(rm_b41.b41_compania, rm_b41.b41_localidad)
			RETURNING r_g02.*
		IF r_g02.g02_compania IS NULL THEN
			CALL fl_mostrar_mensaje('No existe esta localidad.', 'exclamation')
			NEXT FIELD b41_localidad
		END IF
		DISPLAY r_g02.g02_nombre TO tit_localidad
		IF r_g02.g02_estado = 'B' THEN
			CALL fl_mensaje_estado_bloqueado()
			NEXT FIELD b41_localidad
		END IF
	AFTER FIELD b41_modulo
		IF vm_flag_mant = 'M' THEN
			LET rm_b41.b41_modulo = r_g50.g50_modulo
			CALL fl_lee_modulo(rm_b41.b41_modulo) RETURNING r_g50.*
			DISPLAY r_g50.g50_modulo TO b41_modulo
			DISPLAY r_g50.g50_nombre TO tit_modulo
			CONTINUE INPUT
		END IF
		IF rm_b41.b41_modulo IS NOT NULL THEN
			CALL fl_lee_modulo(rm_b41.b41_modulo) RETURNING r_g50.*
			IF r_g50.g50_modulo IS NULL THEN
				CALL fl_mostrar_mensaje('No existe este modulo.', 'exclamation')
				NEXT FIELD b41_modulo
			END IF
			DISPLAY r_g50.g50_nombre TO tit_modulo
			IF r_g50.g50_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD b41_modulo
			END IF
		ELSE
			CLEAR tit_modulo
		END IF
	AFTER FIELD b41_grupo_linea
		IF vm_flag_mant = 'M' THEN
			LET rm_b41.b41_grupo_linea = r_g20.g20_grupo_linea
			CALL fl_lee_grupo_linea(rm_b41.b41_compania,
						rm_b41.b41_grupo_linea)
				RETURNING r_g20.*
			DISPLAY r_g20.g20_grupo_linea TO b41_grupo_linea
			DISPLAY r_g20.g20_nombre      TO tit_grupo_linea
			CONTINUE INPUT
		END IF
		IF rm_b41.b41_grupo_linea IS NOT NULL THEN
			CALL fl_lee_grupo_linea(rm_b41.b41_compania,
						rm_b41.b41_grupo_linea)
				RETURNING r_g20.*
			IF r_g20.g20_grupo_linea IS NULL THEN
				CALL fl_mostrar_mensaje('No existe este grupo de linea.', 'exclamation')
				NEXT FIELD b41_grupo_linea
			END IF
			DISPLAY r_g20.g20_nombre TO tit_grupo_linea
		ELSE
			CLEAR tit_grupo_linea
		END IF
	AFTER FIELD b41_caja_mb
                IF rm_b41.b41_caja_mb IS NOT NULL THEN
			CALL validar_cuenta(rm_b41.b41_caja_mb, 1)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b41_caja_mb
			END IF
		ELSE
			CLEAR tit_caja_mb
                END IF
	AFTER FIELD b41_caja_me
                IF rm_b41.b41_caja_me IS NOT NULL THEN
			CALL validar_cuenta(rm_b41.b41_caja_me, 2)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b41_caja_me
			END IF
		ELSE
			CLEAR tit_caja_me
                END IF
	AFTER FIELD b41_cxc_mb
                IF rm_b41.b41_cxc_mb IS NOT NULL THEN
			CALL validar_cuenta(rm_b41.b41_cxc_mb, 3)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b41_cxc_mb
			END IF
		ELSE
			CLEAR tit_cxc_mb
                END IF
	AFTER FIELD b41_cxc_me
                IF rm_b41.b41_cxc_me IS NOT NULL THEN
			CALL validar_cuenta(rm_b41.b41_cxc_me, 4)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b41_cxc_me
			END IF
		ELSE
			CLEAR tit_cxc_me
                END IF
	AFTER FIELD b41_ant_mb
                IF rm_b41.b41_ant_mb IS NOT NULL THEN
			CALL validar_cuenta(rm_b41.b41_ant_mb, 5)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b41_ant_mb
			END IF
		ELSE
			CLEAR tit_ant_mb
                END IF
	AFTER FIELD b41_ant_me
                IF rm_b41.b41_ant_me IS NOT NULL THEN
			CALL validar_cuenta(rm_b41.b41_ant_me, 6)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b41_ant_me
			END IF
		ELSE
			CLEAR tit_ant_me
                END IF
	AFTER FIELD b41_intereses
                IF rm_b41.b41_intereses IS NOT NULL THEN
			CALL validar_cuenta(rm_b41.b41_intereses, 7)
				RETURNING resul
			IF resul = 1 THEN
				NEXT FIELD b41_intereses
			END IF
		ELSE
			CLEAR tit_intereses
                END IF
	AFTER INPUT
		IF vm_flag_mant <> 'I' THEN
			EXIT INPUT
		END IF
		INITIALIZE r_b41.* TO NULL
		SELECT * INTO r_b41.*
			FROM ctbt041
			WHERE b41_compania    = rm_b41.b41_compania
			  AND b41_localidad   = rm_b41.b41_localidad
			  AND b41_modulo      = rm_b41.b41_modulo
			  AND b41_grupo_linea = rm_b41.b41_grupo_linea
		IF r_b41.b41_compania IS NOT NULL THEN
			CALL fl_mostrar_mensaje('Esta configuracion contable ya existe.', 'exclamation')
			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



FUNCTION validar_cuenta(aux_cont, flag)
DEFINE aux_cont		LIKE ctbt010.b10_cuenta
DEFINE flag		SMALLINT
DEFINE r_b10            RECORD LIKE ctbt010.*

CALL fl_lee_cuenta(vg_codcia, aux_cont) RETURNING r_b10.*
IF r_b10.b10_cuenta IS NULL  THEN
	CALL fl_mostrar_mensaje('Cuenta no existe para esta compañía.','exclamation')
	RETURN 1
END IF
CASE flag
	WHEN 1 DISPLAY r_b10.b10_descripcion TO tit_caja_mb
	WHEN 2 DISPLAY r_b10.b10_descripcion TO tit_caja_me
	WHEN 3 DISPLAY r_b10.b10_descripcion TO tit_cxc_mb
	WHEN 4 DISPLAY r_b10.b10_descripcion TO tit_cxc_me
	WHEN 5 DISPLAY r_b10.b10_descripcion TO tit_ant_mb
	WHEN 6 DISPLAY r_b10.b10_descripcion TO tit_ant_me
	WHEN 7 DISPLAY r_b10.b10_descripcion TO tit_intereses
END CASE
IF r_b10.b10_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN 1
END IF
IF r_b10.b10_permite_mov = 'N' THEN
	CALL fl_mostrar_mensaje('Cuenta no permite movimiento.', 'exclamation')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION muestra_siguiente_registro()

IF vm_row_current < vm_num_rows THEN
	LET vm_row_current = vm_row_current + 1
END IF
CALL muestra_reg()

END FUNCTION



FUNCTION muestra_anterior_registro()

IF vm_row_current > 1 THEN
	LET vm_row_current = vm_row_current - 1
END IF
CALL muestra_reg()

END FUNCTION



FUNCTION muestra_contadores(row_current, num_rows)
DEFINE row_current	SMALLINT
DEFINE num_rows		SMALLINT
                                                                                
DISPLAY row_current TO vm_row_current
DISPLAY num_rows    TO vm_num_rows
                                                                                
END FUNCTION



FUNCTION mostrar_registro(num_registro)
DEFINE num_registro	INTEGER
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g20		RECORD LIKE gent020.*
DEFINE r_g50		RECORD LIKE gent050.*

IF vm_num_rows <= 0 THEN
	RETURN
END IF
SELECT * INTO rm_b41.* FROM ctbt041 WHERE ROWID = num_registro	
IF STATUS = NOTFOUND THEN
	CALL fl_mostrar_mensaje('No existe registro con índice: ' || vm_row_current,'exclamation')
	RETURN
END IF
DISPLAY BY NAME rm_b41.*
CALL fl_lee_compania(rm_b41.b41_compania) RETURNING r_g01.*
CALL fl_lee_localidad(rm_b41.b41_compania, rm_b41.b41_localidad)
	RETURNING r_g02.*
CALL fl_lee_modulo(rm_b41.b41_modulo) RETURNING r_g50.*
CALL fl_lee_grupo_linea(rm_b41.b41_compania, rm_b41.b41_grupo_linea)
	RETURNING r_g20.*
DISPLAY r_g01.g01_razonsocial TO tit_compania
DISPLAY r_g02.g02_nombre      TO tit_localidad
DISPLAY r_g50.g50_nombre      TO tit_modulo
DISPLAY r_g20.g20_nombre      TO tit_grupo_linea
CALL fl_lee_cuenta(vg_codcia, rm_b41.b41_caja_mb) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_caja_mb
CALL fl_lee_cuenta(vg_codcia, rm_b41.b41_caja_me) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_caja_me
CALL fl_lee_cuenta(vg_codcia, rm_b41.b41_cxc_mb) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_cxc_mb
CALL fl_lee_cuenta(vg_codcia, rm_b41.b41_cxc_me) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_cxc_me
CALL fl_lee_cuenta(vg_codcia, rm_b41.b41_ant_mb) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_ant_mb
CALL fl_lee_cuenta(vg_codcia, rm_b41.b41_ant_me) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_ant_me
CALL fl_lee_cuenta(vg_codcia, rm_b41.b41_intereses) RETURNING r_b10.*
DISPLAY r_b10.b10_descripcion TO tit_intereses

END FUNCTION



FUNCTION muestra_reg()

CALL mostrar_registro(vm_r_rows[vm_row_current])
CALL muestra_contadores(vm_row_current, vm_num_rows)

END FUNCTION
