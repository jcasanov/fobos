------------------------------------------------------------------------------
-- Titulo           : rolp416.4gl - Listado de Ing/Dscto de roles
-- Elaboracion      : 18-Ago-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp416 base modulo compañía
--			[cod_liqrol] [fecha_ini] [fecha_fin]
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_n00		RECORD LIKE rolt000.*
DEFINE rm_n32		RECORD LIKE rolt032.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_loc		RECORD LIKE gent002.*
DEFINE tit_mes		VARCHAR(10)
DEFINE vm_reporte	CHAR(1)
DEFINE vm_det_ing	CHAR(2)
DEFINE vm_det_egr	CHAR(2)
DEFINE vm_cont		INTEGER
DEFINE liq, liq_sub	INTEGER
DEFINE vm_agrupado	CHAR(1)
DEFINE vm_cabecera	SMALLINT
DEFINE sub_sueldo	DECIMAL(14,2)
DEFINE vm_max_col_imp	SMALLINT
DEFINE vm_archivo	CHAR(6)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp416.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 6 AND num_args() <> 7 THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp416'
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
DEFINE resul	 	SMALLINT

CALL fl_nivel_isolation()
CREATE TEMP TABLE tmp_ing_des(
		n32_cod_trab	INTEGER,
		n30_nombres	VARCHAR(45,25),
		n32_sueldo	DECIMAL(14,2),
		n33_cod_rubro	SMALLINT,
		n33_cant_valor	CHAR(1),
		n33_valor	DECIMAL(14,2),
		n33_det_tot	CHAR(2),
		n33_orden	SMALLINT,
		n32_cod_depto	SMALLINT
	)
CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
IF rm_cia.g01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_loc.*
IF rm_loc.g02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 16
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rol1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf416_1 FROM '../forms/rolf416_1'
ELSE
	OPEN FORM f_rolf416_1 FROM '../forms/rolf416_1c'
END IF
DISPLAY FORM f_rolf416_1
LET vm_max_col_imp = 17
LET vm_det_ing     = 'DI'
LET vm_det_egr     = 'DE'
CALL cargar_datos_liq() RETURNING resul
IF resul THEN
	RETURN
END IF
LET vm_agrupado = 'S'
IF num_args() <> 3 THEN
	CALL llamada_otro_prog()
	RETURN
END IF
WHILE TRUE
	CALL mostrar_datos_liq()
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_reporte()
	DELETE FROM tmp_ing_des
END WHILE
DROP TABLE tmp_ing_des
CLOSE WINDOW w_rol1
EXIT PROGRAM

END FUNCTION



FUNCTION llamada_otro_prog()

INITIALIZE rm_n32.* TO NULL
LET rm_n32.n32_cod_liqrol = arg_val(4)
LET rm_n32.n32_fecha_ini  = arg_val(5)
LET rm_n32.n32_fecha_fin  = arg_val(6)
IF num_args() >= 6 THEN
	LET rm_n32.n32_ano_proceso = YEAR(rm_n32.n32_fecha_ini)
	LET rm_n32.n32_mes_proceso = MONTH(rm_n32.n32_fecha_ini)
	IF num_args() > 6 THEN
		LET vm_reporte = arg_val(7)
	END IF
	CALL mostrar_datos_liq()
	LET int_flag = 0
	INPUT BY NAME vm_reporte, vm_agrupado
		WITHOUT DEFAULTS
		ON KEY(INTERRUPT)
			LET int_flag = 1
			EXIT INPUT
	END INPUT
	IF int_flag THEN
		DROP TABLE tmp_ing_des
		CLOSE WINDOW w_rol1
		EXIT PROGRAM
	END IF
	CALL control_reporte()
END IF
DROP TABLE tmp_ing_des
CLOSE WINDOW w_rol1
EXIT PROGRAM

END FUNCTION



FUNCTION cargar_datos_liq()
DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE r_n05		RECORD LIKE rolt005.*
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE mensaje		VARCHAR(200)

INITIALIZE rm_n32.* TO NULL
CALL fl_lee_parametro_general_roles()  RETURNING rm_n00.*
IF rm_n00.n00_serial IS NULL THEN
        CALL fl_mostrar_mensaje('No existe configuración general para este módulo.', 'stop')
	RETURN 1
END IF
CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*
IF r_n01.n01_compania IS NULL THEN
        CALL fl_mostrar_mensaje('No existe configuración para esta compañía.', 'stop')
	RETURN 1
END IF
IF r_n01.n01_estado <> 'A' THEN
        CALL fl_mostrar_mensaje('Compañía no está activa.', 'stop')
	RETURN 1
END IF
LET rm_n32.n32_ano_proceso = r_n01.n01_ano_proceso
LET rm_n32.n32_mes_proceso = r_n01.n01_mes_proceso
CALL retorna_mes()
INITIALIZE r_n05.* TO NULL
DECLARE q_n05 CURSOR FOR
	SELECT * FROM rolt005
		WHERE n05_compania = vg_codcia
		  AND n05_proceso[1] IN ('M', 'Q', 'S')
		ORDER BY n05_fec_cierre DESC
OPEN q_n05
FETCH q_n05 INTO r_n05.*
INITIALIZE r_n32.* TO NULL
DECLARE q_ultliq CURSOR FOR
	SELECT * FROM rolt032
		WHERE n32_compania   = r_n05.n05_compania
		  --AND n32_cod_liqrol = r_n05.n05_proceso
		  AND n32_estado     <> 'E'
		ORDER BY n32_fecha_fin DESC
OPEN q_ultliq
FETCH q_ultliq INTO r_n32.*
LET rm_n32.n32_cod_liqrol  = r_n32.n32_cod_liqrol
LET rm_n32.n32_fecha_ini   = r_n32.n32_fecha_ini
LET rm_n32.n32_fecha_fin   = r_n32.n32_fecha_fin
LET rm_n32.n32_estado      = r_n32.n32_estado
LET rm_n32.n32_dias_trab   = r_n32.n32_dias_trab
LET rm_n32.n32_dias_falt   = r_n32.n32_dias_falt
LET rm_n32.n32_ano_proceso = r_n32.n32_ano_proceso
LET rm_n32.n32_mes_proceso = r_n32.n32_mes_proceso
CALL retorna_mes()
LET vm_reporte = 'I'
RETURN 0

END FUNCTION



FUNCTION mostrar_datos_liq()
DEFINE r_n03		RECORD LIKE rolt003.*

IF rm_n32.n32_cod_liqrol <> 'XX' THEN
	DISPLAY BY NAME rm_n32.n32_cod_liqrol
ELSE
	CLEAR n32_cod_liqrol
END IF
DISPLAY BY NAME rm_n32.n32_fecha_ini, rm_n32.n32_fecha_fin, vm_reporte
IF rm_n32.n32_cod_liqrol <> 'XX' THEN
	DISPLAY BY NAME rm_n32.n32_ano_proceso, rm_n32.n32_mes_proceso, tit_mes
END IF
CALL fl_lee_proceso_roles(rm_n32.n32_cod_liqrol) RETURNING r_n03.*
IF r_n03.n03_nombre IS NOT NULL THEN
	DISPLAY BY NAME r_n03.n03_nombre
ELSE
	DISPLAY '** TODAS LAS LIQUIDACIONES **' TO n03_nombre
END IF

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE anio		LIKE rolt032.n32_ano_proceso
DEFINE mes		LIKE rolt032.n32_mes_proceso
DEFINE mes_aux		LIKE rolt032.n32_mes_proceso

LET int_flag = 0
INPUT BY NAME rm_n32.n32_cod_liqrol, rm_n32.n32_ano_proceso,
	rm_n32.n32_mes_proceso, vm_reporte, vm_agrupado
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(n32_cod_liqrol) THEN
			CALL fl_ayuda_procesos_roles()
				RETURNING r_n03.n03_proceso,
					  r_n03.n03_nombre
			IF r_n03.n03_proceso IS NOT NULL THEN
				LET rm_n32.n32_cod_liqrol = r_n03.n03_proceso
				DISPLAY BY NAME rm_n32.n32_cod_liqrol,
						r_n03.n03_nombre  
			END IF
		END IF
		IF INFIELD(n32_mes_proceso) THEN
			CALL fl_ayuda_mostrar_meses() RETURNING mes_aux, tit_mes
			IF mes_aux IS NOT NULL THEN
				LET rm_n32.n32_mes_proceso = mes_aux
				DISPLAY BY NAME rm_n32.n32_mes_proceso, tit_mes
			END IF
                END IF
		LET int_flag = 0
	ON KEY(F5)
		CALL generar_archivo()
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F5","Archivo Banco")
	BEFORE FIELD n32_ano_proceso
		LET anio = rm_n32.n32_ano_proceso
	BEFORE FIELD n32_mes_proceso
		LET mes = rm_n32.n32_mes_proceso
	AFTER FIELD n32_cod_liqrol
		IF rm_n32.n32_cod_liqrol IS NOT NULL THEN
   			CALL fl_lee_proceso_roles(rm_n32.n32_cod_liqrol)
                        	RETURNING r_n03.*
			IF r_n03.n03_proceso IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el código de liquidación en la Compañía.','exclamation')
				NEXT FIELD n32_cod_liqrol
			END IF
			DISPLAY BY NAME r_n03.n03_nombre
			CALL mostrar_fechas()
		ELSE
			CLEAR n03_nombre
		END IF
	AFTER FIELD n32_ano_proceso
		IF rm_n32.n32_ano_proceso IS NOT NULL THEN
			IF rm_n32.n32_ano_proceso > YEAR(TODAY) THEN
				CALL fl_mostrar_mensaje('El año no puede ser mayor al año vigente.', 'exclamation')
				NEXT FIELD n32_ano_proceso
			END IF
		ELSE
			LET rm_n32.n32_ano_proceso = anio
			DISPLAY BY NAME rm_n32.n32_ano_proceso
		END IF
		CALL mostrar_fechas()
	AFTER FIELD n32_mes_proceso
		IF rm_n32.n32_mes_proceso IS NULL THEN
			LET rm_n32.n32_mes_proceso = mes
			DISPLAY BY NAME rm_n32.n32_mes_proceso
		END IF
		CALL retorna_mes()
		DISPLAY BY NAME tit_mes
		CALL mostrar_fechas()
END INPUT

END FUNCTION



FUNCTION control_reporte()
DEFINE comando		VARCHAR(100)
DEFINE resul		SMALLINT

LET int_flag = 0
CALL fl_hacer_pregunta('Desea generar también un archivo de texto ?', 'No')
	RETURNING vm_archivo
CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
CALL preparar_query() RETURNING resul
IF resul THEN
	RETURN
END IF
CASE vm_reporte
	WHEN 'I'
		CALL imprimir_listado(vm_det_ing, comando)
	WHEN 'D'
		CALL imprimir_listado(vm_det_egr, comando)
	WHEN 'T'
		CALL imprimir_listado(vm_det_ing, comando)
		CALL imprimir_listado(vm_det_egr, comando)
END CASE

END FUNCTION



FUNCTION preparar_query()
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n32		RECORD
				n32_compania	LIKE rolt032.n32_compania,
				n32_cod_trab	LIKE rolt032.n32_cod_trab,
				n32_cod_depto	LIKE rolt032.n32_cod_depto,
				n32_sueldo	LIKE rolt032.n32_sueldo,
				n32_tot_ing	LIKE rolt032.n32_tot_ing,
				n32_tot_egr	LIKE rolt032.n32_tot_egr,
				n32_tot_neto	LIKE rolt032.n32_tot_neto
			END RECORD
DEFINE r_n33		RECORD
				n33_cod_rubro	LIKE rolt033.n33_cod_rubro,
				n33_orden	LIKE rolt033.n33_orden,
				n33_det_tot	LIKE rolt033.n33_det_tot,
				n33_imprime_0	LIKE rolt033.n33_imprime_0,
				n33_cant_valor	LIKE rolt033.n33_cant_valor,
				n33_valor	LIKE rolt033.n33_valor
			END RECORD
DEFINE query		CHAR(2000)
DEFINE expr_lq		VARCHAR(100)

LET expr_lq = '   AND n33_cod_liqrol  = "', rm_n32.n32_cod_liqrol, '"'
IF rm_n32.n32_cod_liqrol = 'XX' THEN
	LET expr_lq = '   AND n33_cod_liqrol IN ("Q1", "Q2") '
END IF
LET query = 'SELECT * FROM rolt033 ',
		' WHERE n33_compania    = ', vg_codcia,
			expr_lq CLIPPED,
		'   AND n33_fecha_ini  >= "', rm_n32.n32_fecha_ini, '"',
		'   AND n33_fecha_fin  <= "', rm_n32.n32_fecha_fin, '"',
		' INTO TEMP t_rolt033 '
PREPARE tmp_n33 FROM query
EXECUTE tmp_n33
LET expr_lq = '   AND a.n32_cod_liqrol  = "', rm_n32.n32_cod_liqrol, '"'
IF rm_n32.n32_cod_liqrol = 'XX' THEN
	LET expr_lq = '   AND a.n32_cod_liqrol IN ("Q1", "Q2") '
END IF
LET query = 'SELECT a.n32_compania, a.n32_cod_trab, a.n32_cod_depto, ',
		'NVL(SUM(a.n32_sueldo / ',
			' CASE WHEN "', rm_n32.n32_cod_liqrol, '" = "XX" ',
			' THEN ',
			' (SELECT COUNT(*) ',
				'FROM rolt032 b ',
				'WHERE b.n32_compania    = a.n32_compania ',
				'  AND b.n32_ano_proceso = a.n32_ano_proceso ',
				'  AND b.n32_mes_proceso = a.n32_mes_proceso ',
				'  AND b.n32_cod_trab    = a.n32_cod_trab) ',
			' ELSE 1 ',
			' END), 0), ',
		'NVL(SUM(a.n32_tot_ing), 0), NVL(SUM(a.n32_tot_egr), 0), ',
		'NVL(SUM(a.n32_tot_neto), 0) ',
		' FROM rolt032 a ',
		' WHERE a.n32_compania    = ', vg_codcia,
			expr_lq CLIPPED,
		'   AND a.n32_fecha_ini  >= "', rm_n32.n32_fecha_ini, '"',
		'   AND a.n32_fecha_fin  <= "', rm_n32.n32_fecha_fin, '"',
		'   AND a.n32_estado     <> "E" ',
		' GROUP BY 1, 2, 3 '
PREPARE tmp_n32 FROM query
DECLARE q_det CURSOR FOR tmp_n32
LET expr_lq = '   AND n33_cod_liqrol  = "', rm_n32.n32_cod_liqrol, '"'
IF rm_n32.n32_cod_liqrol = 'XX' THEN
	LET expr_lq = '   AND n33_cod_liqrol IN ("Q1", "Q2") '
END IF
FOREACH q_det INTO r_n32.*
	LET query = 'SELECT n33_cod_rubro, n33_orden, n33_det_tot, ',
			'n33_imprime_0, n33_cant_valor, NVL(SUM(n33_valor), 0)',
			' FROM t_rolt033 ',
			' WHERE n33_compania    = ', r_n32.n32_compania,
				expr_lq CLIPPED,
			'   AND n33_fecha_ini  >= "', rm_n32.n32_fecha_ini, '"',
			'   AND n33_fecha_fin  <= "', rm_n32.n32_fecha_fin, '"',
			'   AND n33_cod_trab    = ', r_n32.n32_cod_trab,
			' GROUP BY 1, 2, 3, 4, 5 '
	PREPARE tmp_det_n FROM query
	DECLARE q_n33 CURSOR FOR tmp_det_n
	CALL fl_lee_trabajador_roles(r_n32.n32_compania, r_n32.n32_cod_trab)
		RETURNING r_n30.*
	FOREACH q_n33 INTO r_n33.*
		IF r_n33.n33_valor = 0 AND r_n33.n33_imprime_0 = 'N' THEN
			CONTINUE FOREACH
		END IF
		CALL fl_lee_rubro_roles(r_n33.n33_cod_rubro) RETURNING r_n06.*
		IF r_n06.n06_flag_ident = 'DC' THEN
			CONTINUE FOREACH
		END IF
		INSERT INTO tmp_ing_des
			VALUES(r_n32.n32_cod_trab, r_n30.n30_nombres,
				r_n32.n32_sueldo, r_n33.n33_cod_rubro,
				r_n33.n33_cant_valor, r_n33.n33_valor,
				r_n33.n33_det_tot, r_n33.n33_orden,
				r_n32.n32_cod_depto)
	END FOREACH
	INSERT INTO tmp_ing_des
		VALUES(r_n32.n32_cod_trab, r_n30.n30_nombres,
			r_n32.n32_sueldo, 1000, 'V', r_n32.n32_tot_ing,
			'TI', 1000, r_n32.n32_cod_depto)
	INSERT INTO tmp_ing_des
		VALUES(r_n32.n32_cod_trab, r_n30.n30_nombres,
			r_n32.n32_sueldo, 1001, 'V', r_n32.n32_tot_egr,
			'TE', 1001, r_n32.n32_cod_depto)
	INSERT INTO tmp_ing_des
		VALUES(r_n32.n32_cod_trab, r_n30.n30_nombres,
			r_n32.n32_sueldo, 1002, 'V', r_n32.n32_tot_neto,
			'TN', 1002, r_n32.n32_cod_depto)
END FOREACH
DROP TABLE t_rolt033
SELECT COUNT(*) INTO vm_cont FROM tmp_ing_des
IF vm_cont = 0 THEN
	LET int_flag = 0
	CALL fl_mensaje_consulta_sin_registros()
	RETURN 1
END IF
CALL insertar_rubro_falt()
CASE vm_reporte
	WHEN 'I'
		CALL totalizar_en_una_columna(vm_det_ing)
	WHEN 'D'
		CALL totalizar_en_una_columna(vm_det_egr)
	WHEN 'T'
		CALL totalizar_en_una_columna(vm_det_ing)
		CALL totalizar_en_una_columna(vm_det_egr)
END CASE
RETURN 0

END FUNCTION



FUNCTION insertar_rubro_falt()
DEFINE cod_trab		LIKE rolt032.n32_cod_trab
DEFINE nom		LIKE rolt030.n30_nombres
DEFINE sueldo		LIKE rolt032.n32_sueldo
DEFINE cod_rubro	LIKE rolt033.n33_cod_rubro
DEFINE cant		LIKE rolt033.n33_cant_valor
DEFINE det_tot		LIKE rolt033.n33_det_tot
DEFINE orden		LIKE rolt033.n33_orden
DEFINE dep		LIKE rolt032.n32_cod_depto
DEFINE r_det		RECORD
				n32_cod_trab	INTEGER,
				n30_nombres	VARCHAR(45,25),
				n32_sueldo	DECIMAL(14,2),
				n33_cod_rubro	SMALLINT,
				n33_cant_valor	CHAR(1),
				n33_valor	DECIMAL(14,2),
				n33_det_tot	CHAR(2),
				n33_orden	SMALLINT,
				n32_cod_depto	SMALLINT
			END RECORD

DECLARE q_ins1 CURSOR FOR
	SELECT UNIQUE n33_cod_rubro, n33_cant_valor, n33_det_tot, n33_orden
		FROM tmp_ing_des
FOREACH q_ins1 INTO cod_rubro, cant, det_tot, orden
	DECLARE q_ins2 CURSOR FOR
		SELECT UNIQUE n32_cod_trab, n30_nombres, n32_sueldo,
				n32_cod_depto
			FROM tmp_ing_des
	FOREACH q_ins2 INTO cod_trab, nom, sueldo, dep
		SELECT * FROM tmp_ing_des
			WHERE n32_cod_trab  = cod_trab
			  AND n32_cod_depto = dep
			  AND n33_cod_rubro = cod_rubro
		IF STATUS = NOTFOUND THEN
			LET r_det.n32_cod_trab   = cod_trab
			LET r_det.n30_nombres    = nom
			LET r_det.n32_sueldo     = sueldo
			LET r_det.n33_cod_rubro  = cod_rubro
			LET r_det.n33_cant_valor = cant
			LET r_det.n33_valor      = 0.00
			LET r_det.n33_det_tot    = det_tot
			LET r_det.n33_orden      = orden
			LET r_det.n32_cod_depto  = dep
			INSERT INTO tmp_ing_des VALUES(r_det.*)
		END IF
	END FOREACH
END FOREACH

END FUNCTION



FUNCTION totalizar_en_una_columna(det_t)
DEFINE det_t		CHAR(2)
DEFINE cod_r		LIKE rolt033.n33_cod_rubro
DEFINE num_col		INTEGER
DEFINE val_tope		SMALLINT

SELECT UNIQUE n33_cod_rubro
	FROM tmp_ing_des
	WHERE n33_det_tot = det_t
	INTO TEMP tmp_caca
SELECT COUNT(*) cuantos INTO num_col FROM tmp_caca
DROP TABLE tmp_caca
IF num_col <= vm_max_col_imp THEN
	RETURN
END IF
CASE det_t
	WHEN vm_det_ing
		LET val_tope = vm_max_col_imp
	WHEN vm_det_egr
		LET val_tope = 50 + vm_max_col_imp - 1
		IF vg_codloc = 3 THEN
			LET val_tope = val_tope - 1
		END IF
END CASE
SELECT n32_cod_trab cod_trab, n30_nombres nom, n32_sueldo suel,
		n33_cant_valor cant, n33_valor valor_rub, n33_det_tot det_tot,
		n32_cod_depto cod_dep
	FROM tmp_ing_des
	WHERE n32_cod_trab = 9999
	INTO TEMP t1
INSERT INTO t1
	SELECT n32_cod_trab, n30_nombres, n32_sueldo, n33_cant_valor,
			NVL(SUM(n33_valor), 0) valor_rub, n33_det_tot,
			n32_cod_depto
		FROM tmp_ing_des
		WHERE n33_det_tot = det_t
		  AND n33_orden   > val_tope
		GROUP BY 1, 2, 3, 4, 6, 7
DELETE FROM tmp_ing_des
	WHERE n33_det_tot = det_t
	  AND n33_orden   > val_tope
INSERT INTO tmp_ing_des
	SELECT cod_trab, nom, suel, 9999 cod_rubr, cant, valor_rub, det_tot,
			9999 orde, cod_dep
		FROM t1
DROP TABLE t1

END FUNCTION



FUNCTION imprimir_listado(det_t, comando)
DEFINE det_t		CHAR(2)
DEFINE comando		VARCHAR(100)
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE sueldo		LIKE rolt032.n32_sueldo
DEFINE cod_depto	LIKE rolt032.n32_cod_depto
DEFINE n_dp		LIKE gent034.g34_nombre
DEFINE campo		VARCHAR(30)
DEFINE tabla		VARCHAR(15)
DEFINE expr_where	VARCHAR(100)
DEFINE expr_orden	VARCHAR(50)
DEFINE query		CHAR(500)

LET campo      = ', g34_nombre '
LET tabla      = ', gent034 '
LET expr_where = ' WHERE g34_compania  = ', vg_codcia,
		 '   AND g34_cod_depto = n32_cod_depto '
LET expr_orden = ' ORDER BY 5, 2'
IF vm_agrupado = 'N' THEN
	LET campo      = ', 0 '
	LET tabla      = NULL
	LET expr_where = NULL
	LET expr_orden = ' ORDER BY 2'
END IF
LET query = 'SELECT UNIQUE n32_cod_trab, n30_nombres, n32_sueldo, ',
		'n32_cod_depto ', campo CLIPPED,
		' FROM tmp_ing_des ', tabla CLIPPED,
		expr_where CLIPPED,
		expr_orden CLIPPED
PREPARE tmp_t1 FROM query
DECLARE q_t1 CURSOR FOR tmp_t1
START REPORT reporte_ing_des TO PIPE comando
--START REPORT reporte_ing_des TO FILE "nomina_imp.txt"
LET liq = 0
FOREACH q_t1 INTO r_n30.n30_cod_trab, r_n30.n30_nombres, sueldo, cod_depto, n_dp
	OUTPUT TO REPORT reporte_ing_des(r_n30.n30_cod_trab, r_n30.n30_nombres,
					sueldo, cod_depto, det_t)
	LET liq = liq + 1
END FOREACH
FINISH REPORT reporte_ing_des

END FUNCTION



REPORT reporte_ing_des(cod_trab, nombres, sueldo, cod_depto, det_t)
DEFINE cod_trab		LIKE rolt030.n30_cod_trab
DEFINE nombres		LIKE rolt030.n30_nombres
DEFINE sueldo		LIKE rolt032.n32_sueldo
DEFINE cod_depto	LIKE rolt032.n32_cod_depto
DEFINE det_t		CHAR(2)
DEFINE r_det		RECORD
				n32_cod_trab	INTEGER,
				n30_nombres	VARCHAR(45,25),
				n32_sueldo	DECIMAL(14,2),
				n33_cod_rubro	SMALLINT,
				n33_cant_valor	CHAR(1),
				n33_valor	DECIMAL(14,2),
				n33_det_tot	CHAR(2),
				n33_orden	SMALLINT,
				n32_cod_depto	SMALLINT
			END RECORD
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n06		RECORD LIKE rolt006.*
DEFINE cod_rubro	LIKE rolt033.n33_cod_rubro
DEFINE orden		LIKE rolt033.n33_orden
DEFINE lin_texto	LIKE rolt006.n06_etiq_impr
DEFINE tot_valor	DECIMAL(14,2)
DEFINE valor		VARCHAR(10)
DEFINE nom_depto	VARCHAR(36)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(20)
DEFINE usuario		VARCHAR(19)
DEFINE registro		CHAR(600)
DEFINE enter, num_pipe	SMALLINT
DEFINE cuantos, i	SMALLINT
DEFINE postit, numcol	SMALLINT
DEFINE inicol, col	SMALLINT
DEFINE maxcol, i_col	SMALLINT
DEFINE escape, act_des	SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT
DEFINE act_neg, des_neg	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT

OUTPUT
	TOP MARGIN	3
	LEFT MARGIN	0
	RIGHT MARGIN	267
	BOTTOM MARGIN	3
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresión
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	LET act_des	= 0
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	LET inicol      = 36
	DECLARE q_tit2 CURSOR FOR
		SELECT UNIQUE n33_cod_rubro FROM tmp_ing_des
			WHERE n33_det_tot = det_t
	LET numcol = 0
	FOREACH q_tit2 INTO cod_rubro
		LET numcol = numcol + 1
	END FOREACH
	LET i_col = 11
	IF numcol > 18 THEN
		LET i_col = 10
	END IF
	LET maxcol = inicol
	FOREACH q_tit2 INTO cod_rubro
		LET maxcol = maxcol + i_col
	END FOREACH
	LET maxcol  = maxcol + (i_col * 3)
	LET cuantos = i_col - 1
	IF det_t = vm_det_ing THEN
		LET titulo = "DETALLE DE INGRESOS"
	END IF
	IF det_t = vm_det_egr THEN
		LET titulo = "DETALLE DE EGRESOS"
	END IF
	LET postit  = (maxcol / 2) - LENGTH(titulo) / 2
	LET modulo  = "MODULO: NOMINA"
	LET usuario = 'USUARIO: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	IF numcol > 14 THEN
		print ASCII escape;
		print ASCII act_comp;
		print ASCII escape;
		print ASCII act_12cpi;
	END IF
	IF numcol >= 9 AND numcol <= 14 THEN
		print ASCII escape;
		print ASCII act_comp;
	END IF
	IF numcol >= 7 AND numcol < 9 THEN
		print ASCII escape;
		print ASCII act_12cpi;
	END IF
	print ASCII escape;
	print ASCII act_neg
	PRINT COLUMN 001, rm_cia.g01_razonsocial,
  	      COLUMN maxcol - 12, "PAGINA: ", PAGENO USING "&&&"
	SKIP 1 LINES
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN postit, titulo,
	      COLUMN maxcol - 8, UPSHIFT(vg_proceso)
	IF rm_n32.n32_cod_liqrol <> 'XX' THEN
		CALL fl_lee_proceso_roles(rm_n32.n32_cod_liqrol)
			RETURNING r_n03.*
		LET titulo = "LIQUIDACION: ", rm_n32.n32_cod_liqrol, " ",
			r_n03.n03_nombre_abr CLIPPED
	ELSE
		LET titulo = "LIQUIDACION: ** TODAS LAS LIQUIDACIONES **"
	END IF
	LET titulo = titulo CLIPPED, " del ",
			rm_n32.n32_fecha_ini USING "dd-mm-yyyy",
			' al ', rm_n32.n32_fecha_fin USING "dd-mm-yyyy"
	LET postit = (maxcol / 2) - LENGTH(titulo) / 2
	PRINT COLUMN postit, titulo
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
		1 SPACES, TIME,
	      COLUMN maxcol - 20, usuario
	LET col = inicol
	PRINT COLUMN 001, "----------------------------------";
	WHILE col < maxcol
		IF numcol > 18 THEN
			PRINT COLUMN 001, "----------";
		ELSE
			PRINT COLUMN 001, "-----------";
		END IF
		LET col = col + i_col
	END WHILE
	PRINT 1 SPACES
	PRINT COLUMN 001, "COD",
	      COLUMN 005, "E M P L E A D O",
	      COLUMN 026, "   SUELDO";
	DECLARE q_tit CURSOR FOR
		SELECT UNIQUE n33_cod_rubro, n33_orden FROM tmp_ing_des
			WHERE n33_det_tot = det_t
			ORDER BY n33_orden, n33_cod_rubro
	LET col = inicol
	FOREACH q_tit INTO cod_rubro, orden
		CALL fl_lee_rubro_roles(cod_rubro) RETURNING r_n06.*
		IF r_n06.n06_cod_rubro IS NOT NULL THEN
			LET lin_texto = fl_justifica_titulo('D',
					r_n06.n06_etiq_impr[1,cuantos],cuantos)
		ELSE
			LET lin_texto = 'OTRAS COL.'
		END IF
		PRINT COLUMN col, lin_texto;
{--
		PRINT COLUMN col, fl_justifica_titulo('D',
					r_n06.n06_etiq_impr[1,cuantos],cuantos);
--}
		LET col = col + i_col
	END FOREACH
	PRINT COLUMN col, " TOT. ING.";
	LET col = col + i_col
	PRINT COLUMN col, " TOT. EGR.";
	LET col = col + i_col
	PRINT COLUMN col, " TOT. NETO"
	LET col = inicol
	PRINT COLUMN 001, "----------------------------------";
	WHILE col < maxcol
		IF numcol > 18 THEN
			PRINT COLUMN 001, "----------";
		ELSE
			PRINT COLUMN 001, "-----------";
		END IF
		LET col = col + i_col
	END WHILE
	print ASCII escape;
	print ASCII des_neg
	LET vm_cabecera = 1

BEFORE GROUP OF cod_depto
	IF vm_agrupado = 'S' THEN
		IF NOT vm_cabecera OR PAGENO > 1 THEN
			SKIP 1 LINES
		END IF
		NEED 7 LINES
		CALL fl_lee_departamento(vg_codcia, cod_depto)
			RETURNING r_g34.*
		LET nom_depto  = '** ', r_g34.g34_nombre CLIPPED, ' **'
		print ASCII escape;
		print ASCII act_neg;
		PRINT COLUMN 002, nom_depto;
		print ASCII escape;
		print ASCII des_neg
		IF vm_archivo = 'Yes' THEN
			LET registro = cod_depto USING "<<<&&&", '|',
					r_g34.g34_nombre CLIPPED, '|'
			SELECT COUNT(*) INTO num_pipe
				FROM tmp_ing_des
				WHERE n32_cod_trab  = cod_trab
				  AND n32_cod_depto = cod_depto
				  AND n33_det_tot   = det_t
			FOR i = 1 TO num_pipe + 3
				LET registro = registro CLIPPED, '|'
			END FOR
			LET enter = 13
			DISPLAY registro CLIPPED, ASCII(enter)
		END IF
		LET vm_cabecera = 0
		LET liq_sub     = 0
		LET sub_sueldo  = 0
	END IF

ON EVERY ROW
	IF vm_agrupado = 'S' THEN
		NEED 6 LINES
	ELSE
		NEED 3 LINES
	END IF
	PRINT COLUMN 001, cod_trab		USING "&&&",
	      COLUMN 005, nombres[1,20],
	      COLUMN 026, sueldo		USING "##,##&.##";
	IF vm_archivo = 'Yes' THEN
		LET registro = cod_trab USING "<<<&&&", '|',
				nombres CLIPPED, '|',
				sueldo USING "##,##&.##", '|'
	END IF
	DECLARE q_lin CURSOR FOR
		SELECT * FROM tmp_ing_des
			WHERE n32_cod_trab  = cod_trab
			  AND n32_cod_depto = cod_depto
			  AND n33_det_tot   = det_t
			ORDER BY n33_orden, n33_cod_rubro
	LET col = inicol
	FOREACH q_lin INTO r_det.*
		LET valor = r_det.n33_valor USING "##,##&.##"
		PRINT COLUMN col, fl_justifica_titulo('D', valor, cuantos);
		IF vm_archivo = 'Yes' THEN
			LET registro = registro CLIPPED,
					r_det.n33_valor USING "##,##&.##", '|'
		END IF
		LET col = col + i_col
	END FOREACH
	SELECT * INTO r_det.*
		FROM tmp_ing_des
		WHERE n32_cod_trab  = cod_trab
		  AND n32_cod_depto = cod_depto
		  AND n33_cod_rubro = 1000
		  AND n33_det_tot   = 'TI'
	LET valor = r_det.n33_valor USING "##,##&.##"
	PRINT COLUMN col, fl_justifica_titulo('D', valor, cuantos);
	IF vm_archivo = 'Yes' THEN
		LET registro = registro CLIPPED,
				r_det.n33_valor USING "##,##&.##", '|'
	END IF
	LET col = col + i_col
	SELECT * INTO r_det.*
		FROM tmp_ing_des
		WHERE n32_cod_trab  = cod_trab
		  AND n32_cod_depto = cod_depto
		  AND n33_cod_rubro = 1001
		  AND n33_det_tot   = 'TE'
	LET valor = r_det.n33_valor USING "##,##&.##"
	PRINT COLUMN col, fl_justifica_titulo('D', valor, cuantos);
	IF vm_archivo = 'Yes' THEN
		LET registro = registro CLIPPED,
				r_det.n33_valor USING "##,##&.##", '|'
	END IF
	LET col = col + i_col
	SELECT * INTO r_det.*
		FROM tmp_ing_des
		WHERE n32_cod_trab  = cod_trab
		  AND n32_cod_depto = cod_depto
		  AND n33_cod_rubro = 1002
		  AND n33_det_tot   = 'TN'
	LET valor = r_det.n33_valor USING "##,##&.##"
	PRINT COLUMN col, fl_justifica_titulo('D', valor, cuantos);
	IF vm_archivo = 'Yes' THEN
		LET registro = registro CLIPPED,
				r_det.n33_valor USING "##,##&.##", '|'
		LET r_det.n33_valor = NULL
		SELECT NVL(SUM(n32_tot_gan), 0)
			INTO r_det.n33_valor
			FROM rolt032
			WHERE n32_compania    = vg_codcia
			  AND n32_cod_liqrol IN ("Q1", "Q2")
			  AND n32_fecha_ini  >= rm_n32.n32_fecha_ini
			  AND n32_fecha_fin  <= rm_n32.n32_fecha_fin
			  AND n32_cod_trab    = cod_trab
			  AND n32_estado     <> "E"
		IF r_det.n33_valor IS NULL THEN
			LET r_det.n33_valor = 0
		END IF
		LET registro = registro CLIPPED,
				r_det.n33_valor USING "##,##&.##", '|'
	END IF
	PRINT 1 SPACES
	LET liq_sub     = liq_sub    + 1
	LET sub_sueldo  = sub_sueldo + sueldo
	IF vm_archivo = 'Yes' THEN
		LET enter = 13
		DISPLAY registro CLIPPED, ASCII(enter)
	END IF

AFTER GROUP OF cod_depto
	IF vm_agrupado = 'S' THEN
		NEED 5 LINES
		LET col = inicol + 1
		print ASCII escape;
		print ASCII act_neg;
		PRINT COLUMN 026, 2 SPACES, "---------";
		WHILE col < maxcol
			PRINT COLUMN col, 2 SPACES, "---------";
			LET col = col + i_col
		END WHILE
		PRINT 1 SPACES
		PRINT COLUMN 001, "No. LIQ. ", liq_sub	USING "<<&",
		      COLUMN 014, "SUBTOT. ==>",
		      COLUMN 025, sub_sueldo		USING "###,##&.##";
		DECLARE q_tot_s CURSOR FOR
			SELECT UNIQUE n33_cod_rubro, n33_orden
				FROM tmp_ing_des
				WHERE n32_cod_depto = cod_depto
			  	  AND n33_det_tot   = det_t
				ORDER BY n33_orden, n33_cod_rubro
		--LET col = inicol + 1
		LET col = inicol
		FOREACH q_tot_s INTO cod_rubro, orden
			SELECT SUM(n33_valor) INTO tot_valor
				FROM tmp_ing_des
				WHERE n32_cod_depto = cod_depto
				  AND n33_cod_rubro = cod_rubro
			PRINT COLUMN col, tot_valor	USING "###,##&.##";
			LET col = col + i_col
		END FOREACH
		SELECT SUM(n33_valor) INTO tot_valor
			FROM tmp_ing_des
			WHERE n33_det_tot   = 'TI'
			  AND n32_cod_depto = cod_depto
		PRINT COLUMN col, tot_valor	USING "###,##&.##";
		LET col = col + i_col
		SELECT SUM(n33_valor) INTO tot_valor
			FROM tmp_ing_des
			WHERE n33_det_tot   = 'TE'
			  AND n32_cod_depto = cod_depto
		PRINT COLUMN col, tot_valor	USING "###,##&.##";
		LET col = col + i_col
		SELECT SUM(n33_valor) INTO tot_valor
			FROM tmp_ing_des
			WHERE n33_det_tot   = 'TN'
			  AND n32_cod_depto = cod_depto
		PRINT COLUMN col, tot_valor	USING "###,##&.##";
		print ASCII escape;
		print ASCII des_neg
	END IF

ON LAST ROW
	IF vm_agrupado = 'S' THEN
		NEED 3 LINES
		SKIP 1 LINES
	ELSE
		NEED 2 LINES
	END IF
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 026, 2 SPACES, "---------";
	LET col = inicol + 1
	WHILE col < maxcol
		PRINT COLUMN col, 2 SPACES, "---------";
		LET col = col + i_col
	END WHILE
	PRINT 1 SPACES
	PRINT COLUMN 001, "No. LIQ. ", liq	USING "<<&",
	      COLUMN 014, "TOTALES ==>",
	      COLUMN 025, SUM(sueldo)		USING "###,##&.##";
	DECLARE q_tot CURSOR FOR
		SELECT UNIQUE n33_cod_rubro, n33_orden
			FROM tmp_ing_des
		  	WHERE n33_det_tot = det_t
			ORDER BY n33_orden, n33_cod_rubro
	--LET col = inicol + 1
	LET col = inicol
	FOREACH q_tot INTO cod_rubro, orden
		SELECT SUM(n33_valor) INTO tot_valor
			FROM tmp_ing_des
			WHERE n33_cod_rubro = cod_rubro
		PRINT COLUMN col, tot_valor	USING "###,##&.##";
		LET col = col + i_col
	END FOREACH
	SELECT SUM(n33_valor) INTO tot_valor
		FROM tmp_ing_des
		WHERE n33_det_tot = 'TI'
	PRINT COLUMN col, tot_valor	USING "###,##&.##";
	LET col = col + i_col
	SELECT SUM(n33_valor) INTO tot_valor
		FROM tmp_ing_des
		WHERE n33_det_tot = 'TE'
	PRINT COLUMN col, tot_valor	USING "###,##&.##";
	LET col = col + i_col
	SELECT SUM(n33_valor) INTO tot_valor
		FROM tmp_ing_des
		WHERE n33_det_tot = 'TN'
	PRINT COLUMN col, tot_valor	USING "###,##&.##";
	IF numcol < 7 THEN
		print ASCII escape;
		print ASCII des_neg
	ELSE
		print ASCII escape;
		print ASCII des_neg;
	END IF
	IF numcol > 14 THEN
		print ASCII escape;
		print ASCII desact_comp;
		print ASCII escape;
		print ASCII act_10cpi
	END IF
	IF numcol >= 9 AND numcol <= 14 THEN
		print ASCII escape;
		print ASCII desact_comp
	END IF
	IF numcol >= 7 AND numcol < 9 THEN
		print ASCII escape;
		print ASCII act_10cpi
	END IF

END REPORT



FUNCTION retorna_mes()

CALL fl_justifica_titulo('I', fl_retorna_nombre_mes(rm_n32.n32_mes_proceso), 10)
	RETURNING tit_mes

END FUNCTION 



FUNCTION mostrar_fechas()

IF rm_n32.n32_cod_liqrol <> 'XX' THEN
	CALL fl_retorna_rango_fechas_proceso(vg_codcia, rm_n32.n32_cod_liqrol,
				rm_n32.n32_ano_proceso, rm_n32.n32_mes_proceso)
		RETURNING rm_n32.n32_fecha_ini, rm_n32.n32_fecha_fin
END IF
DISPLAY BY NAME rm_n32.n32_fecha_ini, rm_n32.n32_fecha_fin

END FUNCTION 



FUNCTION generar_archivo()
DEFINE query 		CHAR(6000)
DEFINE archivo		VARCHAR(100)
DEFINE mensaje		VARCHAR(200)
DEFINE nom_mes		VARCHAR(10)
DEFINE r_g31		RECORD LIKE gent031.*

CREATE TEMP TABLE tmp_rol_ban
	(
		tipo_pago		CHAR(2),
		cuenta_empresa		CHAR(10),
		secuencia		SERIAL,
		comp_pago		CHAR(5),
		cod_trab		CHAR(6),
		moneda			CHAR(3),
		valor			VARCHAR(13),
		forma_pago		CHAR(3),
		codi_banco		CHAR(4),
		tipo_cuenta		CHAR(3),
		cuenta_empleado		CHAR(11),
		tipo_doc_id		CHAR(1),
		num_doc_id		VARCHAR(13),
		--num_doc_id		DECIMAL(13,0),
		empleado		VARCHAR(40),
		direccion		VARCHAR(40),
		ciudad			VARCHAR(20),
		telefono		VARCHAR(10),
		local_cobro		VARCHAR(10),
		referencia		VARCHAR(30),
		referencia_adic		VARCHAR(30)
	)

LET query = 'SELECT "PA" AS tip_pag, g09_numero_cta AS cuenta_empr,',
			' 0 AS secu, "" AS comp_p, n32_cod_trab AS cod_emp,',
			' g13_simbolo AS mone, TRUNC(n32_tot_neto * 100, 0) AS',
			' neto_rec, "CTA" AS for_pag, "0040" AS cod_ban,',
			' CASE WHEN n30_tipo_cta_tra = "A"',
				' THEN "AHO"',
				' ELSE "CTE"',
			' END AS tipo_c, n32_cta_trabaj AS cuenta_empl,',
			' n30_tipo_doc_id AS tipo_id,',
			' CASE WHEN n32_cod_trab = 24 AND ', vg_codloc, ' = 1 ',
				' THEN "0920503067"',
				' ELSE n30_num_doc_id',
			' END AS cedula,',
			' CASE WHEN n32_cod_trab = 24 AND ', vg_codloc, ' = 1 ',
				' THEN "CHILA RUA EMILIANO FRANCISCO"',
				' ELSE n30_nombres',
			' END AS empleados, n30_domicilio AS direc,',
			' g31_nombre AS ciudad_emp, n30_telef_domic AS fono,',
			' "" AS loc_cob, n03_nombre AS refer1,',
			' CASE',
				' WHEN n32_mes_proceso = 01 THEN "ENERO"',
				' WHEN n32_mes_proceso = 02 THEN "FEBRERO"',
				' WHEN n32_mes_proceso = 03 THEN "MARZO"',
				' WHEN n32_mes_proceso = 04 THEN "ABRIL"',
				' WHEN n32_mes_proceso = 05 THEN "MAYO"',
				' WHEN n32_mes_proceso = 06 THEN "JUNIO"',
				' WHEN n32_mes_proceso = 07 THEN "JULIO"',
				' WHEN n32_mes_proceso = 08 THEN "AGOSTO"',
				' WHEN n32_mes_proceso = 09 THEN "SEPTIEMBRE"',
				' WHEN n32_mes_proceso = 10 THEN "OCTUBRE"',
				' WHEN n32_mes_proceso = 11 THEN "NOVIEMBRE"',
				' WHEN n32_mes_proceso = 12 THEN "DICIEMBRE"',
			' END || "-" || LPAD(n32_ano_proceso, 4, 0) AS refer2',
		' FROM rolt032, rolt030, gent009, gent013, gent031,',
			' rolt003 ',
		' WHERE n32_compania    = ', vg_codcia,
		'   AND n32_cod_liqrol  = "', rm_n32.n32_cod_liqrol,'"',
		'   AND n32_fecha_ini   = "', rm_n32.n32_fecha_ini, '"',
		'   AND n32_fecha_fin   = "', rm_n32.n32_fecha_fin, '"',
		'   AND n32_estado     <> "E"',
		'   AND n32_tot_neto    > 0 ',
  		'   AND n30_compania    = n32_compania ',
		'   AND n30_cod_trab    = n32_cod_trab ',
		'   AND g09_compania    = n32_compania ',
		'   AND g09_banco       = n32_bco_empresa ',
		'   AND n03_proceso     = n32_cod_liqrol ',
		'   AND g13_moneda      = n32_moneda ',
		'   AND g31_ciudad      = n30_ciudad_nac ',
		' ORDER BY 14 ',
		' INTO TEMP t1 '
PREPARE exec_dat FROM query
EXECUTE exec_dat
LET query = 'INSERT INTO tmp_rol_ban ',
		'(tipo_pago, cuenta_empresa, secuencia, comp_pago, cod_trab,',
		' moneda, valor, forma_pago, codi_banco, tipo_cuenta,',
		' cuenta_empleado, tipo_doc_id, num_doc_id, empleado,',
		' direccion, ciudad, telefono, local_cobro, referencia,',
		' referencia_adic) ',
		' SELECT * FROM t1 '
PREPARE exec_tmp FROM query
EXECUTE exec_tmp
DROP TABLE t1
LET query = 'SELECT tipo_pago, cuenta_empresa, secuencia, comp_pago, cod_trab,',
		' "USD" moneda, LPAD(valor, 13, 0) valor, forma_pago,',
		' codi_banco, tipo_cuenta,',
		' LPAD(cuenta_empleado, 11, 0) cta_emp, tipo_doc_id,',
		' LPAD(num_doc_id, 13, 0) num_doc_id,',
		' REPLACE(empleado, "ñ", "N") empleado,',
		--' REPLACE(direccion, "ñ", "N") direccion,',
		--' ciudad, telefono, local_cobro, referencia, referencia_adic',
		' "" direccion, "" ciudad, "" telefono, "" local_cobro,',
		' "ROL DE PAGO" referencia, referencia_adic',
		' FROM tmp_rol_ban ',
		' INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
DROP TABLE tmp_rol_ban
UNLOAD TO "../../../tmp/rol_pag.txt" DELIMITER "	"
	SELECT * FROM t1
		ORDER BY secuencia
{--
LET archivo = "rol_pag_", rm_n32.n32_fecha_fin USING "mmm", "_",
		rm_n32.n32_fecha_fin USING "yyyy", ".txt"
--}
--LET archivo = "acreditacion_quincena.txt"
LET nom_mes = UPSHIFT(fl_justifica_titulo('I',
			fl_retorna_nombre_mes(MONTH(rm_n32.n32_fecha_fin)), 11))
LET archivo = "ACRE_", rm_loc.g02_nombre[1, 3] CLIPPED, "_",
		rm_n32.n32_cod_liqrol, nom_mes[1, 3] CLIPPED,
		YEAR(rm_n32.n32_fecha_fin) USING "####", "_"
CALL fl_lee_ciudad(rm_loc.g02_ciudad) RETURNING r_g31.*
LET archivo = archivo CLIPPED, r_g31.g31_siglas CLIPPED, ".txt"
LET mensaje = 'Archivo ', archivo CLIPPED, ' Generado ', FGL_GETENV("HOME"),
		'/tmp/  OK'
LET archivo = "mv ../../../tmp/rol_pag.txt $HOME/tmp/", archivo CLIPPED
RUN archivo
DROP TABLE t1
CALL fl_mostrar_mensaje(mensaje, 'info')

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
