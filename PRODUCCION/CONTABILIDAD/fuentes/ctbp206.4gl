--------------------------------------------------------------------------------
-- Titulo           : ctbp206.4gl - Cierre de mes contable
-- Elaboracion      : 14-nov-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun ctbp206 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
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
CALL startlog('../logs/ctbp206.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'ctbp206'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPEN WINDOW w_ctbf206_1 AT 03, 02 WITH 10 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,
			BORDER, MESSAGE LINE LAST)
OPEN FORM f_ctbf206_1 FROM "../forms/ctbf206_1"
DISPLAY FORM f_ctbf206_1
CALL fl_retorna_usuario()
INITIALIZE rm_b00.* TO NULL
CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING rm_b00.*
IF rm_b00.b00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ningún módulo para este proceso.', 'stop')
	LET int_flag = 0
	CLOSE WINDOW w_ctbf206_1
	EXIT PROGRAM
END IF
CALL control_ingreso()
LET int_flag = 0
CLOSE WINDOW w_ctbf206_1
EXIT PROGRAM

END FUNCTION



FUNCTION control_ingreso()
DEFINE resp		CHAR(6)

CLEAR FORM
CALL mostrar_registro()
WHILE TRUE
	CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING rm_b00.*
	IF rm_b00.b00_compania IS NULL THEN
		CALL fgl_winmessage(vg_producto,'No existe ningún módulo para este proceso.','stop')
		EXIT WHILE
	END IF
	LET vm_anopro_ini = YEAR(rm_b00.b00_fecha_cm)
	LET vm_mespro_ini = MONTH(rm_b00.b00_fecha_cm) + 1
	IF vm_mespro_ini > 12 THEN
		LET vm_mespro_ini = 1
		LET vm_anopro_ini = vm_anopro_ini + 1
	END IF
	LET vm_anopro_fin = YEAR(vg_fecha)
	LET vm_mespro_fin = MONTH(vg_fecha) - 1
	IF vm_mespro_fin = 0 THEN
		LET vm_mespro_fin = 12
		LET vm_anopro_fin = vm_anopro_fin - 1
	END IF
	CALL mostrar_registro()
	CALL leer_mes()
	IF int_flag THEN
		EXIT WHILE
	END IF
	LET int_flag = 0
	CALL fl_mensaje_seguro_ejecutar_proceso() RETURNING resp
	IF resp <> 'Yes' THEN
		CONTINUE WHILE
	END IF
	CALL proceso_cierre_mensual()
	CALL fl_mostrar_mensaje('Cierre Mensual Termino Correctamente.', 'info')
	MESSAGE '                                                      '
END WHILE

END FUNCTION



FUNCTION mostrar_registro()

IF NOT validar_mes() THEN
	EXIT PROGRAM
END IF
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
DEFINE mensaje		VARCHAR(100)

LET int_flag = 0
INPUT BY NAME vm_mespro_ini, vm_anopro_ini, vm_mespro_fin, vm_anopro_fin
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	BEFORE FIELD vm_anopro_ini
		LET ano_ini = vm_anopro_ini
	BEFORE FIELD vm_anopro_fin
		LET ano_fin = vm_anopro_fin
	BEFORE FIELD vm_mespro_ini
		LET mes_ini = vm_mespro_ini
	BEFORE FIELD vm_mespro_fin
		LET mes_fin = vm_mespro_fin
	AFTER FIELD vm_mespro_ini
		IF vm_mespro_ini IS NULL THEN
			LET vm_mespro_ini = mes_ini
			DISPLAY BY NAME vm_mespro_ini
		END IF
		CALL fl_retorna_nombre_mes(vm_mespro_ini) RETURNING tit_mes_ini
		CALL fl_justifica_titulo('I', tit_mes_ini, 11)
			RETURNING tit_mes_ini
		DISPLAY BY NAME tit_mes_ini
		LET fecha = MDY(vm_mespro_ini, 01, vm_anopro_ini)
				+ 1 UNITS MONTH - 1 UNITS DAY
		IF fecha >= vg_fecha THEN
			IF MONTH(fecha) = MONTH(vg_fecha) THEN
				CALL fl_mostrar_mensaje('El mes actual no puede ser cerrado dentro del mismo mes.', 'exclamation')
			ELSE
				CALL fl_mostrar_mensaje('El periodo Inicial para el cierre mensual esta incorrecto.', 'exclamation')
			END IF
			CONTINUE INPUT
		END IF
		IF fecha < rm_b00.b00_fecha_cm THEN
			LET mensaje = 'El Mes de ', tit_mes_ini CLIPPED, '-',
					vm_anopro_ini USING "&&&&",
					' esta cerrado.'
			CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			NEXT FIELD vm_mespro_ini
		END IF
	AFTER FIELD vm_anopro_ini
		IF vm_anopro_ini IS NULL THEN
			LET vm_anopro_ini = ano_ini
			DISPLAY BY NAME vm_anopro_ini
		END IF
		LET fecha = MDY(vm_anopro_ini, 01, vm_anopro_ini)
				+ 1 UNITS MONTH
		IF YEAR(fecha) > YEAR(vg_fecha) THEN
			CALL fl_mostrar_mensaje('Año Inicial de proceso contable esta incorrecto.', 'exclamation')
			NEXT FIELD vm_anopro_ini
		END IF
	AFTER FIELD vm_mespro_fin
		IF vm_mespro_fin IS NULL THEN
			LET vm_mespro_fin = mes_fin
			DISPLAY BY NAME vm_mespro_fin
		END IF
		CALL fl_retorna_nombre_mes(vm_mespro_fin) RETURNING tit_mes_fin
		CALL fl_justifica_titulo('I', tit_mes_fin, 11)
			RETURNING tit_mes_fin
		DISPLAY BY NAME tit_mes_fin
		LET fecha = MDY(vm_mespro_fin, 01, vm_anopro_fin)
				+ 1 UNITS MONTH - 1 UNITS DAY
		IF fecha >= vg_fecha THEN
			IF MONTH(fecha) = MONTH(vg_fecha) THEN
				CALL fl_mostrar_mensaje('El mes actual no puede ser cerrado dentro del mismo mes.', 'exclamation')
			ELSE
				CALL fl_mostrar_mensaje('El periodo final para el cierre mensual esta incorrecto.', 'exclamation')
			END IF
			CONTINUE INPUT
		END IF
		IF fecha < rm_b00.b00_fecha_cm THEN
			LET mensaje = 'El Mes de ', tit_mes_fin CLIPPED, '-',
					vm_anopro_fin USING "&&&&",
					' esta cerrado.'
			CALL fl_mostrar_mensaje(mensaje, 'exclamation')
			NEXT FIELD vm_mespro_fin
		END IF
	AFTER FIELD vm_anopro_fin
		IF vm_anopro_fin IS NULL THEN
			LET vm_anopro_fin = ano_fin
			DISPLAY BY NAME vm_anopro_fin
		END IF
		LET fecha = MDY(vm_anopro_fin, 01, vm_anopro_fin)
				+ 1 UNITS MONTH
		IF YEAR(fecha) > YEAR(vg_fecha) THEN
			CALL fl_mostrar_mensaje('Año Final de proceso contable esta incorrecto.', 'exclamation')
			NEXT FIELD vm_anopro_fin
		END IF
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
		LET fecha = MDY(vm_mespro_ini, 01, vm_anopro_ini)
				+ 1 UNITS MONTH - 1 UNITS DAY
		IF fecha >= vg_fecha THEN
			IF MONTH(fecha) = MONTH(vg_fecha) THEN
				CALL fl_mostrar_mensaje('El mes actual no puede ser cerrado dentro del mismo mes.', 'exclamation')
			ELSE
				CALL fl_mostrar_mensaje('El periodo Inicial para el cierre mensual esta incorrecto.', 'exclamation')
			END IF
			CONTINUE INPUT
		END IF
		LET fecha = MDY(vm_mespro_fin, 01, vm_anopro_fin)
				+ 1 UNITS MONTH - 1 UNITS DAY
		IF fecha >= vg_fecha THEN
			IF MONTH(fecha) = MONTH(vg_fecha) THEN
				CALL fl_mostrar_mensaje('El mes actual no puede ser cerrado dentro del mismo mes.', 'exclamation')
			ELSE
				CALL fl_mostrar_mensaje('El periodo final para el cierre mensual esta incorrecto.', 'exclamation')
			END IF
			CONTINUE INPUT
		END IF
END INPUT

END FUNCTION



FUNCTION validar_mes()
DEFINE dia, mes, anio	SMALLINT
DEFINE fecha		DATE

CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING rm_b00.*
IF (MONTH(rm_b00.b00_fecha_cm) = 12 AND YEAR(rm_b00.b00_fecha_cm)) >=
    rm_b00.b00_anopro
THEN
	CALL fgl_winmessage(vg_producto,'Debe cerrar el año: ' || rm_b00.b00_anopro, 'exclamation')
	RETURN 0
END IF
LET mes  = MONTH(rm_b00.b00_fecha_cm) + 1
LET anio = YEAR(rm_b00.b00_fecha_cm)
IF mes = 13 THEN
	LET mes  = 1
	LET anio = anio + 1
END IF
IF mes < 12 THEN
	LET fecha = MDY(mes + 1,1,anio)
ELSE
	LET fecha = MDY(1,1,anio + 1)
END IF
LET fecha = fecha - 1 UNITS DAY
IF fecha > vg_fecha THEN
	CALL fgl_winmessage(vg_producto,'Muy pronto para cerrar este mes. Debe hacerlo el último día del mes', 'exclamation')
	RETURN 0
END IF
LET rm_b00.b00_fecha_cm = fecha
RETURN 1

END FUNCTION



FUNCTION proceso_cierre_mensual()
DEFINE primera, ultimo	SMALLINT
DEFINE anio		INTEGER
DEFINE mes		SMALLINT
DEFINE mes_ini, mes_fin	SMALLINT

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
		CALL mayorizacion_mensual(anio, mes)
		IF NOT validar_mes() THEN
			EXIT PROGRAM
		END IF
		CALL cerrar_mes(anio, mes)
	END FOR
END FOR

END FUNCTION



FUNCTION mayorizacion_mensual(anio, mes)
DEFINE anio		INTEGER
DEFINE mes		SMALLINT
DEFINE mayorizado	SMALLINT
DEFINE mensaje		VARCHAR(150)

CALL fl_mayorizacion_mes(vg_codcia, rm_b00.b00_moneda_base, anio, mes, 0)
	RETURNING mayorizado
IF NOT mayorizado THEN
	LET mensaje = 'No se pudo mayorizar el MES ', mes USING "&&", ' ',
		fl_justifica_titulo('I',fl_retorna_nombre_mes(mes), 11) CLIPPED,
		'  AÑO ', anio USING "&&&&", '. Ultimo periodo mayorizado ',
		(MDY(mes, 01, anio) - 1 UNITS DAY) USING "yyyy-mm", '.'
	CALL fl_mostrar_mensaje(mensaje, 'stop')
	EXIT PROGRAM
END IF
LET mensaje = 'MES ', mes USING "&&", ' ', fl_justifica_titulo('I',
	fl_retorna_nombre_mes(mes), 11) CLIPPED, '  AÑO ', anio USING "&&&&",
	'  MAYORIZADO CORRECTAMENTE.'
MESSAGE mensaje CLIPPED
SLEEP 2

END FUNCTION



FUNCTION cerrar_mes(anio, mes)
DEFINE anio		INTEGER
DEFINE mes		SMALLINT
DEFINE r_ctb		RECORD LIKE ctbt000.*
DEFINE mensaje		VARCHAR(150)

BEGIN WORK
WHENEVER ERROR CONTINUE
	DECLARE q_up CURSOR FOR
		SELECT * FROM ctbt000
			WHERE b00_compania = vg_codcia
		FOR UPDATE
	OPEN q_up
	FETCH q_up INTO r_ctb.*
	IF STATUS < 0 THEN
		ROLLBACK WORK
		CALL fl_mensaje_bloqueo_otro_usuario()
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
	WHENEVER ERROR STOP
	UPDATE ctbt000
		SET b00_fecha_cm = rm_b00.b00_fecha_cm
		WHERE CURRENT OF q_up
COMMIT WORK
LET mensaje = 'MES ', mes USING "&&", ' ', fl_justifica_titulo('I',
	fl_retorna_nombre_mes(mes), 11) CLIPPED, '  AÑO ', anio USING "&&&&",
	'  CERRADO CORRECTAMENTE.'
MESSAGE mensaje CLIPPED
SLEEP 2

END FUNCTION
