--------------------------------------------------------------------------------
-- Titulo           : actp400.4gl - Listado de Activos Fijos
-- Elaboracion      : 06-Oct-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun actp400 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_a00		RECORD LIKE actt000.*
DEFINE rm_a10		RECORD LIKE actt010.*
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_fec_ini_dep	DATE
DEFINE vm_tot_val	DECIMAL(14,2)
DEFINE vm_tot_dep	DECIMAL(14,2)
DEFINE vm_tot_val_t	DECIMAL(14,2)
DEFINE vm_tot_dep_t	DECIMAL(14,2)
DEFINE vm_tot_val_d	DECIMAL(14,2)
DEFINE vm_tot_dep_d	DECIMAL(14,2)
DEFINE vm_tot_valor	DECIMAL(14,2)
DEFINE vm_tot_dep_g	DECIMAL(14,2)
DEFINE vm_top		SMALLINT
DEFINE vm_left		SMALLINT
DEFINE vm_right		SMALLINT
DEFINE vm_bottom	SMALLINT
DEFINE vm_page		SMALLINT



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/actp400.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 9 AND num_args() <> 10 THEN
	-- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de paráametros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'actp400'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
LET vm_top    = 1
LET vm_left   = 0
LET vm_right  = 132
LET vm_bottom = 4
LET vm_page   = 66
CALL fl_lee_compania_activos(vg_codcia) RETURNING rm_a00.*
IF rm_a00.a00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configurada ninguna compañía para Activos Fijos.', 'stop')
	EXIT PROGRAM
END IF
INITIALIZE rm_a10.*, vm_fecha_ini, vm_fecha_fin, vm_fec_ini_dep TO NULL
SELECT NVL(MIN(a10_fecha_comp), MDY(01, 01, 1990))
	INTO vm_fecha_ini
	FROM actt010
	WHERE a10_compania  = vg_codcia
	  AND a10_estado   IN ("S", "D", "V", "E", "R", "N")
IF num_args() <> 4 THEN
	CALL llamada_de_otro_programa()
	EXIT PROGRAM
END IF
OPEN WINDOW w_actf400_1 AT 3, 2 WITH 13 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 1)
OPEN FORM f_actf400_1 FROM "../forms/actf400_1"
DISPLAY FORM f_actf400_1
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION llamada_de_otro_programa()
DEFINE r_a01		RECORD LIKE actt001.*
DEFINE r_a02		RECORD LIKE actt002.*
DEFINE r_g02		RECORD LIKE gent002.*

LET rm_a10.a10_estado    = arg_val(5)
LET rm_a10.a10_grupo_act = arg_val(6)
IF rm_a10.a10_grupo_act = 0 THEN
	LET rm_a10.a10_grupo_act = NULL
END IF
LET rm_a10.a10_tipo_act  = arg_val(7)
IF rm_a10.a10_tipo_act = 0 THEN
	LET rm_a10.a10_tipo_act = NULL
END IF
LET rm_a10.a10_localidad = arg_val(8)
IF rm_a10.a10_localidad = 0 THEN
	LET rm_a10.a10_localidad = NULL
END IF
LET vm_fecha_fin   = arg_val(9)
IF num_args() > 9 THEN
	LET vm_fec_ini_dep = arg_val(10)
	IF rm_a10.a10_estado <> 'X' THEN
		LET vm_fec_ini_dep = NULL
	END IF
END IF
IF rm_a10.a10_grupo_act IS NOT NULL THEN
	CALL fl_lee_grupo_activo(vg_codcia, rm_a10.a10_grupo_act)
		RETURNING r_a01.*
	IF r_a01.a01_grupo_act IS NULL THEN
		CALL fl_mostrar_mensaje('No existe grupo de activo', 'exclamation')
		RETURN
	END IF
END IF
IF rm_a10.a10_tipo_act IS NOT NULL THEN
	CALL fl_lee_tipo_activo(vg_codcia, rm_a10.a10_tipo_act)
		RETURNING r_a02.*
	IF r_a02.a02_tipo_act IS NULL THEN
		CALL fl_mostrar_mensaje('No existe tipo de activo', 'exclamation')
		RETURN
	END IF
END IF
IF rm_a10.a10_localidad IS NOT NULL THEN
	CALL fl_lee_localidad(vg_codcia, rm_a10.a10_localidad)
		RETURNING r_g02.*
	IF r_g02.g02_localidad IS NULL THEN
		CALL fl_mostrar_mensaje('No existe esta localidad.', 'exclamation')
		RETURN
	END IF	
END IF
IF vm_fecha_ini > vm_fecha_fin THEN
	CALL fl_mostrar_mensaje('La fecha inicial debe ser menor o igual que la fecha final.', 'exclamation')
	RETURN
END IF
CALL control_imprimir_listado()

END FUNCTION



FUNCTION control_reporte()
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE tit_est		VARCHAR(30)

LET rm_a10.a10_localidad = vg_codloc
--LET rm_a10.a10_estado    = 'T'
LET rm_a10.a10_estado    = 'X'
LET vm_fecha_fin	 = TODAY
CALL fl_lee_localidad(vg_codcia, rm_a10.a10_localidad) RETURNING r_g02.*
DISPLAY BY NAME r_g02.g02_nombre 
CALL muestra_estado(rm_a10.a10_estado, 1) RETURNING tit_est
WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_imprimir_listado()
END WHILE 
CLOSE WINDOW w_actf400_1

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_a01		RECORD LIKE actt001.*
DEFINE r_a02		RECORD LIKE actt002.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE estado		LIKE actt010.a10_estado
DEFINE fec_ini		DATE
DEFINE fec_fin		DATE
DEFINE tit_est		VARCHAR(30)

INITIALIZE r_a01.*, r_a02.* TO NULL
LET int_flag = 0
INPUT BY NAME rm_a10.a10_grupo_act, rm_a10.a10_tipo_act, rm_a10.a10_localidad,
	vm_fecha_ini, vm_fecha_fin, rm_a10.a10_estado
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(a10_grupo_act) THEN
			CALL fl_ayuda_grupo_activo(vg_codcia) 
				RETURNING r_a01.a01_grupo_act, r_a01.a01_nombre
			IF r_a01.a01_grupo_act IS NOT NULL THEN
				LET rm_a10.a10_grupo_act = r_a01.a01_grupo_act
				DISPLAY BY NAME rm_a10.a10_grupo_act
				DISPLAY r_a01.a01_nombre TO tit_grupo_act
			END IF 
		END IF
		IF INFIELD(a10_tipo_act) THEN
			CALL fl_ayuda_tipo_activo(vg_codcia,
							rm_a10.a10_grupo_act) 
				RETURNING r_a02.a02_tipo_act, r_a02.a02_nombre
			IF r_a02.a02_tipo_act IS NOT NULL THEN
				LET rm_a10.a10_tipo_act = r_a02.a02_tipo_act
				DISPLAY BY NAME rm_a10.a10_tipo_act
				DISPLAY r_a02.a02_nombre TO tit_tipo_act
			END IF 
		END IF
		IF INFIELD(a10_localidad) THEN
			CALL fl_ayuda_localidad(vg_codcia) 
				RETURNING r_g02.g02_localidad, r_g02.g02_nombre
			IF r_g02.g02_localidad IS NOT NULL THEN
				LET rm_a10.a10_localidad = r_g02.g02_localidad
				DISPLAY BY NAME rm_a10.a10_localidad,
						r_g02.g02_nombre
			END IF 
		END IF
		IF INFIELD(a10_estado) THEN
			CALL fl_ayuda_estado_activos(vg_codcia, 0)
				RETURNING rm_a10.a10_estado, tit_est
			IF rm_a10.a10_estado IS NOT NULL THEN
				DISPLAY BY NAME rm_a10.a10_estado
				CALL muestra_estado(rm_a10.a10_estado, 1)	
					RETURNING tit_est
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD vm_fecha_ini
		LET fec_ini = vm_fecha_ini
	BEFORE FIELD vm_fecha_fin
		LET fec_fin = vm_fecha_fin
	BEFORE FIELD a10_estado
		LET estado = rm_a10.a10_estado
	AFTER FIELD a10_grupo_act
		IF rm_a10.a10_grupo_act IS NOT NULL THEN
			CALL fl_lee_grupo_activo(vg_codcia,rm_a10.a10_grupo_act)
				RETURNING r_a01.*
			IF r_a01.a01_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe este grupo de activo en la compania.', 'exclamation')
				NEXT FIELD a10_grupo_act
			END IF
			DISPLAY r_a01.a01_nombre TO tit_grupo_act
		ELSE
			CLEAR tit_grupo_act
		END IF
	AFTER FIELD a10_tipo_act
		IF rm_a10.a10_tipo_act IS NOT NULL THEN
			CALL fl_lee_tipo_activo(vg_codcia, rm_a10.a10_tipo_act)
				RETURNING r_a02.*
			IF r_a02.a02_compania IS NULL THEN
				CALL fl_mostrar_mensaje('No existe este tipo de activo en la compania.', 'exclamation')
				NEXT FIELD a10_tipo_act
			END IF
			DISPLAY r_a02.a02_nombre TO tit_tipo_act
		ELSE
			CLEAR tit_tipo_act
		END IF
	AFTER FIELD a10_localidad
		IF rm_a10.a10_localidad IS NOT NULL THEN
			CALL fl_lee_localidad(vg_codcia, rm_a10.a10_localidad)
				RETURNING r_g02.*
			IF r_g02.g02_localidad IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'No existe esta localidad.', 'exclamation')
				NEXT FIELD a10_localidad
			END IF	
			DISPLAY BY NAME r_g02.g02_nombre 
		ELSE
			CLEAR g02_nombre
		END IF
	AFTER FIELD vm_fecha_ini
		IF vm_fecha_ini IS NULL THEN
			LET vm_fecha_ini = fec_ini
			DISPLAY BY NAME vm_fecha_ini
		END IF
		IF vm_fecha_ini > TODAY THEN
			CALL fl_mostrar_mensaje('La fecha inicial no puede ser mayor a la fecha actual.', 'exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
	AFTER FIELD vm_fecha_fin
		IF vm_fecha_fin IS NULL THEN
			LET vm_fecha_fin = fec_fin
			DISPLAY BY NAME vm_fecha_fin
		END IF
		IF vm_fecha_fin > TODAY THEN
			CALL fl_mostrar_mensaje('La fecha final no puede ser mayor a la fecha actual.', 'exclamation')
			NEXT FIELD vm_fecha_fin
		END IF
	AFTER FIELD a10_estado
		IF rm_a10.a10_estado IS NULL THEN
			LET rm_a10.a10_estado = estado
		END IF
		CALL muestra_estado(rm_a10.a10_estado, 1) RETURNING tit_est
	AFTER INPUT
		IF vm_fecha_ini > vm_fecha_fin THEN
			CALL fl_mostrar_mensaje('La fecha inicial no puede ser mayor a la fecha final.', 'exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
END INPUT

END FUNCTION


 
FUNCTION control_imprimir_listado()
DEFINE r_report 	RECORD
				a10_estado	LIKE actt010.a10_estado,
				a10_codigo_bien	LIKE actt010.a10_codigo_bien,
				a10_descripcion	LIKE actt010.a10_descripcion,
				a10_fecha_comp	LIKE actt010.a10_fecha_comp,
				a10_codprov	LIKE actt010.a10_codprov,
				a10_porc_deprec	LIKE actt010.a10_porc_deprec,
				a10_moneda	LIKE actt010.a10_moneda,
				a10_valor	LIKE actt010.a10_valor,
				a10_tot_dep_mb	LIKE actt010.a10_tot_dep_mb,
				valor_actual	LIKE actt010.a10_tot_dep_mb
			END RECORD
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE query		VARCHAR(1200)
DEFINE expr_orden	VARCHAR(100)
DEFINE comando 		VARCHAR(100)
DEFINE resp 		CHAR(6)

IF num_args() = 4 THEN
	LET vm_fec_ini_dep = vm_fecha_ini
END IF
IF NOT preparar_tabla_trabajo() THEN
	RETURN
END IF
LET int_flag = 0
CALL fl_hacer_pregunta('Desea generar un archivo ?', 'No') RETURNING resp
IF resp = 'Yes' THEN
	CALL control_archivo()
END IF
CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
LET expr_orden = ' ORDER BY a10_grupo_act, a10_tipo_act, a10_cod_depto, ',
			'a10_codigo_bien '
IF rm_a10.a10_grupo_act IS NOT NULL THEN
	--LET expr_orden = ' ORDER BY a10_codigo_bien '
END IF
INITIALIZE r_a10.* TO NULL
LET query = 'SELECT * FROM tmp_act ', expr_orden CLIPPED
PREPARE reporte FROM query
DECLARE q_reporte CURSOR FOR reporte
START REPORT report_activos TO PIPE comando
--START REPORT report_activos TO FILE "activos.txt"
LET vm_tot_valor = 0
LET vm_tot_dep_g = 0
FOREACH q_reporte INTO r_a10.a10_grupo_act, r_a10.a10_tipo_act,
			r_a10.a10_cod_depto, r_report.*
	OUTPUT TO REPORT report_activos(r_report.*, r_a10.a10_grupo_act,
					r_a10.a10_tipo_act, r_a10.a10_cod_depto)
END FOREACH
FINISH REPORT report_activos
DROP TABLE tmp_act

END FUNCTION



FUNCTION preparar_tabla_trabajo()
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE query		CHAR(6000)
DEFINE exp_gru		VARCHAR(100)
DEFINE exp_tip		VARCHAR(100)
DEFINE exp_loc		VARCHAR(100)
DEFINE cuantos		INTEGER

LET exp_gru = NULL
IF rm_a10.a10_grupo_act IS NOT NULL THEN
	LET exp_gru = '   AND a10_grupo_act    = ', rm_a10.a10_grupo_act  
END IF
LET exp_tip = NULL
IF rm_a10.a10_tipo_act IS NOT NULL THEN
	LET exp_tip = '   AND a10_tipo_act     = ', rm_a10.a10_tipo_act 
END IF
LET exp_loc = NULL
IF rm_a10.a10_localidad IS NOT NULL THEN
	LET exp_loc = '   AND a10_localidad    = ', rm_a10.a10_localidad
END IF
IF rm_a10.a10_estado <> 'X' THEN
	LET query = 'SELECT a10_grupo_act, a10_tipo_act, a10_cod_depto, ',
			'a10_estado, a10_codigo_bien, a10_descripcion, ',
			'a10_fecha_comp, a10_codprov, a10_porc_deprec, ',
			'a10_moneda, a10_valor_mb, a10_tot_dep_mb, ',
			'(a10_valor_mb - a10_tot_dep_mb) valor_actual ',
			' FROM actt010 ',
			' WHERE a10_compania    = ', vg_codcia, ' ',
			exp_loc CLIPPED, ' ',
			exp_gru CLIPPED, ' ',
			exp_tip CLIPPED, ' ',
			'   AND a10_fecha_comp BETWEEN "', vm_fecha_ini,
						'" AND "', vm_fecha_fin, '"',
			fl_retorna_expr_estado_act(vg_codcia, rm_a10.a10_estado,
							0) CLIPPED,
			' INTO TEMP tmp_act '
	PREPARE exec_act FROM query
	EXECUTE exec_act
	SELECT COUNT(*) INTO cuantos FROM tmp_act
	IF cuantos = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		DROP TABLE tmp_act
		RETURN 0
	END IF
	RETURN 1
END IF
SELECT UNIQUE a12_compania cia, a12_codigo_bien cod_bien, DATE(a12_fecing) fecha
	FROM actt012
	WHERE a12_compania      = vg_codcia
	  AND a12_codigo_tran  IN ("BA", "VE", "BV")
	  AND DATE(a12_fecing) <= vm_fecha_fin
	INTO TEMP tmp_baj
LET query = 'SELECT * FROM actt010 ',
		' WHERE a10_compania     = ', vg_codcia,
		exp_loc CLIPPED,
		exp_gru CLIPPED,
		exp_tip CLIPPED,
		fl_retorna_expr_estado_act(vg_codcia, rm_a10.a10_estado,
						1) CLIPPED,
		'   AND a10_codigo_bien NOT IN ',
				'(SELECT cod_bien ',
					'FROM tmp_baj ',
					'WHERE fecha < "', vm_fecha_ini,'") ',
		' INTO TEMP tmp_a10 '
PREPARE exec_a10 FROM query
EXECUTE exec_a10
LET query = 'SELECT a.* FROM actt012 a ',
		' WHERE a.a12_compania      = ', vg_codcia,
	  	'   AND a.a12_codigo_tran  NOT IN ("EG", "BA", "VE", "BV") ',
		'   AND a.a12_codigo_bien  IN ',
				'(SELECT a10_codigo_bien ',
				'FROM tmp_a10 ',
				'WHERE a10_compania = a.a12_compania) ',
		'   AND a.a12_valor_mb     <= 0 ',
		'   AND DATE(a.a12_fecing) <= "', vm_fecha_fin, '"',
		'   AND EXISTS (SELECT UNIQUE b.a12_codigo_tran ',
				'FROM actt012 b ',
				'WHERE b.a12_compania    = a.a12_compania ',
				'  AND b.a12_codigo_tran = "DP" ',
				'  AND b.a12_codigo_bien = a.a12_codigo_bien) ',
		' UNION ',
		' SELECT a.* FROM actt012 a ',
			' WHERE a.a12_compania      = ', vg_codcia,
			'   AND a.a12_codigo_tran  <> "EG" ',
			'   AND a.a12_codigo_bien  IN ',
				'(SELECT a10_codigo_bien ',
				'FROM tmp_a10 ',
				'WHERE a10_compania  = a.a12_compania ',
				'  AND a10_grupo_act = 1) ',
			'   AND a.a12_valor_mb     <= 0 ',
			'   AND DATE(a.a12_fecing) <= "', vm_fecha_fin, '"',
		' INTO TEMP tmp_a12 '
PREPARE exec_a12 FROM query
EXECUTE exec_a12
LET query = 'SELECT a10_compania, a10_localidad, a10_grupo_act, a10_tipo_act, ',
			'a10_cod_depto, a10_codigo_bien, a10_estado, ',
			'a10_descripcion, a10_fecha_comp, a10_codprov, ',
			'a10_moneda, a10_valor_mb, a10_porc_deprec, ',
			'a10_val_dep_mb, ',
			'NVL(SUM(a12_valor_mb) * (-1), 0) tot_dep_ant, ',
			'a10_tot_dep_mb ',
		' FROM tmp_a10, tmp_a12 ',
		' WHERE a12_compania     = a10_compania ',
		'   AND a12_codigo_bien  = a10_codigo_bien ',
		'   AND DATE(a12_fecing) < "', vm_fec_ini_dep, '"',
		' GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 16 ',
		' UNION',
		' SELECT a10_compania, a10_localidad, a10_grupo_act, ',
			'a10_tipo_act, a10_cod_depto, a10_codigo_bien, ',
			'a10_estado, a10_descripcion, a10_fecha_comp, ',
			'a10_codprov, a10_moneda, a10_valor_mb, ',
			'a10_porc_deprec, a10_val_dep_mb, 0.00 tot_dep_ant, ',
			'a10_tot_dep_mb ',
		' FROM tmp_a10, tmp_a12 ',
		' WHERE a12_compania     = a10_compania ',
		'   AND a12_codigo_bien  = a10_codigo_bien ',
		'   AND EXTEND(a12_fecing, YEAR TO MONTH) <= ',
			'EXTEND(DATE("', vm_fecha_fin, '"), YEAR TO MONTH) ',
		' INTO TEMP tt '
PREPARE exec_tt FROM query
EXECUTE exec_tt
SELECT a10_compania, a10_localidad, a10_grupo_act, a10_tipo_act, a10_cod_depto,
	a10_codigo_bien, a10_estado, a10_descripcion, a10_fecha_comp,
	a10_codprov, a10_moneda, a10_valor_mb, a10_porc_deprec, a10_val_dep_mb,
	NVL(SUM(tot_dep_ant), 0) tot_dep_ant, a10_tot_dep_mb
	FROM tt
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 16
	INTO TEMP t1
DROP TABLE tt
LET query = 'SELECT a10_localidad, a10_grupo_act, a10_tipo_act, a10_cod_depto,',
		' a10_codigo_bien, a10_estado, a10_descripcion, ',
		'a10_fecha_comp, a10_codprov, a10_moneda, a10_valor_mb, ',
		'a10_porc_deprec, a10_val_dep_mb, tot_dep_ant, ',
		'NVL(SUM(a12_valor_mb) * (-1), 0) tot_dep_act, a10_tot_dep_mb ',
		' FROM t1, tmp_a12 ',
		' WHERE a12_compania     = a10_compania ',
		'   AND a12_codigo_bien  = a10_codigo_bien ',
		'   AND DATE(a12_fecing) BETWEEN "', vm_fec_ini_dep,
					  '" AND "', vm_fecha_fin, '"',
		' GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 16 ',
		' UNION ',
		' SELECT a10_localidad, a10_grupo_act, a10_tipo_act, ',
			'a10_cod_depto, a10_codigo_bien, a10_estado, ',
			'a10_descripcion, a10_fecha_comp, a10_codprov, ',
			'a10_moneda, a10_valor_mb, a10_porc_deprec, ',
			'a10_val_dep_mb, tot_dep_ant, 0.00 tot_dep_act, ',
			'a10_tot_dep_mb ',
		' FROM t1, tmp_a12 ',
		' WHERE a10_estado      IN ("N", "E", "V", "D")',
		'   AND a12_compania     = a10_compania ',
		'   AND a12_codigo_bien  = a10_codigo_bien ',
		'   AND DATE(a12_fecing) < "', vm_fec_ini_dep, '"',
		' INTO TEMP t2 '
PREPARE expresion FROM query
EXECUTE expresion
DROP TABLE tmp_a12
DROP TABLE t1
SELECT a10_grupo_act, a10_tipo_act, a10_cod_depto, a10_codigo_bien, a10_estado,
	a10_descripcion, a10_fecha_comp, a10_codprov, a10_moneda, a10_valor_mb,
	a10_porc_deprec, a10_val_dep_mb, NVL(tot_dep_ant, 0) tot_dep_ant,
	NVL(SUM(tot_dep_act), 0) tot_dep_act, a10_tot_dep_mb
	FROM t2
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 15
	UNION
	SELECT a10_grupo_act, a10_tipo_act, a10_cod_depto, a10_codigo_bien,
		a10_estado, a10_descripcion, a10_fecha_comp, a10_codprov,
		a10_moneda, a10_valor_mb, a10_porc_deprec, a10_val_dep_mb,
		0.00 tot_dep_ant, 0.00 tot_dep_act, a10_tot_dep_mb
		FROM tmp_a10
		WHERE a10_grupo_act = 1
		  AND NOT EXISTS
			(SELECT 1 FROM t2
				WHERE t2.a10_codigo_bien =
					tmp_a10.a10_codigo_bien)
	UNION
	SELECT a10_grupo_act, a10_tipo_act, a10_cod_depto, a10_codigo_bien,
		a10_estado, a10_descripcion, a10_fecha_comp, a10_codprov,
		a10_moneda, a10_valor_mb, a10_porc_deprec, a10_val_dep_mb,
		0.00 tot_dep_ant, 0.00 tot_dep_act, a10_tot_dep_mb
		FROM tmp_a10, actt012 a
		WHERE a.a12_compania      = a10_compania
		  AND a.a12_codigo_tran   = 'IN'
		  AND a.a12_codigo_bien   = a10_codigo_bien
		  AND DATE(a.a12_fecing) <= vm_fecha_fin
			  AND NOT EXISTS
				(SELECT UNIQUE b.a12_codigo_tran
				FROM actt012 b
				WHERE b.a12_compania      = a.a12_compania
		  		  AND b.a12_codigo_tran   = 'DP'
		  		  AND b.a12_codigo_bien   = a.a12_codigo_bien
				  AND DATE(b.a12_fecing) >= vm_fecha_ini)
	INTO TEMP t3
DROP TABLE tmp_a10
DROP TABLE t2
SELECT a10_grupo_act, a10_tipo_act, a10_cod_depto, a10_codigo_bien, a10_estado,
	a10_descripcion, a10_fecha_comp, a10_codprov, a10_moneda, a10_valor_mb,
	a10_porc_deprec, a10_val_dep_mb, NVL(SUM(tot_dep_ant), 0) tot_dep_ant,
	NVL(SUM(tot_dep_act), 0) tot_dep_act
	FROM t3
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
	INTO TEMP t2
DROP TABLE t3
LET query = 'SELECT a10_grupo_act, a10_tipo_act, a10_cod_depto, ',
			'a10_codigo_bien, a10_estado, a10_descripcion, ',
			'a10_fecha_comp, a10_codprov, a10_moneda, ',
			'CASE WHEN NVL((SELECT 1 FROM tmp_baj ',
					'WHERE cod_bien  = a10_codigo_bien ',
					'  AND fecha    <= "',
							vm_fecha_fin, '"), ',
					'0) = 0 ',
				'THEN a10_valor_mb ',
				'ELSE 0.00 ',
			'END a10_valor_mb, ',
			'a10_porc_deprec, a10_val_dep_mb, tot_dep_ant, ',
			'tot_dep_act, ',
			'CASE WHEN NVL((SELECT 1 FROM tmp_baj ',
					'WHERE cod_bien  = a10_codigo_bien ',
					'  AND fecha    <= "',
							vm_fecha_fin, '"), ',
					'0) = 0 ',
				'THEN (tot_dep_ant + tot_dep_act) ',
				'ELSE 0.00 ',
			'END a10_tot_dep_mb ',
		' FROM t2 ',
		' INTO TEMP tmp_mov '
PREPARE exec_mov FROM query
EXECUTE exec_mov
DROP TABLE t2
DROP TABLE tmp_baj
LET query = 'SELECT a10_grupo_act, a10_tipo_act, a10_cod_depto, a10_estado, ',
			'a10_codigo_bien, a10_descripcion, a10_fecha_comp, ',
			'a10_codprov, a10_porc_deprec, a10_moneda, ',
			'a10_valor_mb, a10_tot_dep_mb, ',
			'CASE WHEN a10_estado = "V" OR a10_estado = "E" ',
				'THEN a10_valor_mb - a10_tot_dep_mb ',
				'ELSE (a10_valor_mb - (tot_dep_ant ',
						'+ tot_dep_act)) ',
				'END valor_actual ',
		'FROM tmp_mov ',
		'INTO TEMP tmp_act '
PREPARE exec_cons FROM query
EXECUTE exec_cons
DROP TABLE tmp_mov
DELETE FROM tmp_act
	WHERE a10_estado      IN ("V", "E")
	  AND valor_actual    <= 0
	  AND a10_codigo_bien IN
		(SELECT a.a10_codigo_bien
			FROM actt010 a
			WHERE a.a10_compania    = vg_codcia
			  AND a.a10_fecha_baja <= vm_fecha_fin)
SELECT COUNT(*) INTO cuantos FROM tmp_act
IF cuantos = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	DROP TABLE tmp_act
	RETURN 0
END IF
RETURN 1

END FUNCTION


    
REPORT report_activos(r_report, a10_grupo_act, a10_tipo_act, a10_cod_depto)
DEFINE r_report 	RECORD
				a10_estado	LIKE actt010.a10_estado,
				a10_codigo_bien	LIKE actt010.a10_codigo_bien,
				a10_descripcion	LIKE actt010.a10_descripcion,
				a10_fecha_comp	LIKE actt010.a10_fecha_comp,
				a10_codprov	LIKE actt010.a10_codprov,
				a10_porc_deprec	LIKE actt010.a10_porc_deprec,
				a10_moneda	LIKE actt010.a10_moneda,
				a10_valor	LIKE actt010.a10_valor,
				a10_tot_dep_mb	LIKE actt010.a10_tot_dep_mb,
				valor_actual	LIKE actt010.a10_tot_dep_mb
			END RECORD
DEFINE a10_grupo_act	LIKE actt010.a10_grupo_act
DEFINE a10_tipo_act	LIKE actt010.a10_tipo_act
DEFINE a10_cod_depto	LIKE actt010.a10_cod_depto
DEFINE r_a01		RECORD LIKE actt001.*
DEFINE r_a02		RECORD LIKE actt002.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE r_p01		RECORD LIKE cxpt001.*
DEFINE desc_est		VARCHAR(30)
DEFINE titulo		VARCHAR(80)
DEFINE escape		SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT
DEFINE act_neg, des_neg	SMALLINT

OUTPUT
	TOP MARGIN	vm_top
	LEFT MARGIN	vm_left
	RIGHT MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE LENGTH	vm_page

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	CALL fl_justifica_titulo('C', 'LISTADO DE ACTIVOS FIJOS', 80)
		RETURNING titulo
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 001, rg_cia.g01_razonsocial
	PRINT COLUMN 031, titulo CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 122, 'PAGINA: ', PAGENO USING '&&&'
	IF rm_a10.a10_grupo_act IS NOT NULL THEN
		CALL fl_lee_grupo_activo(vg_codcia, rm_a10.a10_grupo_act)
			RETURNING r_a01.*
		PRINT COLUMN 001, 'GRUPO DE ACTIVO    : ',
		      COLUMN 022, rm_a10.a10_grupo_act USING "<<<<<&", ' ',
				r_a01.a01_nombre
	END IF
	IF rm_a10.a10_tipo_act IS NOT NULL THEN
		CALL fl_lee_tipo_activo(vg_codcia, rm_a10.a10_tipo_act)
			RETURNING r_a02.*
		PRINT COLUMN 001, 'TIPO DE ACTIVO     : ',
		      COLUMN 022, rm_a10.a10_tipo_act USING "<<<<<&", ' ',
				r_a02.a02_nombre
	END IF
	IF rm_a10.a10_localidad IS NOT NULL THEN
		CALL fl_lee_localidad(vg_codcia, rm_a10.a10_localidad)
			RETURNING r_g02.*
		PRINT COLUMN 001, 'LOCALIDAD          : ',
		      COLUMN 022, rm_a10.a10_localidad USING "<<<<<&", ' ',
				r_g02.g02_nombre
	END IF
	CALL muestra_estado(rm_a10.a10_estado, 0) RETURNING desc_est
	PRINT COLUMN 001, 'RANGO DE FECHAS    : ',
		vm_fecha_ini USING "dd-mm-yyyy", ' - ',
		vm_fecha_fin USING "dd-mm-yyyy"
	PRINT COLUMN 001, 'ESTADO DEL ACTIVO  : ',
	      COLUMN 022, desc_est CLIPPED
	PRINT COLUMN 001, 'FECHA DE IMPRESION : ',
	      COLUMN 022, TODAY USING 'dd-mm-yyyy', 1 SPACES, TIME,
	      COLUMN 113, fl_justifica_titulo('D','USUARIO: ' || vg_usuario, 19)
	PRINT '------------------------------------------------------------------------------------------------------------------------------------'
	PRINT COLUMN 001, 'ESTADO',
	      COLUMN 012, 'CODIGO',
	      COLUMN 019, 'DESCRIPCION DEL BIEN',
	      COLUMN 053, 'FECHA ADQ.',
	      COLUMN 064, 'PROVEEDOR',
	      COLUMN 085, '% DEP.',
	      COLUMN 092, 'MO',
	      COLUMN 095, '  VALOR BIEN',
	      COLUMN 108, 'DEPREC.ACUM.',
	      COLUMN 121, 'VALOR LIBROS'
	PRINT '------------------------------------------------------------------------------------------------------------------------------------'

BEFORE GROUP OF a10_grupo_act
	NEED 18 LINES 
	LET vm_tot_val = 0
	LET vm_tot_dep = 0
	CALL fl_lee_grupo_activo(vg_codcia, a10_grupo_act) RETURNING r_a01.*
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 002, 'GRUPO DE ACTIVO: ', a10_grupo_act USING "<<<<<&",
		' ', r_a01.a01_nombre;
	print ASCII escape;
	print ASCII des_neg
	SKIP 1 LINES
	
BEFORE GROUP OF a10_tipo_act
	NEED 16 LINES 
	LET vm_tot_val_t = 0
	LET vm_tot_dep_t = 0
	CALL fl_lee_tipo_activo(vg_codcia, a10_tipo_act) RETURNING r_a02.*
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 002, 'TIPO DE ACTIVO : ', a10_tipo_act USING "<<<<<&",
		' ', r_a02.a02_nombre;
	print ASCII escape;
	print ASCII des_neg
	SKIP 1 LINES
	
BEFORE GROUP OF a10_cod_depto
	NEED 14 LINES 
	LET vm_tot_val_d = 0
	LET vm_tot_dep_d = 0
	CALL fl_lee_departamento(vg_codcia, a10_cod_depto) RETURNING r_g34.*
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 002, 'DEPARTAMENTO   : ', a10_cod_depto USING "<<<<<&",
		' ', r_g34.g34_nombre;
	print ASCII escape;
	print ASCII des_neg
	SKIP 1 LINES
	
ON EVERY ROW
	NEED 12 LINES 
	CALL muestra_estado(r_report.a10_estado, 0) RETURNING desc_est
	CALL fl_lee_proveedor(r_report.a10_codprov) RETURNING r_p01.*
	PRINT COLUMN 001, desc_est[1, 10]		CLIPPED,
	      COLUMN 012, r_report.a10_codigo_bien	USING "<<<<<&",
	      COLUMN 019, r_report.a10_descripcion[1, 33],
	      COLUMN 053, r_report.a10_fecha_comp	USING "dd-mm-yyyy",
	      COLUMN 064, r_p01.p01_nomprov[1, 20],
	      COLUMN 085, r_report.a10_porc_deprec	USING "##&.##",
	      COLUMN 092, r_report.a10_moneda,
	      COLUMN 095, r_report.a10_valor   		USING "#,###,##&.##",
	      COLUMN 108, r_report.a10_tot_dep_mb	USING "#,###,##&.##",
	      COLUMN 121, r_report.valor_actual		USING "#,###,##&.##"
	LET vm_tot_val   = vm_tot_val   + r_report.a10_valor
	LET vm_tot_dep   = vm_tot_dep   + r_report.a10_tot_dep_mb
	LET vm_tot_val_t = vm_tot_val_t + r_report.a10_valor
	LET vm_tot_dep_t = vm_tot_dep_t + r_report.a10_tot_dep_mb
	LET vm_tot_val_d = vm_tot_val_d + r_report.a10_valor
	LET vm_tot_dep_d = vm_tot_dep_d + r_report.a10_tot_dep_mb

AFTER GROUP OF a10_grupo_act
	NEED 11 LINES
	LET vm_tot_valor = vm_tot_valor + vm_tot_val
	LET vm_tot_dep_g = vm_tot_dep_g + vm_tot_dep
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 097, '------------',
	      COLUMN 110, '------------',
	      COLUMN 123, '------------'
	PRINT COLUMN 072, 'TOTALES DEL GRUPO ==>  ',
	      COLUMN 095, vm_tot_val			USING "#,###,##&.##",
	      COLUMN 108, vm_tot_dep			USING "#,###,##&.##",
	      COLUMN 121, vm_tot_val - vm_tot_dep	USING "#,###,##&.##";
	print ASCII escape;
	print ASCII des_neg
	SKIP 1 LINES

AFTER GROUP OF a10_tipo_act
	NEED 8 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 097, '------------',
	      COLUMN 110, '------------',
	      COLUMN 123, '------------'
	PRINT COLUMN 073, 'TOTALES DEL TIPO ==>  ',
	      COLUMN 095, vm_tot_val_t			USING "#,###,##&.##",
	      COLUMN 108, vm_tot_dep_t			USING "#,###,##&.##",
	      COLUMN 121, vm_tot_val_t - vm_tot_dep_t	USING "#,###,##&.##";
	print ASCII escape;
	print ASCII des_neg
	SKIP 1 LINES

AFTER GROUP OF a10_cod_depto
	NEED 5 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 097, '------------',
	      COLUMN 110, '------------',
	      COLUMN 123, '------------'
	PRINT COLUMN 071, 'TOTALES DEL DEPTO. ==>  ',
	      COLUMN 095, vm_tot_val_d			USING "#,###,##&.##",
	      COLUMN 108, vm_tot_dep_d			USING "#,###,##&.##",
	      COLUMN 121, vm_tot_val_d - vm_tot_dep_d	USING "#,###,##&.##";
	print ASCII escape;
	print ASCII des_neg
	SKIP 1 LINES

ON LAST ROW
	NEED 2 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 097, '------------',
	      COLUMN 110, '------------',
	      COLUMN 123, '------------'
	PRINT COLUMN 072, 'TOTALES GENERALES ==>  ',
	      COLUMN 095, vm_tot_valor                  USING "#,###,##&.##",
	      COLUMN 108, vm_tot_dep_g			USING '#,###,##&.##',
	      COLUMN 121, vm_tot_valor - vm_tot_dep_g	USING "#,###,##&.##";
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII desact_comp 

END REPORT
 


FUNCTION borrar_cabecera()

CLEAR FORM

END FUNCTION



FUNCTION muestra_estado(estado, flag)
DEFINE estado		LIKE actt010.a10_estado
DEFINE flag		SMALLINT
DEFINE r_a06		RECORD LIKE actt006.*
DEFINE tit_estado	LIKE actt006.a06_descripcion

LET tit_estado = NULL
CALL fl_lee_estado_activos(vg_codcia, estado) RETURNING r_a06.*
IF r_a06.a06_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Estado no existe.', 'exclamation')
	RETURN tit_estado
END IF
LET tit_estado = r_a06.a06_descripcion
IF flag THEN
	DISPLAY BY NAME tit_estado
END IF
RETURN tit_estado

END FUNCTION



FUNCTION control_archivo()
DEFINE mensaje		VARCHAR(100)

ERROR 'Generando Archivo actp400.unl ... por favor espere'
UNLOAD TO "../../../tmp/actp400.unl"
	SELECT a10_grupo_act, a01_nombre, a10_tipo_act, a02_nombre,
			a10_cod_depto, g34_nombre, a06_descripcion,
			a10_codigo_bien, a10_descripcion, a10_fecha_comp,
			a10_codprov, p01_nomprov, a10_porc_deprec, a10_valor_mb,
			a10_tot_dep_mb, valor_actual
		FROM tmp_act, actt006, actt001, actt002, gent034, cxpt001
		WHERE a06_compania  = vg_codcia
		  AND a06_estado    = a10_estado
		  AND a01_compania  = a06_compania
		  AND a01_grupo_act = a10_grupo_act
		  AND a02_compania  = a01_compania
		  AND a02_grupo_act = a01_grupo_act
		  AND a02_tipo_act  = a10_tipo_act
		  AND g34_compania  = a02_compania
		  AND g34_cod_depto = a10_cod_depto
		  AND p01_codprov   = a10_codprov
		ORDER BY a10_grupo_act, a10_tipo_act, a10_cod_depto,
			a10_codigo_bien
RUN "mv ../../../tmp/actp400.unl $HOME/tmp/"
LET mensaje = FGL_GETENV("HOME"), '/tmp/actp400.unl'
CALL fl_mostrar_mensaje('Archivo Generado en: ' || mensaje, 'info')
ERROR ' '

END FUNCTION
