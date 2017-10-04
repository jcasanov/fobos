--------------------------------------------------------------------------------
-- Titulo           : ctbp310.4gl - Consulta Balance de Comprobación
-- Elaboracion      : 23-May-2005
-- Autor            : NPC
-- Formato Ejecucion: fglrun ctbp310 base módulo compañía 
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_nivel_max	SMALLINT
DEFINE vm_mes_ant	SMALLINT
DEFINE vm_ano_ant	SMALLINT
DEFINE rm_par 		RECORD 
				moneda		LIKE gent013.g13_moneda,
				n_moneda	LIKE gent013.g13_nombre,
				cuenta_ini	LIKE ctbt010.b10_cuenta,
				n_cuenta_ini	LIKE ctbt010.b10_descripcion,
				cuenta_fin	LIKE ctbt010.b10_cuenta,
				n_cuenta_fin	LIKE ctbt010.b10_descripcion,
				nivel_ini	LIKE ctbt010.b10_nivel,
				n_nivel_ini	LIKE ctbt001.b01_nombre,
				nivel_fin 	LIKE ctbt010.b10_nivel,
				n_nivel_fin	LIKE ctbt001.b01_nombre,
				ano		SMALLINT,
				mes_ini		SMALLINT,
				n_mes_ini	VARCHAR(11),
				mes_fin		SMALLINT,
				n_mes_fin	VARCHAR(11),
				diario_cie	CHAR(1),
				ver_tot_dc	CHAR(1),
				ver_saldos	CHAR(1)
			END RECORD
DEFINE rm_detalle	ARRAY[4000] OF RECORD
				cuenta		LIKE ctbt010.b10_cuenta,
				saldo_ant	DECIMAL(14,2),
				mov_neto_db	DECIMAL(14,2),
				mov_neto_cr	DECIMAL(14,2),
				saldo_fin	DECIMAL(14,2)
			END RECORD
DEFINE vm_num_det	SMALLINT
DEFINE vm_max_det	SMALLINT
DEFINE tot_mov_neto_db	DECIMAL(14,2)
DEFINE tot_mov_neto_cr	DECIMAL(14,2)
DEFINE vm_page		SMALLINT	-- PAGE   LENGTH
DEFINE vm_top		SMALLINT	-- TOP    MARGIN
DEFINE vm_left		SMALLINT	-- LEFT   MARGIN
DEFINE vm_right		SMALLINT	-- RIGHT  MARGIN
DEFINE vm_bottom	SMALLINT	-- BOTTOM MARGIN



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/ctbp310.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 
		'Número de parámetros incorrecto', 
		'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'ctbp310'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE r_b01		RECORD LIKE ctbt001.*
DEFINE r_g13		RECORD LIKE gent013.*

CALL fl_nivel_isolation()
LET vm_top     = 1
LET vm_left    = 0
LET vm_right   = 132
LET vm_bottom  = 4
LET vm_page    = 66
LET vm_max_det = 4000
OPEN WINDOW w_mas AT 3, 2 WITH 20 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, 
		BORDER, MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_ctb FROM "../forms/ctbf401_1"
DISPLAY FORM f_ctb
INITIALIZE rm_par.* TO NULL
SELECT * INTO r_b01.* FROM ctbt001
	WHERE b01_nivel = (SELECT MAX(b01_nivel) FROM ctbt001)
LET vm_nivel_max = r_b01.b01_nivel
IF vm_nivel_max IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No se ha configurado la estructura de niveles del plan de cuentas.', 'stop')
	EXIT PROGRAM
END IF
LET rm_par.moneda      = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_par.moneda) RETURNING r_g13.*
LET rm_par.n_moneda    = r_g13.g13_nombre
LET rm_par.nivel_ini   = r_b01.b01_nivel
LET rm_par.n_nivel_ini = r_b01.b01_nombre
LET rm_par.nivel_fin   = r_b01.b01_nivel
LET rm_par.n_nivel_fin = r_b01.b01_nombre
LET rm_par.diario_cie  = 'N'
LET rm_par.ver_tot_dc  = 'S'
LET rm_par.ver_saldos  = 'S'
WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	IF rm_par.ver_tot_dc = 'N' THEN
		CALL control_consulta_saldo()
	ELSE
		CALL control_consulta_totales()
	END IF
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_b01		RECORD LIKE ctbt001.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE r_b12		RECORD LIKE ctbt012.*

LET INT_FLAG = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET INT_FLAG = 1 
		RETURN
	ON KEY(F2)
		IF INFIELD(moneda) THEN
			CALL fl_ayuda_monedas() RETURNING r_g13.g13_moneda, 
					  		  r_g13.g13_nombre,
					  		  r_g13.g13_decimales
			IF r_g13.g13_moneda IS NOT NULL THEN
				LET rm_par.moneda   = r_g13.g13_moneda
				LET rm_par.n_moneda = r_g13.g13_nombre
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		IF INFIELD(cuenta_ini) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, 0) 
				RETURNING r_b10.b10_cuenta, 
					  r_b10.b10_descripcion 
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_par.cuenta_ini   = r_b10.b10_cuenta
				LET rm_par.n_cuenta_ini = r_b10.b10_descripcion
				DISPLAY BY NAME rm_par.*
			END IF	
		END IF
		IF INFIELD(cuenta_fin) THEN
			CALL fl_ayuda_cuenta_contable(vg_codcia, 0) 
				RETURNING r_b10.b10_cuenta, 
					  r_b10.b10_descripcion 
			IF r_b10.b10_cuenta IS NOT NULL THEN
				LET rm_par.cuenta_fin   = r_b10.b10_cuenta
				LET rm_par.n_cuenta_fin = r_b10.b10_descripcion
				DISPLAY BY NAME rm_par.*
			END IF	
		END IF
		IF INFIELD(nivel_ini) THEN
			CALL fl_ayuda_nivel_cuentas() 
				RETURNING r_b01.b01_nivel,
					  r_b01.b01_nombre,
					  r_b01.b01_posicion_i,
					  r_b01.b01_posicion_f
			IF r_b01.b01_nivel IS NOT NULL THEN
				LET rm_par.nivel_ini   = r_b01.b01_nivel
				LET rm_par.n_nivel_ini = r_b01.b01_nombre
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		IF INFIELD(nivel_fin) THEN
			CALL fl_ayuda_nivel_cuentas() 
				RETURNING r_b01.b01_nivel,
					  r_b01.b01_nombre,
					  r_b01.b01_posicion_i,
					  r_b01.b01_posicion_f
			IF r_b01.b01_nivel IS NOT NULL THEN
				LET rm_par.nivel_fin   = r_b01.b01_nivel
				LET rm_par.n_nivel_fin = r_b01.b01_nombre
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		LET INT_FLAG = 0
	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda) RETURNING r_g13.*
			IF r_g13.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
					'Moneda no existe.', 
					'exclamation')
				NEXT FIELD moneda
			END IF
			LET rm_par.n_moneda = r_g13.g13_nombre
			DISPLAY BY NAME rm_par.n_moneda
		ELSE
			LET rm_par.n_moneda = NULL
			CLEAR n_moneda
		END IF
	AFTER FIELD cuenta_ini  
		IF rm_par.cuenta_ini IS NOT NULL THEN
			CALL fl_lee_cuenta(vg_codcia, rm_par.cuenta_ini)
				RETURNING r_b10.*
			IF r_b10.b10_cuenta IS NULL THEN
				CALL FGL_WINMESSAGE(vg_producto, 
                            	 	            'Cuenta no ' ||
                                                    'existe',        
                                                    'exclamation')
				NEXT FIELD cuenta_ini  
			END IF
			LET rm_par.n_cuenta_ini = r_b10.b10_descripcion
			DISPLAY BY NAME rm_par.*
		ELSE
			LET rm_par.n_cuenta_ini = NULL
			DISPLAY BY NAME rm_par.*
		END IF
	AFTER FIELD cuenta_fin  
		IF rm_par.cuenta_fin IS NOT NULL THEN
			CALL fl_lee_cuenta(vg_codcia, rm_par.cuenta_fin)
				RETURNING r_b10.*
			IF r_b10.b10_cuenta IS NULL THEN
				CALL FGL_WINMESSAGE(vg_producto, 
                       		 	            'Cuenta no ' ||
                       	                            'existe',        
                               	                    'exclamation')
				NEXT FIELD cuenta_fin  
			END IF
			LET rm_par.n_cuenta_fin = r_b10.b10_descripcion
			DISPLAY BY NAME rm_par.*
		ELSE
			LET rm_par.n_cuenta_fin = NULL
			DISPLAY BY NAME rm_par.*
		END IF
	AFTER FIELD nivel_ini
		IF rm_par.nivel_ini IS NOT NULL THEN
			CALL fl_lee_nivel_cuenta(rm_par.nivel_ini)
				RETURNING r_b01.*
			IF r_b01.b01_nivel IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					'Nivel no existe.',
					'exclamation')
				NEXT FIELD nivel_ini
			END IF
			LET rm_par.n_nivel_ini = r_b01.b01_nombre
			DISPLAY BY NAME rm_par.*
		ELSE
			LET rm_par.nivel_ini = vm_nivel_max
			CALL fl_lee_nivel_cuenta(rm_par.nivel_ini)
				RETURNING r_b01.*
			LET rm_par.n_nivel_ini = r_b01.b01_nombre
			DISPLAY BY NAME rm_par.*
		END IF
	AFTER FIELD nivel_fin
		IF rm_par.nivel_fin IS NOT NULL THEN
			CALL fl_lee_nivel_cuenta(rm_par.nivel_fin)
				RETURNING r_b01.*
			IF r_b01.b01_nivel IS NULL THEN
				CALL fgl_winmessage(vg_producto,
					'Nivel no existe.',
					'exclamation')
				NEXT FIELD nivel_fin
			END IF
			LET rm_par.n_nivel_fin = r_b01.b01_nombre
			DISPLAY BY NAME rm_par.*
		ELSE
			LET rm_par.nivel_fin = vm_nivel_max
			CALL fl_lee_nivel_cuenta(rm_par.nivel_fin)
				RETURNING r_b01.*
			LET rm_par.n_nivel_fin = r_b01.b01_nombre
			DISPLAY BY NAME rm_par.*
		END IF
	AFTER FIELD mes_ini
		IF rm_par.mes_ini IS NOT NULL THEN
			CALL fl_retorna_nombre_mes(rm_par.mes_ini)
				RETURNING rm_par.n_mes_ini
			LET rm_par.n_mes_ini = fl_justifica_titulo('I', 
					       rm_par.n_mes_ini, 10)
			DISPLAY BY NAME rm_par.*
		ELSE
			LET rm_par.n_mes_ini = NULL
			DISPLAY BY NAME rm_par.*
		END IF
	AFTER FIELD mes_fin
		IF rm_par.mes_fin IS NOT NULL THEN
			CALL fl_retorna_nombre_mes(rm_par.mes_fin)
				RETURNING rm_par.n_mes_fin
			LET rm_par.n_mes_fin = fl_justifica_titulo('I', 
					       rm_par.n_mes_fin, 10)
			DISPLAY BY NAME rm_par.*
		ELSE
			LET rm_par.n_mes_fin = NULL
			DISPLAY BY NAME rm_par.*
		END IF
	AFTER INPUT		 
		IF rm_par.nivel_ini > rm_par.nivel_fin THEN
			CALL fgl_winmessage(vg_producto,
				'Nivel inicial debe ser ' ||
 				'menor o igual al final.',
				'exclamation')
			NEXT FIELD nivel_ini
		END IF
		IF rm_par.mes_ini > rm_par.mes_fin THEN
			CALL fgl_winmessage(vg_producto,
				'Mes inicial debe ser ' ||
 				'menor o igual al final.',
				'exclamation')
			NEXT FIELD mes_ini
		END IF
		IF rm_par.cuenta_fin < rm_par.cuenta_ini THEN
			CALL fgl_winmessage(vg_producto,
				'La cuenta inicial debe ser menor ' ||
 				'o igual a la cuenta final.',
				'exclamation')
			NEXT FIELD cuenta_ini
		END IF	
		CALL valida_diario_cierre_anio(rm_par.ano) RETURNING r_b12.*
		IF r_b12.b12_compania IS NULL THEN
			LET rm_par.ver_saldos = 'N'
			DISPLAY BY NAME rm_par.ver_saldos
		END IF
END INPUT

END FUNCTION



FUNCTION control_consulta_saldo()
DEFINE expr_cta		VARCHAR(100)
DEFINE query		VARCHAR(400)
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE descripcion	LIKE ctbt010.b10_descripcion
DEFINE estado		LIKE ctbt010.b10_estado
DEFINE fecha		DATE
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE cuantos, i	INTEGER
DEFINE valor		DECIMAL(16,2)
DEFINE val1, val2	DECIMAL(16,2)
DEFINE saldo_ant	DECIMAL(16,2)
DEFINE saldo_fin	DECIMAL(16,2)
DEFINE mov_neto		DECIMAL(16,2)
DEFINE mov_neto_db	DECIMAL(16,2)
DEFINE mov_neto_cr	DECIMAL(16,2)

LET expr_cta = ' 1 = 1 '
IF rm_par.cuenta_ini IS NOT NULL THEN
	LET expr_cta = 'b10_cuenta   >= "', rm_par.cuenta_ini CLIPPED, '"'
END IF
IF rm_par.cuenta_fin IS NOT NULL THEN
	LET expr_cta = expr_cta CLIPPED, ' AND ',
	               'b10_cuenta   <= "', rm_par.cuenta_fin CLIPPED, '"'
END IF
IF rm_par.cuenta_ini = rm_par.cuenta_fin THEN
	LET expr_cta = 'b10_cuenta    = "', rm_par.cuenta_ini CLIPPED, '"'
END IF
LET query = 'SELECT b10_cuenta, b10_descripcion, b10_estado ',
		' FROM ctbt010 ',
		' WHERE b10_compania  = ', vg_codcia, 
		'   AND ', expr_cta CLIPPED,
		'   AND b10_nivel     BETWEEN ', rm_par.nivel_ini,
					' AND ', rm_par.nivel_fin,
		' ORDER BY 1'
PREPARE magu FROM query
DECLARE q_magu CURSOR FOR magu
OPEN q_magu
FETCH q_magu
IF STATUS = NOTFOUND THEN
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE q_magu
	FREE q_magu
	RETURN
END IF
LET vm_mes_ant = rm_par.mes_ini - 1
LET vm_ano_ant = rm_par.ano
IF rm_par.mes_ini = 1 THEN
	LET vm_mes_ant = 12
	LET vm_ano_ant = rm_par.ano - 1
END IF
IF rm_par.diario_cie = 'N' THEN
	CALL quitar_diario_cierre_anio(rm_par.ano, 'D')
	IF vm_ano_ant <> rm_par.ano THEN
		--CALL quitar_diario_cierre_anio(vm_ano_ant, 'D')
	END IF
END IF
LET vm_num_det = 1
FOREACH q_magu INTO cuenta, descripcion, estado
	IF estado = 'B' THEN
		SELECT COUNT(*) INTO cuantos
			FROM ctbt013
			WHERE b13_compania = vg_codcia
			  AND b13_cuenta   = cuenta
		IF cuantos = 0 THEN
			CONTINUE FOREACH
		END IF
	END IF
	LET fecha = MDY(vm_mes_ant, 1, vm_ano_ant) + 1 UNITS MONTH - 1 UNITS DAY
	IF cuenta[1, 1] <> '3' THEN
		CALL fl_obtiene_saldo_contable(vg_codcia, cuenta, rm_par.moneda,
						fecha, 'S')
			RETURNING saldo_ant
	ELSE
		CALL fl_obtener_saldo_cuentas_patrimonio(vg_codcia, cuenta,
				rm_par.moneda, fecha, vg_fecha, 'A')
			RETURNING saldo_ant, val1
	END IF
	LET mov_neto = 0
	IF cuenta[1, 1] <> '3' THEN
		FOR i = rm_par.mes_ini TO rm_par.mes_fin
			LET fecha = MDY(i, 1, rm_par.ano) + 1 UNITS MONTH 
				    - 1 UNITS DAY
			CALL fl_obtiene_saldo_contable(vg_codcia, cuenta,
						rm_par.moneda, fecha, 'M')
				RETURNING valor
			LET mov_neto = mov_neto + valor
		END FOR
	ELSE
		LET fecha_ini = MDY(rm_par.mes_ini, 1, rm_par.ano)
		LET fecha_fin = MDY(rm_par.mes_fin, 1, rm_par.ano) +
				1 UNITS MONTH - 1 UNITS DAY
		CALL fl_obtener_saldo_cuentas_patrimonio(vg_codcia, cuenta,
				rm_par.moneda, fecha_ini, fecha_fin, 'S')
			RETURNING val1, val2
		LET mov_neto = mov_neto + val1 + val2
	END IF
	LET mov_neto_db = mov_neto
	LET mov_neto_cr = 0
	IF mov_neto < 0 THEN
		LET mov_neto_db = 0
		LET mov_neto_cr = mov_neto
	END IF
	LET saldo_fin                          = saldo_ant + mov_neto
	LET rm_detalle[vm_num_det].cuenta      = cuenta
	LET rm_detalle[vm_num_det].saldo_ant   = saldo_ant
	LET rm_detalle[vm_num_det].mov_neto_db = mov_neto_db
	LET rm_detalle[vm_num_det].mov_neto_cr = mov_neto_cr
	LET rm_detalle[vm_num_det].saldo_fin   = saldo_fin
	LET vm_num_det = vm_num_det + 1
	IF vm_num_det > vm_max_det THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_det = vm_num_det - 1
IF vm_num_det = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	IF rm_par.diario_cie = 'N' THEN
		CALL quitar_diario_cierre_anio(rm_par.ano, 'M')
		IF vm_ano_ant <> rm_par.ano THEN
			--CALL quitar_diario_cierre_anio(vm_ano_ant, 'M')
		END IF
	END IF
	RETURN
END IF
CALL mostrar_detalle()
IF rm_par.diario_cie = 'N' THEN
	CALL quitar_diario_cierre_anio(rm_par.ano, 'M')
	IF vm_ano_ant <> rm_par.ano THEN
		--CALL quitar_diario_cierre_anio(vm_ano_ant, 'M')
	END IF
END IF

END FUNCTION



FUNCTION control_consulta_totales()
DEFINE comando		VARCHAR(100)
DEFINE r_b01		RECORD LIKE ctbt001.*
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE cuenta_ini	LIKE ctbt010.b10_cuenta
DEFINE cuenta_fin	LIKE ctbt010.b10_cuenta
DEFINE descripcion	LIKE ctbt010.b10_descripcion
DEFINE estado		LIKE ctbt010.b10_estado
DEFINE nivel		LIKE ctbt010.b10_nivel
DEFINE cuantos		INTEGER
DEFINE expr_cta		VARCHAR(150)
DEFINE query		VARCHAR(1500)
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE
DEFINE fecha		DATE
DEFINE saldo_ant, val1	DECIMAL(16,2)
DEFINE saldo_fin	DECIMAL(16,2)
DEFINE mov_neto_db	DECIMAL(16,2)
DEFINE mov_neto_cr	DECIMAL(16,2)
DEFINE valor_cie	DECIMAL(16,2)
DEFINE j, ini, fin 	SMALLINT
DEFINE ceros, nueves	CHAR(10)

LET vm_mes_ant = rm_par.mes_ini - 1
LET vm_ano_ant = rm_par.ano
IF rm_par.mes_ini = 1 THEN
	LET vm_mes_ant = 12
	LET vm_ano_ant = rm_par.ano - 1
END IF
IF rm_par.diario_cie = 'N' THEN
	CALL quitar_diario_cierre_anio(rm_par.ano, 'D')
	IF vm_ano_ant <> rm_par.ano THEN
		--CALL quitar_diario_cierre_anio(vm_ano_ant, 'D')
	END IF
END IF
LET expr_cta = NULL
IF rm_par.cuenta_ini IS NOT NULL THEN
	LET expr_cta = '   AND b10_cuenta   >= "', rm_par.cuenta_ini CLIPPED,'"'
END IF
IF rm_par.cuenta_fin IS NOT NULL THEN
	LET expr_cta = expr_cta CLIPPED,
			'   AND b10_cuenta   <= "',rm_par.cuenta_fin CLIPPED,'"'
END IF
LET fecha_ini = MDY(rm_par.mes_ini, 1, rm_par.ano)
LET fecha_fin = MDY(rm_par.mes_fin, 1, rm_par.ano) + 1 UNITS MONTH - 1 UNITS DAY
LET query = 'SELECT * FROM ctbt010 ',
		' WHERE b10_compania  = ', vg_codcia, 
		expr_cta CLIPPED,
		'   AND b10_nivel     BETWEEN ', rm_par.nivel_ini,
					' AND ', vm_nivel_max,
		' INTO TEMP tmp_b10 '
PREPARE exec_b10 FROM query
EXECUTE exec_b10
LET query = 'SELECT b10_cuenta, b10_descripcion, b10_estado, b10_nivel, ',
		' (SELECT NVL(SUM(b13_valor_base), 0) ',
			' FROM ctbt013, ctbt012 ',
			' WHERE b13_compania     = b10_compania ',
			'   AND b13_cuenta       = b10_cuenta ',
			'   AND b13_fec_proceso BETWEEN "', fecha_ini,
						 '" AND "', fecha_fin, '"',
			'   AND b13_valor_base  >= 0 ',
			'   AND b12_compania     = b13_compania ',
			'   AND b12_tipo_comp    = b13_tipo_comp ',
			'   AND b12_num_comp     = b13_num_comp ',
			'   AND b12_estado       = "M" ',
			'   AND b12_moneda       = "', rm_par.moneda, '")',
			' movi_neto_db, ',
		' (SELECT NVL(SUM(b13_valor_base), 0) ',
			' FROM ctbt013, ctbt012 ',
			' WHERE b13_compania     = b10_compania ',
			'   AND b13_cuenta       = b10_cuenta ',
			'   AND b13_fec_proceso BETWEEN "', fecha_ini,
						 '" AND "', fecha_fin, '"',
			'   AND b13_valor_base   < 0 ',
			'   AND b12_compania     = b13_compania ',
			'   AND b12_tipo_comp    = b13_tipo_comp ',
			'   AND b12_num_comp     = b13_num_comp ',
			'   AND b12_estado       = "M" ',
			'   AND b12_moneda       = "', rm_par.moneda, '")',
			' movi_neto_cr ',
		' FROM tmp_b10 ',
		' GROUP BY 1, 2, 3, 4, 5, 6 ',
		' INTO TEMP tmp_totcta '
PREPARE cons_sum FROM query
EXECUTE cons_sum
DROP TABLE tmp_b10
DECLARE q_sum CURSOR FOR SELECT * FROM tmp_totcta ORDER BY b10_cuenta
OPEN q_sum
FETCH q_sum
IF STATUS = NOTFOUND THEN
	IF rm_par.diario_cie = 'N' THEN
		CALL quitar_diario_cierre_anio(rm_par.ano, 'M')
		IF vm_ano_ant <> rm_par.ano THEN
			--CALL quitar_diario_cierre_anio(vm_ano_ant, 'M')
		END IF
	END IF
	CALL fl_mensaje_consulta_sin_registros()
	DROP TABLE tmp_totcta
	CLOSE q_sum
	FREE q_sum
	RETURN
END IF
LET vm_num_det = 1
FOREACH q_sum INTO cuenta, descripcion, estado, nivel, mov_neto_db, mov_neto_cr
	IF nivel > rm_par.nivel_fin THEN
		CONTINUE FOREACH
	END IF
	IF estado = 'B' THEN
		SELECT COUNT(*) INTO cuantos
			FROM ctbt013
			WHERE b13_compania = vg_codcia
			  AND b13_cuenta   = cuenta
		IF cuantos = 0 THEN
			CONTINUE FOREACH
		END IF
	END IF
	LET fecha = MDY(vm_mes_ant, 1, vm_ano_ant) + 1 UNITS MONTH - 1 UNITS DAY
	IF cuenta[1, 1] <> '3' THEN
		CALL fl_obtiene_saldo_contable(vg_codcia, cuenta, rm_par.moneda,
						fecha, 'S')
			RETURNING saldo_ant
	ELSE
		CALL fl_obtener_saldo_cuentas_patrimonio(vg_codcia, cuenta,
					rm_par.moneda, fecha, vg_fecha, 'A')
			RETURNING saldo_ant, val1
	END IF
	IF vm_nivel_max <> nivel THEN
		LET cuenta_ini = cuenta
		LET cuenta_fin = cuenta
		SELECT * INTO r_b01.* FROM ctbt001 WHERE b01_nivel = nivel + 1
		LET ceros  = NULL
		LET nueves = NULL
		FOR j = r_b01.b01_posicion_i TO r_b01.b01_posicion_f
			LET ceros  = ceros CLIPPED, '0'
			LET nueves = nueves CLIPPED, '9'
		END FOR
		LET ini                  = r_b01.b01_posicion_i
		LET fin                  = r_b01.b01_posicion_f
		LET cuenta_ini[ini, fin] = ceros CLIPPED
		LET cuenta_fin[ini, fin] = nueves CLIPPED, '999'
		SELECT NVL(SUM(movi_neto_db), 0), NVL(SUM(movi_neto_cr), 0)
			INTO mov_neto_db, mov_neto_cr
			FROM tmp_totcta
			WHERE b10_cuenta BETWEEN cuenta_ini AND cuenta_fin
	
	END IF
	IF cuenta[1, 1] = '3' AND rm_par.ver_saldos = 'S' THEN
		LET valor_cie = 0
		SELECT NVL(b13_valor_base, 0) INTO valor_cie
			FROM ctbt050, ctbt012, ctbt013
			WHERE b50_compania  = vg_codcia
			  AND b50_anio      = rm_par.ano
			  AND b12_compania  = b50_compania
			  AND b12_tipo_comp = b50_tipo_comp
			  AND b12_num_comp  = b50_num_comp
			  AND b12_estado    = 'A'
			  AND b13_compania  = b12_compania
			  AND b13_tipo_comp = b12_tipo_comp
			  AND b13_num_comp  = b12_num_comp
			  AND b13_cuenta    = cuenta
		IF valor_cie >= 0 THEN
			LET mov_neto_db = mov_neto_db + valor_cie
		ELSE
			LET mov_neto_cr = mov_neto_cr + valor_cie
		END IF
	END IF
	LET saldo_fin = saldo_ant + mov_neto_db + mov_neto_cr
	LET rm_detalle[vm_num_det].cuenta      = cuenta
	LET rm_detalle[vm_num_det].saldo_ant   = saldo_ant
	LET rm_detalle[vm_num_det].mov_neto_db = mov_neto_db
	LET rm_detalle[vm_num_det].mov_neto_cr = mov_neto_cr
	LET rm_detalle[vm_num_det].saldo_fin   = saldo_fin
	IF cuenta[1, 1] > '3' AND rm_par.ver_saldos = 'S' THEN
		LET rm_detalle[vm_num_det].saldo_ant   = 0
		LET rm_detalle[vm_num_det].mov_neto_db = saldo_fin
		LET rm_detalle[vm_num_det].mov_neto_cr = saldo_fin
		LET rm_detalle[vm_num_det].saldo_fin   = 0
	END IF
	LET vm_num_det = vm_num_det + 1
	IF vm_num_det > vm_max_det THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_det = vm_num_det - 1
IF vm_num_det = 0 THEN
	IF rm_par.diario_cie = 'N' THEN
		CALL quitar_diario_cierre_anio(rm_par.ano, 'M')
		IF vm_ano_ant <> rm_par.ano THEN
			--CALL quitar_diario_cierre_anio(vm_ano_ant, 'M')
		END IF
	END IF
	CALL fl_mensaje_consulta_sin_registros()
	DROP TABLE tmp_totcta
	RETURN
END IF
CALL mostrar_detalle()
IF rm_par.diario_cie = 'N' THEN
	CALL quitar_diario_cierre_anio(rm_par.ano, 'M')
	IF vm_ano_ant <> rm_par.ano THEN
		--CALL quitar_diario_cierre_anio(vm_ano_ant, 'M')
	END IF
END IF
DROP TABLE tmp_totcta

END FUNCTION



FUNCTION valida_diario_cierre_anio(anio)
DEFINE anio		SMALLINT
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_b50		RECORD LIKE ctbt050.*

INITIALIZE r_b50.*, r_b12.* TO NULL
DECLARE q_b50 CURSOR FOR
	SELECT * FROM ctbt050
		WHERE b50_compania = vg_codcia
		  AND b50_anio     = anio
OPEN q_b50
FETCH q_b50 INTO r_b50.*
IF r_b50.b50_compania IS NULL THEN
	CLOSE q_b50
	FREE q_b50
	RETURN r_b12.*
END IF
CLOSE q_b50
FREE q_b50
CALL fl_lee_comprobante_contable(r_b50.b50_compania, r_b50.b50_tipo_comp,
				 r_b50.b50_num_comp)
	RETURNING r_b12.*
RETURN r_b12.*

END FUNCTION



FUNCTION quitar_diario_cierre_anio(anio, flag_m)
DEFINE anio		SMALLINT
DEFINE flag_m		CHAR(1)
DEFINE r_b12		RECORD LIKE ctbt012.*
DEFINE r_b50		RECORD LIKE ctbt050.*

CALL valida_diario_cierre_anio(anio) RETURNING r_b12.*
IF r_b12.b12_estado = 'E' THEN
	CALL fl_mostrar_mensaje('El Diario de cierre de año ha sido Eliminado.', 'stop')
	EXIT PROGRAM
END IF
IF r_b12.b12_estado = 'M' AND flag_m = 'M' THEN
	RETURN
END IF
IF r_b12.b12_estado = 'A' AND flag_m = 'D' THEN
	RETURN
END IF
CALL fl_mayoriza_comprobante_ult(vg_codcia, r_b50.b50_tipo_comp,
					r_b50.b50_num_comp, flag_m)

END FUNCTION



FUNCTION mostrar_detalle()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE i, j	 	SMALLINT
DEFINE r_b10		RECORD LIKE ctbt010.*

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
OPEN WINDOW w_ctb2 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_ctbf310_1 FROM '../forms/ctbf310_1'
ELSE
	OPEN FORM f_ctbf310_1 FROM '../forms/ctbf310_1c'
END IF
DISPLAY FORM f_ctbf310_1
--#DISPLAY "Cuenta"		TO tit_col1
--#DISPLAY "Saldo Anterior"	TO tit_col2
--#DISPLAY "Debito"		TO tit_col3
--#DISPLAY "Credito"		TO tit_col4
--#DISPLAY "Saldo Final"	TO tit_col5
DISPLAY BY NAME rm_par.cuenta_ini, rm_par.cuenta_fin,
		rm_par.ano, rm_par.mes_ini, rm_par.n_mes_ini,
		rm_par.mes_fin, rm_par.n_mes_fin, rm_par.diario_cie,
		rm_par.ver_tot_dc, rm_par.ver_saldos
CALL mostrar_totales_gen()
LET int_flag = 0
CALL set_count(vm_num_det)
DISPLAY ARRAY rm_detalle TO rm_detalle.*
       	ON KEY(INTERRUPT)   
		LET int_flag = 1
       	        EXIT DISPLAY  
	ON KEY(F5)
		LET i = arr_curr()
		CALL control_movimientos(i)
		LET int_flag = 0
	ON KEY(F6)
		CALL control_imprimir()
		LET int_flag = 0
	BEFORE DISPLAY 
		CALL dialog.keysetlabel('ACCEPT', '')
	BEFORE ROW 
		LET i = arr_curr()
		LET j = scr_line()
		DISPLAY i          TO num_row
		DISPLAY vm_num_det TO max_row
		CALL fl_lee_cuenta(vg_codcia, rm_detalle[i].cuenta)
			RETURNING r_b10.*
		DISPLAY BY NAME r_b10.b10_descripcion
        AFTER DISPLAY  
                CONTINUE DISPLAY  
END DISPLAY
CLOSE WINDOW w_ctb2
RETURN

END FUNCTION



FUNCTION mostrar_totales_gen()
DEFINE i		SMALLINT

LET tot_mov_neto_db = 0
LET tot_mov_neto_cr = 0
FOR i = 1 TO vm_num_det
	LET tot_mov_neto_db = tot_mov_neto_db + rm_detalle[i].mov_neto_db
	LET tot_mov_neto_cr = tot_mov_neto_cr + rm_detalle[i].mov_neto_cr
END FOR
DISPLAY BY NAME tot_mov_neto_db, tot_mov_neto_cr

END FUNCTION


 
FUNCTION control_movimientos(i)
DEFINE i		SMALLINT
DEFINE comando		CHAR(400)
DEFINE run_prog		CHAR(10)
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE

LET run_prog = '; fglrun '
IF vg_gui = 0 THEN
	LET run_prog = '; fglgo '
END IF
LET fecha_ini = MDY(rm_par.mes_ini, 1, rm_par.ano)
LET fecha_fin = MDY(rm_par.mes_fin, 1, rm_par.ano) + 1 UNITS MONTH - 1 UNITS DAY
LET comando = 'cd ..', vg_separador, '..', vg_separador, 'CONTABILIDAD',
	vg_separador, 'fuentes', vg_separador, run_prog, 'ctbp302 ', vg_base,
	' ', vg_modulo, ' ', vg_codcia, ' "', rm_detalle[i].cuenta, '" "',
	fecha_ini, '" "', fecha_fin, '" "', rm_par.moneda, '"'
RUN comando

END FUNCTION



FUNCTION control_imprimir()
DEFINE comando		VARCHAR(100)
DEFINE i		SMALLINT

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT rep_bal_comprobacion TO PIPE comando
FOR i = 1 TO vm_num_det
	OUTPUT TO REPORT rep_bal_comprobacion(rm_detalle[i].*, i)
END FOR
FINISH REPORT rep_bal_comprobacion

END FUNCTION



REPORT rep_bal_comprobacion(cuenta, saldo_ant, mov_neto_db, mov_neto_cr,
				saldo_fin, i)
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE saldo_ant	DECIMAL(16,2)
DEFINE saldo_fin	DECIMAL(16,2)
DEFINE mov_neto_db	DECIMAL(16,2)
DEFINE mov_neto_cr	DECIMAL(16,2)
DEFINE i		SMALLINT
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_b10		RECORD LIKE ctbt010.*
DEFINE tit_sdo_ant	CHAR(20)
DEFINE tit_sdo_act	CHAR(20)
DEFINE usuario		VARCHAR(20)
DEFINE modulo		VARCHAR(20)
DEFINE titulo		VARCHAR(30)
DEFINE fecha		DATE
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT

OUTPUT
	TOP    MARGIN	vm_top
	LEFT   MARGIN	vm_left
	RIGHT  MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE   LENGTH	vm_page

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET modulo      = "Módulo: Contabilidad"
	LET usuario     = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 20) RETURNING usuario
	CALL fl_justifica_titulo('C', 'BALANCE DE COMPROBACION', 30)
		RETURNING titulo
	CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING r_g02.*
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 001, rg_cia.g01_razonsocial CLIPPED,
	      COLUMN 055, r_g02.g02_nombre CLIPPED, " - ",
			r_g02.g02_abreviacion CLIPPED,
	      COLUMN 122, "Pagina: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 051, titulo CLIPPED,
	      COLUMN 126, UPSHIFT(vg_proceso)
	SKIP 1 LINES
	IF rm_par.cuenta_ini IS NULL AND rm_par.cuenta_fin IS NULL THEN
		PRINT COLUMN 040, "** Rango Cuentas  : Todas " 
	ELSE
		PRINT COLUMN 040, "** Rango Cuentas  : ", 
				 rm_par.cuenta_ini,  ' a ', rm_par.cuenta_fin 
	END IF
	PRINT COLUMN 040, "** Rango Niveles  : ", rm_par.nivel_ini USING '#', 
					      " a ", rm_par.nivel_fin USING '#'
	PRINT COLUMN 040, "** Moneda         : ", rm_par.moneda, ' ',
						 rm_par.n_moneda
	PRINT COLUMN 040, "** Ano            : ", rm_par.ano USING '####'
	PRINT COLUMN 040, "** Meses          : ", rm_par.n_mes_ini, " a ", 
					         rm_par.n_mes_fin
	IF rm_par.ver_saldos = 'S' THEN
		PRINT COLUMN 001, "  Ver Saldos en Débito y Crédito.";
	ELSE
		PRINT COLUMN 001, "  ";
	END IF
	IF rm_par.diario_cie = 'N' THEN
		PRINT COLUMN 099, "  No incluido Diario Cierre anual."
	ELSE
		PRINT COLUMN 102, "  Incluido Diario Cierre anual."
	END IF
	SKIP 1 LINES
	PRINT COLUMN 01, "Fecha de Impresión: ", vg_fecha USING "dd-mm-yyyy", 
	                 1 SPACES, TIME,
	      COLUMN 113, usuario
	LET fecha = MDY(vm_mes_ant, 1, vm_ano_ant) + 1 UNITS MONTH 
		    - 1 UNITS DAY
	LET tit_sdo_ant = fecha USING 'dd-mm-yyyy'
	LET tit_sdo_ant = fl_justifica_titulo('D', tit_sdo_ant, 20)
	LET fecha = MDY(rm_par.mes_fin, 1, rm_par.ano) + 1 UNITS MONTH 
		    - 1 UNITS DAY
	LET tit_sdo_act = fecha USING 'dd-mm-yyyy'
	LET tit_sdo_act = fl_justifica_titulo('D', tit_sdo_act, 20)
	PRINT COLUMN 001, '------------------------------------------------------------------------------------------------------------------------------------'
	PRINT COLUMN 050, '            SALDO AL',
	      COLUMN 071, '         DEBITO NETO',
	      COLUMN 092, '        CREDITO NETO',
	      COLUMN 113, '            SALDO AL'
	PRINT COLUMN 001, 'CUENTA',
	      COLUMN 014, 'DESCRIPCION',
	      COLUMN 050, tit_sdo_ant,
	      COLUMN 071, '             PERIODO',
	      COLUMN 092, '             PERIODO',
	      COLUMN 113, tit_sdo_act
	PRINT COLUMN 001, '------------------------------------------------------------------------------------------------------------------------------------'
ON EVERY ROW
	CALL fl_lee_cuenta(vg_codcia, rm_detalle[i].cuenta) RETURNING r_b10.*
	NEED 3 LINES
	PRINT COLUMN 001, cuenta,
	      COLUMN 014, r_b10.b10_descripcion[1, 34] CLIPPED,
	      COLUMN 050, saldo_ant USING '((((,(((,(((,((&.##)',
	      COLUMN 071, mov_neto_db USING '((((,(((,(((,((&.##)',
	      COLUMN 092, mov_neto_cr USING '((((,(((,(((,((&.##)',
	      COLUMN 113, saldo_fin USING '((((,(((,(((,((&.##)'

ON LAST ROW
	PRINT COLUMN 071, '--------------------',
	      COLUMN 092, '--------------------'
	PRINT COLUMN 071, tot_mov_neto_db USING '((((,(((,(((,((&.##)',
	      COLUMN 092, tot_mov_neto_cr USING '((((,(((,(((,((&.##)';
	print ASCII escape;
	print ASCII desact_comp 

END REPORT
