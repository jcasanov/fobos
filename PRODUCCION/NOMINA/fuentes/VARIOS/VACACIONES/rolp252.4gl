--------------------------------------------------------------------------------
-- Titulo           : rolp252.4gl - Proceso de Vacaciones
-- Elaboracion      : 12-Dic-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp252 base modulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_b00		RECORD LIKE ctbt000.*
DEFINE rm_n00		RECORD LIKE rolt000.*
DEFINE rm_n05		RECORD LIKE rolt005.*
DEFINE rm_n39		RECORD LIKE rolt039.*
DEFINE rm_n39_act	RECORD LIKE rolt039.*
DEFINE rm_n90		RECORD LIKE rolt090.*
DEFINE rm_detvac	ARRAY[6000] OF RECORD
				cod_trab	LIKE rolt039.n39_cod_trab,
				nombres		LIKE rolt030.n30_nombres,
				n39_periodo_ini	LIKE rolt039.n39_periodo_ini,
				n39_periodo_fin	LIKE rolt039.n39_periodo_fin,
				n39_dias_vac	LIKE rolt039.n39_dias_vac,
				n39_valor_vaca	LIKE rolt039.n39_valor_vaca
			END RECORD
DEFINE rm_descto	ARRAY[200] OF RECORD
				n40_cod_rubro	LIKE rolt040.n40_cod_rubro,
				n06_nombre	LIKE rolt006.n06_nombre,
				n40_valor	LIKE rolt040.n40_valor
			END RECORD
DEFINE rm_des_aux	ARRAY[200] OF RECORD
				n40_cod_rubro	LIKE rolt040.n40_cod_rubro,
				n06_nombre	LIKE rolt006.n06_nombre,
				n40_valor	LIKE rolt040.n40_valor,
				n40_num_prest	LIKE rolt040.n40_num_prest
			END RECORD
DEFINE rm_anticipo	ARRAY[200] OF RECORD
				n40_cod_rubro	LIKE rolt040.n40_cod_rubro,
				n40_num_prest	LIKE rolt040.n40_num_prest
			END RECORD
DEFINE rm_diasgoz	ARRAY[20] OF RECORD
				n47_cod_liqrol	LIKE rolt047.n47_cod_liqrol,
				n47_fecha_ini	LIKE rolt047.n47_fecha_ini,
				n47_fecha_fin	LIKE rolt047.n47_fecha_fin,
				n47_max_dias	LIKE rolt047.n47_max_dias,
				n47_dias_real	LIKE rolt047.n47_dias_real,
				n47_dias_goza	LIKE rolt047.n47_dias_goza,
				n47_fecini_vac	LIKE rolt047.n47_fecini_vac,
				n47_fecfin_vac	LIKE rolt047.n47_fecfin_vac,
				n47_secuencia	LIKE rolt047.n47_secuencia,
				n47_estado	LIKE rolt047.n47_estado
			END RECORD
DEFINE vm_nivel		LIKE ctbt001.b01_nivel
DEFINE vm_proceso	LIKE rolt039.n39_proceso
DEFINE vm_vac_goz	LIKE rolt039.n39_proceso
DEFINE vm_vac_pag	LIKE rolt039.n39_proceso
DEFINE vm_anticipo	LIKE rolt039.n39_proceso
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_max_det	SMALLINT
DEFINE vm_num_det	SMALLINT
DEFINE vm_row_cur	SMALLINT
DEFINE vm_max_rub	SMALLINT
DEFINE vm_num_rub	SMALLINT
DEFINE vm_total		DECIMAL(14,2)
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_anio_arr	SMALLINT
DEFINE vm_dias_min_par	SMALLINT   -- Dias minimo transcurridos para calculo
				   -- de vacaciones parciales.


MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp252.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 4 AND num_args() <> 6 AND num_args() <> 8
   AND num_args() <> 9
THEN
	-- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp252'
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
DEFINE r_n03		RECORD LIKE rolt003.*

LET vm_proceso = 'VA'
CALL fl_lee_proceso_roles(vm_proceso) RETURNING r_n03.*
IF r_n03.n03_proceso IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configurado el proceso VACACIONES en la tabla rolt003.', 'stop')
	EXIT PROGRAM
END IF
LET vm_vac_goz = 'VA'
LET vm_vac_pag = 'VP'
CALL fl_lee_proceso_roles(vm_vac_pag) RETURNING r_n03.*
IF r_n03.n03_proceso IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configurado el proceso VACACIONES PAGADAS en la tabla rolt003.', 'exclamation')
	EXIT PROGRAM
END IF
LET vm_anticipo = 'AV'
CALL fl_lee_conf_adic_rol(vg_codcia) RETURNING rm_n90.*
IF rm_n90.n90_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configuracion adicional de nomina en la tabla rolt090.', 'stop')
	EXIT PROGRAM
END IF
LET vm_dias_min_par = rm_n90.n90_dias_min_par		--60
LET vm_anio_arr     = rm_n90.n90_anio_ini_vac		--2004
CALL fl_nivel_isolation()
CALL fl_retorna_proceso_roles_activo(vg_codcia) RETURNING rm_n05.*
IF num_args() = 3 THEN
	IF rm_n05.n05_proceso <> vm_proceso AND
	   rm_n05.n05_proceso <> vm_vac_pag
	THEN
		CALL fl_mostrar_mensaje('No puede ejecutar este proceso mientras exista otro proceso de Nomina Activo.', 'stop')
		EXIT PROGRAM
	END IF
	IF rm_n05.n05_proceso <> vm_vac_pag THEN
		CALL fl_mostrar_mensaje('No puede ejecutar este proceso mientras exista otro proceso de Nomina Activo.', 'stop')
		--EXIT PROGRAM
	END IF
END IF
CALL fl_lee_compania_contabilidad(vg_codcia) RETURNING rm_b00.*
IF rm_b00.b00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ninguna compañía configurada en CONTABILIDAD.', 'stop')
	EXIT PROGRAM
END IF
SELECT MAX(b01_nivel) INTO vm_nivel FROM ctbt001
IF vm_nivel IS NULL THEN
	CALL fl_mostrar_mensaje('No existe ningun nivel de cuenta configurado en la compañía.','stop')
	EXIT PROGRAM
END IF
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 22
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rolf252_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf252_1 FROM '../forms/rolf252_1'
ELSE
	OPEN FORM f_rolf252_1 FROM '../forms/rolf252_1c'
END IF
DISPLAY FORM f_rolf252_1
CALL fl_lee_parametro_general_roles() RETURNING rm_n00.*
CALL muestra_botones()
INITIALIZE rm_n39.*, vm_fecha_ini, vm_fecha_fin TO NULL
LET vm_max_det = 6000
IF num_args() <> 3 THEN
	CALL llamada_otro_prog()
	RETURN
END IF
LET vm_row_cur        = 0
LET vm_num_det        = 0
LET rm_n39.n39_estado = 'X'
CALL muestra_contadores()
{--
IF rm_n39_act.n39_estado = 'A' THEN
	CALL borrar_pantalla()
	CALL menu_entrada()
	RETURN
END IF
--}
WHILE TRUE
	LET vm_proceso = vm_vac_goz
	CALL borrar_pantalla()
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_consulta()
END WHILE

END FUNCTION



FUNCTION retorna_proceso_vaciones_activo(cod_trab)
DEFINE cod_trab		LIKE rolt039.n39_cod_trab
DEFINE cont		INTEGER

INITIALIZE rm_n39_act.* TO NULL
SELECT COUNT(*) INTO cont FROM rolt039
	WHERE n39_compania  = vg_codcia
	  AND n39_proceso  IN (vm_vac_goz, vm_vac_pag)
	  AND n39_cod_trab  = cod_trab
	  AND n39_estado    = 'A'
IF cont > 1 THEN
	CALL fl_mostrar_mensaje('No puede ejecutar este proceso porque existe mas de una Vacación Activa para este empleado.', 'stop')
	EXIT PROGRAM
END IF
SELECT * INTO rm_n39_act.*
	FROM rolt039
	WHERE n39_compania = vg_codcia
	  AND n39_proceso  = vm_vac_goz
	  AND n39_cod_trab = cod_trab
	  AND n39_estado   = 'A'
UNION
SELECT * INTO rm_n39_act.*
	FROM rolt039
	WHERE n39_compania = vg_codcia
	  AND n39_proceso  = vm_vac_pag
	  AND n39_cod_trab = cod_trab
	  AND n39_estado   = 'A'

END FUNCTION



FUNCTION llamada_otro_prog()
DEFINE r_n30		RECORD LIKE rolt030.*

LET vm_row_cur        = 0
LET vm_num_det        = 0
LET rm_n39.n39_estado = arg_val(4)
IF num_args() >= 6 THEN
	LET rm_n39.n39_proceso     = arg_val(5)
	LET rm_n39.n39_cod_trab    = arg_val(6)
	LET rm_n39.n39_periodo_ini = arg_val(7)
	LET rm_n39.n39_periodo_fin = arg_val(8)
END IF
CALL fl_lee_trabajador_roles(vg_codcia,	rm_n39.n39_cod_trab) RETURNING r_n30.*
DISPLAY BY NAME rm_n39.n39_estado, rm_n39.n39_cod_trab, r_n30.n30_nombres,
		vm_fecha_ini, vm_fecha_fin
IF num_args() = 8 THEN
	CALL control_asignar_vac()
	RETURN
END IF
IF num_args() = 9 THEN
	CALL control_dias_gozados()
	RETURN
END IF
IF rm_n39.n39_estado <> 'A' THEN
	CALL control_consulta()
	RETURN
END IF
CALL menu_entrada()

END FUNCTION



FUNCTION menu_entrada()

MENU 'OPCIONES'
	COMMAND KEY('M') 'Modificar Comp.'
		CALL lee_parametros()
		IF NOT int_flag THEN
			CALL control_consulta()
		END IF
	COMMAND KEY('L') 'Liquidación'
		CALL control_cerrar_vac()
	COMMAND KEY('S') 'Salir' 'Salir del Programa.'
		EXIT MENU
END MENU

END FUNCTION



FUNCTION muestra_botones()

--#DISPLAY 'Cod.'	TO tit_col1
--#DISPLAY 'Empleado'	TO tit_col2
--#DISPLAY 'Fec. Ini.'	TO tit_col3
--#DISPLAY 'Fec. Fin.'	TO tit_col4
--#DISPLAY 'D. Va.'	TO tit_col5
--#DISPLAY 'Valor'	TO tit_col6

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE fecha		DATE
DEFINE mensaje		VARCHAR(200)

LET fecha = MDY(01, 01, rm_n90.n90_anio_ini_vac)
LET int_flag = 0
INPUT BY NAME rm_n39.n39_cod_trab, rm_n39.n39_estado, vm_fecha_ini, vm_fecha_fin
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(n39_cod_trab) THEN
                        CALL fl_ayuda_codigo_empleado(vg_codcia)
                                RETURNING r_n30.n30_cod_trab, r_n30.n30_nombres
                        IF r_n30.n30_cod_trab IS NOT NULL THEN
                                LET rm_n39.n39_cod_trab = r_n30.n30_cod_trab
                                DISPLAY BY NAME rm_n39.n39_cod_trab,
						r_n30.n30_nombres
                        END IF
                END IF
		LET int_flag = 0
	AFTER FIELD n39_cod_trab
		IF rm_n39.n39_cod_trab IS NOT NULL THEN
			CALL fl_lee_trabajador_roles(vg_codcia,
							rm_n39.n39_cod_trab)
                        	RETURNING r_n30.*
			IF r_n30.n30_compania IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el código de este empleado en la Compañía.','exclamation')
				NEXT FIELD n39_cod_trab
			END IF
			DISPLAY BY NAME r_n30.n30_nombres
			IF r_n30.n30_estado = 'I' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD n39_cod_trab
			END IF
		ELSE
			CLEAR n30_nombres
		END IF
	AFTER FIELD vm_fecha_ini
		IF rm_n39.n39_estado <> 'P' THEN
			LET vm_fecha_ini = NULL
			LET vm_fecha_fin = NULL
			DISPLAY BY NAME vm_fecha_ini, vm_fecha_fin
			CONTINUE INPUT
		END IF
		IF vm_fecha_ini IS NOT NULL THEN
			IF vm_fecha_ini > TODAY THEN
				CALL fl_mostrar_mensaje('La fecha inicial no puede ser mayor a la fecha de hoy.', 'exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
			IF vm_fecha_ini < fecha THEN
				LET mensaje = 'La fecha inicial no puede ser ',
						'menor a la fecha ',
						fecha USING "dd-mm-yyyy", '.'
				CALL fl_mostrar_mensaje(mensaje, 'exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
		END IF
	AFTER FIELD vm_fecha_fin
		IF rm_n39.n39_estado <> 'P' THEN
			LET vm_fecha_ini = NULL
			LET vm_fecha_fin = NULL
			DISPLAY BY NAME vm_fecha_ini, vm_fecha_fin
			CONTINUE INPUT
		END IF
		IF vm_fecha_fin IS NOT NULL THEN
			IF vm_fecha_fin > TODAY THEN
				CALL fl_mostrar_mensaje('La fecha final no puede ser mayor a la fecha de hoy.', 'exclamation')
				NEXT FIELD vm_fecha_fin
			END IF
		END IF
	AFTER INPUT
		IF vm_fecha_ini IS NOT NULL AND vm_fecha_fin IS NULL THEN
			CALL fl_mostrar_mensaje('Digite la fecha final.', 'exclamation')
			NEXT FIELD vm_fecha_fin
		END IF
		IF vm_fecha_ini IS NULL AND vm_fecha_fin IS NOT NULL THEN
			CALL fl_mostrar_mensaje('Digite la fecha inicial.', 'exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
		IF vm_fecha_ini IS NOT NULL AND vm_fecha_fin IS NOT NULL THEN
			IF vm_fecha_ini > vm_fecha_fin THEN
				CALL fl_mostrar_mensaje('La fecha inicial no puede ser mayor a la fecha final.', 'exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
		END IF
		IF rm_n39.n39_estado <> 'P' AND NOT calculado_impto_renta() THEN
			CALL fl_mostrar_mensaje('Ya se ha calculado el IMPUESTO A LA RENTA para este mes. Por favor liquide las vacaciones "pendientes" y "en proceso", el próximo mes.', 'info')
			IF vg_codloc <> 3 THEN
				CONTINUE INPUT
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION calculado_impto_renta()
DEFINE fecha		DATETIME YEAR TO MONTH
DEFINE fecha_ult	DATE
DEFINE resul		SMALLINT
DEFINE valor		LIKE rolt033.n33_valor

LET resul = 0
CALL fecha_ultima_quincena() RETURNING fecha_ult
LET fecha = EXTEND(fecha_ult, YEAR TO MONTH)
IF fecha < EXTEND(TODAY, YEAR TO MONTH) THEN
	RETURN 1
END IF
LET valor = 0
SELECT NVL(SUM(n33_valor), 0) INTO valor
	FROM rolt033
	WHERE n33_compania          = vg_codcia
	  --AND n33_cod_liqrol        IN ("Q1", "Q2")
	  AND n33_cod_liqrol        = "Q2"
	  AND EXTEND(n33_fecha_fin,
		YEAR TO MONTH)      = fecha
	  AND n33_cod_rubro         = (SELECT n06_cod_rubro
					FROM rolt006
					WHERE n06_estado     = 'A'
					  AND n06_flag_ident = 'IR')
	  AND n33_valor             > 0
IF valor = 0 THEN
	LET resul = 1
END IF
RETURN resul

END FUNCTION



FUNCTION control_consulta()
DEFINE i, salir		SMALLINT

WHILE TRUE
	IF NOT preparar_query() THEN
		RETURN
	END IF
	FOR i = 1 TO 10
		LET rm_orden[i] = '' 
	END FOR
	LET vm_columna_1           = 2
	LET vm_columna_2           = 3
	LET rm_orden[vm_columna_1] = 'ASC'
	LET rm_orden[vm_columna_2] = 'DESC'
	WHILE TRUE
		CALL cargar_datos_arr()
		CALL muestra_detalle() RETURNING salir
		IF int_flag THEN
			UPDATE rolt005
				SET n05_activo     = 'N',
				    n05_fecini_act = NULL,
				    n05_fecfin_act = NULL
				WHERE n05_compania  = vg_codcia
				  AND n05_proceso  IN (vm_vac_pag, vm_vac_goz)
				  AND n05_activo    = 'S'
			EXIT WHILE
		END IF
	END WHILE
	DROP TABLE tmp_vacaciones
	IF salir = 1 THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION preparar_query()
DEFINE query		CHAR(1500)
DEFINE expr_trab	VARCHAR(100)
DEFINE expr_fec		VARCHAR(200)

IF rm_n39.n39_estado = 'X' THEN
	RETURN preparar_empleados_pendientes()
END IF
LET expr_trab = NULL
IF rm_n39.n39_cod_trab IS NOT NULL THEN
	LET expr_trab = '   AND n39_cod_trab = ', rm_n39.n39_cod_trab
END IF
LET expr_fec = NULL
IF vm_fecha_ini IS NOT NULL THEN
	LET expr_fec = '   AND DATE(n39_fecing) BETWEEN "', vm_fecha_ini,
						 '" AND "', vm_fecha_fin, '"'
END IF
LET query = 'SELECT n39_cod_trab, n30_nombres, n39_periodo_ini, ',
		'n39_periodo_fin, (n39_dias_vac + n39_dias_adi) n39_dias_vac, ',
		' CASE WHEN n39_estado = "A"',
			' THEN n39_valor_vaca + n39_valor_adic',
			' ELSE n39_neto ',
		' END n39_valor_vaca ',
		' FROM rolt039, rolt030 ',
		' WHERE n39_compania = ', vg_codcia,
		'   AND n39_proceso  IN("', vm_vac_goz, '", "',vm_vac_pag, '")',
		expr_trab CLIPPED,
		expr_fec CLIPPED,
		'   AND n39_estado   = "', rm_n39.n39_estado, '"',
		'   AND n30_compania = n39_compania ',
		'   AND n30_cod_trab = n39_cod_trab ',
		' INTO TEMP tmp_vacaciones '
PREPARE temp FROM query
EXECUTE temp
DECLARE q_temp CURSOR FOR SELECT * FROM tmp_vacaciones
OPEN q_temp
FETCH q_temp
IF STATUS = NOTFOUND THEN
	CLOSE q_temp
	FREE q_temp
	DROP TABLE tmp_vacaciones
	CALL fl_mensaje_consulta_sin_registros()
	RETURN 0
END IF
CLOSE q_temp
FREE q_temp
RETURN 1

END FUNCTION



FUNCTION preparar_empleados_pendientes()
DEFINE fecha_ult	LIKE rolt032.n32_fecha_fin
DEFINE query		CHAR(4000)
DEFINE expr_trab	VARCHAR(100)
DEFINE cuantos		INTEGER

LET expr_trab = NULL
IF rm_n39.n39_cod_trab IS NOT NULL THEN
	LET expr_trab = '   AND n32_cod_trab     = ', rm_n39.n39_cod_trab
END IF
LET query = 'SELECT UNIQUE n32_compania cia, n32_cod_trab cod_trab, ',
			'n32_ano_proceso anio ',
		' FROM rolt032 ',
		' WHERE n32_compania     = ', vg_codcia,
		'   AND n32_cod_liqrol  IN("Q1", "Q2") ',
		expr_trab CLIPPED,
		'   AND n32_ano_proceso  > ', rm_n90.n90_anio_ini_vac,
		' INTO TEMP tmp_n32 '
PREPARE exec_n32 FROM query
EXECUTE exec_n32
SELECT COUNT(*) INTO cuantos FROM tmp_n32
IF cuantos = 0 THEN
	DROP TABLE tmp_n32
	CALL fl_mensaje_consulta_sin_registros()
	RETURN 0
END IF
CALL fecha_ultima_quincena() RETURNING fecha_ult
LET query = 'SELECT n30_compania, n30_cod_trab, n30_nombres,',
		' CASE WHEN EXTEND(n30_fecha_ing, MONTH TO DAY) = "02-29"',
		' THEN MDY(MONTH(n30_fecha_ing), 28, YEAR(n30_fecha_ing))',
		' ELSE n30_fecha_ing',
		' END n30_fecha_ing, n30_sueldo_mes ',
		' FROM rolt030 ',
		' WHERE n30_compania  = ', vg_codcia,
		'   AND n30_estado    = "A" ',
		'   AND n30_tipo_trab = "N" ',
		' INTO TEMP tmp_n30 '
PREPARE exec_n30 FROM query
EXECUTE exec_n30
LET query = 'SELECT n30_cod_trab cod_t, n30_nombres nom, ',
		'MDY(MONTH(n30_fecha_ing), DAY(n30_fecha_ing),anio - 1) p_ini,',
		'MDY(MONTH(n30_fecha_ing), DAY(n30_fecha_ing), anio)',
				' - 1 UNITS DAY p_fin, ',
		rm_n00.n00_dias_vacac, ' + ',
		'(CASE WHEN (MDY(MONTH(n30_fecha_ing), DAY(n30_fecha_ing),',
				' anio)) ',
			'>= (n30_fecha_ing + (', rm_n00.n00_ano_adi_vac,
			' - 1) UNITS YEAR - 1 UNITS DAY) ',
			'THEN CASE WHEN (', rm_n00.n00_dias_vacac, ' + ',
			'((YEAR(MDY(MONTH(n30_fecha_ing), DAY(n30_fecha_ing), ',
			'anio)) - YEAR(n30_fecha_ing + (',
			rm_n00.n00_ano_adi_vac, ' - 1) UNITS YEAR - ',
			'1 UNITS DAY)) * ', rm_n00.n00_dias_adi_va, ')) > ',
			rm_n00.n00_max_vacac,
			' THEN ', rm_n00.n00_max_vacac, ' - ',
					rm_n00.n00_dias_vacac,
			' ELSE ((YEAR(MDY(MONTH(n30_fecha_ing), ',
				'DAY(n30_fecha_ing), anio)) - ',
				'YEAR(n30_fecha_ing + (',rm_n00.n00_ano_adi_vac,
				' - 1) UNITS YEAR - 1 UNITS DAY)) * ',
				rm_n00.n00_dias_adi_va, ')',
			' END ',
			'ELSE 0 ',
		'END) d_vac, ',
	'(NVL((SELECT SUM(n32_tot_gan) ',
		' FROM rolt032 ',
		' WHERE n32_compania     = n30_compania ',
		'   AND n32_cod_liqrol  IN("Q1", "Q2") ',
		'   AND n32_fecha_ini   >= MDY(MONTH(n30_fecha_ing), ',
			'(CASE WHEN DAY(n30_fecha_ing) >= 1 ',
				'AND DAY(n30_fecha_ing) <= 15 ',
				'THEN 1 ELSE 16 END), anio - 1) ',
		'   AND n32_fecha_fin   <= MDY(MONTH(n30_fecha_ing), ',
			'(CASE WHEN DAY(n30_fecha_ing) >= 1 ',
				'AND DAY(n30_fecha_ing) <= 15 ',
				'THEN 1 ELSE 16 END), anio) - 1 UNITS DAY ',
		'   AND n32_cod_trab     = n30_cod_trab ',
		'   AND n32_ano_proceso >= ', rm_n90.n90_anio_ini_vac,
		'   AND n32_estado      <> "E"), 0) / (',
			rm_n90.n90_dias_ano_vac, ' / ', rm_n00.n00_dias_vacac,
			') ',
		'+ ((NVL((SELECT SUM(n32_tot_gan) ',
			' FROM rolt032 ',
			' WHERE n32_compania     = n30_compania ',
			'   AND n32_cod_liqrol  IN("Q1", "Q2") ',
			'   AND n32_fecha_ini   >= MDY(MONTH(n30_fecha_ing), ',
				'(CASE WHEN DAY(n30_fecha_ing) >= 1 ',
					'AND DAY(n30_fecha_ing) <= 15 ',
					'THEN 1 ELSE 16 END), anio - 1) ',
			'   AND n32_fecha_fin   <= MDY(MONTH(n30_fecha_ing), ',
				'(CASE WHEN DAY(n30_fecha_ing) >= 1 ',
					'AND DAY(n30_fecha_ing) <= 15 ',
					'THEN 1 ELSE 16 END), anio) - 1 ',
					'UNITS DAY ',
			'   AND n32_cod_trab     = n30_cod_trab ',
			'   AND n32_ano_proceso >= ', rm_n90.n90_anio_ini_vac,
			'   AND n32_estado      <> "E"), 0) / (',
		rm_n90.n90_dias_ano_vac, ' / ', rm_n00.n00_dias_vacac,
			')) / ', rm_n00.n00_dias_vacac, ') * ',
	'(CASE WHEN (MDY(MONTH(n30_fecha_ing), DAY(n30_fecha_ing), anio)) ',
		'>= (n30_fecha_ing + (', rm_n00.n00_ano_adi_vac,
			' - 1) UNITS YEAR - 1 UNITS DAY) ',
		'THEN CASE WHEN (', rm_n00.n00_dias_vacac, ' + ',
			'((YEAR(MDY(MONTH(n30_fecha_ing), DAY(n30_fecha_ing), ',
			'anio)) - YEAR(n30_fecha_ing + (',
			rm_n00.n00_ano_adi_vac,	'- 1) UNITS YEAR - ',
			'1 UNITS DAY)) * ', rm_n00.n00_dias_adi_va, ')) > ',
			rm_n00.n00_max_vacac,
			' THEN ', rm_n00.n00_max_vacac, ' - ',
					rm_n00.n00_dias_vacac,
			' ELSE ((YEAR(MDY(MONTH(n30_fecha_ing), ',
				'DAY(n30_fecha_ing), anio)) - ',
				'YEAR(n30_fecha_ing + (',rm_n00.n00_ano_adi_vac,
				' - 1) UNITS YEAR - 1 UNITS DAY)) * ',
				rm_n00.n00_dias_adi_va, ')',
			' END ',
		' ELSE 0 ',
		' END)) v_vac ',
	' FROM tmp_n32, tmp_n30 ',
	' WHERE n30_compania  = cia ',
	'   AND n30_cod_trab  = cod_trab ',
	'   AND MDY(MONTH(n30_fecha_ing), ',
		'(CASE WHEN DAY(n30_fecha_ing) >= 1 ',
			'AND DAY(n30_fecha_ing) <= 15 ',
		'THEN 1 ELSE 16 END), ',
		'anio) - 1 UNITS DAY <= EXTEND(DATE("', fecha_ult,
					'"), YEAR TO DAY) ',
	'   AND NOT EXISTS ',
		'(SELECT * FROM rolt039 ',
		'WHERE n39_compania     = n30_compania ',
		'  AND n39_proceso     IN ("', vm_vac_goz, '", "',
						vm_vac_pag, '")',
		'  AND n39_cod_trab     = n30_cod_trab ',
		'  AND n39_periodo_ini >= MDY(MONTH(n30_fecha_ing), ',
						'DAY(n30_fecha_ing), anio - 1)',
		'  AND n39_periodo_fin <= MDY(MONTH(n30_fecha_ing), ',
				'DAY(n30_fecha_ing), anio) - 1 UNITS DAY) ',
	' INTO TEMP tmp_pend '
PREPARE exec_pend FROM query
EXECUTE exec_pend
DELETE FROM tmp_pend WHERE v_vac <= 0
LET query = 'INSERT INTO tmp_pend ',
		' SELECT n30_cod_trab cod_t, n30_nombres nom, n39_periodo_ini',
			' p_ini, n39_periodo_fin p_fin, ',
			'(n39_dias_vac + n39_dias_adi) d_vac, ',
			'(n39_valor_vaca + n39_valor_adic) v_vac ',
		' FROM tmp_n32, tmp_n30, rolt039 ',
		' WHERE n30_compania     = cia ',
		'   AND n30_cod_trab     = cod_trab ',
		'   AND n39_compania     = n30_compania ',
		'   AND n39_proceso     IN ("', vm_vac_goz, '", "',
						vm_vac_pag, '")',
		'   AND n39_cod_trab     = n30_cod_trab ',
		'   AND n39_periodo_ini >= MDY(MONTH(n30_fecha_ing), ',
		 				'DAY(n30_fecha_ing), anio - 1)',
		'   AND n39_periodo_fin <= MDY(MONTH(n30_fecha_ing), ',
				'DAY(n30_fecha_ing), anio) - 1 UNITS DAY ',
		'   AND n39_estado       = "A" '
PREPARE exec_pend2 FROM query
EXECUTE exec_pend2
DROP TABLE tmp_n32
DROP TABLE tmp_n30
SELECT * FROM tmp_pend INTO TEMP tmp_vacaciones
DROP TABLE tmp_pend
SELECT COUNT(*) INTO cuantos FROM tmp_vacaciones
IF cuantos = 0 THEN
	DROP TABLE tmp_vacaciones
	CALL fl_mensaje_consulta_sin_registros()
	RETURN 0
ELSE
	RETURN 1
END IF

END FUNCTION



FUNCTION cargar_datos_arr()
DEFINE query		CHAR(800)

LET query = 'SELECT * FROM tmp_vacaciones ',
		' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
			', ', vm_columna_2, ' ', rm_orden[vm_columna_2]
PREPARE deto FROM query
DECLARE q_det CURSOR FOR deto
LET vm_num_det = 1
FOREACH q_det INTO rm_detvac[vm_num_det].*
	LET vm_num_det = vm_num_det + 1
	IF vm_num_det > vm_max_det THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_det = vm_num_det - 1

END FUNCTION



FUNCTION muestra_detalle()
DEFINE r_n57		RECORD LIKE rolt057.*
DEFINE col, salir	SMALLINT

LET salir = 1
CALL mostrar_total()
CALL set_count(vm_num_det)
LET int_flag = 0
DISPLAY ARRAY rm_detvac TO rm_detvac.*
       	ON KEY(INTERRUPT)   
		LET int_flag = 1
       	        EXIT DISPLAY  
	ON KEY(F5)
		LET vm_row_cur = arr_curr()
		IF rm_n39.n39_estado <> 'P' THEN
			BEGIN WORK
			CALL retorna_proceso_vaciones_activo(
						rm_detvac[vm_row_cur].cod_trab)
			IF rm_n39_act.n39_compania IS NOT NULL THEN
				IF rm_n39_act.n39_cod_trab <>
				   rm_detvac[vm_row_cur].cod_trab
				THEN
					ROLLBACK WORK
					CALL fl_mostrar_mensaje('Ya existe una Vacación Activa. Por favor Liquide primero esa vacación.', 'exclamation')
					CONTINUE DISPLAY
				END IF
			END IF
		END IF
		CALL control_asignar_vac()
		IF rm_n39.n39_estado <> 'P' THEN
			IF NOT int_flag THEN
				COMMIT WORK
				CALL fl_mostrar_mensaje('Vacaciones Generadas Ok.', 'info')
				CALL retorna_proceso_vaciones_activo(
						rm_detvac[vm_row_cur].cod_trab)
			ELSE
				ROLLBACK WORK
			END IF
		END IF
		LET int_flag = 0
	ON KEY(F6)
		IF rm_n39.n39_estado = 'P' THEN
			CONTINUE DISPLAY
		END IF
		IF rm_n05.n05_compania IS NULL THEN
			CALL fl_mostrar_mensaje('No esta activo ninguno de los proceso de vacaciones. Vuelva a generar las vacaciones del empleado.', 'exclamation')
			CONTINUE DISPLAY
		END IF
		LET vm_row_cur = arr_curr()
		CALL retorna_proceso_vaciones_activo(
						rm_detvac[vm_row_cur].cod_trab)
		CALL control_cerrar_vac()
		LET int_flag = 1
		LET salir    = 0
		EXIT DISPLAY
	ON KEY(F7)
		LET vm_row_cur = arr_curr()
		CALL ver_empleado(rm_detvac[vm_row_cur].cod_trab)
		LET int_flag = 0
	ON KEY(F8)
		LET vm_row_cur = arr_curr()
		INITIALIZE r_n57.* TO NULL
		SELECT * INTO r_n57.*
			FROM rolt057
			WHERE n57_compania    = vg_codcia
			  AND n57_proceso     = vm_proceso
			  AND n57_cod_trab    = rm_detvac[vm_row_cur].cod_trab
			  AND n57_periodo_ini =
					rm_detvac[vm_row_cur].n39_periodo_ini
			  AND n57_periodo_fin =
					rm_detvac[vm_row_cur].n39_periodo_fin
		IF r_n57.n57_compania IS NULL THEN
			CONTINUE DISPLAY
		END IF
		CALL ver_contabilizacion(r_n57.n57_tipo_comp,r_n57.n57_num_comp)
		LET int_flag = 0
	ON KEY(F9)
		LET vm_row_cur = arr_curr()
		CALL control_imprimir()
		LET int_flag = 0
	ON KEY(F10)
		LET vm_row_cur = arr_curr()
		CALL control_dias_gozados()
		LET int_flag = 0
	ON KEY(F15)
		LET col = 1
		EXIT DISPLAY
	ON KEY(F16)
		LET col = 2
		EXIT DISPLAY
	ON KEY(F17)
		LET col = 3
		EXIT DISPLAY
	ON KEY(F18)
		LET col = 4
		EXIT DISPLAY
	ON KEY(F19)
		LET col = 5
		EXIT DISPLAY
	ON KEY(F20)
		LET col = 6
		EXIT DISPLAY
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("F1","") 
		--#CALL dialog.keysetlabel("CONTROL-W","") 
		--#IF rm_n39.n39_estado <> 'P' THEN
			--#CALL dialog.keysetlabel("F5", "Generar Vacación") 
			--#CALL dialog.keysetlabel("F6", "Liquidación") 
		--#ELSE
			--#CALL dialog.keysetlabel("F5", "Comprobante") 
			--#CALL dialog.keysetlabel("F6", "") 
		--#END IF
	--#BEFORE ROW 
		--#LET vm_row_cur = arr_curr()	
		--#CALL muestra_contadores()
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY  
END DISPLAY
IF salir = 0 OR int_flag = 1 THEN
	RETURN salir
END IF
IF col <> vm_columna_1 THEN
	LET vm_columna_2           = vm_columna_1 
	LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
	LET vm_columna_1           = col 
END IF
IF rm_orden[vm_columna_1] = 'ASC' THEN
	LET rm_orden[vm_columna_1] = 'DESC'
ELSE
	LET rm_orden[vm_columna_1] = 'ASC'
END IF
RETURN salir

END FUNCTION



FUNCTION mostrar_total()
DEFINE i		SMALLINT

LET vm_total = 0
FOR i = 1 TO vm_num_det
	LET vm_total = vm_total + rm_detvac[i].n39_valor_vaca
END FOR
DISPLAY BY NAME vm_total

END FUNCTION



FUNCTION retorna_valor_vacacion(cod_trab, fec_ing, per_ini, per_fin)
DEFINE cod_trab		LIKE rolt039.n39_cod_trab
DEFINE fec_ing		LIKE rolt039.n39_fecha_ing
DEFINE per_ini		LIKE rolt039.n39_periodo_ini
DEFINE per_fin		LIKE rolt039.n39_periodo_fin
DEFINE tot_ganado	LIKE rolt039.n39_tot_ganado
DEFINE valor_vac	LIKE rolt039.n39_valor_vaca
DEFINE dias_vac		DECIMAL(4,0)
DEFINE dias_adi		DECIMAL(4,0)
DEFINE fec_tope		DATE
DEFINE anios_ant	SMALLINT
DEFINE dias_trab	SMALLINT
DEFINE factor_dia_vac	DECIMAL(20,12)
DEFINE factor_dia_adi	DECIMAL(20,12)

IF DAY(per_ini) > 1 AND DAY(per_ini) < 16 THEN
	LET per_ini = MDY(MONTH(per_ini), 01, YEAR(per_ini))
END IF
IF DAY(per_ini) > 16 THEN
	LET per_ini = MDY(MONTH(per_ini), 16, YEAR(per_ini))
END IF
LET per_fin = per_ini + rm_n90.n90_dias_anio UNITS DAY
IF NOT anio_bisiesto(YEAR(per_fin)) AND MONTH(per_fin) > 2 THEN
	LET per_fin = per_fin - 1 UNITS DAY
END IF
SELECT NVL(SUM(n32_tot_gan), 0) INTO tot_ganado
	FROM rolt032
	WHERE n32_compania     = vg_codcia
	  AND n32_cod_liqrol  IN("Q1", "Q2")
	  AND n32_fecha_ini   >= per_ini
	  AND n32_fecha_fin   <= per_fin
	  AND n32_cod_trab     = cod_trab
	  AND n32_ano_proceso >= vm_anio_arr
	  AND n32_estado      <> 'E'
LET valor_vac = tot_ganado / (rm_n90.n90_dias_ano_vac / rm_n00.n00_dias_vacac)
LET dias_vac  = rm_n00.n00_dias_vacac
LET dias_adi  = 0
IF anio_bisiesto(YEAR(fec_ing)) AND MONTH(fec_ing) THEN
	LET fec_ing = fec_ing - 1 UNITS DAY
END IF
LET fec_tope  = fec_ing + (rm_n00.n00_ano_adi_vac - 1) UNITS YEAR - 1 UNITS DAY
IF per_fin >= fec_tope THEN
	LET anios_ant = YEAR(per_fin) - YEAR(fec_tope)
	LET dias_adi  = anios_ant * rm_n00.n00_dias_adi_va
	IF (dias_vac + dias_adi) > rm_n00.n00_max_vacac THEN
		LET dias_adi = rm_n00.n00_max_vacac - rm_n00.n00_dias_vacac
	END IF
END IF
IF per_fin > fecha_ultima_quincena() THEN
	LET factor_dia_vac = dias_vac / rm_n90.n90_dias_ano_vac		--360
	LET factor_dia_adi = dias_adi / rm_n90.n90_dias_ano_vac
	LET dias_trab      = fecha_ultima_quincena() - per_ini + 1
	LET dias_vac       = factor_dia_vac * dias_trab
	LET dias_adi       = factor_dia_adi * dias_trab
END IF
RETURN dias_vac, dias_adi, tot_ganado, valor_vac

END FUNCTION



FUNCTION muestra_contadores()

DISPLAY BY NAME vm_row_cur, vm_num_det

END FUNCTION



FUNCTION borrar_pantalla()
DEFINE i		SMALLINT

FOR i = 1 TO fgl_scr_size('rm_detvac')
	CLEAR rm_detvac[i].*
END FOR
CLEAR vm_total

END FUNCTION



FUNCTION bloquear_registro()
DEFINE r_n39		RECORD LIKE rolt039.*
DEFINE resul		SMALLINT

LET resul = 0
WHENEVER ERROR CONTINUE
DECLARE q_up CURSOR FOR
	SELECT * FROM rolt039
		WHERE n39_compania    = rm_n39_act.n39_compania
		  AND n39_proceso     = rm_n39_act.n39_proceso
		  AND n39_cod_trab    = rm_n39_act.n39_cod_trab
		  AND n39_periodo_ini = rm_n39_act.n39_periodo_ini
		  AND n39_periodo_fin = rm_n39_act.n39_periodo_fin
	FOR UPDATE
OPEN q_up
FETCH q_up INTO r_n39.*
IF STATUS < 0 THEN
	CLOSE q_up
	FREE q_up
	CALL fl_mensaje_bloqueo_otro_usuario()
	LET resul = 1
END IF
IF STATUS = NOTFOUND THEN
	CLOSE q_up
	FREE q_up
	CALL fl_mostrar_mensaje('Primero genere el registro de vacaciones para este empleado. Hagalo Presionando el botón GENERAR VACACION.', 'exclamation')
	LET resul = 1
END IF
WHENEVER ERROR STOP
RETURN resul

END FUNCTION



FUNCTION control_asignar_vac()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE existe, resul 	SMALLINT
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n39		RECORD LIKE rolt039.*

IF num_args() <> 8 THEN
	IF NOT primera_vacacion_procesar() THEN
		LET int_flag = 1
		RETURN
	END IF
END IF
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 22
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rolf252_2 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf252_2 FROM '../forms/rolf252_2'
ELSE
	OPEN FORM f_rolf252_2 FROM '../forms/rolf252_2c'
END IF
DISPLAY FORM f_rolf252_2
CLEAR FORM
IF num_args() <> 8 THEN
	IF rm_n39_act.n39_proceso <> vm_proceso THEN
		LET vm_proceso = rm_n39_act.n39_proceso
	END IF
	IF rm_n39.n39_estado = 'P' THEN
		DECLARE q_proceso CURSOR FOR
			SELECT n39_proceso
			FROM rolt039
			WHERE n39_compania    = vg_codcia
			  AND n39_cod_trab    = rm_detvac[vm_row_cur].cod_trab
			  AND n39_periodo_ini =
					rm_detvac[vm_row_cur].n39_periodo_ini
			  AND n39_periodo_fin =
					rm_detvac[vm_row_cur].n39_periodo_fin
		OPEN q_proceso
		FETCH q_proceso INTO vm_proceso
		CLOSE q_proceso
		FREE q_proceso
	END IF
	CALL fl_lee_vacaciones(vg_codcia, vm_proceso,
			rm_detvac[vm_row_cur].cod_trab,
			rm_detvac[vm_row_cur].n39_periodo_ini,
			rm_detvac[vm_row_cur].n39_periodo_fin)
		RETURNING r_n39.*
ELSE
	CALL fl_lee_vacaciones(vg_codcia,rm_n39.n39_proceso,rm_n39.n39_cod_trab,
				rm_n39.n39_periodo_ini, rm_n39.n39_periodo_fin)
		RETURNING r_n39.*
END IF
IF r_n39.n39_compania IS NULL THEN
	CALL carga_datos_vac() RETURNING r_n39.*
	LET existe = 0
ELSE
	LET existe = 1
	IF rm_n39.n39_estado <> 'P' THEN
		IF bloquear_registro() AND rm_n39.n39_estado <> 'P' THEN
			CLOSE WINDOW w_rolf252_2
			RETURN
		END IF
	END IF
END IF
LET vm_num_rub = 0
LET vm_max_rub = 200
CALL borrar_ingresos_descuentos()
IF num_args() <> 8 THEN
	{--
	CALL reajustar_valor_vacaciones_por_sueldo(r_n39.*)
		RETURNING r_n39.*, resul
	IF resul THEN
		CALL calcular_iess(r_n39.*) RETURNING r_n39.n39_descto_iess
		CALL fl_mostrar_mensaje('El valor de las vacaciones (valor normal y valor adicional) han sido reajustados al sueldo actual del empleado, para que no sean menor al mismo.', 'info')
	END IF
	--}
END IF
CALL mostrar_datos_empleado(r_n39.*)
IF rm_n39.n39_estado = 'P' THEN
	MENU 'OPCIONES'
		COMMAND KEY('D') 'Ingresos/Dsctos.'
			CALL control_ingresos_descuentos(r_n39.*, 'C')
		COMMAND KEY('G') 'Dias Gozados'
			CALL control_dias_gozados()
		COMMAND KEY('T') 'Detalle Tot. Gan.'
			CALL fl_valor_ganado_liquidacion(vg_codcia, vm_proceso,
							r_n39.n39_cod_trab,
							r_n39.n39_perini_real,
							r_n39.n39_perfin_real)
		COMMAND KEY('I') 'Imprimir'
			CALL control_imprimir()
		COMMAND KEY('R') 'Regresar' 'Regresar a la pantalla anterior.'
			EXIT MENU
	END MENU
	CLOSE WINDOW w_rolf252_2
	RETURN
END IF
CALL cargar_ingresos_descuentos(0) RETURNING resul
IF NOT resul THEN
	CALL generar_ingresos_descuentos(r_n39.*, 0) RETURNING resul
END IF
IF resul THEN
	CALL calcular_total_vac(r_n39.*) RETURNING r_n39.*
END IF
CALL fl_lee_trabajador_roles(vg_codcia, rm_n39.n39_cod_trab) RETURNING r_n30.*
IF (r_n30.n30_tipo_pago  <> 'E' AND r_n30.n30_bco_empresa  IS NOT NULL) AND
   (rm_n39.n39_tipo_pago <> 'E' AND rm_n39.n39_bco_empresa IS NULL)
THEN
	LET rm_n39.n39_tipo_pago   = r_n30.n30_tipo_pago
	LET rm_n39.n39_bco_empresa = r_n30.n30_bco_empresa
	LET rm_n39.n39_cta_empresa = r_n30.n30_cta_empresa
	IF rm_n39.n39_tipo_pago = 'T' THEN
		LET rm_n39.n39_cta_trabaj = r_n30.n30_cta_trabaj
	END IF
	CALL fl_lee_banco_general(rm_n39.n39_bco_empresa) RETURNING r_g08.*
	DISPLAY BY NAME r_g08.g08_nombre
END IF
LET int_flag = 0
INPUT BY NAME r_n39.n39_fecini_vac, r_n39.n39_fecfin_vac, r_n39.n39_tipo,
	r_n39.n39_gozar_adic, r_n39.n39_dias_vac, r_n39.n39_dias_adi,
	r_n39.n39_moneda, r_n39.n39_tipo_pago, r_n39.n39_bco_empresa,
	r_n39.n39_cta_empresa, r_n39.n39_cta_trabaj
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(n39_moneda) THEN
                	CALL fl_ayuda_monedas()
				RETURNING r_g13.g13_moneda, r_g13.g13_nombre,
					  r_g13.g13_decimales
                	IF r_g13.g13_moneda IS NOT NULL THEN
				LET r_n39.n39_moneda = r_g13.g13_moneda
                        	DISPLAY BY NAME r_n39.n39_moneda,
						r_g13.g13_nombre
                	END IF
		END IF
		IF INFIELD(n39_bco_empresa) THEN
                        CALL fl_ayuda_cuenta_banco(vg_codcia, 'A')
                                RETURNING r_g08.g08_banco, r_g08.g08_nombre,
					r_g09.g09_tipo_cta, r_g09.g09_numero_cta
                        IF r_g08.g08_banco IS NOT NULL THEN
				LET r_n39.n39_bco_empresa = r_g08.g08_banco
				LET r_n39.n39_cta_empresa = r_g09.g09_numero_cta
				CALL fl_lee_trabajador_roles(r_n39.n39_compania,
							r_n39.n39_cod_trab)
					RETURNING r_n30.*
				IF rm_n39.n39_tipo_pago = 'T' THEN
					LET r_n39.n39_cta_trabaj =
							r_n30.n30_cta_trabaj
				END IF
                                DISPLAY BY NAME r_n39.n39_bco_empresa,
						r_g08.g08_nombre,
						r_n39.n39_cta_empresa,
						r_n39.n39_cta_trabaj
                        END IF
                END IF
		IF INFIELD(n39_cta_trabaj) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, vm_nivel)
				RETURNING r_b10.b10_cuenta,r_b10.b10_descripcion
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET r_n39.n39_cta_trabaj = r_b10.b10_cuenta
				DISPLAY BY NAME rm_n39.n39_cta_trabaj
			END IF
		END IF
		LET int_flag = 0
	ON KEY(F5)
		CALL control_ingresos_descuentos(r_n39.*, 'I')
		CALL calcular_total_vac(r_n39.*) RETURNING r_n39.*
		LET int_flag = 0
	ON KEY(F6)
		CALL fl_valor_ganado_liquidacion(vg_codcia, vm_proceso,
						r_n39.n39_cod_trab,
						r_n39.n39_perini_real,
						r_n39.n39_perfin_real)
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F6","Detalle Tot. Gan.")
	AFTER FIELD n39_tipo, n39_gozar_adic
		IF r_n39.n39_tipo = 'P' THEN
			LET r_n39.n39_dias_goza  = 0
			LET r_n39.n39_gozar_adic = 'N'
			LET r_n39.n39_fecini_vac = NULL
			LET r_n39.n39_fecfin_vac = NULL
		END IF
		CALL calcular_iess(r_n39.*) RETURNING r_n39.n39_descto_iess
		LET r_n39.n39_neto = r_n39.n39_valor_vaca + r_n39.n39_valor_adic
					+ r_n39.n39_otros_ing -
					r_n39.n39_descto_iess -
					r_n39.n39_otros_egr
		IF r_n39.n39_gozar_adic = 'N' AND
		  (r_n39.n39_fecfin_vac - r_n39.n39_dias_adi UNITS DAY) >
		   r_n39.n39_fecini_vac
		THEN
			LET r_n39.n39_fecfin_vac = r_n39.n39_fecfin_vac -
						r_n39.n39_dias_adi UNITS DAY
		END IF
		IF r_n39.n39_gozar_adic = 'S' AND
		  (r_n39.n39_fecini_vac + (r_n39.n39_dias_vac +
			r_n39.n39_dias_adi) UNITS DAY) >
		   r_n39.n39_fecfin_vac
		THEN
			LET r_n39.n39_fecfin_vac = r_n39.n39_fecini_vac +
						(r_n39.n39_dias_vac +
						r_n39.n39_dias_adi - 1)
						UNITS DAY
		END IF
		LET r_n39.n39_dias_goza = r_n39.n39_fecfin_vac -
						r_n39.n39_fecini_vac + 1
		IF r_n39.n39_dias_goza >
		  (r_n39.n39_dias_vac + r_n39.n39_dias_adi)
		THEN
			LET r_n39.n39_dias_goza = r_n39.n39_dias_vac +
							r_n39.n39_dias_adi
		END IF
		DISPLAY BY NAME r_n39.n39_neto, r_n39.n39_descto_iess,
				r_n39.n39_fecini_vac, r_n39.n39_fecfin_vac,
				r_n39.n39_gozar_adic, r_n39.n39_dias_goza
	AFTER FIELD r_n39.n39_fecini_vac
		IF r_n39.n39_fecini_vac IS NOT NULL THEN
			IF r_n39.n39_fecini_vac <= r_n39.n39_perfin_real THEN
				CALL fl_mostrar_mensaje('La Fecha Inicial de Gozo de las Vacaciones no puede ser menor o igual a la Fecha Final Real de Calculo de las Vacaciones.', 'exclamation')
				NEXT FIELD n39_fecini_vac
			END IF
			IF r_n39.n39_fecfin_vac IS NULL THEN
				LET r_n39.n39_fecfin_vac = r_n39.n39_fecini_vac
							+ r_n39.n39_dias_vac
							UNITS DAY
				IF r_n39.n39_gozar_adic = 'S' THEN
					LET r_n39.n39_fecfin_vac =
							r_n39.n39_fecfin_vac +
							r_n39.n39_dias_adi
							UNITS DAY
				END IF
				LET r_n39.n39_fecfin_vac = r_n39.n39_fecfin_vac
								- 1 UNITS DAY
				DISPLAY BY NAME r_n39.n39_fecfin_vac
			END IF
			LET r_n39.n39_dias_goza = r_n39.n39_fecfin_vac -
						r_n39.n39_fecini_vac + 1
			IF r_n39.n39_dias_goza >
			  (r_n39.n39_dias_vac + r_n39.n39_dias_adi)
			THEN
				LET r_n39.n39_dias_goza = r_n39.n39_dias_vac +
							r_n39.n39_dias_adi
			END IF
		ELSE
			LET r_n39.n39_dias_goza = 0
		END IF
		DISPLAY BY NAME r_n39.n39_dias_goza
	AFTER FIELD r_n39.n39_fecfin_vac
		IF r_n39.n39_fecfin_vac IS NOT NULL THEN
			LET r_n39.n39_dias_goza = r_n39.n39_fecfin_vac -
							r_n39.n39_fecini_vac + 1
			IF r_n39.n39_dias_goza >
			  (r_n39.n39_dias_vac + r_n39.n39_dias_adi)
			THEN
				LET r_n39.n39_dias_goza = r_n39.n39_dias_vac +
							r_n39.n39_dias_adi
			END IF
		ELSE
			LET r_n39.n39_dias_goza = 0
		END IF
		DISPLAY BY NAME r_n39.n39_dias_goza
	AFTER FIELD n39_moneda
                IF r_n39.n39_moneda IS NOT NULL THEN
                        CALL fl_lee_moneda(r_n39.n39_moneda) RETURNING r_g13.*
                        IF r_g13.g13_moneda IS NULL  THEN
                                CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
                                NEXT FIELD n39_moneda
                        END IF
                        DISPLAY BY NAME r_g13.g13_nombre
                        IF r_g13.g13_estado = 'B' THEN
                                CALL fl_mensaje_estado_bloqueado()
                                NEXT FIELD n39_moneda
                        END IF
                ELSE
                        LET r_n39.n39_moneda = rg_gen.g00_moneda_base
                        CALL fl_lee_moneda(r_n39.n39_moneda) RETURNING r_g13.*
                        DISPLAY BY NAME r_n39.n39_moneda, r_g13.g13_nombre
                END IF
	AFTER FIELD n39_tipo_pago
		CALL fl_lee_trabajador_roles(r_n39.n39_compania,
						r_n39.n39_cod_trab)
			RETURNING r_n30.*
		CASE r_n39.n39_tipo_pago
			WHEN 'E'
				LET r_n39.n39_bco_empresa = NULL
				LET r_n39.n39_cta_empresa = NULL
				LET r_n39.n39_cta_trabaj  = NULL
			WHEN 'C'
				LET r_n39.n39_bco_empresa =r_n30.n30_bco_empresa
				LET r_n39.n39_cta_empresa =r_n30.n30_cta_empresa
				LET r_n39.n39_cta_trabaj  = NULL
			WHEN 'T'
				LET r_n39.n39_bco_empresa =r_n30.n30_bco_empresa
				LET r_n39.n39_cta_empresa =r_n30.n30_cta_empresa
				LET r_n39.n39_cta_trabaj  = r_n30.n30_cta_trabaj
		END CASE
		CALL fl_lee_banco_general(r_n39.n39_bco_empresa)
			RETURNING r_g08.*
		DISPLAY BY NAME r_n39.n39_tipo_pago, r_n39.n39_bco_empresa,
				r_g08.g08_nombre, r_n39.n39_cta_empresa,
				r_n39.n39_cta_trabaj
	AFTER FIELD n39_bco_empresa
                IF r_n39.n39_bco_empresa IS NOT NULL THEN
                        CALL fl_lee_banco_general(r_n39.n39_bco_empresa)
                                RETURNING r_g08.*
			IF r_g08.g08_banco IS NULL THEN
				CALL fl_mostrar_mensaje('Banco no existe.','exclamation')
				NEXT FIELD n39_bco_empresa
			END IF
			DISPLAY BY NAME r_g08.g08_nombre
		ELSE
			CLEAR n39_bco_empresa, g08_nombre, n39_cta_empresa
                END IF
	AFTER FIELD n39_cta_empresa
                IF r_n39.n39_cta_empresa IS NOT NULL THEN
                        CALL fl_lee_banco_compania(vg_codcia,
					r_n39.n39_bco_empresa,
					r_n39.n39_cta_empresa)
                                RETURNING r_g09.*
			IF r_g09.g09_banco IS NULL THEN
				CALL fl_mostrar_mensaje('Banco o Cuenta Corriente no existe en la compañía.','exclamation')
				NEXT FIELD n39_bco_empresa
			END IF
			LET r_n39.n39_cta_empresa = r_g09.g09_numero_cta
			DISPLAY BY NAME r_n39.n39_cta_empresa
                        CALL fl_lee_banco_general(r_n39.n39_bco_empresa)
                                RETURNING r_g08.*
			DISPLAY BY NAME r_g08.g08_nombre
			IF r_g09.g09_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD n39_bco_empresa
			END IF
			CALL fl_lee_cuenta(r_g09.g09_compania,
						r_g09.g09_aux_cont)
				RETURNING r_b10.*
			IF r_b10.b10_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No se puede escoger una cuenta corriente que no tiene auxiliar contable.', 'exclamation')
				NEXT FIELD n39_bco_empresa
			END IF
			IF r_b10.b10_estado <> 'A' THEN
				CALL fl_mostrar_mensaje('El auxiliar contable de esta cuenta bancaria esta con estado bloqueado.', 'exclamation')
				NEXT FIELD n39_bco_empresa
			END IF
		ELSE
			CLEAR n39_cta_empresa
		END IF
	AFTER FIELD n39_cta_trabaj
		IF r_n39.n39_tipo_pago <> 'T' THEN
			LET r_n39.n39_cta_trabaj = NULL
			DISPLAY BY NAME r_n39.n39_cta_trabaj
			CONTINUE INPUT
		END IF
		IF r_n39.n39_cta_trabaj IS NOT NULL THEN
			{--
			IF validar_cuenta(r_n39.n39_cta_trabaj) THEN
				NEXT FIELD n39_cta_trabaj
			END IF
			--}
		ELSE
			CLEAR n39_cta_trabaj
		END IF
	AFTER INPUT
		IF r_n39.n39_tipo_pago <> 'E' THEN
			IF r_n39.n39_bco_empresa IS NULL
			OR r_n39.n39_cta_empresa IS NULL THEN
				CALL fl_mostrar_mensaje('Empleado con tipo de pago Cheque o Transferencia, debe ingresar el Banco y la Cuenta Corriente.', 'exclamation')
				NEXT FIELD n39_bco_empresa
			END IF
		ELSE
			IF r_n39.n39_bco_empresa IS NULL
			OR r_n39.n39_cta_empresa IS NULL THEN
				INITIALIZE r_n39.n39_bco_empresa,
					r_n39.n39_cta_empresa TO NULL
				CLEAR n39_bco_empresa, n39_cta_empresa,
					g08_nombre
			END IF
		END IF
		IF r_n39.n39_cta_trabaj IS NULL THEN
			IF r_n39.n39_tipo_pago = 'T' THEN
				CALL fl_mostrar_mensaje('Empleado con tipo de Pago Transferencia, debe ingresar el Número de Cuenta Contable.', 'exclamation')
				NEXT FIELD n39_cta_trabaj
			END IF
		END IF
		IF r_n39.n39_tipo_pago = 'T' THEN
			IF r_n39.n39_cta_trabaj IS NOT NULL THEN
			{--
				IF validar_cuenta(r_n39.n39_cta_trabaj) THEN
					NEXT FIELD n39_cta_trabaj
				END IF
			--}
			END IF
		END IF
		IF r_n39.n39_neto < 0 THEN
			CALL fl_mostrar_mensaje('No puede procesar una vacación con el Valor a Recibir menor a cero.', 'exclamation')
			CONTINUE INPUT
		END IF
		IF r_n39.n39_fecini_vac IS NULL THEN
			IF r_n39.n39_fecfin_vac IS NOT NULL THEN
				CALL fl_mostrar_mensaje('Debe ingresar también la Fecha Inicial de Gozo de las vacaciones.', 'exclamation')
				NEXT FIELD n39_fecini_vac
			END IF
		END IF
		IF r_n39.n39_fecfin_vac IS NULL THEN
			IF r_n39.n39_fecini_vac IS NOT NULL THEN
				CALL fl_mostrar_mensaje('Debe ingresar también la Fecha Final de Gozo de las vacaciones.', 'exclamation')
				NEXT FIELD n39_fecfin_vac
			END IF
		END IF
		IF r_n39.n39_fecfin_vac IS NOT NULL AND
		   r_n39.n39_fecini_vac IS NOT NULL
		THEN
			IF r_n39.n39_fecini_vac > r_n39.n39_fecfin_vac THEN
				CALL fl_mostrar_mensaje('La Fecha Inicial de Gozo de las Vacaciones no puede ser mayor que la Fecha Final de Gozo de las Vacaciones.', 'exclamation')
				NEXT FIELD n39_fecini_vac
			END IF
			IF (r_n39.n39_fecfin_vac - r_n39.n39_fecini_vac) >
			   (r_n39.n39_dias_vac + r_n39.n39_dias_adi)
			THEN
				CALL fl_mostrar_mensaje('La Fecha Final de Gozo de las Vacaciones no puede ser mayor que la Fecha Inicial de Gozo de las Vacaciones, en total de días de Vacaciones.', 'exclamation')
				NEXT FIELD n39_fecfin_vac
			END IF
			LET r_n39.n39_dias_goza = r_n39.n39_fecfin_vac -
							r_n39.n39_fecini_vac + 1
			IF r_n39.n39_dias_goza >
			  (r_n39.n39_dias_vac + r_n39.n39_dias_adi)
			THEN
				LET r_n39.n39_dias_goza = r_n39.n39_dias_vac +
							r_n39.n39_dias_adi
			END IF
			DISPLAY BY NAME r_n39.n39_dias_goza
		END IF
		IF r_n39.n39_dias_goza IS NULL THEN
			LET r_n39.n39_dias_goza = 0
		END IF
		IF r_n39.n39_tipo = 'G' THEN
			LET vm_proceso = vm_vac_goz
		ELSE
			LET vm_proceso = vm_vac_pag
		END IF
		LET r_n39.n39_proceso = vm_proceso
END INPUT
IF int_flag THEN
	CLOSE WINDOW w_rolf252_2
	RETURN
END IF
CALL control_grabar(r_n39.*, existe)
CALL control_dias_gozados()
CLOSE WINDOW w_rolf252_2
RETURN

END FUNCTION



FUNCTION calcular_total_vac(r_n39)
DEFINE r_n39		RECORD LIKE rolt039.*

LET r_n39.n39_otros_ing = sacar_total_ing_des(0, 'DI')
LET r_n39.n39_otros_egr = sacar_total_ing_des(0, 'DE')
LET r_n39.n39_neto      = r_n39.n39_valor_vaca + r_n39.n39_valor_adic +
				r_n39.n39_otros_ing - r_n39.n39_descto_iess -
				r_n39.n39_otros_egr
DISPLAY BY NAME r_n39.n39_neto, r_n39.n39_otros_ing, r_n39.n39_otros_egr
RETURN r_n39.*

END FUNCTION



FUNCTION validar_cuenta(aux_cont)
DEFINE aux_cont		LIKE ctbt010.b10_cuenta
DEFINE r_cta            RECORD LIKE ctbt010.*

CALL fl_lee_cuenta(vg_codcia, aux_cont) RETURNING r_cta.*
IF r_cta.b10_cuenta IS NULL  THEN
	CALL fl_mostrar_mensaje('Cuenta no existe para esta compañía.','exclamation')
	RETURN 1
END IF
IF r_cta.b10_estado = 'B' THEN
	CALL fl_mensaje_estado_bloqueado()
	RETURN 1
END IF
IF r_cta.b10_nivel <> vm_nivel THEN
	CALL fl_mostrar_mensaje('Nivel de cuenta debe ser solo del último.', 'exclamation')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION control_grabar(r_n39, flag)
DEFINE r_n39		RECORD LIKE rolt039.*
DEFINE flag		SMALLINT
DEFINE query		CHAR(400)

CASE flag
	WHEN 0
		LET r_n39.n39_fecing = CURRENT
		{-- OJO SOLO PARA CARGAR DATOS (MIGRACION)
		IF YEAR(r_n39.n39_perfin_real) < TODAY THEN
			LET query = 'SELECT EXTEND(MDY(',
					MONTH(r_n39.n39_perfin_real), ', ',
					DAY(r_n39.n39_perfin_real), ', ',
					YEAR(r_n39.n39_perfin_real), ')',
					', YEAR TO SECOND) + ',
					EXTEND(CURRENT, HOUR TO HOUR),
					' UNITS HOUR + ',
					EXTEND(CURRENT, MINUTE TO MINUTE),
					' UNITS MINUTE + ',
					EXTEND(CURRENT, SECOND TO SECOND),
					' UNITS SECOND fecha ',
					' FROM dual ',
					' INTO TEMP tmp_fec '
			PREPARE exec_fec FROM query
			EXECUTE exec_fec
			SELECT * INTO r_n39.n39_fecing FROM tmp_fec
			DROP TABLE tmp_fec
		END IF
		--}
		INSERT INTO rolt039 VALUES(r_n39.*)
		CALL grabar_detalle(r_n39.*)
	WHEN 1
		CALL grabar_detalle(r_n39.*)
		IF r_n39.n39_proceso = vm_vac_pag THEN
			DELETE FROM rolt047
				WHERE n47_compania    = r_n39.n39_compania
				  AND n47_proceso     = vm_vac_goz
				  AND n47_cod_trab    = r_n39.n39_cod_trab
				  AND n47_periodo_ini = r_n39.n39_periodo_ini
				  AND n47_periodo_fin = r_n39.n39_periodo_fin
		END IF
		UPDATE rolt039 SET * = r_n39.* WHERE CURRENT OF q_up
END CASE
CALL regenerar_dividendo_vac(r_n39.*)
CALL grabar_proceso_vac_n05('I')

END FUNCTION



FUNCTION regenerar_dividendo_vac(r_n39)
DEFINE r_n39		RECORD LIKE rolt039.*

UPDATE rolt091
	SET n91_proc_vac = r_n39.n39_proceso
	WHERE n91_compania     = r_n39.n39_compania
	  AND n91_proc_vac    IN (vm_vac_goz, vm_vac_pag)
	  AND n91_cod_trab     = r_n39.n39_cod_trab
	  AND n91_periodo_ini  = r_n39.n39_perini_real
	  AND n91_periodo_fin  = r_n39.n39_perfin_real
UPDATE rolt046
	SET n46_cod_liqrol = r_n39.n39_proceso
	WHERE n46_compania    = r_n39.n39_compania
	  AND n46_num_prest   = (SELECT n45_num_prest
				FROM rolt045
				WHERE n45_compania   = n46_compania
				  AND n45_num_prest  = n46_num_prest
				  AND n45_cod_trab   = r_n39.n39_cod_trab
				  AND n45_estado    IN ('A', 'R'))
	  AND n46_cod_liqrol IN (vm_vac_goz, vm_vac_pag)
	  AND n46_fecha_ini   = r_n39.n39_perini_real
	  AND n46_fecha_fin   = r_n39.n39_perfin_real
	  AND n46_saldo       > 0
DELETE FROM rolt058
	WHERE n58_compania   = r_n39.n39_compania
	  AND n58_num_prest IN (SELECT UNIQUE n45_num_prest
				FROM rolt046, rolt045
				WHERE n46_compania    = n58_compania
				  AND n46_cod_liqrol IN (vm_vac_goz, vm_vac_pag)
				  AND n46_saldo       > 0
				  AND n45_compania    = n46_compania
				  AND n45_num_prest   = n46_num_prest
				  AND n45_cod_trab    = r_n39.n39_cod_trab
				  AND n45_estado     IN ('A', 'R'))
	  AND n58_proceso   IN (vm_vac_goz, vm_vac_pag)
INSERT INTO rolt058
	(n58_compania, n58_num_prest, n58_proceso, n58_div_act, n58_num_div,
	 n58_valor_div, n58_valor_dist, n58_saldo_dist, n58_usuario, n58_fecing)
	SELECT a.n46_compania, a.n46_num_prest, a.n46_cod_liqrol,
		NVL((SELECT COUNT(b.n46_secuencia)
			FROM rolt046 b
			WHERE b.n46_compania   = a.n46_compania
			  AND b.n46_num_prest  = a.n46_num_prest
			  AND b.n46_cod_liqrol = a.n46_cod_liqrol
			  AND b.n46_saldo      = 0), 0),
		COUNT(a.n46_secuencia),
		NVL((SELECT SUM(b.n46_valor) / COUNT(b.n46_secuencia)
			FROM rolt046 b
			WHERE b.n46_compania   = a.n46_compania
			  AND b.n46_num_prest  = a.n46_num_prest
			  AND b.n46_cod_liqrol = a.n46_cod_liqrol), 0),
 		NVL(SUM(a.n46_valor), 0), NVL(SUM(a.n46_saldo), 0),
		n45_usuario, n45_fecing
		FROM rolt046 a, rolt045
		WHERE a.n46_compania    = r_n39.n39_compania
		  AND a.n46_cod_liqrol IN (vm_vac_goz, vm_vac_pag)
		  --AND a.n46_saldo       > 0
		  AND n45_compania      = a.n46_compania
		  AND n45_num_prest     = a.n46_num_prest
		  AND n45_cod_trab      = r_n39.n39_cod_trab
		  AND n45_estado       IN ('A', 'R')
		  AND NOT EXISTS (SELECT * FROM rolt058
					WHERE n58_compania  = a.n46_compania
					  AND n58_num_prest = a.n46_num_prest
					  AND n58_proceso   = a.n46_cod_liqrol)
		GROUP BY 1, 2, 3, 4, 6, 9, 10

END FUNCTION



FUNCTION grabar_detalle(r_n39)
DEFINE r_n39		RECORD LIKE rolt039.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n40		RECORD LIKE rolt040.*
DEFINE proc		LIKE rolt039.n39_proceso
DEFINE i		SMALLINT

CALL retorna_proc_vac(vm_vac_goz) RETURNING proc
IF proc IS NULL THEN
	CALL retorna_proc_vac(vm_vac_pag) RETURNING proc
END IF
DELETE FROM rolt040
	WHERE n40_compania    = r_n39.n39_compania
	  AND n40_proceso     = proc
	  AND n40_cod_trab    = rm_detvac[vm_row_cur].cod_trab
	  AND n40_periodo_ini = rm_detvac[vm_row_cur].n39_periodo_ini
	  AND n40_periodo_fin = rm_detvac[vm_row_cur].n39_periodo_fin
FOR i = 1 TO vm_num_rub
	IF rm_descto[i].n40_valor = 0 THEN
		CONTINUE FOR
	END IF
	INITIALIZE r_n40.* TO NULL
	LET r_n40.n40_compania    = r_n39.n39_compania
	LET r_n40.n40_proceso     = r_n39.n39_proceso
	LET r_n40.n40_cod_trab    = r_n39.n39_cod_trab
	LET r_n40.n40_periodo_ini = r_n39.n39_periodo_ini
	LET r_n40.n40_periodo_fin = r_n39.n39_periodo_fin
	LET r_n40.n40_cod_rubro   = rm_descto[i].n40_cod_rubro
	IF rm_descto[i].n40_cod_rubro = rm_anticipo[i].n40_cod_rubro THEN
		IF rm_anticipo[i].n40_num_prest IS NOT NULL THEN
			LET r_n40.n40_num_prest = rm_anticipo[i].n40_num_prest
		END IF
	END IF
	CALL fl_lee_rubro_roles(rm_descto[i].n40_cod_rubro) RETURNING r_n06.*
	LET r_n40.n40_orden       = r_n06.n06_orden
	LET r_n40.n40_det_tot     = r_n06.n06_det_tot
	LET r_n40.n40_imprime_0   = r_n06.n06_imprime_0
	LET r_n40.n40_valor       = rm_descto[i].n40_valor
	INSERT INTO rolt040 VALUES(r_n40.*)
END FOR

END FUNCTION



FUNCTION retorna_proc_vac(proc_v)
DEFINE proc_v		LIKE rolt039.n39_proceso
DEFINE proc		LIKE rolt039.n39_proceso

LET proc = NULL
SELECT UNIQUE n40_proceso
	INTO proc
	FROM rolt040
	WHERE n40_compania    = vg_codcia
	  AND n40_proceso     = proc_v
	  AND n40_cod_trab    = rm_detvac[vm_row_cur].cod_trab
	  AND n40_periodo_ini = rm_detvac[vm_row_cur].n39_periodo_ini
	  AND n40_periodo_fin = rm_detvac[vm_row_cur].n39_periodo_fin
RETURN proc

END FUNCTION



FUNCTION grabar_proceso_vac_n05(flag)
DEFINE flag		CHAR(1)
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE proc		LIKE rolt039.n39_proceso

DECLARE q_up_n05 CURSOR FOR
	SELECT * FROM rolt005
		WHERE n05_compania = vg_codcia
		  AND n05_proceso  = vm_proceso
	FOR UPDATE
OPEN q_up_n05
FETCH q_up_n05 INTO r_n05.*
IF STATUS < 0 THEN
	ROLLBACK WORK
	CALL fl_mostrar_mensaje('Algún usuario tiene atrapado por modificación el registro para vacaciones de la tabla rolt005. Por favor llame al Administrador.', 'stop')
	EXIT PROGRAM
END IF
IF STATUS = NOTFOUND THEN
	CLOSE q_up_n05
	INITIALIZE r_n05.* TO NULL
	LET r_n05.n05_compania   = vg_codcia
	LET r_n05.n05_proceso    = vm_proceso
	LET r_n05.n05_activo     = 'S'
	LET r_n05.n05_fecini_act = rm_n39_act.n39_perini_real
	LET r_n05.n05_fecfin_act = rm_n39_act.n39_perfin_real
	LET r_n05.n05_fec_ultcie = TODAY
	LET r_n05.n05_fec_cierre = TODAY
	LET r_n05.n05_usuario = vg_usuario
	LET r_n05.n05_fecing  = CURRENT
	INSERT INTO rolt005 VALUES(r_n05.*)
	OPEN q_up_n05
	FETCH q_up_n05 INTO rm_n05.*
END IF
CASE flag
	WHEN 'I'
		SELECT * FROM rolt005
			WHERE n05_compania = vg_codcia
			  AND n05_proceso  = vm_proceso
			  AND n05_activo   = 'S'
		IF STATUS = NOTFOUND THEN
			UPDATE rolt005
				SET n05_activo     = 'S',
				    n05_fecini_act = rm_n39_act.n39_perini_real,
				    n05_fecfin_act = rm_n39_act.n39_perfin_real
				WHERE CURRENT OF q_up_n05
			OPEN q_up_n05
			FETCH q_up_n05 INTO rm_n05.*
		END IF
	WHEN 'C'
		UPDATE rolt005
			SET n05_activo     = 'N',
			    n05_fecini_act = NULL,
			    n05_fecfin_act = NULL,
			    n05_fec_ultcie = rm_n05.n05_fec_cierre,
			    n05_fec_cierre = TODAY
			WHERE CURRENT OF q_up_n05
		IF vm_proceso = vm_vac_pag THEN
			LET proc = vm_vac_goz
		ELSE
			LET proc = vm_vac_pag
		END IF
		UPDATE rolt005
			SET n05_activo     = 'N',
			    n05_fecini_act = NULL,
			    n05_fecfin_act = NULL,
			    n05_fec_ultcie = rm_n05.n05_fec_cierre,
			    n05_fec_cierre = TODAY
			WHERE n05_compania = vg_codcia
			  AND n05_proceso  = proc
END CASE

END FUNCTION



FUNCTION primera_vacacion_procesar()
DEFINE i, resul		SMALLINT
DEFINE fecha		DATE

LET fecha = MDY(1, 1, 2099)
FOR i = 1 TO vm_num_det
	IF rm_detvac[i].cod_trab <> rm_detvac[vm_row_cur].cod_trab THEN
		CONTINUE FOR
	END IF
	IF rm_detvac[i].n39_periodo_fin < fecha THEN
		LET fecha = rm_detvac[i].n39_periodo_fin
	END IF
END FOR
IF rm_detvac[vm_row_cur].n39_periodo_fin > fecha AND rm_n39.n39_estado <> 'P'
THEN
	CALL fl_mostrar_mensaje('Debe escojer la vacación mas antigua para procesarla.', 'exclamation')
	LET resul = 0
ELSE
	LET resul = 1
END IF
RETURN resul

END FUNCTION



FUNCTION carga_datos_vac()
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n39		RECORD LIKE rolt039.*
DEFINE r_n39_aux	RECORD LIKE rolt039.*

INITIALIZE r_n39.* TO NULL
LET r_n39.n39_compania    = vg_codcia
LET r_n39.n39_proceso     = vm_proceso
LET r_n39.n39_cod_trab    = rm_detvac[vm_row_cur].cod_trab
LET r_n39.n39_periodo_ini = rm_detvac[vm_row_cur].n39_periodo_ini
LET r_n39.n39_periodo_fin = rm_detvac[vm_row_cur].n39_periodo_fin
LET r_n39.n39_perini_real = r_n39.n39_periodo_ini
IF DAY(r_n39.n39_periodo_ini) > 1 AND DAY(r_n39.n39_periodo_ini) < 16 THEN
	LET r_n39.n39_perini_real = MDY(MONTH(r_n39.n39_periodo_ini), 01,
					YEAR(r_n39.n39_periodo_ini))
END IF
IF DAY(r_n39.n39_periodo_ini) > 16 THEN
	LET r_n39.n39_perini_real = MDY(MONTH(r_n39.n39_periodo_ini), 16,
					YEAR(r_n39.n39_periodo_ini))
END IF
LET r_n39.n39_perfin_real = r_n39.n39_perini_real +
				rm_n90.n90_dias_anio UNITS DAY
IF (NOT anio_bisiesto(YEAR(r_n39.n39_perfin_real)) AND
    MONTH(r_n39.n39_perfin_real) > 2) OR
   (EXTEND(r_n39.n39_perini_real, MONTH TO DAY) =
    EXTEND(r_n39.n39_perfin_real, MONTH TO DAY))
THEN
	LET r_n39.n39_perfin_real = r_n39.n39_perfin_real - 1 UNITS DAY
END IF
LET r_n39.n39_tipo        = 'G'
LET r_n39.n39_estado      = 'A'
LET r_n39.n39_gozar_adic  = 'S'
CALL fl_lee_trabajador_roles(r_n39.n39_compania, r_n39.n39_cod_trab)
	RETURNING r_n30.*
LET r_n39.n39_cod_depto   = r_n30.n30_cod_depto
LET r_n39.n39_ano_proceso = YEAR(r_n39.n39_perfin_real)
LET r_n39.n39_mes_proceso = MONTH(r_n39.n39_perfin_real)
LET r_n39.n39_fecha_ing   = r_n30.n30_fecha_ing
CALL retorna_valor_vacacion(r_n39.n39_cod_trab,	r_n39.n39_fecha_ing,
				r_n39.n39_perini_real, r_n39.n39_perfin_real)
	RETURNING r_n39.n39_dias_vac, r_n39.n39_dias_adi, r_n39.n39_tot_ganado,
		  r_n39.n39_valor_vaca
LET r_n39.n39_dias_goza   = 0
LET r_n39.n39_moneda      = r_n30.n30_mon_sueldo
LET r_n39.n39_paridad     = 1
LET r_n39.n39_valor_adic  = (r_n39.n39_valor_vaca / r_n39.n39_dias_vac) *
				r_n39.n39_dias_adi
LET r_n39.n39_otros_ing   = 0
CALL calcular_iess(r_n39.*) RETURNING r_n39.n39_descto_iess
LET r_n39.n39_otros_egr   = obtener_val_ant()
LET r_n39.n39_neto        = r_n39.n39_valor_vaca + r_n39.n39_valor_adic +
				r_n39.n39_otros_ing - r_n39.n39_descto_iess -
				r_n39.n39_otros_egr
LET r_n39.n39_tipo_pago   = r_n30.n30_tipo_pago
IF r_n39.n39_tipo_pago <> 'E' THEN
	LET r_n39.n39_bco_empresa = r_n30.n30_bco_empresa
	LET r_n39.n39_cta_empresa = r_n30.n30_cta_empresa
	IF r_n39.n39_tipo_pago = 'T' THEN
		LET r_n39.n39_cta_trabaj = r_n30.n30_cta_trabaj
	END IF
END IF
LET r_n39.n39_usuario     = vg_usuario
LET r_n39.n39_fecing      = CURRENT
RETURN r_n39.*

END FUNCTION



FUNCTION calcular_iess(r_n39)
DEFINE r_n39		RECORD LIKE rolt039.*
DEFINE r_n13		RECORD LIKE rolt013.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE aux_iess		LIKE rolt039.n39_descto_iess

CALL fl_lee_trabajador_roles(r_n39.n39_compania, r_n39.n39_cod_trab)
	RETURNING r_n30.*
CALL fl_lee_seguros(r_n30.n30_cod_seguro) RETURNING r_n13.*
CASE r_n39.n39_tipo
	WHEN 'G'
		LET r_n39.n39_descto_iess = ((r_n39.n39_valor_vaca +
						r_n39.n39_valor_adic) *
						r_n13.n13_porc_trab) / 100
	WHEN 'P'
		LET r_n39.n39_descto_iess = 0
END CASE
IF r_n39.n39_gozar_adic = 'N' AND r_n39.n39_tipo = 'G' THEN
	LET r_n39.n39_descto_iess = (r_n39.n39_valor_vaca * r_n13.n13_porc_trab)
					/ 100
END IF
SELECT NVL(SUM(n47_valor_pag - n47_valor_des), 0)
	INTO aux_iess
	FROM rolt047
	WHERE n47_compania    = r_n39.n39_compania
	  AND n47_proceso     = vm_vac_goz
	  AND n47_cod_trab    = r_n39.n39_cod_trab
	  AND n47_periodo_ini = r_n39.n39_periodo_ini
	  AND n47_periodo_fin = r_n39.n39_periodo_fin
IF aux_iess > 0 THEN
	LET r_n39.n39_descto_iess = aux_iess
END IF
RETURN r_n39.n39_descto_iess

END FUNCTION



FUNCTION mostrar_datos_empleado(r_n39)
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n39		RECORD LIKE rolt039.*
DEFINE tot_dias		SMALLINT

DISPLAY BY NAME r_n39.n39_estado, r_n39.n39_cod_trab, r_n39.n39_periodo_ini,
		r_n39.n39_periodo_fin, r_n39.n39_tipo, r_n39.n39_perini_real,
		r_n39.n39_perfin_real, r_n39.n39_dias_vac, r_n39.n39_dias_adi,
		r_n39.n39_moneda, r_n39.n39_valor_vaca, r_n39.n39_otros_ing,
		r_n39.n39_valor_adic,r_n39.n39_descto_iess, r_n39.n39_otros_egr,
		r_n39.n39_tot_ganado, r_n39.n39_neto, r_n39.n39_tipo_pago,
		r_n39.n39_bco_empresa, r_n39.n39_cta_empresa,
		r_n39.n39_cta_trabaj, r_n39.n39_gozar_adic, r_n39.n39_dias_goza
CALL muestra_estado(r_n39.n39_estado)
CALL fl_lee_trabajador_roles(vg_codcia, r_n39.n39_cod_trab) RETURNING r_n30.*
DISPLAY BY NAME r_n30.n30_nombres
CALL fl_lee_moneda(r_n39.n39_moneda) RETURNING r_g13.*
DISPLAY BY NAME r_g13.g13_nombre
CALL fl_lee_banco_general(r_n39.n39_bco_empresa) RETURNING r_g08.*
DISPLAY BY NAME r_g08.g08_nombre
LET tot_dias = r_n39.n39_dias_vac + r_n39.n39_dias_adi
DISPLAY BY NAME tot_dias

END FUNCTION



FUNCTION muestra_estado(estado)
DEFINE estado		LIKE rolt039.n39_estado

CASE estado
	WHEN 'A'
		DISPLAY 'EN PROCESO' TO tit_estado
	WHEN 'P'
		DISPLAY 'PROCESADO'  TO tit_estado
END CASE

END FUNCTION



FUNCTION control_ingresos_descuentos(r_n39, flag)
DEFINE r_n39		RECORD LIKE rolt039.*
DEFINE flag		CHAR(1)
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

LET lin_menu = 0
LET row_ini  = 8
LET num_rows = 14
LET num_cols = 53
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rolf252_3 AT row_ini, 15 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf252_3 FROM '../forms/rolf252_3'
ELSE
	OPEN FORM f_rolf252_3 FROM '../forms/rolf252_3c'
END IF
DISPLAY FORM f_rolf252_3
DISPLAY 'Rub'		TO tit_col1
DISPLAY 'Descripción'	TO tit_col2
DISPLAY 'Valor'		TO tit_col3
CASE flag
	WHEN 'I'
		CALL detalle_ingresos_descuentos(r_n39.*)
	WHEN 'C'
		CALL muestra_ingresos_descuentos()
END CASE
CLOSE WINDOW w_rolf252_3

END FUNCTION



FUNCTION control_cerrar_vac()
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_n45		RECORD LIKE rolt045.*
DEFINE i, j		SMALLINT
DEFINE num_quin		INTEGER
DEFINE resp		CHAR(6)

IF rm_n39_act.n39_compania IS NOT NULL THEN
	SELECT COUNT(*) INTO num_quin
		FROM rolt032
		WHERE n32_compania     = rm_n39_act.n39_compania
		  AND n32_cod_liqrol  IN("Q1", "Q2")
		  AND n32_fecha_ini   >= rm_n39_act.n39_perini_real
		  AND n32_fecha_fin   <= rm_n39_act.n39_perfin_real
		  AND n32_cod_trab     = rm_n39_act.n39_cod_trab
		  AND n32_ano_proceso >= vm_anio_arr
		  AND n32_estado       = 'C'
	IF num_quin < 24 THEN
		CALL fl_mostrar_mensaje('No estan CERRADAS todas las quincenas de la NOMINA. Cierre primero la(s) quincena(s) que falta(n) para poder liquidar estas vacaciones de este empleado.', 'exclamation')
		UPDATE rolt005
			SET n05_activo     = 'N',
			    n05_fecini_act = NULL,
			    n05_fecfin_act = NULL
			WHERE n05_compania  = vg_codcia
			  AND n05_proceso  IN (vm_vac_pag, vm_vac_goz)
			  AND n05_activo    = 'S'
		RETURN
	END IF
END IF
BEGIN WORK
IF bloquear_registro() THEN
	WHENEVER ERROR STOP
	ROLLBACK WORK
	RETURN
END IF
CALL fl_hacer_pregunta('Esta seguro de Liquidar estas vacaciones ?', 'Yes')
	RETURNING resp
IF resp <> 'Yes' THEN
	WHENEVER ERROR STOP
	ROLLBACK WORK
	RETURN
END IF
FOR i = 1 TO vm_num_rub
	IF rm_anticipo[i].n40_num_prest IS NULL THEN
		CONTINUE FOR
	END IF
	CALL fl_lee_cab_prestamo_roles(vg_codcia, rm_anticipo[i].n40_num_prest)
		RETURNING r_n45.*
	IF r_n45.n45_compania IS NULL THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		CALL fl_mostrar_mensaje('No existe préstamo: ' ||
					rm_anticipo[i].n40_num_prest, 'stop')
		EXIT PROGRAM
	END IF
	IF (r_n45.n45_descontado + rm_descto[i].n40_valor) >=
	   (r_n45.n45_val_prest + r_n45.n45_valor_int + r_n45.n45_sal_prest_ant)
	THEN
		LET r_n45.n45_estado = 'P' 
	END IF
	UPDATE rolt045
		SET n45_descontado = n45_descontado + rm_descto[i].n40_valor,
		    n45_estado     = r_n45.n45_estado
		WHERE n45_compania  = r_n45.n45_compania
		  AND n45_num_prest = r_n45.n45_num_prest
	UPDATE rolt058
		SET n58_div_act    = n58_div_act + 1,
		    n58_saldo_dist = n58_saldo_dist - rm_descto[i].n40_valor
		WHERE n58_compania  = r_n45.n45_compania
		  AND n58_num_prest = r_n45.n45_num_prest
		  AND n58_proceso   = vm_proceso
	UPDATE rolt046 SET n46_saldo = n46_saldo - rm_descto[i].n40_valor
		WHERE n46_compania   = r_n45.n45_compania
		  AND n46_num_prest  = r_n45.n45_num_prest
		  AND n46_cod_liqrol = vm_proceso
		  AND n46_fecha_ini  = rm_n39_act.n39_perini_real
		  AND n46_fecha_fin  = rm_n39_act.n39_perfin_real
END FOR
LET i = 0
UPDATE rolt039 SET n39_estado = 'P' WHERE CURRENT OF q_up
CALL grabar_proceso_vac_n05('C')
IF rm_n90.n90_gen_cont_vac = 'S' THEN
	CALL generar_contabilizacion() RETURNING r_b12.*
	IF r_b12.b12_compania IS NULL THEN
		WHENEVER ERROR STOP
		ROLLBACK WORK
		RETURN
	END IF
END IF
WHENEVER ERROR STOP
COMMIT WORK
IF rm_n90.n90_gen_cont_vac = 'S' THEN
	IF r_b12.b12_compania IS NOT NULL AND rm_b00.b00_mayo_online = 'S' THEN
		CALL fl_mayoriza_comprobante(r_b12.b12_compania,
				r_b12.b12_tipo_comp, r_b12.b12_num_comp, 'M')
	END IF
	CALL fl_hacer_pregunta('Desea ver contabilización generada ?', 'Yes')
		RETURNING resp
	IF resp = 'Yes' THEN
		CALL ver_contabilizacion(r_b12.b12_tipo_comp,r_b12.b12_num_comp)
	END IF
END IF
CALL control_imprimir()
CALL fl_lee_vacaciones(vg_codcia, vm_proceso, rm_detvac[vm_row_cur].cod_trab,
			rm_detvac[vm_row_cur].n39_periodo_ini,
			rm_detvac[vm_row_cur].n39_periodo_fin)
	RETURNING rm_n39_act.*
CALL fl_mostrar_mensaje('Vacaciones Liquidadas Ok.', 'info')

END FUNCTION



FUNCTION generar_ingresos_descuentos(r_n39, flag)
DEFINE r_n39		RECORD LIKE rolt039.*
DEFINE flag		SMALLINT
DEFINE tot		DECIMAL(14,2)
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n18		RECORD LIKE rolt018.*
DEFINE rubro		LIKE rolt040.n40_cod_rubro
DEFINE num_prest	LIKE rolt040.n40_num_prest
DEFINE valor, valor2	LIKE rolt040.n40_valor

DECLARE q_rub CURSOR FOR
	SELECT * FROM rolt006
		WHERE n06_estado        = 'A'
		  AND n06_det_tot      IN ('DE', 'DI')
		  AND (n06_calculo      = 'N'
		  AND  n06_flag_ident  IS NULL
		   OR  n06_flag_ident   = vm_anticipo
		   OR  n06_flag_ident  IN
				(SELECT UNIQUE n06_flag_ident
					FROM rolt018
					WHERE n18_cod_rubro = n06_cod_rubro))
		  AND (n06_ing_usuario  = 'S'
		  AND  n06_flag_ident  IS NULL
		   OR  n06_flag_ident   = vm_anticipo
		   OR  n06_flag_ident  IN
				(SELECT UNIQUE n06_flag_ident
					FROM rolt018
					WHERE n18_cod_rubro = n06_cod_rubro))
		  AND n06_cant_valor    = 'V'
		ORDER BY n06_nombre
OPEN q_rub
FETCH q_rub INTO r_n06.*
IF STATUS = NOTFOUND THEN
	CLOSE q_rub
	FREE q_rub
	IF flag THEN
		CALL fl_mensaje_consulta_sin_registros()
	END IF
	RETURN 0
END IF
LET vm_num_rub = 1
FOREACH q_rub INTO r_n06.*
	LET valor     = 0
	LET num_prest = NULL
	LET rubro     = NULL
	DECLARE q_prest CURSOR FOR
		SELECT n45_cod_rubro, n45_num_prest, n46_saldo 
			FROM rolt045, rolt046
			WHERE n45_compania   = vg_codcia
			  AND n45_cod_rubro  = r_n06.n06_cod_rubro
			  AND n45_cod_trab   = rm_detvac[vm_row_cur].cod_trab
			  AND n45_estado     IN ('A', 'R')
			  AND n45_val_prest + n45_valor_int +
				n45_sal_prest_ant - n45_descontado > 0
			  AND n45_compania   = n46_compania
			  AND n45_num_prest  = n46_num_prest
			  AND n46_cod_liqrol = vm_proceso
			  AND n46_fecha_ini  = r_n39.n39_perini_real
			  AND n46_fecha_fin  = r_n39.n39_perfin_real
			  AND n46_saldo      > 0
	OPEN q_prest
	FETCH q_prest INTO rubro, num_prest, valor
	CLOSE q_prest
	FREE q_prest
	CALL lee_ident_anticipo(rubro, r_n06.n06_flag_ident) RETURNING r_n18.*
	IF r_n18.n18_flag_ident IS NOT NULL THEN
		LET rm_descto[vm_num_rub].n40_valor = valor
	END IF
	LET rm_descto[vm_num_rub].n40_cod_rubro = r_n06.n06_cod_rubro
	LET rm_descto[vm_num_rub].n06_nombre    = r_n06.n06_nombre
	SELECT * FROM rolt040
		WHERE n40_compania    = vg_codcia
		  AND n40_proceso     = vm_proceso
		  AND n40_cod_trab    = rm_detvac[vm_row_cur].cod_trab
		  AND n40_periodo_ini = rm_detvac[vm_row_cur].n39_periodo_ini
		  AND n40_periodo_fin = rm_detvac[vm_row_cur].n39_periodo_fin
		  AND n40_cod_rubro   = rm_descto[vm_num_rub].n40_cod_rubro
	IF STATUS <> NOTFOUND THEN
		SELECT NVL(n40_valor, 0) INTO valor2
		FROM rolt040
		WHERE n40_compania    = vg_codcia
		  AND n40_proceso     = vm_proceso
		  AND n40_cod_trab    = rm_detvac[vm_row_cur].cod_trab
		  AND n40_periodo_ini = rm_detvac[vm_row_cur].n39_periodo_ini
		  AND n40_periodo_fin = rm_detvac[vm_row_cur].n39_periodo_fin
		  AND n40_cod_rubro   = rm_descto[vm_num_rub].n40_cod_rubro
		IF r_n06.n06_flag_ident IS NULL OR
		   r_n06.n06_flag_ident <> vm_anticipo AND
		   r_n18.n18_flag_ident IS NULL
		THEN
			LET rm_descto[vm_num_rub].n40_valor = valor + valor2
		END IF
	END IF
	IF r_n06.n06_flag_ident = vm_anticipo THEN
		LET rm_descto[vm_num_rub].n40_valor = obtener_val_ant()
	END IF
	LET rm_anticipo[vm_num_rub].n40_cod_rubro = r_n06.n06_cod_rubro
	LET rm_anticipo[vm_num_rub].n40_num_prest = num_prest
	LET rm_des_aux[vm_num_rub].n40_cod_rubro  =
				rm_descto[vm_num_rub].n40_cod_rubro
	LET rm_des_aux[vm_num_rub].n06_nombre     =
				rm_descto[vm_num_rub].n06_nombre
	LET rm_des_aux[vm_num_rub].n40_valor      =
				rm_descto[vm_num_rub].n40_valor
	LET rm_des_aux[vm_num_rub].n40_num_prest  =
				rm_anticipo[vm_num_rub].n40_num_prest
	LET vm_num_rub = vm_num_rub + 1
	IF vm_num_rub > vm_max_rub THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_rub = vm_num_rub - 1
CALL sacar_total_ing_des(flag, 'XX') RETURNING tot
RETURN 1

END FUNCTION



FUNCTION detalle_ingresos_descuentos(r_n39)
DEFINE r_n39		RECORD LIKE rolt039.*
DEFINE i, j, salir	SMALLINT
DEFINE resp		CHAR(6)
DEFINE tot		DECIMAL(14,2)
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n18		RECORD LIKE rolt018.*
DEFINE valor		LIKE rolt040.n40_valor

IF NOT generar_ingresos_descuentos(r_n39.*, 1) THEN
	RETURN
END IF
OPTIONS	INSERT KEY F30
OPTIONS	DELETE KEY F31
LET salir = 0
WHILE NOT salir
	CALL set_count(vm_num_rub)
	LET int_flag = 0
	INPUT ARRAY rm_descto WITHOUT DEFAULTS FROM rm_descto.*
		ON KEY(INTERRUPT)
       	       		LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
		       	IF resp = 'Yes' THEN
             			LET int_flag = 1
				LET salir    = 1
				FOR i = 1 TO vm_num_rub
					LET rm_descto[i].n40_cod_rubro   =
						rm_des_aux[i].n40_cod_rubro
					LET rm_descto[i].n06_nombre      =
						rm_des_aux[i].n06_nombre
					LET rm_descto[i].n40_valor       =
						rm_des_aux[i].n40_valor
					LET rm_anticipo[i].n40_num_prest =
						rm_des_aux[i].n40_num_prest
				END FOR
				EXIT INPUT
        	       	END IF
	       	ON KEY(F5)
			LET i = arr_curr()
			CALL fl_lee_rubro_roles(rm_descto[i].n40_cod_rubro)
				RETURNING r_n06.*
			CALL lee_ident_anticipo(r_n06.n06_cod_rubro,
						r_n06.n06_flag_ident)
				RETURNING r_n18.*
			IF r_n06.n06_flag_ident IS NULL OR
			   r_n06.n06_flag_ident <> vm_anticipo AND
			   r_n18.n18_flag_ident IS NULL
			THEN
				CONTINUE INPUT
			END IF
			CALL ver_anticipo_vac(r_n06.n06_flag_ident, i)
			LET int_flag = 0
		BEFORE INPUT
               		--#CALL dialog.keysetlabel("INSERT","")
               		--#CALL dialog.keysetlabel("DELETE","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		BEFORE INSERT
			EXIT INPUT
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			DISPLAY i TO cur_rub
			DISPLAY BY NAME vm_num_rub
			CALL fl_lee_rubro_roles(rm_descto[i].n40_cod_rubro)
				RETURNING r_n06.*
			CALL lee_ident_anticipo(r_n06.n06_cod_rubro,
						r_n06.n06_flag_ident)
				RETURNING r_n18.*
			IF r_n06.n06_flag_ident IS NULL OR
			   r_n06.n06_flag_ident <> vm_anticipo AND
			   r_n18.n18_flag_ident IS NULL
			THEN
				--#CALL dialog.keysetlabel("F5","")
			ELSE
				--#CALL dialog.keysetlabel("F5","Detalle")
			END IF
		BEFORE FIELD n40_valor
			LET valor = rm_descto[i].n40_valor
		AFTER FIELD n40_valor
			CALL fl_lee_rubro_roles(rm_descto[i].n40_cod_rubro)
				RETURNING r_n06.*
			CALL lee_ident_anticipo(r_n06.n06_cod_rubro,
						r_n06.n06_flag_ident)
				RETURNING r_n18.*
			IF r_n06.n06_flag_ident = vm_anticipo OR
			   r_n18.n18_flag_ident IS NOT NULL
			THEN
				LET rm_descto[i].n40_valor = valor
				DISPLAY rm_descto[i].n40_valor TO
					rm_descto[j].n40_valor
				CONTINUE INPUT
			END IF
			IF rm_descto[i].n40_valor IS NULL THEN
				LET rm_descto[i].n40_valor = valor
				DISPLAY rm_descto[i].n40_valor TO
					rm_descto[j].n40_valor
			END IF
			CALL sacar_total_ing_des(1, 'XX') RETURNING tot
		AFTER INPUT
			LET salir = 1
			FOR i = 1 TO vm_num_rub
				LET rm_des_aux[i].n40_cod_rubro =
						rm_descto[i].n40_cod_rubro
				LET rm_des_aux[i].n06_nombre    =
						rm_descto[i].n06_nombre
				LET rm_des_aux[i].n40_valor     =
						rm_descto[i].n40_valor
				LET rm_des_aux[i].n40_num_prest =
						rm_anticipo[i].n40_num_prest
			END FOR
	END INPUT
END WHILE

END FUNCTION



FUNCTION reajustar_valor_vacaciones_por_sueldo(r_n39)
DEFINE r_n39		RECORD LIKE rolt039.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE sueldo_pro	LIKE rolt030.n30_sueldo_mes
DEFINE resul		SMALLINT

LET resul = 0
CALL fl_lee_trabajador_roles(vg_codcia, r_n39.n39_cod_trab) RETURNING r_n30.*
IF r_n39.n39_valor_vaca < (r_n30.n30_sueldo_mes / 2) THEN
	LET r_n39.n39_valor_vaca = (r_n30.n30_sueldo_mes / 2)
	LET resul                = 1
END IF
IF r_n39.n39_valor_adic > 0 THEN
	LET sueldo_pro = ((r_n30.n30_sueldo_mes / 2) / r_n39.n39_dias_vac) *
			r_n39.n39_dias_adi
	IF r_n39.n39_valor_adic < sueldo_pro THEN
		LET r_n39.n39_valor_adic = sueldo_pro
		LET resul                = 1
	END IF
END IF
RETURN r_n39.*, resul

END FUNCTION



FUNCTION cargar_ingresos_descuentos(flag)
DEFINE flag		SMALLINT
DEFINE r_n40		RECORD LIKE rolt040.*
DEFINE nombre		LIKE rolt006.n06_nombre
DEFINE tot		DECIMAL(14,2)
DEFINE query		CHAR(1200)
DEFINE expr_sql		VARCHAR(255)

IF num_args() <> 8 THEN
	LET expr_sql = '   AND n40_cod_trab    = ',
			rm_detvac[vm_row_cur].cod_trab,
	'   AND n40_proceso     = "', vm_proceso,'"',
	'   AND n40_periodo_ini = "', rm_detvac[vm_row_cur].n39_periodo_ini,'"',
	'   AND n40_periodo_fin = "', rm_detvac[vm_row_cur].n39_periodo_fin, '"'
ELSE
	LET expr_sql = '   AND n40_cod_trab    = ', rm_n39.n39_cod_trab,
		'   AND n40_proceso     = "', rm_n39.n39_proceso,'"',
		'   AND n40_periodo_ini = "', rm_n39.n39_periodo_ini,'"',
		'   AND n40_periodo_fin = "', rm_n39.n39_periodo_fin, '"'
END IF
LET query = 'SELECT rolt040.*, n06_nombre ',
		' FROM rolt040, rolt006 ',
		' WHERE n40_compania    = ', vg_codcia,
		expr_sql CLIPPED,
		'   AND n06_cod_rubro   = n40_cod_rubro ',
		' ORDER BY n06_nombre '
IF NOT flag THEN
	LET query = 'SELECT rolt040.*, n06_nombre ',
			' FROM rolt006, OUTER rolt040 ',
		' WHERE n40_compania      = ', vg_codcia,
		expr_sql CLIPPED,
		'   AND n06_cod_rubro     = n40_cod_rubro ',
		'   AND n06_estado        = "A" ',
		'   AND n06_det_tot      IN ("DE", "DI") ',
		'   AND (n06_calculo      = "N" ',
		'   AND  n06_flag_ident  IS NULL ',
		'    OR  n06_flag_ident   = "', vm_anticipo, '" ',
		'    OR  n06_flag_ident  IN ',
				'(SELECT UNIQUE n06_flag_ident ',
				'FROM rolt018 ',
				'WHERE n18_cod_rubro = n06_cod_rubro)) ',
		'   AND (n06_ing_usuario  = "S" ',
		'   AND  n06_flag_ident  IS NULL ',
		'    OR  n06_flag_ident   = "', vm_anticipo, '" ',
		'    OR  n06_flag_ident  IN ',
				'(SELECT UNIQUE n06_flag_ident ',
				'FROM rolt018 ',
				'WHERE n18_cod_rubro = n06_cod_rubro)) ',
		'   AND n06_cant_valor    = "V" ',
		' ORDER BY n06_nombre '
END IF
PREPARE cons_n40 FROM query
DECLARE q_n40 CURSOR FOR cons_n40
OPEN q_n40
FETCH q_n40 INTO r_n40.*, nombre
IF STATUS = NOTFOUND THEN
	CLOSE q_n40
	FREE q_n40
	IF flag THEN
		CALL fl_mensaje_consulta_sin_registros()
	END IF
	RETURN 0
END IF
LET vm_num_rub = 1
FOREACH q_n40 INTO r_n40.*, nombre
	LET rm_descto[vm_num_rub].n40_cod_rubro   = r_n40.n40_cod_rubro
	LET rm_descto[vm_num_rub].n06_nombre      = nombre
	IF r_n40.n40_valor IS NULL THEN
		LET r_n40.n40_valor = 0
	END IF
	LET rm_descto[vm_num_rub].n40_valor       = r_n40.n40_valor
	LET rm_anticipo[vm_num_rub].n40_cod_rubro = r_n40.n40_cod_rubro
	LET rm_anticipo[vm_num_rub].n40_num_prest = r_n40.n40_num_prest
	LET vm_num_rub                            = vm_num_rub + 1
	IF vm_num_rub > vm_max_rub THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_rub = vm_num_rub - 1
IF r_n40.n40_compania IS NOT NULL THEN
	CALL sacar_total_ing_des(flag, 'XX') RETURNING tot
	RETURN 1
ELSE
	RETURN 0
END IF

END FUNCTION



FUNCTION muestra_ingresos_descuentos()
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n18		RECORD LIKE rolt018.*
DEFINE i, j		SMALLINT

IF NOT cargar_ingresos_descuentos(1) THEN
	RETURN
END IF
LET int_flag = 0
CALL set_count(vm_num_rub)
DISPLAY ARRAY rm_descto TO rm_descto.*
       	ON KEY(INTERRUPT)   
		LET int_flag = 1
       	        EXIT DISPLAY  
	ON KEY(F5)
		LET i = arr_curr()
		CALL fl_lee_rubro_roles(rm_descto[i].n40_cod_rubro)
			RETURNING r_n06.*
		CALL lee_ident_anticipo(r_n06.n06_cod_rubro,
					r_n06.n06_flag_ident)
			RETURNING r_n18.*
		IF r_n06.n06_flag_ident IS NULL OR
		   r_n06.n06_flag_ident <> vm_anticipo AND
		   r_n18.n18_flag_ident IS NULL
		THEN
			CONTINUE DISPLAY
		END IF
		CALL ver_anticipo_vac(r_n06.n06_flag_ident, i)
		LET int_flag = 0
	--#BEFORE DISPLAY 
		--#CALL dialog.keysetlabel('ACCEPT', '')   
		--#CALL dialog.keysetlabel("CONTROL-W","") 
		--#CALL dialog.keysetlabel("F1","") 
	--#BEFORE ROW 
		--#LET i = arr_curr()
		--#LET j = scr_line()
		--#DISPLAY i TO cur_rub
		--#DISPLAY BY NAME vm_num_rub
		--#CALL fl_lee_rubro_roles(rm_descto[i].n40_cod_rubro)
			--#RETURNING r_n06.*
		--#CALL lee_ident_anticipo(r_n06.n06_cod_rubro,
					--#r_n06.n06_flag_ident)
			--#RETURNING r_n18.*
		--#IF r_n06.n06_flag_ident IS NULL OR
		   --#r_n06.n06_flag_ident <> vm_anticipo AND
		   --#r_n18.n18_flag_ident IS NULL
		--#THEN
			--#CALL dialog.keysetlabel("F5","")
		--#ELSE
			--#CALL dialog.keysetlabel("F5","Detalle")
		--#END IF
        --#AFTER DISPLAY  
                --#CONTINUE DISPLAY
END DISPLAY

END FUNCTION



FUNCTION obtener_val_ant()
DEFINE val_ant		LIKE rolt091.n91_valor_ant

LET val_ant = 0
SELECT NVL(SUM(n91_valor_ant), 0) INTO val_ant
	FROM rolt091
	WHERE n91_compania    = vg_codcia
	  AND n91_proceso     = vm_anticipo
	  AND n91_cod_trab    = rm_detvac[vm_row_cur].cod_trab
	  AND n91_periodo_ini = rm_detvac[vm_row_cur].n39_periodo_ini
	  AND n91_periodo_fin =	rm_detvac[vm_row_cur].n39_periodo_fin
RETURN val_ant

END FUNCTION



FUNCTION obtener_val_ant2()
DEFINE val_ant		LIKE rolt046.n46_valor
DEFINE i		SMALLINT

LET val_ant = 0
FOR i = 1 TO vm_num_rub
	IF rm_anticipo[i].n40_num_prest IS NULL THEN
		CONTINUE FOR
	END IF
	LET val_ant = val_ant + rm_descto[i].n40_valor
END FOR
RETURN val_ant

END FUNCTION



FUNCTION sacar_total_ing_des(flag, tipo)
DEFINE flag		SMALLINT
DEFINE tipo		LIKE rolt006.n06_det_tot
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE i		SMALLINT
DEFINE total_rubro	DECIMAL(14,2)

LET total_rubro = 0
FOR i = 1 TO vm_num_rub
	CALL fl_lee_rubro_roles(rm_descto[i].n40_cod_rubro) RETURNING r_n06.*
	IF NOT flag THEN
		IF r_n06.n06_det_tot <> tipo THEN
			CONTINUE FOR
		END IF
		LET total_rubro = total_rubro + rm_descto[i].n40_valor
	ELSE
		CASE r_n06.n06_det_tot
			WHEN 'DI'
				LET total_rubro = total_rubro +
							rm_descto[i].n40_valor
			WHEN 'DE'
				LET total_rubro = total_rubro -
							rm_descto[i].n40_valor
		END CASE
	END IF
END FOR
IF flag THEN
	DISPLAY BY NAME total_rubro
END IF
RETURN total_rubro

END FUNCTION



FUNCTION borrar_ingresos_descuentos()
DEFINE i		SMALLINT

FOR i = 1 TO vm_max_rub
	INITIALIZE rm_descto[i].*   TO NULL
	INITIALIZE rm_des_aux[i].*  TO NULL
	INITIALIZE rm_anticipo[i].* TO NULL
	LET rm_descto[i].n40_valor  = 0
	LET rm_des_aux[i].n40_valor = 0
END FOR

END FUNCTION



FUNCTION fecha_ultima_quincena()
DEFINE fecha_ult	LIKE rolt032.n32_fecha_fin

SELECT NVL(MAX(n32_fecha_fin), TODAY) INTO fecha_ult
	FROM rolt032
	WHERE n32_compania    = vg_codcia
	  AND n32_cod_liqrol IN("Q1", "Q2")
	  AND n32_estado     <> 'E'
RETURN fecha_ult

END FUNCTION



FUNCTION generar_contabilizacion()
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g14		RECORD LIKE gent014.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n18		RECORD LIKE rolt018.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n56, r_n56_ant	RECORD LIKE rolt056.*
DEFINE r_n56_adi	RECORD LIKE rolt056.*
DEFINE r_n57		RECORD LIKE rolt057.*
DEFINE glosa		LIKE ctbt012.b12_glosa
DEFINE num_che		LIKE ctbt012.b12_num_cheque
DEFINE aux_cont		LIKE ctbt013.b13_cuenta
DEFINE sec		LIKE ctbt013.b13_secuencia
DEFINE val_egr		LIKE rolt039.n39_otros_egr
DEFINE val_vac_g	LIKE rolt039.n39_valor_vaca
DEFINE val_vac_p	LIKE rolt039.n39_valor_adic
DEFINE val_ant		LIKE rolt091.n91_valor_ant
DEFINE frase		VARCHAR(60)
DEFINE valor_cuad	DECIMAL(14,2)
DEFINE lim, i		SMALLINT

INITIALIZE r_b12.*, r_n57.* TO NULL
CALL fl_lee_trabajador_roles(vg_codcia, rm_detvac[vm_row_cur].cod_trab)
	RETURNING r_n30.*
CALL lee_conf_cont_adic(vm_proceso, r_n30.n30_cod_depto) RETURNING r_n56.*
IF NOT validacion_contable(TODAY) THEN
	RETURN r_b12.*
END IF
IF r_n56.n56_compania IS NULL THEN
	CALL fl_lee_proceso_roles(vm_proceso) RETURNING r_n03.*
	CALL fl_mostrar_mensaje('No existen auxiliares contable para este trabajador en el proceso de ' || r_n03.n03_nombre CLIPPED || '.', 'stop')
	RETURN r_b12.*
END IF
IF rm_n39_act.n39_valor_adic > 0 AND r_n56.n56_aux_val_adi IS NULL THEN
	CALL fl_mostrar_mensaje('No existe auxiliar contable para el valor de vacaciones adicionales.', 'stop')
	RETURN r_b12.*
END IF
IF rm_n39_act.n39_otros_ing > 0 AND r_n56.n56_aux_otr_ing IS NULL THEN
	CALL fl_mostrar_mensaje('No existe auxiliar contable para el valor de otros ingresos.', 'stop')
	RETURN r_b12.*
END IF
IF rm_n39_act.n39_descto_iess > 0 AND r_n56.n56_aux_iess IS NULL AND
   rm_n39_act.n39_proceso <> vm_vac_pag
THEN
	CALL fl_mostrar_mensaje('No existe auxiliar contable para el valor de aportaciones del seguro.', 'stop')
	RETURN r_b12.*
END IF
LET r_b12.b12_compania 	  = vg_codcia
LET r_b12.b12_tipo_comp   = "DC"
IF rm_n39_act.n39_tipo_pago = 'C' THEN
	LET r_b12.b12_tipo_comp = "EG"
END IF
{--
IF rm_n39_act.n39_tipo_pago = 'T' THEN
	LET r_b12.b12_tipo_comp = "DP"
END IF
--}
LET r_b12.b12_num_comp    = fl_numera_comprobante_contable(vg_codcia,
				r_b12.b12_tipo_comp, YEAR(TODAY), MONTH(TODAY)) 
IF r_b12.b12_num_comp <= 0 THEN
	INITIALIZE r_b12.* TO NULL
	RETURN r_b12.*
END IF
LET r_b12.b12_estado 	  = 'A'
CASE rm_n39_act.n39_tipo
	WHEN 'G'
		LET frase = 'GOZADAS (APORTE IESS)'
	WHEN 'P'
		LET frase = 'PAGADAS (SIN APORTE IESS)'
END CASE
LET lim = 25
IF rm_n39_act.n39_gozar_adic = 'N' AND rm_n39_act.n39_tipo = 'G' THEN
	LET frase = frase CLIPPED, ' PERO PAG.LIQ.VALOR ADIC.'
	LET lim   = 23
END IF
LET r_b12.b12_glosa       = r_n30.n30_nombres[1, lim] CLIPPED, ', LIQUIDACION ',
				'DE VACACIONES ', frase CLIPPED, ' PERIODO: ',
				rm_n39_act.n39_perini_real USING "dd-mm-yyyy",
				' - ',
				rm_n39_act.n39_perfin_real USING "dd-mm-yyyy"
IF rm_n39_act.n39_tipo_pago = 'T' THEN
	LET r_b12.b12_glosa = r_b12.b12_glosa CLIPPED, ' (TR)'
END IF
IF rm_n39_act.n39_tipo_pago = 'C' THEN
	LET r_b12.b12_benef_che = r_n30.n30_nombres CLIPPED
	CALL lee_cheque(r_b12.*) RETURNING num_che, glosa
	IF int_flag THEN
		CALL fl_mostrar_mensaje('Debe generar el cheque, de lo contrario no se podran liquidar estas vacaciones de este trabajador.', 'stop')
		INITIALIZE r_b12.* TO NULL
		RETURN r_b12.*
	END IF
	LET r_b12.b12_num_cheque = num_che
	LET r_b12.b12_glosa      = glosa CLIPPED
END IF
LET r_b12.b12_origen      = 'A'
CALL fl_lee_moneda(r_n30.n30_mon_sueldo) RETURNING r_g13.*
IF r_g13.g13_moneda = rg_gen.g00_moneda_base THEN
	LET r_g14.g14_tasa = 1
ELSE
	CALL fl_lee_factor_moneda(r_g13.g13_moneda, rg_gen.g00_moneda_base)
		RETURNING r_g14.*
	IF r_g14.g14_serial IS NULL THEN
		CALL fl_mostrar_mensaje('La paridad para esta moneda no existe.', 'stop')
		INITIALIZE r_b12.* TO NULL
		RETURN r_b12.*
	END IF
END IF
LET r_b12.b12_moneda      = r_g13.g13_moneda
LET r_b12.b12_paridad     = r_g14.g14_tasa
LET r_b12.b12_fec_proceso = TODAY
LET r_b12.b12_modulo      = vg_modulo
LET r_b12.b12_usuario     = vg_usuario
LET r_b12.b12_fecing      = CURRENT
INSERT INTO ctbt012 VALUES (r_b12.*) 
LET sec       = 1
LET val_vac_g = 0
SELECT NVL(SUM(n47_valor_pag), 0)
	INTO val_vac_g
	FROM rolt047
	WHERE n47_compania    = rm_n39_act.n39_compania
	  AND n47_proceso     = vm_vac_goz
	  AND n47_cod_trab    = rm_n39_act.n39_cod_trab
	  AND n47_periodo_ini = rm_n39_act.n39_periodo_ini
	  AND n47_periodo_fin = rm_n39_act.n39_periodo_fin
-- OJO NUEVA CONDICION EL 09-OCT-2012
IF rm_n39_act.n39_gozar_adic = "S" THEN
	LET val_vac_g = rm_n39_act.n39_valor_vaca
END IF
--
IF rm_n39_act.n39_tipo_pago = 'T' THEN
	CALL generar_detalle_contable(r_b12.*, r_n56.n56_aux_val_vac,
				-- OJO COMENTADO EL 10-SEP-2012
				--rm_n39_act.n39_valor_vaca, 'D', sec, 1)
				val_vac_g, 'D', sec, 1)
ELSE
	CALL generar_detalle_contable(r_b12.*, r_n56.n56_aux_val_vac,
				-- OJO COMENTADO EL 10-SEP-2012
				--rm_n39_act.n39_valor_vaca, 'D', sec, 0)
				val_vac_g, 'D', sec, 0)
END IF
LET val_vac_p = rm_n39_act.n39_valor_adic
IF val_vac_g < (rm_n39_act.n39_valor_vaca + rm_n39_act.n39_valor_adic) THEN
	LET val_vac_p = (rm_n39_act.n39_valor_vaca + rm_n39_act.n39_valor_adic)
			- val_vac_g
END IF
-- OJO COMENTADO EL 10-SEP-2012
--IF rm_n39_act.n39_valor_adic > 0 THEN
IF val_vac_p > 0 THEN
	LET aux_cont = r_n56.n56_aux_val_adi
	IF rm_n39_act.n39_proceso    <> vm_vac_pag AND
	   rm_n39_act.n39_gozar_adic  = 'N'
	THEN
		CALL lee_conf_cont_adic(vm_vac_pag, r_n30.n30_cod_depto)
			RETURNING r_n56_adi.*
		IF r_n56_adi.n56_aux_val_adi IS NULL THEN
			INITIALIZE r_b12.* TO NULL
			CALL fl_mostrar_mensaje('No existe auxiliar contable para el valor de vacaciones adicionales, por pagar.', 'stop')
			RETURN r_b12.*
		END IF
		LET aux_cont = r_n56_adi.n56_aux_val_adi
	END IF
	LET sec = sec + 1
	IF rm_n39_act.n39_tipo_pago = 'T' THEN
		CALL generar_detalle_contable(r_b12.*, aux_cont,
					-- OJO COMENTADO EL 10-SEP-2012
					--rm_n39_act.n39_valor_adic, 'D', sec, 1)
					val_vac_p, 'D', sec, 1)
	ELSE
		CALL generar_detalle_contable(r_b12.*, aux_cont,
					-- OJO COMENTADO EL 10-SEP-2012
					--rm_n39_act.n39_valor_adic, 'D', sec, 0)
					val_vac_p, 'D', sec, 0)
	END IF
END IF
IF rm_n39_act.n39_otros_ing > 0 THEN
	LET sec = sec + 1
	CALL generar_detalle_contable(r_b12.*, r_n56.n56_aux_otr_ing,
					rm_n39_act.n39_otros_ing, 'D', sec, 0)
END IF
IF rm_n39_act.n39_descto_iess > 0 THEN
	LET sec = sec + 1
	CALL generar_detalle_contable(r_b12.*, r_n56.n56_aux_iess,
					rm_n39_act.n39_descto_iess, 'H', sec, 0)
END IF
IF rm_n39_act.n39_otros_egr > 0 THEN
	LET val_egr = rm_n39_act.n39_otros_egr
	LET val_ant = obtener_val_ant()
	IF val_ant > 0 THEN
		CALL lee_conf_cont_adic(vm_anticipo, r_n30.n30_cod_depto)
			RETURNING r_n56_ant.*
		IF r_n56_ant.n56_compania IS NULL THEN
			CALL fl_mostrar_mensaje('No existen auxiliares contable para este trabajador en el proceso de anticipo de vacaciones.', 'stop')
			INITIALIZE r_b12.* TO NULL
			RETURN r_b12.*
		END IF
		LET sec = sec + 1
		CALL generar_detalle_contable(r_b12.*,r_n56_ant.n56_aux_val_vac,
						val_ant, 'H', sec, 0)
		LET val_egr = val_egr - val_ant
	END IF
	LET val_ant = obtener_val_ant2()
	IF val_ant > 0 THEN
		FOR i = 1 TO vm_num_rub
			IF rm_anticipo[i].n40_num_prest IS NULL THEN
				CONTINUE FOR
			END IF
			CALL fl_lee_rubro_roles(rm_descto[i].n40_cod_rubro)
				RETURNING r_n06.*
			CALL lee_ident_anticipo(r_n06.n06_cod_rubro,
						r_n06.n06_flag_ident)
				RETURNING r_n18.*
			CALL lee_conf_cont_adic(r_n18.n18_flag_ident,
						r_n30.n30_cod_depto)
				RETURNING r_n56_ant.*
			IF r_n56_ant.n56_compania IS NULL THEN
				CALL fl_lee_proceso_roles(r_n18.n18_flag_ident)
					RETURNING r_n03.*
				CALL fl_mostrar_mensaje('No existen auxiliares contable para este trabajador en el proceso de ' || r_n03.n03_nombre CLIPPED || '.', 'stop')
				INITIALIZE r_b12.* TO NULL
				EXIT FOR
			END IF
			LET sec = sec + 1
			CALL generar_detalle_contable(r_b12.*,
						r_n56_ant.n56_aux_val_vac,
						rm_descto[i].n40_valor, 'H',
						sec, 0)
			LET val_egr = val_egr - rm_descto[i].n40_valor
		END FOR
		IF r_b12.b12_compania IS NULL THEN
			RETURN r_b12.*
		END IF
	END IF
	IF val_egr > 0 THEN
		IF r_n56.n56_aux_otr_egr IS NULL THEN
			INITIALIZE r_b12.* TO NULL
			CALL fl_mostrar_mensaje('No existe auxiliar contable para el valor de otros descuentos.', 'stop')
			RETURN r_b12.*
		END IF
		LET sec = sec + 1
		CALL generar_detalle_contable(r_b12.*, r_n56.n56_aux_otr_egr,
						val_egr, 'H', sec, 0)
	END IF
END IF
LET sec = sec + 1
CALL generar_detalle_contable(r_b12.*, r_n56.n56_aux_banco, rm_n39_act.n39_neto,
				'H', sec, 1)
SELECT NVL(SUM(b13_valor_base), 0) INTO valor_cuad
	FROM ctbt013
	WHERE b13_compania  = vg_codcia
	  AND b13_tipo_comp = r_b12.b12_tipo_comp
	  AND b13_num_comp  = r_b12.b12_num_comp
IF valor_cuad <> 0 THEN
	CALL fl_mostrar_mensaje('Se ha generado un error en la contabilizacion. POR FAVOR LLAME AL ADMINISTRADOR.', 'stop')
	INITIALIZE r_b12.* TO NULL
	RETURN r_b12.*
END IF
LET r_n57.n57_compania    = rm_n39_act.n39_compania
LET r_n57.n57_proceso     = rm_n39_act.n39_proceso
LET r_n57.n57_cod_trab    = rm_n39_act.n39_cod_trab
LET r_n57.n57_periodo_ini = rm_n39_act.n39_periodo_ini
LET r_n57.n57_periodo_fin = rm_n39_act.n39_periodo_fin
LET r_n57.n57_tipo_comp   = r_b12.b12_tipo_comp
LET r_n57.n57_num_comp    = r_b12.b12_num_comp
INSERT INTO rolt057 VALUES(r_n57.*)
RETURN r_b12.*

END FUNCTION



FUNCTION lee_conf_cont_adic(cod_lq, cod_depto)
DEFINE cod_lq		LIKE rolt056.n56_proceso
DEFINE cod_depto	LIKE rolt030.n30_cod_depto
DEFINE r_n56		RECORD LIKE rolt056.*

INITIALIZE r_n56.* TO NULL
SELECT * INTO r_n56.*
	FROM rolt056
	WHERE n56_compania  = vg_codcia
	  AND n56_proceso   = cod_lq
	  AND n56_cod_depto = cod_depto
	  AND n56_cod_trab  = rm_detvac[vm_row_cur].cod_trab
	  AND n56_estado    = "A"
RETURN r_n56.*

END FUNCTION



FUNCTION validacion_contable(fecha)
DEFINE fecha		DATE
DEFINE resp 		VARCHAR(6)

IF YEAR(fecha) < YEAR(rm_b00.b00_fecha_cm) OR
  (YEAR(fecha) = YEAR(rm_b00.b00_fecha_cm) AND
   MONTH(fecha) <= MONTH(rm_b00.b00_fecha_cm))
THEN
	CALL fl_mostrar_mensaje('El Mes en Contabilidad esta cerrado. Reapertúrelo para que se pueda generar la contabilización de las Vacaciones.', 'stop')
	RETURN 0
END IF
IF fecha_bloqueada(vg_codcia, MONTH(fecha), YEAR(fecha)) THEN
	CALL fl_mostrar_mensaje('No puede generar contabilización de las Vacaciones de un mes bloqueado en CONTABILIDAD.', 'stop')
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION fecha_bloqueada(codcia, mes, ano)
DEFINE codcia 		LIKE ctbt006.b06_compania
DEFINE mes, ano		SMALLINT
DEFINE r_b06		RECORD LIKE ctbt006.*

INITIALIZE r_b06.* TO NULL 
SELECT * INTO r_b06.*
	FROM ctbt006
	WHERE b06_compania = codcia
	  AND b06_ano      = ano
	  AND b06_mes      = mes
IF r_b06.b06_mes IS NOT NULL THEN
	CALL fl_mostrar_mensaje('Mes contable esta bloqueado.','stop')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION lee_cheque(r_b12)
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE glosa		LIKE ctbt012.b12_glosa

OPEN WINDOW w_rolf252_4 AT 07, 12 WITH FORM "../forms/rolf252_4" 
	ATTRIBUTE(BORDER, COMMENT LINE LAST, FORM LINE FIRST)
LET int_flag = 0
INPUT BY NAME r_b12.b12_num_cheque, r_b12.b12_glosa
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD b12_glosa
		LET glosa = r_b12.b12_glosa
	AFTER FIELD b12_glosa
		IF r_b12.b12_glosa IS NULL THEN
			LET r_b12.b12_glosa = glosa
			DISPLAY BY NAME r_b12.b12_glosa
		END IF
	AFTER FIELD b12_num_cheque
		IF r_b12.b12_num_cheque IS NULL THEN
			NEXT FIELD b12_num_cheque
		END IF
	AFTER INPUT
		IF r_b12.b12_num_cheque IS NULL THEN
			NEXT FIELD b12_num_cheque
		END IF
END INPUT
CLOSE WINDOW w_rolf252_4
RETURN r_b12.b12_num_cheque, r_b12.b12_glosa

END FUNCTION



FUNCTION generar_detalle_contable(r_b12, cuenta, valor, tipo, sec, flag_bco)
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE valor		LIKE ctbt013.b13_valor_base
DEFINE tipo		CHAR(1)
DEFINE sec		LIKE ctbt013.b13_secuencia
DEFINE flag_bco		SMALLINT
DEFINE r_g09		RECORD LIKE gent009.*
DEFINE r_b13		RECORD LIKE ctbt013.*

INITIALIZE r_b13.* TO NULL
LET r_b13.b13_compania    = r_b12.b12_compania
LET r_b13.b13_tipo_comp   = r_b12.b12_tipo_comp
LET r_b13.b13_num_comp    = r_b12.b12_num_comp
LET r_b13.b13_secuencia   = sec
IF flag_bco THEN
	IF rm_n39_act.n39_tipo_pago <> 'E' AND tipo = 'H' THEN
		CALL fl_lee_banco_compania(vg_codcia,rm_n39_act.n39_bco_empresa,
						rm_n39_act.n39_cta_empresa)
			RETURNING r_g09.*
		LET cuenta = r_g09.g09_aux_cont
	END IF
	CASE rm_n39_act.n39_tipo_pago
		WHEN 'C' LET r_b13.b13_tipo_doc = 'CHE'
		{--
		WHEN 'T' IF tipo = 'H' THEN
				LET r_b13.b13_tipo_doc = 'DEP'
			 END IF
		--}
	END CASE
END IF
LET r_b13.b13_cuenta      = cuenta
IF rm_n39_act.n39_tipo_pago = 'T' AND tipo = 'H' AND flag_bco THEN
	LET r_b13.b13_glosa = 'TRANSFERENCIA A CUENTA DEL EMPLEADO '
ELSE
	LET r_b13.b13_glosa = 'LIQ.VAC.EMP. '
END IF
LET r_b13.b13_glosa       = r_b13.b13_glosa CLIPPED, ' ',
				rm_n39_act.n39_cod_trab USING "<<&&", ' ',
				rm_n39_act.n39_perini_real USING "dd-mm-yy",' ',
				rm_n39_act.n39_perfin_real USING "dd-mm-yy"
LET r_b13.b13_valor_base  = 0
LET r_b13.b13_valor_aux   = 0
CASE tipo
	WHEN 'D'
		LET r_b13.b13_valor_base = valor
	WHEN 'H'
		LET r_b13.b13_valor_base = valor * (-1)
END CASE
LET r_b13.b13_fec_proceso = r_b12.b12_fec_proceso
INSERT INTO ctbt013 VALUES (r_b13.*)

END FUNCTION



FUNCTION ver_empleado(cod_trab)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE comando		CHAR(400)
DEFINE run_prog		VARCHAR(20)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA',
	vg_separador, 'fuentes', vg_separador, run_prog, 'rolp108 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', cod_trab
RUN comando

END FUNCTION



FUNCTION ver_contabilizacion(tipo_comp, num_comp)
DEFINE tipo_comp	LIKE ctbt012.b12_tipo_comp
DEFINE num_comp		LIKE ctbt012.b12_num_comp
DEFINE comando		CHAR(400)
DEFINE run_prog		VARCHAR(20)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD',
	vg_separador, 'fuentes', vg_separador, run_prog, 'ctbp201 ', vg_base,
	' CB ', vg_codcia, ' "', tipo_comp, '" ', num_comp
RUN comando

END FUNCTION



FUNCTION ver_anticipo_vac(flag_ident, i)
DEFINE flag_ident	LIKE rolt006.n06_flag_ident
DEFINE i		SMALLINT
DEFINE comando		CHAR(400)
DEFINE run_prog		VARCHAR(20)
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(100)
DEFINE proc		LIKE rolt039.n39_proceso
DEFINE cod_trab		LIKE rolt039.n39_cod_trab
DEFINE per_ini		LIKE rolt039.n39_periodo_ini
DEFINE per_fin		LIKE rolt039.n39_periodo_fin

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
IF num_args() < 8 THEN
	LET proc     = vm_proceso
	LET cod_trab = rm_detvac[vm_row_cur].cod_trab
	LET per_ini  = rm_detvac[vm_row_cur].n39_periodo_ini
	LET per_fin  = rm_detvac[vm_row_cur].n39_periodo_fin
ELSE
	LET proc     = rm_n39.n39_proceso
	LET cod_trab = rm_n39.n39_cod_trab
	LET per_ini  = rm_n39.n39_periodo_ini
	LET per_fin  = rm_n39.n39_periodo_fin
END IF
IF flag_ident = vm_anticipo THEN
	LET prog  = 'rolp253 '
	LET param = cod_trab, ' ', proc, ' ', per_ini, ' ', per_fin
END IF
DECLARE q_n18 CURSOR FOR
	SELECT * FROM rolt018
		WHERE n18_flag_ident = flag_ident
OPEN q_n18
FETCH q_n18
IF STATUS <> NOTFOUND THEN
	LET prog  = 'rolp214 '
	LET param = rm_anticipo[i].n40_num_prest
END IF
CLOSE q_n18
FREE q_n18
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'NOMINA',
	vg_separador, 'fuentes', vg_separador, run_prog, prog, vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' ', param CLIPPED
RUN comando

END FUNCTION



FUNCTION control_imprimir()
DEFINE r_n39		RECORD LIKE rolt039.*
DEFINE comando		VARCHAR(100)
DEFINE query		CHAR(1000)
DEFINE expr_sql		VARCHAR(255)

INITIALIZE r_n39.* TO NULL
IF num_args() <> 8 THEN
	LET expr_sql = '   AND n39_cod_trab    = ',
			rm_detvac[vm_row_cur].cod_trab,
	'   AND n39_proceso     = "', vm_proceso,'"',
	'   AND n39_periodo_ini = "', rm_detvac[vm_row_cur].n39_periodo_ini,'"',
	'   AND n39_periodo_fin = "', rm_detvac[vm_row_cur].n39_periodo_fin, '"'
ELSE
	LET expr_sql = '   AND n39_cod_trab    = ', rm_n39.n39_cod_trab,
		'   AND n39_proceso     = "', rm_n39.n39_proceso,'"',
		'   AND n39_periodo_ini = "', rm_n39.n39_periodo_ini,'"',
		'   AND n39_periodo_fin = "', rm_n39.n39_periodo_fin, '"'
END IF
LET query = 'SELECT * FROM rolt039 ',
		' WHERE n39_compania    = ', vg_codcia,
		expr_sql CLIPPED
PREPARE cons_rep FROM query
DECLARE q_rep CURSOR FOR cons_rep
OPEN q_rep
FETCH q_rep INTO r_n39.*
IF r_n39.n39_compania IS NULL THEN
	CLOSE q_rep
	FREE q_rep
	CALL fl_mostrar_mensaje('No se ha generado el comprobante de vacaciones todavía.', 'exclamation')
	RETURN
END IF
IF r_n39.n39_estado <> 'P' THEN
	CLOSE q_rep
	FREE q_rep
	CALL fl_mostrar_mensaje('No se ha LIQUIDADO el comprobante de vacaciones todavía.', 'exclamation')
	RETURN
END IF
CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT reporte_vacaciones TO PIPE comando
FOREACH q_rep INTO r_n39.*
	OUTPUT TO REPORT reporte_vacaciones(r_n39.*)
END FOREACH
FINISH REPORT reporte_vacaciones

END FUNCTION



REPORT reporte_vacaciones(r_n39)
DEFINE r_n39		RECORD LIKE rolt039.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_g31		RECORD LIKE gent031.*
DEFINE r_n13		RECORD LIKE rolt013.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n47		RECORD LIKE rolt047.*
DEFINE titulo		VARCHAR(80)
DEFINE label_letras	VARCHAR(130)
DEFINE linea		VARCHAR(80)
DEFINE mes, tit_mes	VARCHAR(10)
DEFINE m_i, m_f, frase	VARCHAR(10)
DEFINE tot_dias, escape	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT
DEFINE act_dob1		SMALLINT
DEFINE act_dob2		SMALLINT
DEFINE des_dob		SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	80
	BOTTOM MARGIN	4
	PAGE LENGTH	44

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	LET act_dob1	= 87		# Activar Doble Ancho (inicio)
	LET act_dob2	= 49		# Activar Doble Ancho (final)
	LET des_dob	= 48		# Desactivar Doble Ancho
	CALL fl_justifica_titulo('C', "VACACIONES ANUALES", 80) RETURNING titulo
	print ASCII escape;
	print ASCII act_10cpi;
	PRINT COLUMN 030, ASCII escape, ASCII act_dob1, ASCII act_dob2,
	      COLUMN 034, titulo,
		ASCII escape, ASCII act_dob1, ASCII des_dob,
		ASCII escape, ASCII act_10cpi
	SKIP 2 LINES
	CALL fl_lee_localidad(r_n39.n39_compania, vg_codloc) RETURNING r_g02.*
	CALL fl_lee_ciudad(r_g02.g02_ciudad) RETURNING r_g31.*
	CALL fl_justifica_titulo('I', fl_retorna_nombre_mes(MONTH(TODAY)), 10)
		RETURNING tit_mes
	LET mes = tit_mes
	PRINT COLUMN 005, r_g31.g31_nombre CLIPPED, ', ', DAY(TODAY) USING "&&",
		' de ', mes CLIPPED, ' del ', YEAR(TODAY) USING "&&&&"
	SKIP 1 LINES
	CALL fl_lee_trabajador_roles(r_n39.n39_compania, r_n39.n39_cod_trab)
		RETURNING r_n30.*
	CALL fl_lee_moneda(r_n30.n30_mon_sueldo) RETURNING r_g13.*
	PRINT COLUMN 003, 'Nombre del Trabajador: ', r_n30.n30_nombres CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 003, 'En cumplimiento de lo que prescriben los Art. No. ',
		'69, 70 y 71 del Codigo del'
	LET linea = 'por el periodo ',YEAR(r_n39.n39_perini_real) USING "&&&&",
			' - ', YEAR(r_n39.n39_perfin_real) USING "&&&&", '.'
	IF YEAR(r_n39.n39_perini_real) = YEAR(r_n39.n39_perfin_real) THEN
		LET linea = 'por el año ', YEAR(r_n39.n39_perfin_real)
				USING "&&&&", '.'
	END IF
	PRINT COLUMN 003, 'Trabajo, el trabajador arriba indicado; gozara',
		' de vacaciones'
	PRINT COLUMN 003, linea CLIPPED
	SKIP 1 LINES
	CALL fl_justifica_titulo('I', fl_retorna_nombre_mes(
				MONTH(r_n39.n39_periodo_ini)), 10)
		RETURNING m_i
	CALL fl_justifica_titulo('I', fl_retorna_nombre_mes(
				MONTH(r_n39.n39_periodo_fin)), 10)
		RETURNING m_f
	PRINT COLUMN 003, 'PERIODO: ', m_i[1, 3], '/',
		YEAR(r_n39.n39_periodo_ini) USING "&&&&", '  -  ', m_f[1, 3],
		'/', YEAR(r_n39.n39_periodo_fin) USING "&&&&",
	      COLUMN 050, 'TOTAL GANADO: ', r_g13.g13_simbolo CLIPPED, ' ',
		r_n39.n39_tot_ganado USING "$$,###,##&.##"

ON EVERY ROW
	SKIP 1 LINES
	DECLARE q_gozo CURSOR FOR
		SELECT * FROM rolt047
			WHERE n47_compania    = r_n39.n39_compania
			  AND n47_proceso     = r_n39.n39_proceso
			  AND n47_cod_trab    = r_n39.n39_cod_trab
			  AND n47_periodo_ini = r_n39.n39_periodo_ini
			  AND n47_periodo_fin = r_n39.n39_periodo_fin
			ORDER BY n47_fecini_vac
	LET tot_dias = r_n39.n39_dias_vac + r_n39.n39_dias_adi
	IF r_n39.n39_gozar_adic = 'N' THEN
		LET tot_dias = tot_dias - r_n39.n39_dias_adi
	END IF
	IF r_n39.n39_tipo = 'P' THEN
		LET tot_dias = 0
	END IF
	FOREACH q_gozo INTO r_n47.*
		CASE r_n47.n47_estado
			WHEN 'A' LET frase = 'Por GOZAR'
			WHEN 'G' LET frase = 'GOZADAS  '
		END CASE
		PRINT COLUMN 003, frase, ' desde: ',
			r_n47.n47_fecini_vac USING "dd-mm-yyyy",
			'    hasta: ', r_n47.n47_fecfin_vac USING "dd-mm-yyyy",
			'    Total dias: ', r_n47.n47_dias_goza USING "<<&"
		IF tot_dias > 0 THEN
			LET tot_dias = tot_dias - r_n47.n47_dias_goza
		END IF
	END FOREACH
	SKIP 1 LINES
	IF tot_dias > 0 THEN
		PRINT COLUMN 003, 'Total de dias PENDIENTES: ',
			tot_dias USING "<<&"
		SKIP 1 LINES
	END IF
	CALL fl_lee_seguros(r_n30.n30_cod_seguro) RETURNING r_n13.*
	print ASCII escape;
	print ASCII act_12cpi;
	PRINT COLUMN 003, ASCII escape, ASCII act_dob1, ASCII act_dob2,
	      COLUMN 006, 'LIQUIDACION: ',
		ASCII escape, ASCII act_dob1, ASCII des_dob,
		ASCII escape, ASCII act_10cpi
	PRINT COLUMN 003, 'Por los ', r_n39.n39_dias_vac USING "&&", ' dias',
		'.............................................',
	      COLUMN 064, r_g13.g13_simbolo CLIPPED, ' ',
		r_n39.n39_valor_vaca USING "$$,###,##&.##"
	IF r_n39.n39_dias_adi > 0 THEN
		PRINT COLUMN 003, 'Por los ', r_n39.n39_dias_adi USING "&&",
			' dias adicionales..................................',
		      COLUMN 064, r_g13.g13_simbolo CLIPPED, ' ',
			r_n39.n39_valor_adic USING "$$,###,##&.##"
	ELSE
		PRINT COLUMN 003, ' '
	END IF
	SKIP 1 LINES
	PRINT COLUMN 003, 'TOTAL',
	      COLUMN 064, r_g13.g13_simbolo CLIPPED, ' ',
		r_n39.n39_valor_vaca + r_n39.n39_valor_adic
		USING "$$,###,##&.##"
	SKIP 1 LINES
	print ASCII escape;
	print ASCII act_12cpi;
	PRINT COLUMN 003, ASCII escape, ASCII act_dob1, ASCII act_dob2,
	      COLUMN 006, 'DEDUCCIONES: ',
		ASCII escape, ASCII act_dob1, ASCII des_dob,
		ASCII escape, ASCII act_10cpi
	PRINT COLUMN 008, 'Su aporte ', r_n13.n13_porc_trab USING "#&.##", '% ',
		r_n13.n13_descripcion CLIPPED, '.................',
	      COLUMN 064, r_g13.g13_simbolo CLIPPED, ' ',
		r_n39.n39_descto_iess USING "$$,###,##&.##"
	IF r_n39.n39_otros_ing > 0 THEN
		PRINT COLUMN 008, 'Otros Ingresos............................',
			'............',
		      COLUMN 064, r_g13.g13_simbolo CLIPPED, ' ',
			r_n39.n39_otros_ing USING "$$,###,##&.##"
	END IF
	PRINT COLUMN 008, 'Otros Descuentos..................................',
		'....';
	IF r_n39.n39_otros_egr > 0 THEN
		PRINT COLUMN 064, r_g13.g13_simbolo CLIPPED, ' ',
			r_n39.n39_otros_egr USING "$$,###,##&.##"
	ELSE
		PRINT COLUMN 064, ' '
	END IF

ON LAST ROW
	IF r_n39.n39_otros_ing = 0 THEN
		SKIP 2 LINES
	ELSE
		SKIP 1 LINES
	END IF
	PRINT COLUMN 003, 'Suma Liquida Recibida: ',
	      COLUMN 064, r_g13.g13_simbolo CLIPPED, ' ',
		r_n39.n39_neto USING "$$,###,##&.##"
	SKIP 1 LINES
	LET label_letras = fl_retorna_letras(r_g13.g13_moneda, r_n39.n39_neto)
	PRINT COLUMN 003, 'SON: ', label_letras[1, 77] CLIPPED
	SKIP 3 LINES
	PRINT COLUMN 003, '..............................',
	      COLUMN 040, '..............................'
	PRINT COLUMN 003, '     Firma del Trabajador     ',
	      COLUMN 040, '       Firma del Gerente      '

END REPORT



FUNCTION anio_bisiesto(anio)
DEFINE anio		SMALLINT
DEFINE query		VARCHAR(200)
DEFINE valor		DECIMAL(12,2)

LET query = 'SELECT MOD(', anio, ', 4) val_mod FROM dual INTO TEMP tmp_mod '
PREPARE exec_mod FROM query
EXECUTE exec_mod
SELECT * INTO valor FROM tmp_mod
DROP TABLE tmp_mod
IF valor = 0 THEN
	RETURN 1
ELSE
	RETURN 0
END IF

END FUNCTION



FUNCTION control_dias_gozados()
DEFINE r_reg		RECORD
				n47_cod_liqrol	LIKE rolt047.n47_cod_liqrol,
				n47_fecha_ini	LIKE rolt047.n47_fecha_ini,
				n47_fecha_fin	LIKE rolt047.n47_fecha_fin,
				n47_max_dias	LIKE rolt047.n47_max_dias,
				n47_dias_real	LIKE rolt047.n47_dias_real,
				n47_dias_goza	LIKE rolt047.n47_dias_goza,
				n47_fecini_vac	LIKE rolt047.n47_fecini_vac,
				n47_fecfin_vac	LIKE rolt047.n47_fecfin_vac,
				n47_secuencia	LIKE rolt047.n47_secuencia,
				n47_estado	LIKE rolt047.n47_estado
			END RECORD
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE resp		CHAR(6)
DEFINE i, j, resul	SMALLINT
DEFINE num_row, max_row	SMALLINT
DEFINE salir		SMALLINT
DEFINE tot_dias		SMALLINT
DEFINE tot_goza		SMALLINT
DEFINE tot_dias_aux	SMALLINT
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE r_n39		RECORD LIKE rolt039.*
DEFINE cod_liqrol	LIKE rolt047.n47_cod_liqrol
DEFINE fecha_ini	LIKE rolt047.n47_fecha_ini
DEFINE fecini_vac	LIKE rolt047.n47_fecini_vac

IF num_args() < 8 THEN
	CALL fl_lee_vacaciones(vg_codcia, vm_proceso,
			rm_detvac[vm_row_cur].cod_trab,
			rm_detvac[vm_row_cur].n39_periodo_ini,
			rm_detvac[vm_row_cur].n39_periodo_fin)
		RETURNING r_n39.*
ELSE
	CALL fl_lee_vacaciones(vg_codcia,rm_n39.n39_proceso,rm_n39.n39_cod_trab,
				rm_n39.n39_periodo_ini, rm_n39.n39_periodo_fin)
		RETURNING r_n39.*
END IF
IF r_n39.n39_compania IS NULL THEN
	RETURN
END IF
IF r_n39.n39_tipo = 'P' THEN
	CALL fl_mostrar_mensaje('Estas vacaciones no tiene dias para gozar.', 'exclamation')
	RETURN
END IF
INITIALIZE r_reg.* TO NULL
DECLARE q_n47 CURSOR FOR
	SELECT n47_cod_liqrol, n47_fecha_ini, n47_fecha_fin, n47_max_dias,
		n47_dias_real, n47_dias_goza, n47_fecini_vac, n47_fecfin_vac,
		n47_secuencia, n47_estado
		FROM rolt047
		WHERE n47_compania    = r_n39.n39_compania
		  AND n47_proceso     = r_n39.n39_proceso
		  AND n47_cod_trab    = r_n39.n39_cod_trab
		  AND n47_periodo_ini = r_n39.n39_periodo_ini
		  AND n47_periodo_fin = r_n39.n39_periodo_fin
		ORDER BY n47_secuencia
OPEN q_n47
FETCH q_n47 INTO r_reg.*
CLOSE q_n47
LET tot_dias     = r_n39.n39_dias_vac + r_n39.n39_dias_adi
IF r_n39.n39_dias_goza > tot_dias AND r_reg.n47_cod_liqrol IS NULL THEN
	CALL fl_mostrar_mensaje('Estas vacaciones ya tiene todos sus dias gozados.', 'exclamation')
	RETURN
END IF
IF r_n39.n39_gozar_adic = 'N' THEN
	LET tot_dias           = tot_dias - r_n39.n39_dias_adi
	-- OJO COMENTADO EL 10-SEP-2012
	--LET r_n39.n39_dias_adi = 0
END IF
LET tot_dias_aux = tot_dias - tot_dias_n47(r_n39.*)
LET lin_menu = 0
LET row_ini  = 4
LET num_rows = 21
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rolf252_5 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf252_5 FROM '../forms/rolf252_5'
ELSE
	OPEN FORM f_rolf252_5 FROM '../forms/rolf252_5c'
END IF
DISPLAY FORM f_rolf252_5
DISPLAY "Aplicados En" TO tit_col1
DISPLAY "D.M."         TO tit_col2
DISPLAY "D.R."         TO tit_col3
DISPLAY "D.G."         TO tit_col4
DISPLAY "Fec. I. V."   TO tit_col5
DISPLAY "Fec. F. V."   TO tit_col6
DISPLAY "Sec."         TO tit_col7
DISPLAY "E"            TO tit_col8
CALL fl_lee_trabajador_roles(vg_codcia, r_n39.n39_cod_trab) RETURNING r_n30.*
DISPLAY BY NAME r_n39.n39_cod_trab, r_n30.n30_nombres, r_n39.n39_periodo_ini,
		r_n39.n39_periodo_fin, r_n39.n39_tipo, r_n39.n39_perini_real,
		r_n39.n39_perfin_real, r_n39.n39_dias_vac, r_n39.n39_dias_adi,
		r_n39.n39_gozar_adic, r_n39.n39_dias_goza, r_n39.n39_fecini_vac,
		r_n39.n39_fecfin_vac, tot_dias
DISPLAY "GOZADAS" TO tit_tipo
LET max_row = 20
LET num_row = 1
FOREACH q_n47 INTO r_reg.*
	LET rm_diasgoz[num_row].* = r_reg.*
	LET num_row               = num_row + 1
	LET tot_dias              = tot_dias - r_reg.n47_dias_goza
	{-- OJO COMENTADO EL 10-SEP-2012
	LET r_n39.n39_dias_vac    = r_n39.n39_dias_vac - r_reg.n47_dias_goza
	IF r_n39.n39_dias_vac < 0 THEN
		LET r_n39.n39_dias_adi = r_n39.n39_dias_adi + r_n39.n39_dias_vac
		LET r_n39.n39_dias_vac = 0
	END IF
	--}
	IF num_row > max_row THEN
		EXIT FOREACH
	END IF
END FOREACH
LET num_row = num_row - 1
--IF tot_dias_n47(r_n39.*) <= tot_dias THEN
IF num_row = 0 AND num_args() >= 8 THEN
	CALL fl_mostrar_mensaje('Estas vacaciones no tiene aun registrados sus dias para gozar.', 'exclamation')
	LET int_flag = 0
	CLOSE WINDOW w_rolf252_5
	RETURN
END IF
IF tot_dias > 0 AND num_args() < 8 THEN
	IF num_row = 0 THEN
		LET num_row = 1
	ELSE
		LET num_row = num_row + 1
	END IF
	IF r_n39.n39_dias_vac > 0 AND num_row = 1 THEN
		LET tot_dias           = tot_dias - tot_dias_n47(r_n39.*)
		LET r_n39.n39_dias_vac = r_n39.n39_dias_vac -
						tot_dias_n47(r_n39.*)
	END IF
	IF r_n39.n39_dias_vac < 0 AND num_row = 1 THEN
		LET r_n39.n39_dias_adi = r_n39.n39_dias_adi + r_n39.n39_dias_vac
		LET r_n39.n39_dias_vac = 0
	END IF
	LET resul = 0
	IF r_n39.n39_dias_vac > 0 THEN
		CALL cargar_datos_linea_det_gozar(r_n39.n39_dias_vac,
					r_n39.n39_dias_adi, tot_dias, num_row,1)
			RETURNING resul
		IF NOT resul AND num_row <= 1 THEN
			CLOSE WINDOW w_rolf252_5
			LET int_flag = 0
			RETURN
		END IF
		IF NOT resul THEN
			LET num_row = num_row - 1
		END IF
	ELSE
		LET resul = 1
	END IF
{-- OJO COMENTADO EL 10-SEP-2012
	IF tot_dias > r_n39.n39_dias_vac AND r_n39.n39_gozar_adic = 'S'
	   AND resul
	THEN
		IF r_n39.n39_dias_vac > 0 THEN
			LET num_row = num_row + 1
		END IF
		CALL cargar_datos_linea_det_gozar(r_n39.n39_dias_vac,
				r_n39.n39_dias_adi, tot_dias, num_row, 0)
			RETURNING resul
		IF NOT resul AND num_row <= 1 THEN
			CLOSE WINDOW w_rolf252_5
			LET int_flag = 0
			RETURN
		END IF
		IF NOT resul THEN
			LET num_row = num_row - 1
		END IF
	END IF
--}
END IF
LET salir    = 0
LET int_flag = 0
WHILE TRUE
	IF num_args() < 8 THEN
	CALL set_count(num_row)
	INPUT ARRAY rm_diasgoz WITHOUT DEFAULTS FROM rm_diasgoz.*
		ON KEY(INTERRUPT)
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
		ON KEY(F5)
			LET i = arr_curr()
			IF rm_diasgoz[i].n47_estado = 'E' THEN
				CONTINUE INPUT
			END IF
			CALL ver_liquidacion(i, 'L')
			LET int_flag = 0
		BEFORE INPUT
			CALL dialog.keysetlabel("F1","")
			CALL dialog.keysetlabel("CONTROL-W","")
		BEFORE INSERT
			INITIALIZE rm_diasgoz[i].* TO NULL
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			LET max_row = arr_count()
			IF i > max_row THEN
				LET max_row = max_row + 1
			END IF
			LET r_reg.* = rm_diasgoz[1].*
			DISPLAY i TO num_row
			DISPLAY BY NAME max_row
			IF rm_diasgoz[i].n47_estado = 'E' THEN
				CALL dialog.keysetlabel("F5","")
			ELSE
				CALL dialog.keysetlabel("F5","Liquidacion")
			END IF
			CALL calcula_total_dias_goza(max_row)
			CALL usuario_fecha_dias_goza(r_n39.*, i)
		BEFORE FIELD n47_cod_liqrol
			LET cod_liqrol = rm_diasgoz[i].n47_cod_liqrol
		BEFORE FIELD n47_fecha_ini
			LET fecha_ini = rm_diasgoz[i].n47_fecha_ini
		BEFORE FIELD n47_fecini_vac
			LET fecini_vac = rm_diasgoz[i].n47_fecini_vac
		AFTER FIELD n47_cod_liqrol
			IF rm_diasgoz[i].n47_cod_liqrol IS NULL THEN
				LET rm_diasgoz[i].n47_cod_liqrol = cod_liqrol
			END IF
			IF rm_diasgoz[i].n47_cod_liqrol IS NULL AND i <= 1 THEN
				NEXT FIELD n47_cod_liqrol
			END IF
			CALL genera_linea_datos(r_n39.*, i, j)
			CALL calcula_total_dias_goza(max_row)
		AFTER FIELD n47_fecha_ini
			IF rm_diasgoz[i].n47_fecha_ini IS NULL THEN
				LET rm_diasgoz[i].n47_fecha_ini = fecha_ini
				DISPLAY rm_diasgoz[i].n47_fecha_ini TO
					rm_diasgoz[j].n47_fecha_ini
			END IF
			CALL genera_linea_datos(r_n39.*, i, j)
			CALL calcula_total_dias_goza(max_row)
			IF rm_diasgoz[i].n47_fecha_ini < r_n39.n39_perfin_real
			THEN
				CALL fl_mostrar_mensaje('La fecha inicial debe ser mayor que la fecha final real de vacaciones.', 'exclamation')
				NEXT FIELD n47_fecha_ini
			END IF
			IF YEAR(rm_diasgoz[i].n47_fecha_ini) <>
			   YEAR(r_n39.n39_perfin_real)
			THEN
				--CALL fl_mostrar_mensaje('El anio de la fecha inicial debe ser igual al anio de la fecha final real de vacaciones.', 'exclamation')
				--NEXT FIELD n47_fecha_ini
			END IF
		AFTER FIELD n47_dias_real, n47_dias_goza
			IF rm_diasgoz[i].n47_estado <> 'A' THEN
				CONTINUE INPUT
			END IF
			IF NOT modificar_dias_goza(max_row, i, j, tot_dias_aux)
			THEN
				CONTINUE INPUT
			END IF
			CALL calcula_total_dias_goza(max_row)
		AFTER FIELD n47_fecini_vac
			IF rm_diasgoz[i].n47_fecini_vac IS NULL THEN
				LET rm_diasgoz[i].n47_fecini_vac = fecini_vac
			END IF
			CALL recalcular_fec_vac(i, 0)
			DISPLAY rm_diasgoz[i].* TO rm_diasgoz[j].*
			CALL cargar_datos_liq() RETURNING r_n32.*
			IF NOT ((rm_diasgoz[1].n47_fecini_vac >=
				 r_n32.n32_fecha_ini) AND
				(rm_diasgoz[1].n47_fecini_vac <=
				 r_n32.n32_fecha_fin))
			THEN
				CALL fl_mostrar_mensaje('Estas vacaciones deben gozarse, al menos un dia, en la siguiente quincena a generarse en el sistema.', 'info')
				--NEXT FIELD n47_fecini_vac
			END IF
			IF (rm_diasgoz[i].n47_fecini_vac <
			    rm_diasgoz[i].n47_fecha_ini) OR
			   (rm_diasgoz[i].n47_fecini_vac >
			    rm_diasgoz[i].n47_fecha_fin)
			THEN
				CALL fl_mostrar_mensaje('La fecha inicial de vacaciones debe estar dentro del periodo quincenal a aplicar.', 'exclamation')
				NEXT FIELD n47_fecini_vac
			END IF
			IF NOT ((rm_diasgoz[i].n47_fecfin_vac >=
				 rm_diasgoz[i].n47_fecha_ini) AND
				(rm_diasgoz[i].n47_fecfin_vac <=
				 rm_diasgoz[i].n47_fecha_fin))
			THEN
				CALL fl_mostrar_mensaje('La fecha final de vacaciones debe estar dentro del periodo quincenal a aplicar.', 'exclamation')
				NEXT FIELD n47_fecini_vac
			END IF
		--AFTER ROW
			--LET rm_diasgoz[1].* = r_reg.*
			--DISPLAY rm_diasgoz[1].* TO rm_diasgoz[1].*
		AFTER INPUT
			LET max_row  = arr_count()
			LET tot_goza = 0
			FOR i = 1 TO max_row
				LET tot_goza = tot_goza +
						rm_diasgoz[i].n47_dias_goza
			END FOR
			IF r_n39.n39_gozar_adic = 'S' AND
			   tot_goza <> tot_dias_aux THEN
				CALL fl_mostrar_mensaje('No puede ser el total de dias a gozar ser mayor que el total de dias del empleado.', 'exclamation')
				-- OJO COMENTADO EL 10-SEP-2012
				--CONTINUE INPUT
			END IF
			CALL grabar_n47(r_n39.*, max_row)
			CALL calcular_iess(r_n39.*)
				RETURNING r_n39.n39_descto_iess
			LET r_n39.n39_neto = r_n39.n39_valor_vaca
						+ r_n39.n39_valor_adic
						+ r_n39.n39_otros_ing
						- r_n39.n39_descto_iess
						- r_n39.n39_otros_egr
			LET r_n39.n39_dias_goza = r_n39.n39_dias_vac
						+ r_n39.n39_dias_adi
						- tot_goza
			UPDATE rolt039
				SET n39_dias_goza   = r_n39.n39_dias_goza,
				    n39_descto_iess = r_n39.n39_descto_iess,
				    n39_neto        = r_n39.n39_neto
				WHERE n39_compania    = r_n39.n39_compania
				  AND n39_proceso     = r_n39.n39_proceso
				  AND n39_cod_trab    = r_n39.n39_cod_trab
				  AND n39_periodo_ini = r_n39.n39_periodo_ini
				  AND n39_periodo_fin = r_n39.n39_periodo_fin
			LET salir = 1
	END INPUT
	ELSE
	CALL set_count(num_row)
	DISPLAY ARRAY rm_diasgoz TO rm_diasgoz.*
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			IF rm_diasgoz[i].n47_estado = 'E' THEN
				CONTINUE DISPLAY
			END IF
			CALL ver_liquidacion(i, 'L')
			LET int_flag = 0
		BEFORE DISPLAY
			CALL dialog.keysetlabel("ACCEPT","")
			CALL dialog.keysetlabel("RETURN","")
			CALL dialog.keysetlabel("F1","")
			CALL dialog.keysetlabel("CONTROL-W","")
		BEFORE ROW
			LET i = arr_curr()
			LET j = scr_line()
			DISPLAY i TO num_row
			DISPLAY num_row TO max_row
			IF rm_diasgoz[i].n47_estado = 'E' THEN
				CALL dialog.keysetlabel("F5","")
			ELSE
				CALL dialog.keysetlabel("F5","Liquidacion")
			END IF
			CALL calcula_total_dias_goza(max_row)
			CALL usuario_fecha_dias_goza(r_n39.*, i)
		AFTER DISPLAY
			CONTINUE DISPLAY
	END DISPLAY
	END IF
	IF int_flag <> 0 OR salir THEN
		EXIT WHILE
	END IF
END WHILE
CLOSE WINDOW w_rolf252_5

END FUNCTION



FUNCTION genera_linea_datos(r_n39, i, j)
DEFINE r_n39		RECORD LIKE rolt039.*
DEFINE i, j		SMALLINT
DEFINE dia		SMALLINT

{--
IF i - 1 < 1 THEN
	RETURN
END IF
--}
LET dia = 1
IF rm_diasgoz[i].n47_cod_liqrol = 'Q2' THEN
	LET dia = 16
END IF
IF rm_diasgoz[i].n47_fecha_ini IS NULL THEN
	LET rm_diasgoz[i].n47_fecha_ini = rm_diasgoz[i - 1].n47_fecha_fin
					+ 1 UNITS DAY
ELSE
	LET rm_diasgoz[i].n47_fecha_ini =MDY(MONTH(rm_diasgoz[i].n47_fecha_ini),
					dia, YEAR(rm_diasgoz[i].n47_fecha_ini))
END IF
IF rm_diasgoz[i].n47_cod_liqrol = 'Q2' THEN
	LET rm_diasgoz[i].n47_fecha_fin =MDY(MONTH(rm_diasgoz[i].n47_fecha_ini),
					01, YEAR(rm_diasgoz[i].n47_fecha_ini))
					+ 1 UNITS MONTH - 1 UNITS DAY
ELSE
	LET rm_diasgoz[i].n47_fecha_fin =MDY(MONTH(rm_diasgoz[i].n47_fecha_ini),
					 15, YEAR(rm_diasgoz[i].n47_fecha_ini))
END IF
IF rm_diasgoz[i].n47_max_dias IS NULL THEN
	LET rm_diasgoz[i].n47_max_dias  = r_n39.n39_dias_vac
	LET rm_diasgoz[i].n47_dias_real = r_n39.n39_dias_vac
	LET rm_diasgoz[i].n47_dias_goza = r_n39.n39_dias_vac
END IF
IF rm_diasgoz[i].n47_fecini_vac IS NULL THEN
	LET rm_diasgoz[i].n47_fecini_vac = rm_diasgoz[i - 1].n47_fecfin_vac
					+ 1 UNITS DAY
	IF rm_diasgoz[i].n47_fecini_vac < rm_diasgoz[i].n47_fecha_ini THEN
		LET rm_diasgoz[i].n47_fecini_vac = rm_diasgoz[i].n47_fecha_ini
	END IF
	CALL recalcular_fec_vac(i, 0)
END IF
IF rm_diasgoz[i].n47_secuencia IS NULL THEN
	LET rm_diasgoz[i].n47_secuencia = rm_diasgoz[i - 1].n47_secuencia + 1
END IF
IF rm_diasgoz[i].n47_estado IS NULL THEN
	LET rm_diasgoz[i].n47_estado = 'A'
END IF
DISPLAY rm_diasgoz[i].* TO rm_diasgoz[j].*

END FUNCTION



FUNCTION modificar_dias_goza(lim, i, j, dias_vac)
DEFINE lim, i, j	SMALLINT
DEFINE dias_vac		LIKE rolt039.n39_dias_vac
DEFINE dias_aux_g	LIKE rolt047.n47_dias_goza
DEFINE l		SMALLINT

LET dias_aux_g = rm_diasgoz[i].n47_dias_goza
IF rm_diasgoz[i].n47_dias_goza > dias_vac THEN
	CALL fl_mostrar_mensaje('El número de días a gozar no puede ser mayor al número de días vacaciones.', 'exclamation')
	RETURN 0
END IF
IF rm_diasgoz[i].n47_dias_real > rm_diasgoz[i].n47_dias_goza THEN
	CALL fl_mostrar_mensaje('El número de días real no puede ser mayor al número de días a gozar.', 'exclamation')
	RETURN 0
END IF
FOR l = i TO lim
	LET rm_diasgoz[l].n47_max_dias = rm_diasgoz[l].n47_dias_goza
	CALL recalcular_fec_vac(l, 1)
END FOR
DISPLAY rm_diasgoz[i].* TO rm_diasgoz[j].*
RETURN 1

END FUNCTION



FUNCTION tot_dias_n47(r_n39)
DEFINE r_n39		RECORD LIKE rolt039.*
DEFINE tot_dias		SMALLINT

LET tot_dias = 0
SELECT NVL(SUM(n47_dias_goza), 0) INTO tot_dias
	FROM rolt047
	WHERE n47_compania    = r_n39.n39_compania
	  AND n47_proceso     = r_n39.n39_proceso
	  AND n47_cod_trab    = r_n39.n39_cod_trab
	  AND n47_periodo_ini = r_n39.n39_periodo_ini
	  AND n47_periodo_fin = r_n39.n39_periodo_fin
	  AND n47_estado      = "G"
RETURN tot_dias

END FUNCTION



FUNCTION grabar_n47(r_n39, num_row)
DEFINE r_n39		RECORD LIKE rolt039.*
DEFINE num_row		SMALLINT
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE r_n47		RECORD LIKE rolt047.*
DEFINE i		SMALLINT
DEFINE tiempo_max	INTEGER
DEFINE query		CHAR(600)
DEFINE mensaje		VARCHAR(200)

LET query = 'SELECT TRUNC((NVL(',
		'(SELECT MAX(n39_perfin_real) ',
			'FROM rolt039 ',
			'WHERE n39_compania = ', vg_codcia,
			'  AND n39_proceso  = "', vm_proceso, '"',
			'  AND n39_cod_trab = ', r_n39.n39_cod_trab,
			'  AND n39_estado   = "P"), TODAY) - DATE("',
			r_n39.n39_perfin_real, '")) / ', rm_n90.n90_dias_anio,
			') + 1 val_t ',
		' FROM dual ',
		' INTO TEMP t1 '
PREPARE exec_t1_a FROM query
EXECUTE exec_t1_a
SELECT val_t INTO tiempo_max FROM t1
DROP TABLE t1
IF tiempo_max > rm_n90.n90_tiem_max_vac THEN
	LET mensaje = 'Estas vacaciones tienen mas de ',
			rm_n90.n90_tiem_max_vac USING "<<<&",
			' años, ya no se pueden gozar estos días.'
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	RETURN
END IF
DELETE FROM rolt047
	WHERE n47_compania    = r_n39.n39_compania
	  AND n47_proceso     = r_n39.n39_proceso
	  AND n47_cod_trab    = r_n39.n39_cod_trab
	  AND n47_periodo_ini = r_n39.n39_periodo_ini
	  AND n47_periodo_fin = r_n39.n39_periodo_fin
	  AND n47_estado      = "A"
FOR i = 1 TO num_row
	IF rm_diasgoz[i].n47_estado <> 'A' THEN
		CONTINUE FOR
	END IF
	LET r_n47.n47_compania    = r_n39.n39_compania
	LET r_n47.n47_proceso     = r_n39.n39_proceso
	LET r_n47.n47_cod_trab    = r_n39.n39_cod_trab
	LET r_n47.n47_periodo_ini = r_n39.n39_periodo_ini
	LET r_n47.n47_periodo_fin = r_n39.n39_periodo_fin
	LET r_n47.n47_secuencia   = i
	LET r_n47.n47_fecini_vac  = rm_diasgoz[i].n47_fecini_vac
	LET r_n47.n47_fecfin_vac  = rm_diasgoz[i].n47_fecfin_vac
	LET r_n47.n47_estado      = rm_diasgoz[i].n47_estado
	LET r_n47.n47_max_dias    = rm_diasgoz[i].n47_max_dias
	LET r_n47.n47_dias_real   = rm_diasgoz[i].n47_dias_real
	LET r_n47.n47_dias_goza   = rm_diasgoz[i].n47_dias_goza
	LET r_n47.n47_cod_liqrol  = rm_diasgoz[i].n47_cod_liqrol
	LET r_n47.n47_fecha_ini   = rm_diasgoz[i].n47_fecha_ini
	LET r_n47.n47_fecha_fin   = rm_diasgoz[i].n47_fecha_fin
	LET r_n47.n47_valor_pag   = calcula_valor_vacaciones(r_n39.*, i,
								vm_proceso)
	LET r_n47.n47_valor_des   = calcula_valor_vacaciones(r_n39.*, i, 'XV')
	LET r_n47.n47_usuario     = vg_usuario
	LET r_n47.n47_fecing      = CURRENT
	INSERT INTO rolt047 VALUES (r_n47.*)
END FOR

END FUNCTION


 
FUNCTION ver_liquidacion(i, flag)
DEFINE i		SMALLINT
DEFINE flag		CHAR(1)
DEFINE param		VARCHAR(60)
DEFINE prog		VARCHAR(10)
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n32		RECORD LIKE rolt032.*

IF num_args() < 8 THEN
	LET r_n30.n30_cod_trab = rm_detvac[vm_row_cur].cod_trab
ELSE
	LET r_n30.n30_cod_trab = rm_n39.n39_cod_trab
END IF
CALL fl_lee_liquidacion_roles(vg_codcia, rm_diasgoz[i].n47_cod_liqrol,
			rm_diasgoz[i].n47_fecha_ini,rm_diasgoz[i].n47_fecha_fin,
			r_n30.n30_cod_trab)
	RETURNING r_n32.*
CALL fl_lee_trabajador_roles(vg_codcia, r_n30.n30_cod_trab)
	RETURNING r_n30.*
LET prog = 'rolp303 '
CASE flag
	WHEN 'T'
		LET param = ' "', rm_diasgoz[i].n47_cod_liqrol, '" ',
				'"', rm_diasgoz[i].n47_fecha_ini, '" ',
				'"', rm_diasgoz[i].n47_fecha_fin, '" "N" ',
				r_n32.n32_cod_depto
	WHEN 'L'
		LET param = ' "', rm_diasgoz[i].n47_cod_liqrol, '" ',
				'"', rm_diasgoz[i].n47_fecha_ini, '" ',
				'"', rm_diasgoz[i].n47_fecha_fin, '" "N" ',
				r_n32.n32_cod_depto, ' ', r_n32.n32_cod_trab
	WHEN 'I'
		LET prog  = 'rolp405 '
		LET param = ' ', YEAR(r_n32.n32_fecha_ini), ' ',
				MONTH(r_n32.n32_fecha_ini), ' "',
				r_n32.n32_cod_liqrol, '"', ' "N" ',
				r_n32.n32_cod_depto, ' ', r_n32.n32_cod_trab
		IF r_n30.n30_estado = 'J' THEN
			LET prog  = 'rolp404 '
			LET param = ' ', YEAR(r_n32.n32_fecha_ini), ' ',
					MONTH(r_n32.n32_fecha_ini)
		END IF
END CASE
CALL ejecuta_comando('NOMINA', vg_modulo, prog, param)

END FUNCTION



FUNCTION calcula_valor_vacaciones(r_n39, i, flag_ident)
DEFINE i, j		SMALLINT
DEFINE r_n39		RECORD LIKE rolt039.*
DEFINE flag_ident	LIKE rolt006.n06_flag_ident
DEFINE r_n13		RECORD LIKE rolt013.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE val_vac		LIKE rolt039.n39_valor_vaca
DEFINE valor		LIKE rolt033.n33_valor
DEFINE tot_dias		LIKE rolt039.n39_dias_vac

LET valor = 0
--IF r_n39.n39_estado = 'P' AND r_n39.n39_tipo = 'G' THEN

-- OJO COMENTADO EL 10-SEP-2012
--IF r_n39.n39_tipo = 'G' THEN
	LET tot_dias = r_n39.n39_dias_vac
	LET val_vac  = r_n39.n39_valor_vaca
	IF r_n39.n39_gozar_adic = 'S' THEN
		LET tot_dias = tot_dias + r_n39.n39_dias_adi
		LET val_vac  = val_vac  + r_n39.n39_valor_adic
	END IF
	LET valor = ((val_vac + r_n39.n39_otros_ing) / tot_dias) *
			rm_diasgoz[i].n47_dias_goza
	IF flag_ident = 'XV' THEN
		CALL fl_lee_trabajador_roles(r_n39.n39_compania,
						r_n39.n39_cod_trab)
			RETURNING r_n30.*
		CALL fl_lee_seguros(r_n30.n30_cod_seguro) RETURNING r_n13.*
		LET valor = valor - (valor * r_n13.n13_porc_trab / 100)
	END IF
--END IF
RETURN valor

END FUNCTION



FUNCTION cargar_datos_linea_det_gozar(dias_vac, dias_adi, tot_dias, i, flag)
DEFINE dias_vac		LIKE rolt039.n39_dias_vac
DEFINE dias_adi		LIKE rolt039.n39_dias_adi
DEFINE tot_dias, i, l	SMALLINT
DEFINE flag		SMALLINT
DEFINE r_n32		RECORD LIKE rolt032.*

CALL cargar_datos_liq() RETURNING r_n32.*
IF r_n32.n32_cod_liqrol IS NULL THEN
	CALL fl_mostrar_mensaje('No existe una liquidación de quincena ACTIVA todavía.', 'exclamation')
	RETURN 0
END IF
LET rm_diasgoz[i].n47_cod_liqrol = r_n32.n32_cod_liqrol
LET rm_diasgoz[i].n47_fecha_ini  = r_n32.n32_fecha_ini
IF flag THEN
	LET rm_diasgoz[i].n47_fecha_fin  = r_n32.n32_fecha_fin
	LET rm_diasgoz[i].n47_max_dias   = tot_dias
	IF rm_diasgoz[i].n47_max_dias > (rm_n00.n00_dias_mes / 2) THEN
		LET rm_diasgoz[i].n47_max_dias = (rm_n00.n00_dias_mes / 2)
	END IF
	LET rm_diasgoz[i].n47_dias_real  = dias_vac
	LET rm_diasgoz[i].n47_dias_goza  = dias_vac
	CALL recalcular_fec_vac(i, 1)
ELSE
	LET l = i - 1
	IF l < 1 THEN
		LET l = 1
		LET i = 1
	END IF
	IF rm_diasgoz[l].n47_fecha_ini = r_n32.n32_fecha_ini THEN
		IF rm_diasgoz[l].n47_cod_liqrol = 'Q1' THEN
			LET rm_diasgoz[i].n47_cod_liqrol = 'Q2'
			LET rm_diasgoz[i].n47_fecha_ini  =
				rm_diasgoz[l].n47_fecha_fin + 1 UNITS DAY
		ELSE
			LET rm_diasgoz[i].n47_cod_liqrol = 'Q1'
			LET rm_diasgoz[i].n47_fecha_ini  =
				rm_diasgoz[l].n47_fecha_ini + 1 UNITS MONTH
				- 15 UNITS DAY
		END IF
	END IF
	LET rm_diasgoz[i].n47_fecha_fin  = rm_diasgoz[i].n47_fecha_ini +
				((rm_n00.n00_dias_mes / 2) - 1) UNITS DAY
	IF (DAY(DATE(EXTEND(rm_diasgoz[i].n47_fecha_fin, YEAR TO MONTH)) +
		1 UNITS MONTH - 1 UNITS DAY) = 31) AND
	   (rm_diasgoz[i].n47_cod_liqrol = 'Q2')
	THEN
		LET rm_diasgoz[i].n47_fecha_fin = rm_diasgoz[i].n47_fecha_fin +
							1 UNITS DAY
	END IF
	LET rm_diasgoz[i].n47_max_dias   = tot_dias - dias_vac
	LET rm_diasgoz[i].n47_dias_real  = dias_adi
	LET rm_diasgoz[i].n47_dias_goza  = dias_adi
	CALL recalcular_fec_vac(i, 1)
END IF
LET rm_diasgoz[i].n47_secuencia = i
LET rm_diasgoz[i].n47_estado    = 'A'
RETURN 1

END FUNCTION



FUNCTION recalcular_fec_vac(i, flag)
DEFINE i, flag		SMALLINT

IF DAY(rm_diasgoz[i].n47_fecha_ini) = 16 THEN
	IF flag THEN
		LET rm_diasgoz[i].n47_fecini_vac = rm_diasgoz[i].n47_fecha_fin -
				(rm_diasgoz[i].n47_dias_goza - 1) UNITS DAY
	END IF
	LET rm_diasgoz[i].n47_fecfin_vac = rm_diasgoz[i].n47_fecha_fin
ELSE
	IF flag THEN
		LET rm_diasgoz[i].n47_fecini_vac = rm_diasgoz[i].n47_fecha_ini
	END IF
END IF
LET rm_diasgoz[i].n47_fecfin_vac = rm_diasgoz[i].n47_fecini_vac +
				(rm_diasgoz[i].n47_dias_goza - 1) UNITS DAY

END FUNCTION



FUNCTION cargar_datos_liq()
DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE mensaje		VARCHAR(200)

INITIALIZE r_n32.* TO NULL
IF rm_n00.n00_serial IS NULL THEN
        CALL fl_mostrar_mensaje('No existe configuración general para este módulo.', 'stop')
	RETURN r_n32.*
END IF
CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*
IF r_n01.n01_compania IS NULL THEN
        CALL fl_mostrar_mensaje('No existe configuración para esta compañía.', 'stop')
	RETURN r_n32.*
END IF
IF r_n01.n01_estado <> 'A' THEN
        CALL fl_mostrar_mensaje('Compañía no esta activa.', 'stop')
	RETURN r_n32.*
END IF
LET r_n32.n32_ano_proceso = r_n01.n01_ano_proceso
LET r_n32.n32_mes_proceso = r_n01.n01_mes_proceso
INITIALIZE r_n05.* TO NULL
DECLARE q_n05 CURSOR FOR
	SELECT * FROM rolt005
		WHERE n05_compania   = vg_codcia
		  AND n05_proceso[1] IN ('M', 'Q', 'S')
		ORDER BY n05_fec_cierre DESC
OPEN q_n05
FETCH q_n05 INTO r_n05.*
INITIALIZE r_n32.* TO NULL
DECLARE q_ultliq CURSOR FOR
	SELECT * FROM rolt032
		WHERE n32_compania = r_n05.n05_compania
		  AND n32_estado   = 'C'
		ORDER BY n32_fecha_fin DESC
OPEN q_ultliq
FETCH q_ultliq INTO r_n32.*
IF r_n32.n32_compania IS NOT NULL THEN
	IF r_n32.n32_cod_liqrol = 'Q1' THEN
		LET r_n32.n32_cod_liqrol = 'Q2'
	ELSE
		LET r_n32.n32_cod_liqrol = 'Q1'
	END IF
ELSE
	LET r_n32.n32_cod_liqrol = r_n05.n05_proceso
END IF
CALL fl_retorna_rango_fechas_proceso(vg_codcia, r_n32.n32_cod_liqrol, 
			     r_n01.n01_ano_proceso, r_n01.n01_mes_proceso)
	RETURNING r_n32.n32_fecha_ini, r_n32.n32_fecha_fin
RETURN r_n32.*

END FUNCTION



FUNCTION calcula_total_dias_goza(l)
DEFINE l, i		SMALLINT
DEFINE tot_real		SMALLINT
DEFINE tot_goza		SMALLINT

LET tot_real = 0
LET tot_goza = 0
FOR i = 1 TO l
	LET tot_real = tot_real + rm_diasgoz[i].n47_dias_real
	LET tot_goza = tot_goza + rm_diasgoz[i].n47_dias_goza
END FOR
DISPLAY BY NAME tot_real, tot_goza

END FUNCTION



FUNCTION usuario_fecha_dias_goza(r_n39, i)
DEFINE r_n39		RECORD LIKE rolt039.*
DEFINE i		SMALLINT
DEFINE r_n47		RECORD LIKE rolt047.*
DEFINE query		CHAR(1000)

INITIALIZE r_n47.* TO NULL
LET r_n47.n47_usuario = vg_usuario
LET r_n47.n47_fecing  = CURRENT
LET query = 'SELECT NVL(n47_usuario, "', vg_usuario CLIPPED, '") usuar, ',
		'NVL(n47_fecing, CURRENT) fecha ',
		' FROM rolt047 ',
		' WHERE n47_compania    = ', r_n39.n39_compania,
		'   AND n47_proceso     = "', r_n39.n39_proceso, '"',
		'   AND n47_cod_trab    = ', r_n39.n39_cod_trab,
		'   AND n47_periodo_ini = "', r_n39.n39_periodo_ini, '"',
		'   AND n47_periodo_fin = "', r_n39.n39_periodo_fin, '"',
		'   AND n47_secuencia   = ', rm_diasgoz[i].n47_secuencia,
		' INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
SELECT * INTO r_n47.n47_usuario, r_n47.n47_fecing FROM t1
DISPLAY BY NAME r_n47.n47_usuario, r_n47.n47_fecing
DROP TABLE t1

END FUNCTION



FUNCTION regenerar_novedades(cod_trab, flag)
DEFINE cod_trab		LIKE rolt039.n39_cod_trab
DEFINE flag		SMALLINT
DEFINE param		VARCHAR(60)
DEFINE prog		VARCHAR(10)
DEFINE mensaje		VARCHAR(200)
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE r_n30		RECORD LIKE rolt030.*

CALL fl_retorna_proceso_roles_activo(vg_codcia) RETURNING r_n05.*
IF r_n05.n05_compania IS NOT NULL THEN
	IF r_n05.n05_proceso[1,1] = 'M' OR r_n05.n05_proceso[1,1] = 'Q' OR
	   r_n05.n05_proceso[1,1] = 'S' THEN
		CALL fl_lee_trabajador_roles(vg_codcia, cod_trab)
			RETURNING r_n30.*
		LET mensaje = 'Se va a regenerar novedad de ',r_n05.n05_proceso,
				' ', r_n05.n05_fecini_act USING "dd-mm-yyyy",
				' - ', r_n05.n05_fecfin_act USING "dd-mm-yyyy",
				' para el trabajador ', cod_trab USING "&&&&",
				' ', r_n30.n30_nombres CLIPPED
		IF flag THEN
			CALL fl_mostrar_mensaje(mensaje, 'info')
		END IF
		LET prog  = 'rolp203 '
		LET param = ' X ', cod_trab
		CALL ejecuta_comando('NOMINA', vg_modulo, prog, param)
	END IF
END IF

END FUNCTION



FUNCTION ejecuta_comando(modulo, mod, prog, param)
DEFINE modulo		VARCHAR(15)
DEFINE mod		LIKE gent050.g50_modulo
DEFINE prog		VARCHAR(10)
DEFINE param		VARCHAR(60)
DEFINE comando          VARCHAR(250)
DEFINE run_prog		VARCHAR(10)

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET comando = 'cd ..', vg_separador, '..', vg_separador, modulo,
		vg_separador, 'fuentes', vg_separador, run_prog, prog,
		vg_base, ' ', mod, ' ', vg_codcia, ' ', param
RUN comando

END FUNCTION



FUNCTION lee_ident_anticipo(rubro, flag_ident)
DEFINE rubro		LIKE rolt018.n18_cod_rubro
DEFINE flag_ident	LIKE rolt018.n18_flag_ident
DEFINE r_n18		RECORD LIKE rolt018.*

INITIALIZE r_n18.* TO NULL
SELECT * INTO r_n18.*
	FROM rolt018
	WHERE n18_cod_rubro  = rubro
	  AND n18_flag_ident = flag_ident
RETURN r_n18.*

END FUNCTION
