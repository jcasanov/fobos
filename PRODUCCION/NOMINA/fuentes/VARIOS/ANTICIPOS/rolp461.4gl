--------------------------------------------------------------------------------
-- Titulo           : rolp461.4gl - Listado de Anticipos
-- Elaboracion      : 07-Abr-2007
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp461 base modulo compa�ia
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_n90		RECORD LIKE rolt090.*
DEFINE rm_par		RECORD
				anio		SMALLINT,
				mes		SMALLINT,
				tit_mes		VARCHAR(11),
				cod_trab	LIKE rolt045.n45_cod_trab,
				nom_trab	LIKE rolt030.n30_nombres,
				listado		CHAR(1),
				list_tot	CHAR(1)
			END RECORD
DEFINE vm_tot_ini	DECIMAL(14,2)
DEFINE vm_tot_fin	DECIMAL(14,2)
DEFINE vm_num_col	INTEGER
DEFINE vm_tot_emp	INTEGER
DEFINE ver_saldos	CHAR(1)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp461.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN		-- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp461'
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
CALL fl_lee_conf_adic_rol(vg_codcia) RETURNING rm_n90.*
IF rm_n90.n90_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configuracion adicional de nomina en la tabla rolt090.', 'stop')
	EXIT PROGRAM
END IF
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 11
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rolf461_1 AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rolf461_1 FROM '../forms/rolf461_1'
ELSE
	OPEN FORM f_rolf461_1 FROM '../forms/rolf461_1c'
END IF
DISPLAY FORM f_rolf461_1
INITIALIZE rm_par.* TO NULL
LET rm_par.anio     = YEAR(TODAY)
LET rm_par.mes      = MONTH(TODAY)
LET rm_par.listado  = 'S'
LET rm_par.list_tot = 'S'
CALL muestra_mes()
WHILE TRUE
	CALL leer_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_listado()
END WHILE

END FUNCTION



FUNCTION leer_parametros()
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE anio_aux		SMALLINT
DEFINE mes_aux		SMALLINT
DEFINE resp		CHAR(6)

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(cod_trab) THEN
			CALL fl_ayuda_codigo_empleado(vg_codcia)
				RETURNING r_n30.n30_cod_trab, r_n30.n30_nombres
			IF r_n30.n30_cod_trab IS NOT NULL THEN
				LET rm_par.cod_trab = r_n30.n30_cod_trab
				LET rm_par.nom_trab = r_n30.n30_nombres
				DISPLAY BY NAME rm_par.cod_trab, rm_par.nom_trab
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	BEFORE FIELD anio
		LET anio_aux = rm_par.anio
	BEFORE FIELD mes
		LET mes_aux = rm_par.mes
	AFTER FIELD anio
		IF rm_par.anio IS NULL THEN
			LET rm_par.anio = anio_aux
			DISPLAY BY NAME rm_par.anio
		END IF
		IF rm_par.anio < rm_n90.n90_anio_ini_ant THEN
			CALL fl_mostrar_mensaje('El a�o no puede ser menor que el a�o de inicio del proceso anticipos.', 'exclamation')
			NEXT FIELD anio
		END IF
	AFTER FIELD mes
		IF rm_par.mes IS NULL THEN
			LET rm_par.mes = mes_aux
			DISPLAY BY NAME rm_par.mes
		END IF
		CALL muestra_mes()
	AFTER FIELD cod_trab
		IF rm_par.cod_trab IS NOT NULL THEN
			CALL fl_lee_trabajador_roles(vg_codcia, rm_par.cod_trab)
                        	RETURNING r_n30.*
			IF r_n30.n30_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe el código de este empleado en la Compañía.','exclamation')
				NEXT FIELD cod_trab
			END IF
			LET rm_par.nom_trab = r_n30.n30_nombres
			DISPLAY BY NAME rm_par.nom_trab
		ELSE
			CLEAR nom_trab
		END IF
END INPUT
IF int_flag THEN
	RETURN
END IF
LET ver_saldos = 'S'
LET int_flag = 0
CALL fl_hacer_pregunta('Desea ver Saldos ?', 'Yes') RETURNING resp
IF resp <> 'Yes' THEN
	LET ver_saldos = 'N'
END IF

END FUNCTION



FUNCTION control_listado()
DEFINE comando		VARCHAR(100)

IF NOT preparar_tabla_temporal() THEN
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	DROP TABLE tmp_ant
	RETURN
END IF
CALL listado_ant_mes(comando)
IF rm_par.listado = 'S' AND ver_saldos = 'N' THEN
	CALL listado_ant_proc(comando)
END IF
IF rm_par.list_tot = 'S' THEN
	CALL listado_ant_tot(comando)
END IF
DROP TABLE tmp_ant

END FUNCTION



FUNCTION listado_ant_mes(comando)
DEFINE comando		VARCHAR(100)
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE sal_ini		DECIMAL(12,2)

DECLARE q_ant CURSOR FOR
	SELECT UNIQUE cod_trab, empleado FROM tmp_ant ORDER BY 2
START REPORT reporte_anticipos_mes TO PIPE comando
SELECT COUNT(UNIQUE cod_trab) INTO vm_tot_emp FROM tmp_ant
LET vm_tot_ini = 0
LET vm_tot_fin = 0
FOREACH q_ant INTO r_n30.n30_cod_trab, r_n30.n30_nombres
	IF rm_par.anio = rm_n90.n90_anio_ini_ant AND rm_par.mes <= 4 THEN
		LET sal_ini = 0
	ELSE
		CALL generar_tabla_temp_t1(rm_par.anio, rm_par.mes, 'S')
		SELECT NVL(SUM(saldo_ini), 0) INTO sal_ini
			FROM t1
			WHERE cod_trab = r_n30.n30_cod_trab
	END IF
	OUTPUT TO REPORT reporte_anticipos_mes(r_n30.n30_cod_trab,
						r_n30.n30_nombres, sal_ini)
	LET vm_tot_ini = vm_tot_ini + sal_ini
	IF NOT (rm_par.anio = rm_n90.n90_anio_ini_ant AND rm_par.mes <= 4) THEN
		DROP TABLE t1
	END IF
END FOREACH
FINISH REPORT reporte_anticipos_mes

END FUNCTION



FUNCTION listado_ant_proc(comando)
DEFINE comando		VARCHAR(100)
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE sal_ini		DECIMAL(12,2)

DECLARE q_proc CURSOR FOR
	SELECT UNIQUE lq, nom_pro FROM tmp_ant ORDER BY 1
FOREACH q_proc INTO r_n03.n03_proceso, r_n03.n03_nombre_abr
	DECLARE q_ant2 CURSOR FOR
		SELECT cod_trab, empleado, saldo
			FROM tmp_ant
			WHERE lq    = r_n03.n03_proceso
			  AND saldo > 0
			ORDER BY 2
	START REPORT reporte_anticipos_proc TO PIPE comando
	SELECT COUNT(UNIQUE cod_trab) INTO vm_tot_emp
		FROM tmp_ant
		WHERE lq    = r_n03.n03_proceso
		  AND saldo > 0
	LET vm_tot_ini = 0
	FOREACH q_ant2 INTO r_n30.n30_cod_trab, r_n30.n30_nombres, sal_ini
		OUTPUT TO REPORT reporte_anticipos_proc(r_n03.n03_nombre_abr,
				r_n30.n30_cod_trab, r_n30.n30_nombres, sal_ini)
		LET vm_tot_ini = vm_tot_ini + sal_ini
	END FOREACH
	FINISH REPORT reporte_anticipos_proc
END FOREACH

END FUNCTION



FUNCTION listado_ant_tot(comando)
DEFINE comando		VARCHAR(100)
DEFINE r_n30		RECORD LIKE rolt030.*

CALL preparar_tabla_temporal_tot()
DECLARE q_ant_tot CURSOR FOR
	SELECT UNIQUE cod_trab, empleado FROM tmp_ant_tot ORDER BY 2
START REPORT reporte_anticipos_tot TO PIPE comando
SELECT COUNT(UNIQUE cod_trab) INTO vm_tot_emp FROM tmp_ant_tot
LET vm_tot_fin = 0
FOREACH q_ant_tot INTO r_n30.n30_cod_trab, r_n30.n30_nombres
	OUTPUT TO REPORT reporte_anticipos_tot(r_n30.n30_cod_trab,
						r_n30.n30_nombres)
END FOREACH
FINISH REPORT reporte_anticipos_tot
DROP TABLE tmp_ant_tot

END FUNCTION



FUNCTION preparar_tabla_temporal()
DEFINE cuantos		INTEGER

CALL generar_tabla_temp_t1(rm_par.anio, rm_par.mes, 'D')
SELECT COUNT(*) INTO cuantos FROM t1
IF cuantos = 0 THEN
	DROP TABLE t1
	RETURN 0
END IF
SELECT UNIQUE lq cod, n03_nombre_abr nom_pro
	FROM rolt003, t1
	WHERE n03_proceso = lq
	INTO TEMP t2
SELECT COUNT(*) INTO vm_num_col FROM t2
SELECT UNIQUE cod_trab cod_t, empleado nombre FROM t1 INTO TEMP t3
SELECT UNIQUE cod_t, nombre, cod, nom_pro FROM t2, t3 INTO TEMP tmp_pro
DROP TABLE t2
DROP TABLE t3
SELECT cod_t cod_trab, nombre empleado, cod lq, nom_pro, NVL(saldo, 0) saldo
	FROM tmp_pro, OUTER t1
	WHERE cod   = lq
	  AND cod_t = cod_trab
	INTO TEMP tmp_ant
DROP TABLE t1
DROP TABLE tmp_pro
RETURN 1

END FUNCTION



FUNCTION preparar_tabla_temporal_tot()
DEFINE cuantos		INTEGER

SELECT UNIQUE cod_trab, empleado FROM tmp_ant INTO TEMP t1
IF ver_saldos = 'S' THEN
	SELECT t1.*, n58_proceso lq, NVL(SUM(n58_saldo_dist), 0) valor_tot
		FROM t1, rolt045, rolt058
		WHERE n45_compania  = vg_codcia
		  AND n45_cod_trab  = cod_trab
		  AND n45_estado    NOT IN ("T", "E")
		  AND n58_compania  = n45_compania
		  AND n58_num_prest = n45_num_prest
		GROUP BY 1, 2, 3
	UNION ALL
	SELECT t1.*,n91_proc_vac lq,NVL(SUM(n91_valor_ant - NVL(n40_valor,0)),0)
		valor_tot
		FROM t1, rolt091, OUTER rolt040
		WHERE n91_compania      = vg_codcia
		  AND n91_cod_trab      = cod_trab
		  AND YEAR(n91_fecing) >= 2007
		  AND n40_compania      = n40_compania
		  AND n40_proceso       = n91_proc_vac
		  AND n40_cod_trab      = n91_cod_trab
		  AND n40_periodo_ini   = n91_periodo_ini
		  AND n40_periodo_fin   = n91_periodo_fin
		GROUP BY 1, 2, 3
		INTO TEMP t2
ELSE
	SELECT t1.*, n58_proceso lq, NVL(SUM(n58_valor_dist), 0) valor_tot
		FROM t1, rolt045, rolt058
		WHERE n45_compania  = vg_codcia
		  AND n45_cod_trab  = cod_trab
		  AND n45_estado    NOT IN ("T", "E")
		  AND n58_compania  = n45_compania
		  AND n58_num_prest = n45_num_prest
		GROUP BY 1, 2, 3
	UNION ALL
	SELECT t1.*, n91_proc_vac lq, NVL(SUM(n91_valor_ant), 0) valor_tot
		FROM t1, rolt091
		WHERE n91_compania      = vg_codcia
		  AND n91_cod_trab      = cod_trab
		  AND YEAR(n91_fecing) >= 2007
		GROUP BY 1, 2, 3
		INTO TEMP t2
END IF
DROP TABLE t1
SELECT UNIQUE lq cod, n03_nombre_abr nom_pro
	FROM rolt003, t2
	WHERE n03_proceso = lq
	INTO TEMP t3
SELECT COUNT(*) INTO vm_num_col FROM t3
SELECT UNIQUE cod_trab cod_t, empleado nombre, cod, nom_pro
	FROM t2, t3
	INTO TEMP tmp_pro
DROP TABLE t3
SELECT cod_t cod_trab, nombre empleado, cod lq, nom_pro,
	NVL(SUM(valor_tot), 0) valor_tot
	FROM tmp_pro, OUTER t2
	WHERE cod   = lq
	  AND cod_t = cod_trab
	GROUP BY 1, 2, 3, 4
	INTO TEMP tmp_ant_tot
DROP TABLE t2
DROP TABLE tmp_pro

END FUNCTION



FUNCTION generar_tabla_temp_t1(ano, mes, flag_sal)
DEFINE ano, mes		SMALLINT
DEFINE flag_sal		CHAR(1)
DEFINE fec_ini, fec_fin	DATE
DEFINE query		CHAR(8000)

LET fec_ini = MDY(mes, 01, ano)
LET fec_fin = MDY(mes, 01, ano) + 1 UNITS MONTH - 1 UNITS DAY
LET query = preparar_query(1, fec_ini, fec_fin, flag_sal),
		' UNION ALL ',
		preparar_query(2, fec_fin, fec_fin, flag_sal),
		' UNION ALL ',
		preparar_query(3, fec_fin, fec_fin, flag_sal),
		' UNION ALL ',
		preparar_query(4, fec_fin, fec_fin, flag_sal),
		' UNION ALL ',
		preparar_query_ant_vac(fec_fin, fec_fin, flag_sal),
		' INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1

END FUNCTION



FUNCTION preparar_query(flag, fec_ini, fec_fin, flag_sal)
DEFINE flag		SMALLINT
DEFINE fec_ini, fec_fin	DATE
DEFINE flag_sal		CHAR(1)
DEFINE query		CHAR(2000)
DEFINE campos		VARCHAR(100)
DEFINE expr_trab	VARCHAR(100)
DEFINE expr_liq		VARCHAR(100)
DEFINE expr_fec		VARCHAR(400)
DEFINE expr_grp		VARCHAR(20)

CASE flag
	WHEN 1
		LET expr_liq = '   AND n46_cod_liqrol[1, 1] IN ("Q", "M", "S")'
		LET expr_fec = '   AND EXTEND(n46_fecha_fin, YEAR TO MONTH)',
				' BETWEEN EXTEND(DATE("', fec_ini, '"), ',
							'YEAR TO MONTH) ',
				' AND EXTEND(DATE("', fec_fin, '"), ',
							'YEAR TO MONTH) '
	WHEN 2
		LET expr_liq = '   AND n46_cod_liqrol       IN ("DT", "DC")'
		LET expr_fec = '   AND EXTEND(n46_fecha_fin, YEAR TO MONTH) + ',
					'1 UNITS MONTH = ',
				' EXTEND(DATE("', fec_fin, '"), YEAR TO MONTH)'
	WHEN 3
		LET expr_liq = '   AND n46_cod_liqrol        = "UT"'
		LET expr_fec = '   AND EXTEND(n46_fecha_fin, YEAR TO MONTH) + ',
					'4 UNITS MONTH = ',
				' EXTEND(DATE("', fec_fin, '"), YEAR TO MONTH)'
	WHEN 4
		LET expr_liq = '   AND n46_cod_liqrol        = "VA"'
		LET expr_fec = '   AND EXTEND(n46_fecha_fin, YEAR TO MONTH) = ',
				' EXTEND(DATE("', fec_fin, '"), YEAR TO MONTH)'
END CASE
LET expr_trab = NULL
IF rm_par.cod_trab IS NOT NULL THEN
	LET expr_trab = '   AND n45_cod_trab          = ', rm_par.cod_trab
END IF
CASE flag_sal
	WHEN 'D'
		LET campos   = ', n30_nombres empleado, n46_cod_liqrol lq,'
		IF ver_saldos = 'S' THEN
			LET campos = campos CLIPPED, ' n46_saldo saldo '
		ELSE
			LET campos = campos CLIPPED, ' n46_valor saldo '
		END IF
		LET expr_grp = NULL
	WHEN 'S'
		IF ver_saldos = 'S' THEN
			LET campos   = ', NVL(SUM(n46_saldo), 0) saldo_ini'
		ELSE
			LET campos   = ', NVL(SUM(n46_valor), 0) saldo_ini'
		END IF
		CASE flag
			WHEN 1
				LET expr_fec = '   AND EXTEND(n46_fecha_fin, ',
						'YEAR TO MONTH) < ',
						'EXTEND(DATE("', fec_ini, '"),',
						' YEAR TO MONTH) '
			WHEN 2
				LET expr_fec = '   AND EXTEND(n46_fecha_fin, ',
						'YEAR TO MONTH) < ',
						' EXTEND(DATE("', fec_fin,
						'"), YEAR TO MONTH)'
			WHEN 3
				LET expr_fec = '   AND EXTEND(n46_fecha_fin, ',
						'YEAR TO MONTH) + ',
						'3 UNITS MONTH < ',
						' EXTEND(DATE("', fec_fin,
						'"), YEAR TO MONTH)'
			WHEN 4
				LET expr_fec = '   AND EXTEND(n46_fecha_fin, ',
						'YEAR TO MONTH) - ',
						'1 UNITS MONTH < ',
						' EXTEND(DATE("', fec_fin,
						'"), YEAR TO MONTH)'
		END CASE
		LET expr_grp = ' GROUP BY 1 '
END CASE
LET query = 'SELECT n45_cod_trab cod_trab', campos CLIPPED,
		' FROM rolt045, rolt046, rolt030 ',
		' WHERE n45_compania          = ', vg_codcia,
		expr_trab CLIPPED,
		'   AND n45_estado           NOT IN ("T", "E") ',
		'   AND n46_compania          = n45_compania ',
		'   AND n46_num_prest         = n45_num_prest ',
		expr_liq CLIPPED,
		expr_fec CLIPPED,
		'   AND n30_compania          = n45_compania ',
		'   AND n30_cod_trab          = n45_cod_trab ',
		expr_grp CLIPPED
RETURN query CLIPPED

END FUNCTION



FUNCTION preparar_query_ant_vac(fec_ini, fec_fin, flag_sal)
DEFINE fec_ini, fec_fin	DATE
DEFINE flag_sal		CHAR(1)
DEFINE query		CHAR(2000)
DEFINE campos		VARCHAR(150)
DEFINE tabla		VARCHAR(20)
DEFINE expr_trab	VARCHAR(100)
DEFINE expr_fec		VARCHAR(400)
DEFINE expr_joi		VARCHAR(400)
DEFINE expr_grp		VARCHAR(20)

LET expr_fec = '   AND EXTEND(n91_periodo_fin, YEAR TO MONTH) = ',
				' EXTEND(DATE("', fec_fin, '"), YEAR TO MONTH)'
LET expr_trab = NULL
IF rm_par.cod_trab IS NOT NULL THEN
	LET expr_trab = '   AND n91_cod_trab          = ', rm_par.cod_trab
END IF
LET tabla    = NULL
LET expr_joi = NULL
IF ver_saldos = 'S' THEN
	LET tabla    = 'OUTER rolt040, '
	LET expr_joi = '   AND n40_compania          = n40_compania ',
			'   AND n40_proceso           = n91_proc_vac ',
			'   AND n40_cod_trab          = n91_cod_trab ',
			'   AND n40_periodo_ini       = n91_periodo_ini ',
			'   AND n40_periodo_fin       = n91_periodo_fin '
END IF
CASE flag_sal
	WHEN 'D'
		LET campos   = ', n30_nombres empleado, n91_proc_vac lq,'
		IF ver_saldos = 'S' THEN
			LET campos = campos CLIPPED,
				' n91_valor_ant - NVL(n40_valor, 0) saldo '
		ELSE
			LET campos = campos CLIPPED, ' n91_valor_ant saldo '
		END IF
		LET expr_grp = NULL
	WHEN 'S'
		IF ver_saldos = 'S' THEN
			LET campos   = ', NVL(SUM(n91_valor_ant - ',
					'NVL(n40_valor, 0)), 0) saldo_ini'
		ELSE
			LET campos   = ', NVL(SUM(n91_valor_ant), 0) saldo_ini'
		END IF
		LET expr_fec = '   AND EXTEND(n91_periodo_fin, ',
				'YEAR TO MONTH) - ',
				'1 UNITS MONTH < ',
				' EXTEND(DATE("', fec_fin,
				'"), YEAR TO MONTH)'
		LET expr_grp = ' GROUP BY 1 '
END CASE
LET query = 'SELECT n91_cod_trab cod_trab', campos CLIPPED,
		' FROM rolt091, ', tabla CLIPPED, 'rolt030 ',
		' WHERE n91_compania          = ', vg_codcia,
		expr_trab CLIPPED,
		'   AND n91_proc_vac          = "VA"',
		expr_fec CLIPPED,
		expr_joi CLIPPED,
		'   AND n30_compania          = n91_compania ',
		'   AND n30_cod_trab          = n91_cod_trab ',
		expr_grp CLIPPED
RETURN query CLIPPED

END FUNCTION



FUNCTION muestra_mes()

CALL fl_justifica_titulo('I', fl_retorna_nombre_mes(rm_par.mes), 11)
	RETURNING rm_par.tit_mes
DISPLAY BY NAME rm_par.tit_mes

END FUNCTION



REPORT reporte_anticipos_mes(cod_emp, nom_emp, sal_ini)
DEFINE cod_emp		LIKE rolt030.n30_cod_trab
DEFINE nom_emp		LIKE rolt030.n30_nombres
DEFINE sal_ini		DECIMAL(12,2)
DEFINE sal_fin		DECIMAL(12,2)
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE cod_p		LIKE rolt003.n03_proceso
DEFINE nom_p		LIKE rolt003.n03_nombre_abr
DEFINE valor		LIKE rolt046.n46_valor
DEFINE fec_ant, fec_ter	DATE
DEFINE lim		SMALLINT
DEFINE col_p1, col_p2	SMALLINT
DEFINE col_p3		SMALLINT
DEFINE esp_bla		CHAR(4)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(32)
DEFINE usuario		VARCHAR(19,15)
DEFINE columna		SMALLINT
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT
DEFINE act_dob1		SMALLINT
DEFINE act_dob2		SMALLINT
DEFINE des_dob		SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	132
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	LET act_dob1	= 87		# Activar Doble Ancho (inicio)
	LET act_dob2	= 49		# Activar Doble Ancho (final)
	LET des_dob	= 48		# Desactivar Doble Ancho
	CALL fl_justifica_titulo('C', "LISTADO DE ANTICIPOS", 40)
		RETURNING titulo
	print ASCII escape;
	print ASCII act_10cpi;
	print ASCII escape;
	print ASCII act_comp;
	PRINT COLUMN 006, ASCII escape, ASCII act_dob1, ASCII act_dob2,
	      COLUMN 010, titulo CLIPPED,
		ASCII escape, ASCII act_dob1, ASCII des_dob,
		ASCII escape, ASCII act_10cpi, ASCII escape, ASCII act_comp
	SKIP 1 LINES
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = 'MODULO: ', r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario	= "USUARIO: ", vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	LET columna = 40
	IF vm_num_col > 4 THEN
		LET columna = 36
	END IF
	DECLARE q_tit_d CURSOR FOR
		SELECT UNIQUE lq, nom_pro
			FROM tmp_ant
			ORDER BY 1
	LET columna = columna + 14
	FOREACH q_tit_d INTO cod_p, nom_p
		LET columna = columna + 14
	END FOREACH
	LET columna = columna + 13
	LET col_p1  = 122
	LET col_p2  = 126
	LET col_p3  = 114
	LET col_p1  = col_p1 - (132 - columna + 1)
	LET col_p2  = col_p2 - (132 - columna + 1)
	LET col_p3  = col_p3 - (132 - columna + 1)
	PRINT COLUMN 001, r_g01.g01_razonsocial CLIPPED,
	      COLUMN col_p1, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN col_p2, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 046, "** PERIODO  : ", rm_par.anio USING "&&&&", ' - ',
		rm_par.mes USING "&&", ' ', rm_par.tit_mes CLIPPED
	IF rm_par.cod_trab IS NOT NULL THEN
		PRINT COLUMN 046, "** EMPLEADO : ",
			rm_par.cod_trab USING "<<<<&&", ' ',
			rm_par.nom_trab[1, 35] CLIPPED
	END IF
	IF ver_saldos = 'S' THEN
		PRINT COLUMN 056, "** S A L D O S **"
	ELSE
		PRINT COLUMN 056, "** T O T A L E S **"
	END IF
	PRINT COLUMN 001, "FECHA DE IMPRESION: ", TODAY USING "dd-mm-yyyy",
			1 SPACES, TIME,
	      COLUMN col_p3, usuario CLIPPED
	LET fec_ant = MDY(rm_par.mes, 01, rm_par.anio) - 1 UNITS DAY
	LET fec_ter = MDY(rm_par.mes, 01, rm_par.anio)
			+ 1 UNITS MONTH - 1 UNITS DAY
	LET columna = 40
	LET esp_bla = "----"
	IF vm_num_col > 4 THEN
		LET columna = 36
		LET esp_bla = NULL
	END IF
	PRINT COLUMN 001, "-----------------------------------",esp_bla CLIPPED,
	      COLUMN columna, "--------------";
	DECLARE q_ray_t1 CURSOR FOR
		SELECT UNIQUE lq, nom_pro
			FROM tmp_ant
			ORDER BY 1
	LET columna = columna + 14
	FOREACH q_ray_t1 INTO cod_p, nom_p
		PRINT COLUMN columna, "--------------";
		LET columna = columna + 14
	END FOREACH
	PRINT COLUMN columna, "-------------"
	LET columna = 40
	LET esp_bla = "  "
	IF vm_num_col > 4 THEN
		LET columna = 36
		LET esp_bla = NULL
	END IF
	PRINT COLUMN 001, "CODIGO",
	      COLUMN 008, esp_bla CLIPPED, "     E M P L E A D O S";
	IF ver_saldos = 'S' THEN
		PRINT COLUMN columna, "SALDO ANTERI.";
	ELSE
		PRINT COLUMN columna, "TOTAL ANTERI.";
	END IF
	DECLARE q_tit CURSOR FOR
		SELECT UNIQUE lq, nom_pro
			FROM tmp_ant
			ORDER BY 1
	LET columna = columna + 14
	FOREACH q_tit INTO cod_p, nom_p
		PRINT COLUMN columna, fl_justifica_titulo('D',nom_p[1, 13], 13);
		LET columna = columna + 14
	END FOREACH
	IF ver_saldos = 'S' THEN
		PRINT COLUMN columna, "  SALDO FINAL"
	ELSE
		PRINT COLUMN columna, "  TOTAL FINAL"
	END IF
	LET columna = 40
	IF vm_num_col > 4 THEN
		LET columna = 36
	END IF
	PRINT COLUMN columna + 3, fec_ant	USING "dd-mm-yyyy";
	DECLARE q_fec_t CURSOR FOR
		SELECT UNIQUE lq, nom_pro
			FROM tmp_ant
			ORDER BY 1
	LET columna = columna + 14
	FOREACH q_fec_t INTO cod_p, nom_p
		LET columna = columna + 14
	END FOREACH
	PRINT COLUMN columna + 3, fec_ter	USING "dd-mm-yyyy"
	LET columna = 40
	LET esp_bla = "----"
	IF vm_num_col > 4 THEN
		LET columna = 36
		LET esp_bla = NULL
	END IF
	PRINT COLUMN 001, "-----------------------------------",esp_bla CLIPPED,
	      COLUMN columna, "--------------";
	DECLARE q_ray_t2 CURSOR FOR
		SELECT UNIQUE lq, nom_pro
			FROM tmp_ant
			ORDER BY 1
	LET columna = columna + 14
	FOREACH q_ray_t2 INTO cod_p, nom_p
		PRINT COLUMN columna, "--------------";
		LET columna = columna + 14
	END FOREACH
	PRINT COLUMN columna, "-------------"

ON EVERY ROW
	NEED 3 LINES
	LET sal_fin = sal_ini
	LET columna = 40
	LET lim     = 31
	IF vm_num_col > 4 THEN
		LET columna = 36
		LET lim     = 27
	END IF
	PRINT COLUMN 001, cod_emp		USING "####&&",
	      COLUMN 008, nom_emp[1, lim]	CLIPPED,
	      COLUMN columna, sal_ini		USING "--,---,--&.##";
	DECLARE q_pro CURSOR FOR
		SELECT lq, saldo FROM tmp_ant
			WHERE cod_trab = cod_emp
			ORDER BY 1
	LET columna = columna + 14
	FOREACH q_pro INTO cod_p, valor
		PRINT COLUMN columna, valor	USING "--,---,--&.##";
		LET columna = columna + 14
		LET sal_fin = sal_fin + valor
	END FOREACH
	PRINT COLUMN columna, sal_fin		USING "--,---,--&.##"
	LET vm_tot_fin = vm_tot_fin + sal_fin

ON LAST ROW
	NEED 2 LINES
	LET columna = 40
	IF vm_num_col > 4 THEN
		LET columna = 36
	END IF
	PRINT COLUMN columna, "-------------";
	DECLARE q_ray CURSOR FOR
		SELECT lq, NVL(SUM(saldo), 0)
			FROM tmp_ant
			GROUP BY 1
			ORDER BY 1
	LET columna = columna + 14
	FOREACH q_ray INTO cod_p, valor
		PRINT COLUMN columna, "-------------";
		LET columna = columna + 14
	END FOREACH
	PRINT COLUMN columna, "-------------"
	DECLARE q_tot CURSOR FOR
		SELECT lq, NVL(SUM(saldo), 0)
			FROM tmp_ant
			GROUP BY 1
			ORDER BY 1
	LET columna = 40
	IF vm_num_col > 4 THEN
		LET columna = 36
	END IF
	PRINT COLUMN 003, "TOT. EMP. ", vm_tot_emp	USING "<<<<&",
	      COLUMN 024, "TOTALES ==>",
	      COLUMN columna, vm_tot_ini	USING "--,---,--&.##";
	LET columna = columna + 14
	FOREACH q_tot INTO cod_p, valor
		PRINT COLUMN columna, valor	USING "--,---,--&.##";
		LET columna = columna + 14
	END FOREACH
	PRINT COLUMN columna, vm_tot_fin	USING "--,---,--&.##";
	print ASCII escape;
	print ASCII act_10cpi;
	print ASCII escape;
	print ASCII desact_comp

END REPORT



REPORT reporte_anticipos_proc(nom_p, cod_emp, nom_emp, sal_ini)
DEFINE nom_p		LIKE rolt003.n03_nombre_abr
DEFINE cod_emp		LIKE rolt030.n30_cod_trab
DEFINE nom_emp		LIKE rolt030.n30_nombres
DEFINE sal_ini		DECIMAL(12,2)
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(32)
DEFINE usuario		VARCHAR(19,15)
DEFINE escape		SMALLINT
DEFINE act_10cpi	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	80
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = 'MODULO: ', r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario	= "USUARIO: ", vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	print ASCII escape;
	print ASCII act_10cpi;
	PRINT COLUMN 003, r_g01.g01_razonsocial CLIPPED,
	      COLUMN 072, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 028, "DESCUENTOS DE ", nom_p CLIPPED,
	      COLUMN 074, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 020, "** PERIODO  : ", rm_par.anio USING "&&&&", ' - ',
		rm_par.mes USING "&&", ' ', rm_par.tit_mes CLIPPED
	IF rm_par.cod_trab IS NOT NULL THEN
		PRINT COLUMN 020, "** EMPLEADO : ",
			rm_par.cod_trab USING "<<<<&&", ' ',
			rm_par.nom_trab[1, 35] CLIPPED
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA DE IMPRESION: ", TODAY USING "dd-mm-yyyy",
			1 SPACES, TIME,
	      COLUMN 062, usuario CLIPPED
	PRINT COLUMN 001, "--------------------------------------------------------------------------------"
	PRINT COLUMN 001, "CODIGO",
	      COLUMN 012, "             E M P L E A D O S",
	      COLUMN 068, "VALOR DESCTO."
	PRINT COLUMN 001, "--------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, cod_emp		USING "####&&",
	      COLUMN 012, nom_emp		CLIPPED,
	      COLUMN 068, sal_ini		USING "--,---,--&.##"

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 068, "-------------"
	PRINT COLUMN 003, "TOT. EMP. ", vm_tot_emp	USING "<<<<&",
	      COLUMN 057, "TOTAL ==>",
	      COLUMN 068, vm_tot_ini		USING "--,---,--&.##"

END REPORT



REPORT reporte_anticipos_tot(cod_emp, nom_emp)
DEFINE cod_emp		LIKE rolt030.n30_cod_trab
DEFINE nom_emp		LIKE rolt030.n30_nombres
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE cod_p		LIKE rolt003.n03_proceso
DEFINE nom_p		LIKE rolt003.n03_nombre_abr
DEFINE valor		LIKE rolt046.n46_valor
DEFINE sal_fin		DECIMAL(12,2)
DEFINE lim		SMALLINT
DEFINE col_p1, col_p2	SMALLINT
DEFINE col_p3		SMALLINT
DEFINE esp_bla		CHAR(4)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(32)
DEFINE usuario		VARCHAR(19,15)
DEFINE columna		SMALLINT
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT
DEFINE act_dob1		SMALLINT
DEFINE act_dob2		SMALLINT
DEFINE des_dob		SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	132
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	LET act_dob1	= 87		# Activar Doble Ancho (inicio)
	LET act_dob2	= 49		# Activar Doble Ancho (final)
	LET des_dob	= 48		# Desactivar Doble Ancho
	IF ver_saldos = 'S' THEN
		CALL fl_justifica_titulo('C', "LISTADO SALDOS ANTICIPOS", 30)
			RETURNING titulo
	ELSE
		CALL fl_justifica_titulo('C', "LISTADO TOTALES ANTICIPOS", 30)
			RETURNING titulo
	END IF
	print ASCII escape;
	print ASCII act_10cpi;
	print ASCII escape;
	print ASCII act_comp;
	PRINT COLUMN 006, ASCII escape, ASCII act_dob1, ASCII act_dob2,
	      COLUMN 010, titulo CLIPPED,
		ASCII escape, ASCII act_dob1, ASCII des_dob,
		ASCII escape, ASCII act_10cpi, ASCII escape, ASCII act_comp
	SKIP 1 LINES
	CALL fl_lee_compania(vg_codcia) RETURNING r_g01.*
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = 'MODULO: ', r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario	= "USUARIO: ", vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	LET columna = 40
	IF vm_num_col > 4 THEN
		LET columna = 36
	END IF
	DECLARE q_tit_d1 CURSOR FOR
		SELECT UNIQUE lq, nom_pro
			FROM tmp_ant_tot
			ORDER BY 1
	FOREACH q_tit_d1 INTO cod_p, nom_p
		LET columna = columna + 14
	END FOREACH
	LET columna = columna + 13
	LET col_p1  = 122
	LET col_p2  = 126
	LET col_p3  = 114
	LET col_p1  = col_p1 - (132 - columna + 1)
	LET col_p2  = col_p2 - (132 - columna + 1)
	LET col_p3  = col_p3 - (132 - columna + 1)
	PRINT COLUMN 001, r_g01.g01_razonsocial CLIPPED,
	      COLUMN col_p1, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN col_p2, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 046, "** PERIODO  : ", rm_par.anio USING "&&&&", ' - ',
		rm_par.mes USING "&&", ' ', rm_par.tit_mes CLIPPED
	IF rm_par.cod_trab IS NOT NULL THEN
		PRINT COLUMN 046, "** EMPLEADO : ",
			rm_par.cod_trab USING "<<<<&&", ' ',
			rm_par.nom_trab[1, 35] CLIPPED
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA DE IMPRESION: ", TODAY USING "dd-mm-yyyy",
			1 SPACES, TIME,
	      COLUMN col_p3, usuario CLIPPED
	LET columna = 40
	LET esp_bla = "----"
	IF vm_num_col > 4 THEN
		LET columna = 36
		LET esp_bla = NULL
	END IF
	PRINT COLUMN 001, "-----------------------------------",esp_bla CLIPPED;
	DECLARE q_ray_t3 CURSOR FOR
		SELECT UNIQUE lq, nom_pro
			FROM tmp_ant_tot
			ORDER BY 1
	FOREACH q_ray_t3 INTO cod_p, nom_p
		PRINT COLUMN columna, "--------------";
		LET columna = columna + 14
	END FOREACH
	PRINT COLUMN columna, "-------------"
	LET columna = 40
	LET esp_bla = "  "
	IF vm_num_col > 4 THEN
		LET columna = 36
		LET esp_bla = NULL
	END IF
	PRINT COLUMN 001, "CODIGO",
	      COLUMN 008, esp_bla CLIPPED, "     E M P L E A D O S";
	DECLARE q_tit1 CURSOR FOR
		SELECT UNIQUE lq, nom_pro
			FROM tmp_ant_tot
			ORDER BY 1
	FOREACH q_tit1 INTO cod_p, nom_p
		PRINT COLUMN columna, fl_justifica_titulo('D',nom_p[1, 13], 13);
		LET columna = columna + 14
	END FOREACH
	IF ver_saldos = 'S' THEN
		PRINT COLUMN columna, "SALDO PROCES."
	ELSE
		PRINT COLUMN columna, "TOTAL PROCES."
	END IF
	LET columna = 40
	LET esp_bla = "----"
	IF vm_num_col > 4 THEN
		LET columna = 36
		LET esp_bla = NULL
	END IF
	PRINT COLUMN 001, "-----------------------------------",esp_bla CLIPPED;
	DECLARE q_ray_t4 CURSOR FOR
		SELECT UNIQUE lq, nom_pro
			FROM tmp_ant_tot
			ORDER BY 1
	FOREACH q_ray_t4 INTO cod_p, nom_p
		PRINT COLUMN columna, "--------------";
		LET columna = columna + 14
	END FOREACH
	PRINT COLUMN columna, "-------------"

ON EVERY ROW
	NEED 3 LINES
	LET columna = 40
	LET lim     = 31
	IF vm_num_col > 4 THEN
		LET columna = 36
		LET lim     = 27
	END IF
	PRINT COLUMN 001, cod_emp		USING "####&&",
	      COLUMN 008, nom_emp[1, lim]	CLIPPED;
	DECLARE q_pro1 CURSOR FOR
		SELECT lq, valor_tot FROM tmp_ant_tot
			WHERE cod_trab = cod_emp
			ORDER BY 1
	LET sal_fin = 0
	FOREACH q_pro1 INTO cod_p, valor
		PRINT COLUMN columna, valor	USING "--,---,--&.##";
		LET columna = columna + 14
		LET sal_fin = sal_fin + valor
	END FOREACH
	PRINT COLUMN columna, sal_fin		USING "--,---,--&.##"
	LET vm_tot_fin = vm_tot_fin + sal_fin

ON LAST ROW
	NEED 2 LINES
	LET columna = 40
	IF vm_num_col > 4 THEN
		LET columna = 36
	END IF
	DECLARE q_ray5 CURSOR FOR
		SELECT lq, NVL(SUM(valor_tot), 0)
			FROM tmp_ant_tot
			GROUP BY 1
			ORDER BY 1
	FOREACH q_ray5 INTO cod_p, valor
		PRINT COLUMN columna, "-------------";
		LET columna = columna + 14
	END FOREACH
	PRINT COLUMN columna, "-------------"
	DECLARE q_tot1 CURSOR FOR
		SELECT lq, NVL(SUM(valor_tot), 0)
			FROM tmp_ant_tot
			GROUP BY 1
			ORDER BY 1
	LET columna = 40
	IF vm_num_col > 4 THEN
		LET columna = 36
	END IF
	PRINT COLUMN 003, "TOT. EMP. ", vm_tot_emp	USING "<<<<&",
	      COLUMN 024, "TOTALES ==>";
	FOREACH q_tot1 INTO cod_p, valor
		PRINT COLUMN columna, valor	USING "--,---,--&.##";
		LET columna = columna + 14
	END FOREACH
	PRINT COLUMN columna, vm_tot_fin	USING "--,---,--&.##";
	print ASCII escape;
	print ASCII act_10cpi;
	print ASCII escape;
	print ASCII desact_comp

END REPORT



FUNCTION llamar_visor_teclas()
DEFINE a		SMALLINT

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION
