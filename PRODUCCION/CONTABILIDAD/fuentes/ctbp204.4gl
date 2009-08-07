------------------------------------------------------------------------------
-- Titulo           : ctbp204.4gl - Remayorización mensual
-- Elaboracion      : 15-nov-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun ctbp204 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_ctb		RECORD LIKE ctbt000.*
DEFINE vm_mes		SMALLINT
DEFINE b00_mespro	SMALLINT
DEFINE vm_anio		SMALLINT
DEFINE tit_mes		CHAR(11)
DEFINE r_ctb		RECORD LIKE ctbt000.*

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ctbp204.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'ctbp204'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
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
OPEN FORM f_ctb FROM "../forms/ctbf204_1"
DISPLAY FORM f_ctb
INITIALIZE rm_ctb.* TO NULL
CALL control_ingreso()

END FUNCTION



FUNCTION control_ingreso()
DEFINE nocerrar				SMALLINT
DEFINE mayorizado			SMALLINT
DEFINE fecha, fecha_lim		DATE

CALL fl_retorna_usuario()

INITIALIZE rm_ctb.* TO NULL
CLEAR FORM
LET rm_ctb.b00_anopro = year(TODAY)
LET b00_mespro        = month(TODAY) 
LET vm_anio           = rm_ctb.b00_anopro
LET vm_mes            = b00_mespro
CALL mostrar_registro()
CALL leer_mes()
IF int_flag THEN
	RETURN
END IF
LET fecha 		= MDY(b00_mespro, 1, rm_ctb.b00_anopro)
LET fecha_lim 	= MDY(MONTH(TODAY), 1, YEAR(TODAY)) + 1 UNITS MONTH

WHILE TRUE
	LET b00_mespro        = MONTH(fecha)
	LET rm_ctb.b00_anopro = YEAR(fecha)
	LET mayorizado = fl_mayorizacion_mes(vg_codcia, r_ctb.b00_moneda_base, 
				     	     rm_ctb.b00_anopro, b00_mespro)
	IF NOT mayorizado THEN
		CALL fgl_winmessage(vg_producto, 
			'No se pudo mayorizar el mes.',
			'exclamation')
		EXIT WHILE
	END IF
	LET fecha = fecha + 1 UNITS MONTH
	IF (fecha >= fecha_lim) THEN
		CALL fgl_winmessage(vg_producto,
			 'Mayorizacion termino correctamente.',
			 'exclamation')
		EXIT WHILE
	END IF	
END WHILE

END FUNCTION



FUNCTION leer_mes()
DEFINE resp		CHAR(6)
DEFINE fecha		DATE

LET int_flag = 0
INPUT BY NAME rm_ctb.b00_anopro, b00_mespro
	WITHOUT DEFAULTS
	{ON KEY(INTERRUPT)
		IF field_touched(rm_ctb.b00_anopro, b00_mespro) THEN
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
	AFTER FIELD b00_anopro
		IF rm_ctb.b00_anopro IS NOT NULL THEN
			CALL fl_lee_compania_contabilidad(vg_codcia)
				RETURNING r_ctb.*
			IF r_ctb.b00_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe ningún módulo para este proceso.','stop')
				EXIT PROGRAM
			END IF
			IF rm_ctb.b00_anopro > year(TODAY)
			OR rm_ctb.b00_anopro < r_ctb.b00_anopro THEN
				CALL fgl_winmessage(vg_producto,'Año de proceso contable está incorrecto.','exclamation')
				NEXT FIELD b00_anopro
			END IF
		ELSE
			LET rm_ctb.b00_anopro = vm_anio
			DISPLAY BY NAME rm_ctb.b00_anopro
		END IF
	AFTER FIELD b00_mespro
		CALL fl_retorna_nombre_mes(b00_mespro) RETURNING tit_mes
		DISPLAY BY NAME tit_mes
		IF b00_mespro IS NOT NULL THEN
			LET fecha = mdy(b00_mespro,day(TODAY),
					rm_ctb.b00_anopro)
			IF fecha > TODAY THEN
				CALL fgl_winmessage(vg_producto,'Mes para la remayorización está incorrecto.','exclamation')
				--NEXT FIELD b00_mespro
			END IF
		ELSE
			LET b00_mespro = vm_mes
			DISPLAY BY NAME b00_mespro
		END IF
END INPUT

END FUNCTION



FUNCTION mostrar_registro()

DISPLAY BY NAME rm_ctb.b00_anopro, b00_mespro
CALL fl_retorna_nombre_mes(b00_mespro) RETURNING tit_mes
DISPLAY BY NAME tit_mes

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
