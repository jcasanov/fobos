------------------------------------------------------------------------------
-- Titulo           : rolp251.4gl - Cierre de mes 
-- Elaboracion      : 01-dic-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun rolp251 base m�dulo compa��a 
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE rm_ctb		RECORD LIKE ctbt000.*
DEFINE vm_mes		SMALLINT
DEFINE b00_mespro	SMALLINT
DEFINE tit_mes		CHAR(11)

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
--CALL startlog('../logs/errores')
CALL startlog('../logs/rolp251.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # par�metros correcto
	CALL fgl_winmessage(vg_producto, 'N�mero de par�metros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'rolp251'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPEN WINDOW w_mas AT 3,2 WITH 10 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE FIRST,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_ctb FROM "../forms/ctbf206_1"
DISPLAY FORM f_ctb
INITIALIZE rm_ctb.* TO NULL
CALL control_ingreso()

END FUNCTION



FUNCTION control_ingreso()
DEFINE nocerrar		SMALLINT

CALL fl_retorna_usuario()
WHILE TRUE
	INITIALIZE rm_ctb.* TO NULL
	CLEAR FORM
	CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING rm_ctb.*
	IF rm_ctb.b00_compania IS NULL THEN
		CALL fgl_winmessage(vg_producto,'No existe ning�n m�dulo para este proceso.','stop')
		EXIT PROGRAM
	END IF
	CALL mostrar_registro()
	CALL leer_mes()
	IF int_flag THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION leer_mes()
DEFINE resp		CHAR(6)

LET int_flag = 0
INPUT BY NAME b00_mespro
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		EXIT PROGRAM
		{IF field_touched(b00_mespro) THEN
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso()
				RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				RETURN
			END IF
		ELSE
			RETURN
		END IF}
	AFTER FIELD b00_mespro
		LET b00_mespro = vm_mes
		DISPLAY BY NAME b00_mespro
		CALL fl_retorna_nombre_mes(b00_mespro) RETURNING tit_mes
		DISPLAY BY NAME tit_mes
	AFTER INPUT
		CALL cerrar_mes()
		EXIT PROGRAM
END INPUT

END FUNCTION



FUNCTION validar_mes()
DEFINE dia,mes,anio	SMALLINT
DEFINE fecha		DATE

IF MONTH(rm_ctb.b00_fecha_cm) = 12 AND YEAR(rm_ctb.b00_fecha_cm) >= 
	rm_ctb.b00_anopro THEN
	CALL fgl_winmessage(vg_producto,'Debe cerrar el a�o: ' || rm_ctb.b00_anopro, 'exclamation')
	RETURN 1
END IF
LET mes   = month(rm_ctb.b00_fecha_cm) + 1
LET anio  = year(rm_ctb.b00_fecha_cm)
IF mes = 13 THEN
	LET mes  = 1
	LET anio = anio + 1
END IF
LET b00_mespro = mes
LET vm_mes = b00_mespro
DISPLAY BY NAME rm_ctb.b00_anopro, b00_mespro
CALL fl_retorna_nombre_mes(b00_mespro) RETURNING tit_mes
DISPLAY BY NAME tit_mes
IF mes < 12 THEN
	LET fecha = mdy(mes + 1,1,anio)
ELSE
	LET fecha = mdy(1,1,anio + 1)
END IF
LET fecha = fecha - 1
IF fecha > TODAY THEN
	CALL fgl_winmessage(vg_producto,'Muy pronto para cerrar. Hacerlo el �ltimo d�a del mes', 'exclamation')
	RETURN 1
END IF
LET rm_ctb.b00_fecha_cm = fecha
RETURN 0

END FUNCTION



FUNCTION cerrar_mes()
DEFINE r_ctb		RECORD LIKE ctbt000.*
DEFINE mayorizado	SMALLINT

CALL fl_mayorizacion_mes(vg_codcia, rm_ctb.b00_moneda_base, rm_ctb.b00_anopro,
			 MONTH(rm_ctb.b00_fecha_cm))
	RETURNING mayorizado
IF NOT mayorizado THEN
	RETURN
END IF 
BEGIN WORK
WHENEVER ERROR CONTINUE
	DECLARE q_up CURSOR FOR SELECT * FROM ctbt000
		WHERE b00_compania = vg_codcia
		FOR UPDATE
	OPEN q_up
	FETCH q_up INTO r_ctb.*
	IF STATUS < 0 THEN
		COMMIT WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		RETURN
	END IF
	WHENEVER ERROR STOP
	UPDATE ctbt000 SET b00_fecha_cm = rm_ctb.b00_fecha_cm
		WHERE CURRENT OF q_up
COMMIT WORK
CALL fl_mensaje_registro_modificado()

END FUNCTION



FUNCTION mostrar_registro()
DEFINE nocerrar		SMALLINT

CALL validar_mes() RETURNING nocerrar
IF nocerrar THEN
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION no_validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe m�dulo: ' || vg_modulo, 'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compa��a: '|| vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compa��a no est� activa: ' || vg_codcia, 'stop')
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
	CALL fgl_winmessage(vg_producto, 'Localidad no est� activa: '|| vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
