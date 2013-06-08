--------------------------------------------------------------------------------
-- Titulo           : actp401.4gl - Listado de Depreciación Activos Fijos
-- Elaboracion      : 16-Jun-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun actp401 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_a00		RECORD LIKE actt000.*
DEFINE rm_a10		RECORD LIKE actt010.*
DEFINE vm_anio		SMALLINT
DEFINE vm_mes		SMALLINT
DEFINE vm_mespro	SMALLINT
DEFINE vm_anopro	SMALLINT
DEFINE tit_mes		VARCHAR(10)
DEFINE vm_tot_val	DECIMAL(14,2)
DEFINE vm_val_dep	DECIMAL(14,2)
DEFINE vm_tot_acum	DECIMAL(14,2)
DEFINE vm_tot_act	DECIMAL(14,2)
DEFINE vm_tot_dep	DECIMAL(14,2)
DEFINE vm_tot_lib	DECIMAL(14,2)
DEFINE vm_tot_valor	DECIMAL(14,2)
DEFINE vm_val_dep_g	DECIMAL(14,2)
DEFINE vm_tot_acum_g	DECIMAL(14,2)
DEFINE vm_tot_act_g	DECIMAL(14,2)
DEFINE vm_tot_dep_g	DECIMAL(14,2)
DEFINE vm_tot_lib_g	DECIMAL(14,2)
DEFINE vm_top		SMALLINT
DEFINE vm_left		SMALLINT
DEFINE vm_right		SMALLINT
DEFINE vm_bottom	SMALLINT
DEFINE vm_page		SMALLINT



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/actp401.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'actp401'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPEN WINDOW w_actf401_1 AT 3, 2 WITH 15 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 1)
OPEN FORM f_actf401_1 FROM "../forms/actf401_1"
DISPLAY FORM f_actf401_1
CALL fl_lee_compania_activos(vg_codcia) RETURNING rm_a00.*
IF rm_a00.a00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configurada ninguna compañía para Activos Fijos.', 'stop')
	CLOSE WINDOW w_actf401_1
	EXIT PROGRAM
END IF
IF rm_a00.a00_anopro = 2004 AND rm_a00.a00_mespro = 1 THEN
	CALL fl_mostrar_mensaje('No existe ninguna Depreciación Generada para Activos Fijos.', 'stop')
	CLOSE WINDOW w_actf401_1
	EXIT PROGRAM
END IF
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()

INITIALIZE rm_a10.* TO NULL
LET vm_top    = 1
LET vm_left   = 0
LET vm_right  = 160
LET vm_bottom = 4
LET vm_page   = 66
LET vm_anopro = rm_a00.a00_anopro
LET vm_mespro = rm_a00.a00_mespro - 1
IF vm_mespro = 0 THEN
	LET vm_mespro = 12
	LET vm_anopro = vm_anopro - 1
END IF
LET vm_mes    = vm_mespro
LET vm_anio   = vm_anopro
CALL fl_retorna_nombre_mes(vm_mes) RETURNING tit_mes
DISPLAY BY NAME tit_mes
LET rm_a10.a10_estado = 'X'
CALL muestra_estado(rm_a10.a10_estado)
WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL imprimir_listado()
END WHILE 
CLOSE WINDOW w_actf401_1

END FUNCTION



FUNCTION imprimir_listado()
DEFINE r_report 	RECORD
				a10_codigo_bien	LIKE actt010.a10_codigo_bien,
				a10_estado	LIKE actt010.a10_estado,
				a10_descripcion	LIKE actt010.a10_descripcion,
				a10_fecha_comp	LIKE actt010.a10_fecha_comp,
				a10_valor_mb	LIKE actt010.a10_valor_mb,
				a10_porc_deprec	LIKE actt010.a10_porc_deprec,
				a10_val_dep_mb	LIKE actt010.a10_val_dep_mb,
				a13_val_dep_acum LIKE actt013.a13_val_dep_acum,
				dep_acum_act	DECIMAL(14,2),
				a10_tot_dep_mb	LIKE actt010.a10_tot_dep_mb
			END RECORD
DEFINE grupo_act	LIKE actt010.a10_grupo_act
DEFINE query		CHAR(1500)
DEFINE expr_orden	VARCHAR(100)
DEFINE comando 		VARCHAR(100)

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
IF NOT preparar_tabla_trabajo() THEN
	RETURN
END IF
LET expr_orden = ' ORDER BY a10_grupo_act, a10_codigo_bien '
IF rm_a10.a10_grupo_act IS NOT NULL THEN
	LET expr_orden = ' ORDER BY a10_codigo_bien '
END IF
LET query = 'SELECT a10_codigo_bien, a10_estado, a10_descripcion, ',
			'a10_fecha_comp, a10_valor_mb, a10_porc_deprec, ',
			'a10_val_dep_mb, tot_dep_ant, tot_dep_act, ',
			'a10_tot_dep_mb, a10_grupo_act ',
		' FROM tmp_mov ',
		expr_orden CLIPPED
PREPARE reporte FROM query
DECLARE q_reporte CURSOR FOR reporte
START REPORT report_activos TO PIPE comando
LET vm_tot_valor  = 0
LET vm_val_dep_g  = 0
LET vm_tot_acum_g = 0
LET vm_tot_act_g  = 0
LET vm_tot_dep_g  = 0
LET vm_tot_lib_g  = 0
FOREACH q_reporte INTO r_report.*, grupo_act
	OUTPUT TO REPORT report_activos(r_report.*, grupo_act)
END FOREACH
FINISH REPORT report_activos
DROP TABLE tmp_mov

END FUNCTION



{--	FUNCION ANTERIOR DEL REPORTE. FALLAN TOTALES
FUNCTION imprimir_listado()
DEFINE r_report 	RECORD
				a10_codigo_bien	LIKE actt010.a10_codigo_bien,
				a10_estado	LIKE actt010.a10_estado,
				a10_descripcion	LIKE actt010.a10_descripcion,
				a10_fecha_comp	LIKE actt010.a10_fecha_comp,
				a10_valor_mb	LIKE actt010.a10_valor_mb,
				a10_porc_deprec	LIKE actt010.a10_porc_deprec,
				a10_val_dep_mb	LIKE actt010.a10_val_dep_mb,
				a13_val_dep_acum LIKE actt013.a13_val_dep_acum,
				dep_acum_act	DECIMAL(14,2),
				a10_tot_dep_mb	LIKE actt010.a10_tot_dep_mb
			END RECORD
DEFINE query		CHAR(1500)
DEFINE expr_loc		VARCHAR(100)
DEFINE expr_grupo	VARCHAR(100)
DEFINE expr_tipo	VARCHAR(100)
DEFINE expr_orden	VARCHAR(100)
DEFINE expr_act		VARCHAR(100)
DEFINE comando 		VARCHAR(100)
DEFINE fecha_dep	DATE
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE r_a13		RECORD LIKE actt013.*
DEFINE r_a14		RECORD LIKE actt014.*

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
LET expr_grupo = NULL
LET expr_orden = ' ORDER BY a10_grupo_act, a10_codigo_bien '
IF rm_a10.a10_grupo_act IS NOT NULL THEN
	LET expr_grupo = '   AND a10_grupo_act = ', rm_a10.a10_grupo_act
	LET expr_orden = ' ORDER BY a10_codigo_bien '
END IF
LET expr_tipo = NULL
IF rm_a10.a10_tipo_act IS NOT NULL THEN
	LET expr_tipo = '   AND a10_tipo_act = ', rm_a10.a10_tipo_act
END IF
LET expr_loc = NULL
IF rm_a10.a10_localidad IS NOT NULL THEN
	LET expr_loc = '   AND a10_localidad = ', rm_a10.a10_localidad
END IF
LET expr_act = NULL
IF rm_a10.a10_codigo_bien IS NOT NULL THEN
	LET expr_act = '   AND a10_codigo_bien = ', rm_a10.a10_codigo_bien
END IF
INITIALIZE r_a10.*, r_a13.* TO NULL
LET query = 'SELECT * FROM actt010, OUTER actt013 ',
		' WHERE a10_compania    = ', vg_codcia, ' ',
		expr_loc CLIPPED, ' ',
		expr_act CLIPPED, ' ',
		expr_grupo CLIPPED, ' ',
		expr_tipo CLIPPED, ' ',
		fl_retorna_expr_estado_act(vg_codcia,
						rm_a10.a10_estado, 1) CLIPPED,
		'   AND a13_compania    = a10_compania ',
		'   AND a13_codigo_bien = a10_codigo_bien ',
		'   AND a13_ano         = ', vm_anio - 1, ' ',
		expr_orden CLIPPED
PREPARE reporte FROM query
DECLARE q_reporte CURSOR FOR reporte
OPEN q_reporte
FETCH q_reporte
IF STATUS = NOTFOUND THEN
	CLOSE q_reporte
	FREE  q_reporte
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
START REPORT report_activos TO PIPE comando
LET vm_tot_valor  = 0
LET vm_val_dep_g  = 0
LET vm_tot_acum_g = 0
LET vm_tot_act_g  = 0
LET vm_tot_dep_g  = 0
LET vm_tot_lib_g  = 0
LET fecha_dep     = retorna_fecha_dep(vm_anio, vm_mes)
FOREACH q_reporte INTO r_a10.*, r_a13.*
	IF fecha_dep < r_a10.a10_fecha_comp THEN
		CONTINUE FOREACH
	END IF
	LET r_report.a10_codigo_bien  = r_a10.a10_codigo_bien
	LET r_report.a10_estado       = r_a10.a10_estado
	LET r_report.a10_descripcion  = r_a10.a10_descripcion
	LET r_report.a10_fecha_comp   = r_a10.a10_fecha_comp
	LET r_report.a10_valor_mb     = r_a10.a10_valor_mb
	LET r_report.a10_porc_deprec  = r_a10.a10_porc_deprec
	LET r_report.a10_val_dep_mb   = r_a10.a10_val_dep_mb
	LET r_report.a13_val_dep_acum = r_a13.a13_val_dep_acum
	IF r_a13.a13_val_dep_acum IS NULL THEN
		LET r_report.a13_val_dep_acum = 0
	END IF
	LET r_report.dep_acum_act     = 0
	LET r_report.a10_tot_dep_mb   = 0
	CALL fl_lee_depreciacion_mensual_activo(vg_codcia,r_a10.a10_codigo_bien,
						vm_anio, vm_mes)
		RETURNING r_a14.*
	IF r_a14.a14_compania IS NULL THEN
		SELECT * INTO r_a14.*
			FROM actt014
			WHERE a14_compania    = vg_codcia
			  AND a14_codigo_bien = r_a10.a10_codigo_bien
			  AND a14_fecing      IN
				(SELECT MAX(a14_fecing) FROM actt014
					WHERE a14_compania   = vg_codcia
					  AND a14_codigo_bien=
							 r_a10.a10_codigo_bien)
				
	END IF
	IF r_a14.a14_compania IS NOT NULL THEN
		LET r_report.a10_valor_mb     = r_a14.a14_valor_mb
		LET r_report.a10_porc_deprec  = r_a14.a14_porc_deprec
		LET r_report.a10_val_dep_mb   = r_a14.a14_val_dep_mb
		LET r_report.dep_acum_act     = r_a14.a14_dep_acum_act
		LET r_report.a10_tot_dep_mb   = r_a14.a14_tot_dep_mb
	END IF
	IF rm_a10.a10_estado = 'X' THEN
		IF retorna_fecha_dep(r_a14.a14_anio, r_a14.a14_mes) >=
		   fecha_dep
		THEN
			LET r_report.a10_val_dep_mb = 0
		END IF
		IF r_report.a10_tot_dep_mb = 0 THEN
			LET r_report.a10_tot_dep_mb =
						r_a10.a10_tot_dep_mb
		END IF
	END IF
	OUTPUT TO REPORT report_activos(r_report.*, r_a10.a10_grupo_act)
	IF int_flag THEN
		EXIT FOREACH
	END IF
	INITIALIZE r_a10.*, r_a13.* TO NULL
END FOREACH
FINISH REPORT report_activos

END FUNCTION
--}



FUNCTION lee_parametros()
DEFINE r_a01		RECORD LIKE actt001.*
DEFINE r_a02		RECORD LIKE actt002.*
DEFINE r_a06		RECORD LIKE actt006.*
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE estado		LIKE actt010.a10_estado
DEFINE anio		SMALLINT
DEFINE mes		SMALLINT
DEFINE mes_pro		VARCHAR(10)

INITIALIZE r_a01.*, r_a02.* TO NULL
LET int_flag = 0
INPUT BY NAME vm_anio, vm_mes, rm_a10.a10_localidad, rm_a10.a10_grupo_act,
	rm_a10.a10_tipo_act, rm_a10.a10_codigo_bien, rm_a10.a10_estado
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	ON KEY(F2)
		IF INFIELD(vm_mes) THEN
			CALL fl_ayuda_mostrar_meses() RETURNING vm_mes, tit_mes
			IF vm_mes IS NOT NULL THEN
				DISPLAY BY NAME vm_mes, tit_mes
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
		IF INFIELD(a10_codigo_bien) THEN
			CALL fl_ayuda_codigo_bien(vg_codcia,
						rm_a10.a10_grupo_act,
						rm_a10.a10_tipo_act,
						rm_a10.a10_estado, 0)
				RETURNING r_a10.a10_codigo_bien,
					  r_a10.a10_descripcion
			IF r_a10.a10_codigo_bien IS NOT NULL THEN
				LET rm_a10.a10_codigo_bien =
							r_a10.a10_codigo_bien
				LET rm_a10.a10_descripcion =
							r_a10.a10_descripcion
				DISPLAY BY NAME rm_a10.a10_codigo_bien,
						r_a10.a10_descripcion
			END IF
		END IF
		IF INFIELD(a10_estado) THEN
			CALL fl_ayuda_estado_activos(vg_codcia, 1)
				RETURNING r_a06.a06_estado,r_a06.a06_descripcion
			IF r_a06.a06_estado IS NOT NULL THEN
				LET rm_a10.a10_estado = r_a06.a06_estado
				CALL muestra_estado(rm_a10.a10_estado)
			END IF
		END IF
		LET int_flag = 0
	BEFORE FIELD vm_anio
		LET anio = vm_anio
	BEFORE FIELD vm_mes
		LET mes = vm_mes
	BEFORE FIELD a10_estado
		LET estado = rm_a10.a10_estado
	AFTER FIELD vm_anio
		IF vm_anio IS NOT NULL THEN
			IF vm_anio > vm_anopro THEN
				CALL fl_mostrar_mensaje('El año no puede ser mayor al año vigente de Activos Fijos.', 'exclamation')
				NEXT FIELD vm_anio
			END IF
			IF vm_anio > YEAR(TODAY) THEN
				CALL fl_mostrar_mensaje('El año no puede ser mayor al año vigente.', 'exclamation')
				--NEXT FIELD vm_anio
			END IF
			IF vm_anio <= 2003 THEN
				CALL fl_mostrar_mensaje('El año no puede ser menor al año 2004, que es el año de arranque del Modulo Activos Fijos.', 'exclamation')
				NEXT FIELD vm_anio
			END IF
		ELSE
			LET vm_anio = anio
			DISPLAY BY NAME vm_anio
		END IF
	AFTER FIELD vm_mes
		IF vm_mes IS NULL THEN
			LET vm_mes = mes
			DISPLAY BY NAME vm_mes
		END IF
		CALL fl_retorna_nombre_mes(vm_mes) RETURNING tit_mes
		DISPLAY BY NAME tit_mes
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
	AFTER FIELD a10_codigo_bien
		IF rm_a10.a10_codigo_bien IS NOT NULL THEN
			CALL fl_lee_codigo_bien(vg_codcia,
						rm_a10.a10_codigo_bien)
				RETURNING r_a10.*
			IF r_a10.a10_compania IS NULL THEN
				CALL fl_mostrar_mensaje('Este codigo de activo fijo no existe en la compania.', 'exclamation')
				NEXT FIELD a10_codigo_bien
			END IF
			LET rm_a10.a10_descripcion = r_a10.a10_descripcion
		ELSE
			LET rm_a10.a10_descripcion = NULL
		END IF
		DISPLAY BY NAME rm_a10.a10_descripcion
	AFTER FIELD a10_estado
		IF rm_a10.a10_estado IS NULL THEN
			LET rm_a10.a10_estado = estado
		END IF
		IF rm_a10.a10_estado = 'A' OR rm_a10.a10_estado = 'B' THEN
			CALL fl_mostrar_mensaje('No puede escojer estado ACTIVO o BLOQUEADO.', 'exclamation')
			LET rm_a10.a10_estado = 'X'
		END IF
		CALL muestra_estado(rm_a10.a10_estado)
	AFTER INPUT
		IF vm_anio = vm_anopro THEN
			IF vm_mes > vm_mespro THEN
				CALL fl_retorna_nombre_mes(vm_mespro)
					RETURNING mes_pro
				CALL fl_justifica_titulo ('I', mes_pro, 10)
					RETURNING mes_pro
				CALL fl_mostrar_mensaje('El mes debe ser menor o igual al mes de ' || mes_pro CLIPPED || ' que es el mes de proceso de Activos Fijos.', 'exclamation')
				NEXT FIELD vm_mes
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION preparar_tabla_trabajo()
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE query		CHAR(6000)
DEFINE exp_gru		VARCHAR(100)
DEFINE exp_tip		VARCHAR(100)
DEFINE exp_loc		VARCHAR(100)
DEFINE exp_act		VARCHAR(100)
DEFINE fec_ini, fec_fin	DATE
DEFINE cuantos		INTEGER

LET fec_ini = MDY(01, 01, vm_anio)
LET fec_fin = MDY(vm_mes, 01, vm_anio) + 1 UNITS MONTH - 1 UNITS DAY
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
LET exp_act = NULL
IF rm_a10.a10_codigo_bien IS NOT NULL THEN
	LET exp_act = '   AND a10_codigo_bien  = ', rm_a10.a10_codigo_bien
END IF
SELECT UNIQUE a12_compania cia, a12_codigo_bien cod_bien, DATE(a12_fecing) fecha
	FROM actt012
	WHERE a12_compania      = vg_codcia
	  AND a12_codigo_tran  IN ("BA", "VE", "BV")
	  AND DATE(a12_fecing) <= fec_fin
	INTO TEMP tmp_baj
LET query = 'SELECT * FROM actt010 ',
		' WHERE a10_compania     = ', vg_codcia,
		exp_loc CLIPPED,
		exp_gru CLIPPED,
		exp_tip CLIPPED,
		exp_act CLIPPED,
		fl_retorna_expr_estado_act(vg_codcia, rm_a10.a10_estado,
						1) CLIPPED,
		'   AND a10_codigo_bien NOT IN ',
				'(SELECT cod_bien ',
					'FROM tmp_baj ',
					'WHERE fecha < "', fec_ini, '") ',
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
		'   AND DATE(a.a12_fecing) <= "', fec_fin, '"',
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
			'   AND DATE(a.a12_fecing) <= "', fec_fin, '"',
		' INTO TEMP tmp_a12 '
PREPARE exec_a12 FROM query
EXECUTE exec_a12
LET query = 'SELECT a10_compania, a10_localidad, a10_grupo_act, ',
			'a10_codigo_bien, a10_estado, a10_descripcion, ',
			'a10_fecha_comp, a10_valor_mb, a10_porc_deprec, ',
			'a10_val_dep_mb, ',
			'NVL(SUM(a12_valor_mb) * (-1), 0) tot_dep_ant, ',
			'a10_tot_dep_mb ',
		' FROM tmp_a10, tmp_a12 ',
		' WHERE a12_compania     = a10_compania ',
		'   AND a12_codigo_bien  = a10_codigo_bien ',
		'   AND DATE(a12_fecing) < "', fec_ini, '"',
		' GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12 ',
		' UNION',
		' SELECT a10_compania, a10_localidad, a10_grupo_act, ',
			'a10_codigo_bien, a10_estado, a10_descripcion, ',
			'a10_fecha_comp, a10_valor_mb, a10_porc_deprec, ',
			'a10_val_dep_mb, 0.00 tot_dep_ant, a10_tot_dep_mb ',
		' FROM tmp_a10, tmp_a12 ',
		' WHERE a12_compania     = a10_compania ',
		'   AND a12_codigo_bien  = a10_codigo_bien ',
		'   AND EXTEND(a12_fecing, YEAR TO MONTH) <= ',
			'EXTEND(DATE("', fec_fin, '"), YEAR TO MONTH) ',
		' INTO TEMP tt '
PREPARE exec_tt FROM query
EXECUTE exec_tt
SELECT a10_compania, a10_localidad, a10_grupo_act, a10_codigo_bien, a10_estado,
	a10_descripcion, a10_fecha_comp, a10_valor_mb, a10_porc_deprec,
	a10_val_dep_mb, NVL(SUM(tot_dep_ant), 0) tot_dep_ant, a10_tot_dep_mb
	FROM tt
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12
	INTO TEMP t1
DROP TABLE tt
LET query = 'SELECT a10_localidad, a10_grupo_act, a10_codigo_bien, a10_estado,',
		' a10_descripcion, a10_fecha_comp, a10_valor_mb,',
		' a10_porc_deprec, a10_val_dep_mb, tot_dep_ant, ',
		'NVL(SUM(a12_valor_mb) * (-1), 0) tot_dep_act, a10_tot_dep_mb ',
		' FROM t1, tmp_a12 ',
		' WHERE a12_compania     = a10_compania ',
		'   AND a12_codigo_bien  = a10_codigo_bien ',
		'   AND DATE(a12_fecing) BETWEEN "', fec_ini,
					  '" AND "', fec_fin, '"',
		' GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12 ',
		' UNION ',
		' SELECT a10_localidad, a10_grupo_act, a10_codigo_bien, ',
			'a10_estado, a10_descripcion, a10_fecha_comp, ',
			'a10_valor_mb, a10_porc_deprec, a10_val_dep_mb, ',
			'tot_dep_ant, 0.00 tot_dep_act, a10_tot_dep_mb ',
		' FROM t1, tmp_a12 ',
		' WHERE a10_estado      IN ("N", "E", "V", "D")',
		'   AND a12_compania     = a10_compania ',
		'   AND a12_codigo_bien  = a10_codigo_bien ',
		'   AND DATE(a12_fecing) < "', fec_ini, '"',
		' INTO TEMP t2 '
PREPARE expresion FROM query
EXECUTE expresion
DROP TABLE tmp_a12
DROP TABLE t1
SELECT a10_codigo_bien, a10_estado, a10_descripcion, a10_fecha_comp,
	a10_valor_mb, a10_porc_deprec, a10_val_dep_mb,
	NVL(tot_dep_ant, 0) tot_dep_ant,
	NVL(SUM(tot_dep_act), 0) tot_dep_act, a10_tot_dep_mb, a10_grupo_act
	FROM t2
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 10, 11
	UNION
	SELECT a10_codigo_bien, a10_estado, a10_descripcion, a10_fecha_comp,
		a10_valor_mb, a10_porc_deprec, a10_val_dep_mb, 0.00 tot_dep_ant,
		0.00 tot_dep_act, a10_tot_dep_mb, a10_grupo_act
		FROM tmp_a10
		WHERE a10_grupo_act = 1
		  AND NOT EXISTS
			(SELECT 1 FROM t2
				WHERE t2.a10_codigo_bien =
					tmp_a10.a10_codigo_bien)
	INTO TEMP t3
DROP TABLE tmp_a10
DROP TABLE t2
SELECT a10_codigo_bien, a10_estado, a10_descripcion, a10_fecha_comp,
	a10_valor_mb, a10_porc_deprec, a10_val_dep_mb,
	NVL(SUM(tot_dep_ant), 0) tot_dep_ant,
	NVL(SUM(tot_dep_act), 0) tot_dep_act, a10_grupo_act
	FROM t3
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 10
	INTO TEMP t2
DROP TABLE t3
LET query = 'SELECT a10_codigo_bien, a10_estado, a10_descripcion, ',
			'a10_fecha_comp, ',
			'CASE WHEN NVL((SELECT 1 FROM tmp_baj ',
					'WHERE cod_bien  = a10_codigo_bien ',
					'  AND fecha    <= "', fec_fin, '"), ',
					'0) = 0 ',
				'THEN a10_valor_mb ',
				'ELSE 0.00 ',
			'END a10_valor_mb, ',
			'a10_porc_deprec, a10_val_dep_mb, ',
			'CASE WHEN NVL((SELECT 1 FROM tmp_baj ',
					'WHERE cod_bien  = a10_codigo_bien ',
					'  AND fecha    <= "', fec_fin, '"), ',
					'0) = 0 ',
				'THEN tot_dep_ant ',
				'ELSE CASE WHEN a10_estado = "V" ',
					'THEN (tot_dep_act) * (-1) ',
					'ELSE 0.00 ',
					'END ',
			'END tot_dep_ant, ',
			'tot_dep_act, ',
			'CASE WHEN NVL((SELECT 1 FROM tmp_baj ',
					'WHERE cod_bien  = a10_codigo_bien ',
					'  AND fecha    <= "', fec_fin, '"), ',
					'0) = 0 ',
				'THEN (tot_dep_ant + tot_dep_act) ',
				'ELSE 0.00 ',
			'END a10_tot_dep_mb, ',
			'a10_grupo_act ',
		' FROM t2 ',
		' INTO TEMP tmp_mov '
PREPARE exec_mov FROM query
EXECUTE exec_mov
DROP TABLE t2
DROP TABLE tmp_baj
SELECT COUNT(*) INTO cuantos FROM tmp_mov
IF cuantos = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	DROP TABLE tmp_mov
	RETURN 0
END IF
RETURN 1

END FUNCTION



REPORT report_activos(r_report, a10_grupo_act)
DEFINE r_report 	RECORD
				a10_codigo_bien	LIKE actt010.a10_codigo_bien,
				a10_estado	LIKE actt010.a10_estado,
				a10_descripcion	LIKE actt010.a10_descripcion,
				a10_fecha_comp	LIKE actt010.a10_fecha_comp,
				a10_valor_mb	LIKE actt010.a10_valor_mb,
				a10_porc_deprec	LIKE actt010.a10_porc_deprec,
				a10_val_dep_mb	LIKE actt010.a10_val_dep_mb,
				a13_val_dep_acum LIKE actt013.a13_val_dep_acum,
				dep_acum_act	DECIMAL(14,2),
				a10_tot_dep_mb	LIKE actt010.a10_tot_dep_mb
			END RECORD
DEFINE a10_grupo_act	LIKE actt010.a10_grupo_act
DEFINE r_a01		RECORD LIKE actt001.*
DEFINE r_a02		RECORD LIKE actt002.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE desc_est		VARCHAR(30)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE usuario		VARCHAR(19,15)
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT

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
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	LET modulo      = "MODULO: ACTIVOS FIJOS"
	CALL fl_justifica_titulo('D', 'USUARIO: ' || vg_usuario, 19)
		RETURNING usuario
	CALL fl_justifica_titulo('C', 'LISTADO DEPRECIACION DE ACTIVOS FIJOS',
				160)
		RETURNING titulo
	LET titulo      = modulo, titulo
	print ASCII escape;
	print ASCII act_12cpi;
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 001, rg_cia.g01_razonsocial,
	      COLUMN 150, 'PAGINA: ', PAGENO USING '&&&'
	PRINT COLUMN 001, titulo CLIPPED,
	      COLUMN 154, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 054, 'ANIO               : ', vm_anio USING "&&&&"
	PRINT COLUMN 054, 'MES                : ', vm_mes  USING "&&", ' ',
		fl_justifica_titulo ('I', tit_mes, 10)
	IF rm_a10.a10_localidad IS NOT NULL THEN
		CALL fl_lee_localidad(vg_codcia, rm_a10.a10_localidad)
			RETURNING r_g02.*
		PRINT COLUMN 054, 'LOCALIDAD          : ',
			rm_a10.a10_localidad USING "&&", ' ',
			r_g02.g02_nombre CLIPPED
	END IF
	IF rm_a10.a10_grupo_act IS NOT NULL THEN
		CALL fl_lee_grupo_activo(vg_codcia, rm_a10.a10_grupo_act)
			RETURNING r_a01.*
		PRINT COLUMN 054, 'GRUPO DE ACTIVO    : ',
			rm_a10.a10_grupo_act USING "&&", ' ',
			r_a01.a01_nombre CLIPPED
	END IF
	IF rm_a10.a10_tipo_act IS NOT NULL THEN
		CALL fl_lee_tipo_activo(vg_codcia, rm_a10.a10_tipo_act)
			RETURNING r_a02.*
		PRINT COLUMN 054, 'TIPO DE ACTIVO     : ',
			rm_a10.a10_tipo_act USING "&&&", ' ',
			r_a02.a02_nombre CLIPPED
	END IF
	CALL retorna_estado() RETURNING desc_est
	PRINT COLUMN 054, 'ESTADO DEL ACTIVO  : ', desc_est CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA DE IMPRESION: ", TODAY USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 142, usuario CLIPPED
	PRINT COLUMN 001, '----------------------------------------------------------------------------------------------------------------------------------------------------------------'
	PRINT COLUMN 001, 'CODIGO',
	      COLUMN 010, 'E',
	      COLUMN 014, 'D E S C R I P C I O N   D E L   B I E N',
	      COLUMN 057, 'FECHA COMP',
	      COLUMN 069, '  VALOR BIEN',
	      COLUMN 083, '% DEP.',
	      COLUMN 091, 'V. DEPR. MES',
	      --COLUMN 105, 'DEP. ANIO A.',
	      COLUMN 104, ' DEP.ACU. ANT',
	      --COLUMN 119, 'D. ACUM.ACT.',
	      COLUMN 119, 'DEP/VTA/BAJA',
	      COLUMN 133, 'DEPREC. ACUM.',
	      COLUMN 148, 'VALOR LIBROS'
	PRINT COLUMN 001, '----------------------------------------------------------------------------------------------------------------------------------------------------------------'

BEFORE GROUP OF a10_grupo_act
	SKIP TO TOP OF PAGE
	NEED 8 LINES 
	LET vm_tot_val  = 0
	LET vm_val_dep  = 0
	LET vm_tot_acum = 0
	LET vm_tot_act  = 0
	LET vm_tot_dep  = 0
	LET vm_tot_lib  = 0
	CALL fl_lee_grupo_activo(vg_codcia, a10_grupo_act) RETURNING r_a01.*
	PRINT COLUMN 001, 'GRUPO DE ACTIVO: ', a10_grupo_act USING "&&", ' ',
		r_a01.a01_nombre CLIPPED
	SKIP 1 LINES
	
ON EVERY ROW
	NEED 6 LINES 
	PRINT COLUMN 001, r_report.a10_codigo_bien	USING "<<<&&&",
	      COLUMN 010, r_report.a10_estado,
	      COLUMN 014, r_report.a10_descripcion	CLIPPED,
	      COLUMN 057, r_report.a10_fecha_comp	USING "dd-mm-yyyy",
	      COLUMN 069, r_report.a10_valor_mb		USING "#,###,##&.##",
	      COLUMN 083, r_report.a10_porc_deprec	USING "##&.##",
	      COLUMN 091, r_report.a10_val_dep_mb	USING "#,###,##&.##",
	      COLUMN 104, r_report.a13_val_dep_acum	USING '((,(((,((&.##)',
	      COLUMN 119, r_report.dep_acum_act		USING "#,###,##&.##",
	      COLUMN 133, r_report.a10_tot_dep_mb	USING "##,###,##&.##",
	      COLUMN 148, (r_report.a10_valor_mb - r_report.a10_tot_dep_mb)
			USING "##,###,##&.##"
	LET vm_tot_val  = vm_tot_val  + r_report.a10_valor_mb
	LET vm_val_dep  = vm_val_dep  + r_report.a10_val_dep_mb
	LET vm_tot_acum = vm_tot_acum + r_report.a13_val_dep_acum
	LET vm_tot_act  = vm_tot_act  + r_report.dep_acum_act
	LET vm_tot_dep  = vm_tot_dep  + r_report.a10_tot_dep_mb
	LET vm_tot_lib  = vm_tot_lib  +
			(r_report.a10_valor_mb - r_report.a10_tot_dep_mb)

AFTER GROUP OF a10_grupo_act
	NEED 5 LINES
	LET vm_tot_valor  = vm_tot_valor  + vm_tot_val
	LET vm_val_dep_g  = vm_val_dep_g  + vm_val_dep
	LET vm_tot_acum_g = vm_tot_acum_g + vm_tot_acum
	LET vm_tot_act_g  = vm_tot_act_g  + vm_tot_act
	LET vm_tot_dep_g  = vm_tot_dep_g  + vm_tot_dep
	LET vm_tot_lib_g  = vm_tot_lib_g  + vm_tot_lib
	PRINT COLUMN 069, '------------',
	      COLUMN 091, '------------',
	      COLUMN 104, '--------------',
	      COLUMN 119, '------------',
	      COLUMN 133, '-------------',
	      COLUMN 148, '-------------'
	PRINT COLUMN 046, 'TOTALES DEL GRUPO ==>  ',
	      COLUMN 069, vm_tot_val                    USING "#,###,##&.##",
	      COLUMN 091, vm_val_dep			USING "#,###,##&.##",
	      COLUMN 104, vm_tot_acum			USING '((,(((,((&.##)',
	      COLUMN 119, vm_tot_act			USING "#,###,##&.##",
	      COLUMN 133, vm_tot_dep			USING "##,###,##&.##",
	      COLUMN 148, vm_tot_lib			USING "##,###,##&.##"
	SKIP 1 LINES

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 069, '------------',
	      COLUMN 091, '------------',
	      COLUMN 104, '--------------',
	      COLUMN 119, '------------',
	      COLUMN 133, '-------------',
	      COLUMN 148, '-------------'
	PRINT COLUMN 046, 'TOTALES GENERALES ==>  ',
	      COLUMN 069, vm_tot_valor                  USING "#,###,##&.##",
	      COLUMN 091, vm_val_dep_g			USING '#,###,##&.##',
	      COLUMN 104, vm_tot_acum_g			USING '((,(((,((&.##)',
	      COLUMN 119, vm_tot_act_g			USING "#,###,##&.##",
	      COLUMN 133, vm_tot_dep_g			USING '##,###,##&.##',
	      COLUMN 148, vm_tot_lib_g			USING '##,###,##&.##';
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



FUNCTION retorna_estado()
DEFINE r_a06		RECORD LIKE actt006.*

CALL fl_lee_estado_activos(vg_codcia, rm_a10.a10_estado) RETURNING r_a06.*
IF r_a06.a06_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Estado no existe.', 'exclamation')
END IF
RETURN r_a06.a06_descripcion

END FUNCTION



FUNCTION muestra_estado(estado)
DEFINE estado		LIKE actt010.a10_estado
DEFINE r_a06		RECORD LIKE actt006.*

CALL fl_lee_estado_activos(vg_codcia, estado) RETURNING r_a06.*
IF r_a06.a06_compania IS NULL THEN
	CALL fl_mostrar_mensaje('Estado no existe.', 'exclamation')
	LET rm_a10.a10_estado = NULL
END IF
IF r_a06.a06_estado = 'S' THEN
	LET r_a06.a06_descripcion = 'DEPRECIANDOSE'
END IF
DISPLAY BY NAME rm_a10.a10_estado, r_a06.a06_descripcion

END FUNCTION



FUNCTION borrar_cabecera()

CLEAR FORM
INITIALIZE rm_a10.*, vm_anio, vm_mes TO NULL

END FUNCTION



FUNCTION retorna_fecha_dep(v_a, v_m)
DEFINE v_a, v_m		SMALLINT
DEFINE mes, ano		SMALLINT
DEFINE fecha_comp	DATE

LET mes = v_m + 1
LET ano = v_a
IF v_m = 12 THEN
	LET mes = 1
	LET ano = ano + 1
END IF
LET fecha_comp = MDY(mes, 01, ano) - 1 UNITS DAY
RETURN fecha_comp

END FUNCTION
