--------------------------------------------------------------------------------
-- Titulo           : ctbp305.4gl - Consulta Balance General
-- Elaboracion      : 23-nov-2001
-- Autor            : YEC
-- Formato Ejecucion: fglrun ctbp305 base módulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_max_rows	SMALLINT
DEFINE vm_num_act	SMALLINT
DEFINE vm_num_pas	SMALLINT
DEFINE vm_max_nivel	LIKE ctbt001.b01_nivel
DEFINE vm_suicheo 	SMALLINT
DEFINE vm_act_pos_pant	SMALLINT
DEFINE vm_act_pos_arr	SMALLINT
DEFINE vm_pas_pos_pant	SMALLINT
DEFINE vm_pas_pos_arr	SMALLINT
DEFINE tit_activo	VARCHAR(50)
DEFINE val_activo	DECIMAL(14,2)
DEFINE signo_activo	CHAR(2)
DEFINE tit_pasivo	VARCHAR(50)
DEFINE val_pasivo	DECIMAL(14,2)
DEFINE signo_pasivo	CHAR(2)
DEFINE rg_cont		RECORD LIKE ctbt000.*
DEFINE rm_par		RECORD 
				ano		SMALLINT,
				mes		SMALLINT,
				tit_mes		VARCHAR(10),
				moneda		LIKE gent013.g13_moneda,
				tit_mon		LIKE gent013.g13_nombre,
				b10_nivel	LIKE ctbt010.b10_nivel
			END RECORD
DEFINE rm_act		ARRAY[8000] OF RECORD 
				b10_cuenta	LIKE ctbt010.b10_cuenta,
				b10_descripcion	LIKE ctbt010.b10_descripcion,
				saldo_act	DECIMAL(14,2),
				signo_act	CHAR(2)
			END RECORD
DEFINE rm_pas		ARRAY[8000] OF RECORD 
				b10_cuenta	LIKE ctbt010.b10_cuenta,
				b10_descripcion	LIKE ctbt010.b10_descripcion,
				saldo_pas	DECIMAL(14,2),
				signo_pas	CHAR(2)
			END RECORD



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ctbp305.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN    -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'ctbp305'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE comando		VARCHAR(100)
DEFINE r_mon		RECORD LIKE gent013.*

LET vm_max_rows	= 8000
OPEN WINDOW wf AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 30,BORDER,
	      MESSAGE LINE LAST - 2)
OPEN FORM f_bal FROM "../forms/ctbf305_1"
DISPLAY FORM f_bal
CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING rg_cont.*
INITIALIZE rm_par.* TO NULL
LET rm_par.moneda = rg_cont.b00_moneda_base
LET rm_par.ano    = rg_cont.b00_anopro
LET rm_par.mes    = MONTH(vg_fecha)
SELECT MAX(b01_nivel) INTO vm_max_nivel FROM ctbt001
IF vm_max_nivel IS NULL THEN
	CALL fgl_winmessage(vg_producto,'Nivel no está configurado.','stop')
	EXIT PROGRAM
END IF
LET rm_par.b10_nivel = vm_max_nivel
CALL fl_lee_moneda(rm_par.moneda) RETURNING r_mon.*
LET rm_par.tit_mon = r_mon.g13_nombre
WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		RETURN
	END IF
	CALL carga_arreglos()
	LET vm_suicheo = 0 
	WHILE TRUE
		CALL muestra_activo()
		IF int_flag = 1 THEN
			EXIT WHILE
		END IF
		CALL muestra_pasivo()
		IF int_flag = 1 THEN
			EXIT WHILE
		END IF
	END WHILE
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE mon_aux		LIKE gent013.g13_moneda
DEFINE tit_aux		LIKE gent013.g13_nombre
DEFINE nivel		LIKE ctbt001.b01_nivel
DEFINE i, j		SMALLINT
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE rn		RECORD LIKE ctbt001.*

CALL fl_retorna_nombre_mes(rm_par.mes) RETURNING rm_par.tit_mes
LET rm_par.tit_mes = fl_justifica_titulo('I', rm_par.tit_mes, 10)
LET int_flag = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(F2)
		IF INFIELD(moneda) THEN
                       	CALL fl_ayuda_monedas() RETURNING mon_aux, tit_aux, i
                       	IF mon_aux IS NOT NULL THEN
				LET rm_par.moneda  = mon_aux
				LET rm_par.tit_mon = tit_aux
                               	DISPLAY BY NAME rm_par.moneda, rm_par.tit_mon
                       	END IF
                END IF
		IF INFIELD(b10_nivel) THEN
                       	CALL fl_ayuda_nivel_cuentas() 
				RETURNING nivel, tit_aux, i, j
                       	IF nivel IS NOT NULL THEN
				LET rm_par.b10_nivel = nivel
                               	DISPLAY BY NAME rm_par.b10_nivel
                       	END IF
                END IF
                LET int_flag = 0
	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda) RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Moneda no existe', 'exclamation')
				NEXT FIELD moneda
			END IF
			LET rm_par.tit_mon = r_mon.g13_nombre
			DISPLAY BY NAME rm_par.tit_mon
		ELSE
			LET rm_par.tit_mon = NULL
			DISPLAY BY NAME rm_par.tit_mon
		END IF
	AFTER FIELD b10_nivel
		IF rm_par.b10_nivel IS NOT NULL THEN
			CALL fl_lee_nivel_cuenta(rm_par.b10_nivel)
				RETURNING rn.*
			IF rn.b01_nivel IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Nivel de cuenta no existe', 'exclamation')
				NEXT FIELD b10_nivel
			END IF
		END IF
	AFTER FIELD mes
		IF rm_par.mes IS NOT NULL THEN
			CALL fl_retorna_nombre_mes(rm_par.mes) RETURNING 
				rm_par.tit_mes
			LET rm_par.tit_mes = fl_justifica_titulo('I', rm_par.tit_mes, 10)
		ELSE
			LET rm_par.tit_mes = NULL
		END IF	
		DISPLAY BY NAME rm_par.tit_mes
END INPUT

END FUNCTION



FUNCTION carga_arreglos()
DEFINE r_ctas		RECORD LIKE ctbt010.*
DEFINE i		SMALLINT
DEFINE suma		CHAR(3)
DEFINE saldo		DECIMAL(14,2)
DEFINE val1, val2	DECIMAL(14,2)
DEFINE fecha		DATE
DEFINE fec_ini, fec_fin	DATE
DEFINE flag		CHAR(1)

LET fecha = MDY(rm_par.mes, 1, rm_par.ano) + 1 UNITS MONTH - 1 UNITS DAY
DECLARE q_ctas CURSOR FOR SELECT * FROM ctbt010
	WHERE b10_compania = vg_codcia AND
	      b10_tipo_cta = 'B'       AND
	      b10_nivel   <= rm_par.b10_nivel
	ORDER BY b10_cuenta
LET vm_num_act = 1 
LET vm_num_pas = 1 
LET tit_activo   = NULL
LET signo_activo = NULL
LET tit_pasivo   = NULL
LET val_pasivo   = 0
LET signo_pasivo = NULL
FOREACH q_ctas INTO r_ctas.*
	IF r_ctas.b10_cuenta[1,1] = '1' THEN
		IF r_ctas.b10_nivel = 1 THEN
			LET tit_activo = r_ctas.b10_descripcion
			--IF rm_par.ano < 2012 THEN
				LET val_activo = fl_obtiene_saldo_contable(vg_codcia,
					r_ctas.b10_cuenta, rm_par.moneda,
					fecha, 'A')
			{--
			ELSE
				LET val_activo = saldo_cuenta_sin_cierre(
						r_ctas.b10_cuenta, fecha,
						r_ctas.b10_nivel)
			END IF
			--}
			LET signo_activo = obtiene_signo_contable(val_activo)
		END IF
		LET rm_act[vm_num_act].b10_cuenta      = r_ctas.b10_cuenta
		LET rm_act[vm_num_act].b10_descripcion = r_ctas.b10_descripcion
		--IF rm_par.ano < 2012 THEN
			LET rm_act[vm_num_act].saldo_act       =
			fl_obtiene_saldo_contable(vg_codcia, r_ctas.b10_cuenta,
						rm_par.moneda, fecha, 'A')
		{--
		ELSE
			LET rm_act[vm_num_act].saldo_act       =
				saldo_cuenta_sin_cierre(r_ctas.b10_cuenta,
							fecha, r_ctas.b10_nivel)
		END IF
		--}
		LET rm_act[vm_num_act].signo_act       = 
			    obtiene_signo_contable(rm_act[vm_num_act].saldo_act)
		IF vm_num_act > vm_max_rows THEN
			CONTINUE FOREACH
		END IF
		LET vm_num_act = vm_num_act + 1
		IF vm_num_act > vm_max_rows THEN
			CONTINUE FOREACH
		END IF
	ELSE
		IF r_ctas.b10_nivel = 1 THEN
			LET suma = NULL
			IF tit_pasivo IS NOT NULL THEN
				LET suma = ' + '
			END IF
			LET tit_pasivo = tit_pasivo CLIPPED, suma,
					 r_ctas.b10_descripcion CLIPPED
			LET tit_pasivo = fl_justifica_titulo('I', tit_pasivo,50)
			--IF r_ctas.b10_cuenta[1, 1] <> '3' THEN
			--IF rm_par.ano < 2012 THEN
				LET saldo = fl_obtiene_saldo_contable(vg_codcia,
						r_ctas.b10_cuenta,
						rm_par.moneda, fecha, 'A')
			{--
			ELSE
				LET saldo = saldo_cuenta_sin_cierre(
							r_ctas.b10_cuenta,
							fecha, r_ctas.b10_nivel)
			END IF
			--}
			{--
			ELSE
				LET fec_ini = MDY(MONTH(fecha), 1, YEAR(fecha))
				LET fec_fin = fecha
				LET flag    = 'S'
				IF r_ctas.b10_nivel = vm_max_nivel THEN
					LET fec_ini = fecha
					LET fec_fin = TODAY
					LET flag    = 'A'
				END IF
				CALL fl_obtener_saldo_cuentas_patrimonio(
						vg_codcia, r_ctas.b10_cuenta,
						rm_par.moneda, fec_ini, fec_fin,
						flag)
					RETURNING val1, val2
				LET saldo = val1 + val2
			END IF
			--}
			LET val_pasivo = val_pasivo + saldo
		END IF
		LET rm_pas[vm_num_pas].b10_cuenta      = r_ctas.b10_cuenta
		LET rm_pas[vm_num_pas].b10_descripcion = r_ctas.b10_descripcion
		--IF r_ctas.b10_cuenta[1, 1] <> '3' THEN
		--IF rm_par.ano < 2012 THEN
			LET rm_pas[vm_num_pas].saldo_pas =
				fl_obtiene_saldo_contable(vg_codcia,
					r_ctas.b10_cuenta, rm_par.moneda,
					fecha, 'A')
		{--
		ELSE
			LET rm_pas[vm_num_pas].saldo_pas =
				saldo_cuenta_sin_cierre(r_ctas.b10_cuenta,
							fecha, r_ctas.b10_nivel)
		END IF
		--}
		{--
		ELSE
			LET fec_ini = MDY(MONTH(fecha), 1, YEAR(fecha))
			LET fec_fin = fecha
			LET flag    = 'S'
			IF r_ctas.b10_nivel = vm_max_nivel THEN
				LET fec_ini = fecha
				LET fec_fin = TODAY
				LET flag    = 'A'
			END IF
			CALL fl_obtener_saldo_cuentas_patrimonio(vg_codcia,
					r_ctas.b10_cuenta, rm_par.moneda,
					fec_ini, fec_fin, flag)
				RETURNING val1, val2
			LET rm_pas[vm_num_pas].saldo_pas = val1 + val2
		END IF
		--}
		LET rm_pas[vm_num_pas].signo_pas       = 
			    obtiene_signo_contable(rm_pas[vm_num_pas].saldo_pas)
		IF vm_num_pas > vm_max_rows THEN
			CONTINUE FOREACH
		END IF
		LET vm_num_pas = vm_num_pas + 1
		IF vm_num_pas > vm_max_rows THEN
			CONTINUE FOREACH
		END IF
	END IF	
END FOREACH
LET signo_pasivo = obtiene_signo_contable(val_pasivo)
LET vm_num_act = vm_num_act - 1
LET vm_num_pas = vm_num_pas - 1
DISPLAY BY NAME tit_activo, val_activo, signo_activo
DISPLAY BY NAME tit_pasivo, val_pasivo, signo_pasivo
FOR i = 1 TO fgl_scr_size('rm_pas')
	IF i <= vm_num_pas THEN
		DISPLAY rm_pas[i].* TO rm_pas[i].*
	ELSE
		CLEAR rm_pas[i].*
	END IF
END FOR

END FUNCTION



FUNCTION muestra_activo()
DEFINE i		SMALLINT

CALL set_count(vm_num_act)
LET int_flag = 0
DISPLAY ARRAY rm_act TO rm_act.*
	ON KEY(F5)
		LET i = arr_curr()
		CALL control_movimientos(rm_act[i].b10_cuenta) 
	BEFORE DISPLAY
		IF vm_suicheo THEN
			CALL dialog.setcurrline(vm_act_pos_pant,vm_act_pos_arr)
		END IF
	BEFORE ROW
		LET i = arr_curr()
		CALL muestra_contadores(i, vm_num_act, 0, vm_num_pas)
END DISPLAY
IF NOT int_flag THEN
	LET vm_suicheo = 1
	LET vm_act_pos_pant = scr_line()
	LET vm_act_pos_arr  = arr_curr()
END IF

END FUNCTION



FUNCTION muestra_pasivo()
DEFINE i		SMALLINT

CALL set_count(vm_num_pas)
LET int_flag = 0
DISPLAY ARRAY rm_pas TO rm_pas.*
	ON KEY(F5)
		LET i = arr_curr()
		CALL control_movimientos(rm_pas[i].b10_cuenta) 
	BEFORE DISPLAY
		IF vm_suicheo THEN
			CALL dialog.setcurrline(vm_pas_pos_pant,vm_pas_pos_arr)
		END IF
	BEFORE ROW
		LET i = arr_curr()
		CALL muestra_contadores(0, vm_num_act, i, vm_num_pas)
END DISPLAY
IF NOT int_flag THEN
	LET vm_suicheo = 1
	LET vm_pas_pos_pant = scr_line()
	LET vm_pas_pos_arr  = arr_curr()
END IF

END FUNCTION



FUNCTION control_movimientos(cuenta)
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE min_nivel	SMALLINT
DEFINE r_cta		RECORD LIKE ctbt010.*
DEFINE mensaje		VARCHAR(62)
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE comando		VARCHAR(130)

CALL fl_lee_cuenta(vg_codcia, cuenta) RETURNING r_cta.*
LET min_nivel = vm_max_nivel - 2
IF r_cta.b10_permite_mov = 'N' THEN
	CALL fl_mostrar_mensaje('Cuenta no permite movimiento.', 'exclamation')
	--LET mensaje = 'Solo puede ver movimientos de cuentas de nivel', min_nivel USING '#&', ' en adelante'
	--CALL fgl_winmessage(vg_producto, mensaje, 'exclamation')
	RETURN
END IF
LET fecha_ini = MDY(rm_par.mes, 1, rm_par.ano)
LET fecha_fin = fecha_ini + 1 UNITS MONTH - 1 UNITS DAY
LET comando = 'fglrun ctbp302 ' || vg_base || ' ' ||
		vg_modulo || ' ' ||
		vg_codcia || ' ' ||
		cuenta || ' ' ||
		fecha_ini || ' ' ||
		fecha_fin || ' ' ||
		rm_par.moneda
RUN comando

END FUNCTION



FUNCTION obtiene_signo_contable(valor)
DEFINE valor		DECIMAL(15,2)

IF valor < 0 THEN
	RETURN 'Cr'
END IF
IF valor > 0 THEN
	RETURN 'Db'
END IF
RETURN '  '

END FUNCTION



FUNCTION saldo_cuenta_sin_cierre(cuenta, fecha, nivel)
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE fecha		LIKE ctbt012.b12_fec_proceso
DEFINE nivel		LIKE ctbt010.b10_nivel
DEFINE expr_cta		VARCHAR(200)
DEFINE query		CHAR(2000)
DEFINE saldo		DECIMAL(12,2)

{
CASE nivel
	WHEN 1 LET expr_cta = "   AND b11_cuenta[1, 1]  = '", cuenta[1, 1], "'"
	WHEN 2 LET expr_cta = "   AND b11_cuenta[1, 2]  = '", cuenta[1, 2], "'"
	WHEN 3 LET expr_cta = "   AND b11_cuenta[1, 4]  = '", cuenta[1, 4], "'"
	WHEN 4 LET expr_cta = "   AND b11_cuenta[1, 6]  = '", cuenta[1, 6], "'"
	WHEN 5 LET expr_cta = "   AND b11_cuenta[1, 8]  = '", cuenta[1, 8], "'"
	WHEN 6 LET expr_cta = "   AND b11_cuenta        = '", cuenta CLIPPED,"'"
END CASE
}
LET query = "SELECT NVL(b11_db_ano_ant - b11_cr_ano_ant, 0.00) saldo ",
		" FROM t_bal_gen ",
		" WHERE b11_compania = ", vg_codcia,
		"   AND b11_cuenta   = '", cuenta, "'",
		"   AND b11_moneda   = 'DO' ",
		"   AND b11_ano      = ", rm_par.ano,
		" INTO TEMP t1 "
PREPARE exec_t1 FROM query
EXECUTE exec_t1
SELECT * INTO saldo FROM t1
DROP TABLE t1
RETURN saldo

END FUNCTION



FUNCTION muestra_contadores(num_rowc, max_rowc, num_rowd, max_rowd)
DEFINE num_rowc, max_rowc	SMALLINT
DEFINE num_rowd, max_rowd	SMALLINT

DISPLAY BY NAME num_rowc, max_rowc, num_rowd, max_rowd

END FUNCTION
