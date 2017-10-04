------------------------------------------------------------------------------
-- Titulo           : ctbp204.4gl - Remayorización mensual
-- Elaboracion      : 15-nov-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun ctbp204 base módulo compañía localidad
--			[anio_ini] [anio_fin] [mes_ini] [mes_fin]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_b00		RECORD LIKE ctbt000.*
DEFINE vm_anopro_ini	INTEGER
DEFINE vm_anopro_fin	INTEGER
DEFINE vm_mespro_ini	SMALLINT
DEFINE vm_mespro_fin	SMALLINT
DEFINE tit_mes_ini	CHAR(11)
DEFINE tit_mes_fin	CHAR(11)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ctbp204.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 8 THEN	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'ctbp204'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#IF num_args() <> 8 THEN
	--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
--#END IF
CALL fl_validar_parametros()
IF num_args() <> 8 THEN
	CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
END IF
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

CALL fl_nivel_isolation()
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 10
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
IF num_args() <> 8 THEN
	OPEN WINDOW w_ctbp204_1
		AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
		ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST,
				MENU LINE lin_menu, BORDER, MESSAGE LINE LAST)
	IF vg_gui = 1 THEN
		OPEN FORM f_ctbf204_1 FROM '../forms/ctbf204_1'
	ELSE
		OPEN FORM f_ctbf204_1 FROM '../forms/ctbf204_1c'
	END IF
	DISPLAY FORM f_ctbf204_1
END IF
CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING rm_b00.*
IF rm_b00.b00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ningún módulo para este proceso.', 'stop')
	IF num_args() <> 8 THEN
		CLOSE WINDOW w_ctbp204_1
	END IF
	EXIT PROGRAM
END IF
IF num_args() <> 4 THEN
	CALL llamada_con_parametros()
	IF num_args() <> 8 THEN
		CLOSE WINDOW w_ctbp204_1
	END IF
	EXIT PROGRAM
END IF
CALL control_ingreso()
IF num_args() <> 8 THEN
	CLOSE WINDOW w_ctbp204_1
END IF

END FUNCTION



FUNCTION llamada_con_parametros()
DEFINE fecha		DATE

LET vm_anopro_ini = arg_val(5)
LET vm_anopro_fin = arg_val(6)
LET vm_mespro_ini = arg_val(7)
LET vm_mespro_fin = arg_val(8)
IF vm_anopro_ini > YEAR(vg_fecha) OR vm_anopro_ini < rm_b00.b00_anopro THEN
	DISPLAY 'Año Inicial de proceso contable está incorrecto.'
	EXIT PROGRAM
END IF
IF vm_anopro_fin > YEAR(vg_fecha) OR vm_anopro_fin < rm_b00.b00_anopro THEN
	DISPLAY 'Año Final de proceso contable está incorrecto.'
	EXIT PROGRAM
END IF
LET fecha = MDY(vm_mespro_ini, 1, vm_anopro_ini)
IF fecha > vg_fecha OR fecha < rm_b00.b00_fecha_cm THEN
	DISPLAY 'Mes Inicial para la remayorización está incorrecto.'
	EXIT PROGRAM
END IF
LET fecha = MDY(vm_mespro_fin, 1, vm_anopro_fin)
IF fecha > vg_fecha OR fecha < rm_b00.b00_fecha_cm THEN
	DISPLAY 'Mes Inicial para la remayorización está incorrecto.'
	EXIT PROGRAM
END IF
IF vm_anopro_ini > vm_anopro_fin THEN
	DISPLAY 'El Año Final debe ser mayor o igual al Año Inicial.'
	EXIT PROGRAM
END IF
IF vm_anopro_ini = vm_anopro_fin THEN
	IF vm_mespro_ini > vm_mespro_fin THEN
		DISPLAY 'El Mes Final debe ser mayor o igual al Mes Inicial.'
		EXIT PROGRAM
	END IF
END IF
CALL proceso_mayorizacion()
DISPLAY ' '
DISPLAY 'Mayorización Terminó Correctamente.'

END FUNCTION



FUNCTION control_ingreso()

CLEAR FORM
LET vm_anopro_ini = YEAR(vg_fecha)
LET vm_mespro_ini = MONTH(vg_fecha) 
LET vm_anopro_fin = YEAR(vg_fecha)
LET vm_mespro_fin = MONTH(vg_fecha) 
CALL mostrar_registro()
WHILE TRUE
	CALL leer_mes()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL proceso_mayorizacion()
	CALL fl_mostrar_mensaje('Mayorización Terminó Correctamente.', 'info')
	MESSAGE '                                                      '
END WHILE

END FUNCTION



FUNCTION mostrar_registro()

DISPLAY BY NAME vm_anopro_ini, vm_anopro_fin, vm_mespro_ini, vm_mespro_fin
CALL fl_retorna_nombre_mes(vm_mespro_ini) RETURNING tit_mes_ini
CALL fl_retorna_nombre_mes(vm_mespro_fin) RETURNING tit_mes_fin
CALL fl_justifica_titulo('I', tit_mes_ini, 11) RETURNING tit_mes_ini
CALL fl_justifica_titulo('I', tit_mes_fin, 11) RETURNING tit_mes_fin
DISPLAY BY NAME tit_mes_ini, tit_mes_fin

END FUNCTION



FUNCTION leer_mes()
DEFINE fecha		DATE
DEFINE ano_ini		INTEGER
DEFINE ano_fin		INTEGER
DEFINE mes_ini		SMALLINT
DEFINE mes_fin		SMALLINT

LET int_flag = 0
INPUT BY NAME vm_anopro_ini, vm_anopro_fin, vm_mespro_ini, vm_mespro_fin
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
       	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD vm_anopro_ini
		LET ano_ini = vm_anopro_ini
	BEFORE FIELD vm_anopro_fin
		LET ano_fin = vm_anopro_fin
	BEFORE FIELD vm_mespro_ini
		LET mes_ini = vm_mespro_ini
	BEFORE FIELD vm_mespro_fin
		LET mes_fin = vm_mespro_fin
	AFTER FIELD vm_anopro_ini
		IF vm_anopro_ini IS NOT NULL THEN
			IF vm_anopro_ini > YEAR(vg_fecha) OR
			   vm_anopro_ini < rm_b00.b00_anopro
			THEN
				CALL fl_mostrar_mensaje('Año Inicial de proceso contable está incorrecto.', 'exclamation')
				NEXT FIELD vm_anopro_ini
			END IF
		ELSE
			LET vm_anopro_ini = ano_ini
			DISPLAY BY NAME vm_anopro_ini
		END IF
	AFTER FIELD vm_anopro_fin
		IF vm_anopro_fin IS NOT NULL THEN
			IF vm_anopro_fin > YEAR(vg_fecha) OR
			   vm_anopro_fin < rm_b00.b00_anopro
			THEN
				CALL fl_mostrar_mensaje('Año Final de proceso contable está incorrecto.', 'exclamation')
				NEXT FIELD vm_anopro_fin
			END IF
		ELSE
			LET vm_anopro_fin = ano_fin
			DISPLAY BY NAME vm_anopro_fin
		END IF
	AFTER FIELD vm_mespro_ini
		IF vm_mespro_ini IS NOT NULL THEN
			LET fecha = MDY(vm_mespro_ini, 1, vm_anopro_ini)
			IF fecha > vg_fecha OR fecha < rm_b00.b00_fecha_cm THEN
				CALL fl_mostrar_mensaje('Mes Inicial para la remayorización está incorrecto.', 'exclamation')
				NEXT FIELD vm_mespro_ini
			END IF
		ELSE
			LET vm_mespro_ini = mes_ini
			DISPLAY BY NAME vm_mespro_ini
		END IF
		CALL fl_retorna_nombre_mes(vm_mespro_ini) RETURNING tit_mes_ini
		CALL fl_justifica_titulo('I', tit_mes_ini, 11)
			RETURNING tit_mes_ini
		DISPLAY BY NAME tit_mes_ini
	AFTER FIELD vm_mespro_fin
		IF vm_mespro_fin IS NOT NULL THEN
			LET fecha = MDY(vm_mespro_fin, 1, vm_anopro_fin)
			IF fecha > vg_fecha OR fecha < rm_b00.b00_fecha_cm THEN
				CALL fl_mostrar_mensaje('Mes Inicial para la remayorización está incorrecto.', 'exclamation')
				NEXT FIELD vm_mespro_fin
			END IF
		ELSE
			LET vm_mespro_fin = mes_fin
			DISPLAY BY NAME vm_mespro_fin
		END IF
		CALL fl_retorna_nombre_mes(vm_mespro_fin) RETURNING tit_mes_fin
		CALL fl_justifica_titulo('I', tit_mes_fin, 11)
			RETURNING tit_mes_fin
		DISPLAY BY NAME tit_mes_fin
	AFTER INPUT
		IF vm_anopro_ini > vm_anopro_fin THEN
			CALL fl_mostrar_mensaje('El Año Final debe ser mayor o igual al Año Inicial.', 'exclamation')
			NEXT FIELD vm_anopro_fin
		END IF
		IF vm_anopro_ini = vm_anopro_fin THEN
			IF vm_mespro_ini > vm_mespro_fin THEN
				CALL fl_mostrar_mensaje('El Mes Final debe ser mayor o igual al Mes Inicial.', 'exclamation')
				NEXT FIELD vm_mespro_fin
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION proceso_mayorizacion()
DEFINE mayorizado	SMALLINT
DEFINE primera, ultimo	SMALLINT
DEFINE mes		SMALLINT
DEFINE mes_ini, mes_fin	SMALLINT
DEFINE anio		INTEGER
DEFINE mensaje		VARCHAR(150)

LET mes_ini = vm_mespro_ini
LET mes_fin = vm_mespro_fin
IF vm_anopro_ini < vm_anopro_fin THEN
	LET mes_fin = 12
END IF
LET primera = 1
LET ultimo  = 0
FOR anio = vm_anopro_ini TO vm_anopro_fin
	LET ultimo = ultimo + 1
	IF NOT primera AND anio < vm_anopro_fin THEN
		LET mes_ini = 1
		LET mes_fin = 12
	END IF
	IF NOT primera THEN
		IF ultimo > 1 AND anio = vm_anopro_fin THEN
			LET mes_ini = 1
			LET mes_fin = vm_mespro_fin
		END IF
	END IF
	LET primera = 0
	FOR mes = mes_ini TO mes_fin
		CALL fl_mayorizacion_mes(vg_codcia, rm_b00.b00_moneda_base,
						anio, mes, 0)
			RETURNING mayorizado
		IF NOT mayorizado THEN
			LET mensaje = 'No se pudo mayorizar el MES ',
				mes USING "&&", ' ', fl_justifica_titulo('I',
				fl_retorna_nombre_mes(mes), 11) CLIPPED,
				'  AÑO ', anio USING "&&&&",
				'. Ultimo periodo mayorizado ',
				(MDY(mes, 01, anio) - 1 UNITS DAY)
				USING "yyyy-mm", '.'
			CALL fl_mostrar_mensaje(mensaje, 'stop')
			EXIT PROGRAM
		END IF
		LET mensaje = 'MES ', mes USING "&&", ' ',
				fl_justifica_titulo('I',
				fl_retorna_nombre_mes(mes), 11) CLIPPED,
				'  AÑO ', anio USING "&&&&",
				'  MAYORIZADO CORRECTAMENTE.'
		IF num_args() = 4 THEN
			MESSAGE mensaje CLIPPED
			SLEEP 2
		ELSE
			DISPLAY mensaje CLIPPED
			DISPLAY ' '
		END IF
	END FOR
END FOR

END FUNCTION



FUNCTION llamar_visor_teclas()
DEFINE a		SMALLINT

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION
