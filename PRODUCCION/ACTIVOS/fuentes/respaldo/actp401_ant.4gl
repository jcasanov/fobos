------------------------------------------------------------------------------
-- Titulo           : actp401.4gl - Listado de Depreciación Activos Fijos
-- Elaboracion      : 16-Jun-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun actp401 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
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
DEFINE vm_tot_valor	DECIMAL(14,2)
DEFINE vm_val_dep_g	DECIMAL(14,2)
DEFINE vm_tot_acum_g	DECIMAL(14,2)
DEFINE vm_tot_act_g	DECIMAL(14,2)
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
CALL startlog('../logs/actp401.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
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
OPEN WINDOW w_mas AT 3, 2 WITH 20 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 1)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rep FROM "../forms/actf401_1"
DISPLAY FORM f_rep
CALL fl_lee_compania_activos(vg_codcia) RETURNING rm_a00.*
IF rm_a00.a00_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe configurada ninguna compañía para Activos Fijos.', 'stop')
	EXIT PROGRAM
END IF
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
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
DEFINE query		VARCHAR(1200)
DEFINE expr_loc		VARCHAR(100)
DEFINE expr_estado	VARCHAR(100)
DEFINE expr_grupo	VARCHAR(100)
DEFINE expr_tipo	VARCHAR(100)
DEFINE expr_orden	VARCHAR(100)
DEFINE comando 		VARCHAR(100)
DEFINE fecha_dep	DATE
DEFINE fecha		DATE
DEFINE val_mes		INTEGER
DEFINE dias		INTEGER
DEFINE long		SMALLINT
DEFINE r_a10		RECORD LIKE actt010.*
DEFINE r_a13		RECORD LIKE actt013.*
DEFINE r_g02		RECORD LIKE gent002.*

LET vm_top    = 1
LET vm_left   = 0
LET vm_right  = 132
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
LET rm_a10.a10_estado    = 'T'
LET rm_a10.a10_localidad = vg_codloc
CALL fl_lee_localidad(vg_codcia, rm_a10.a10_localidad) RETURNING r_g02.*
DISPLAY BY NAME r_g02.g02_nombre 
WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	CALL retorna_expr_est() RETURNING expr_estado
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
	INITIALIZE r_a10.*, r_a13.* TO NULL
	LET query = 'SELECT * FROM actt010, OUTER actt013 ',
			' WHERE a10_compania    = ', vg_codcia, ' ',
			expr_loc CLIPPED, ' ',
			expr_grupo CLIPPED, ' ',
			expr_tipo CLIPPED, ' ',
			expr_estado CLIPPED, ' ',
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
		CONTINUE WHILE
	END IF
	START REPORT report_activos TO PIPE comando
	LET vm_tot_valor  = 0
	LET vm_val_dep_g  = 0
	LET vm_tot_acum_g = 0
	LET vm_tot_act_g  = 0
	LET vm_tot_dep_g  = 0
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
--OJO
		{-- SIRVE PARA OTRO PROGRAMA
		LET val_mes   = 0
		LET val_mes_c = NULL
		SELECT EXTEND(DATE(fecha_dep), YEAR TO MONTH) -
				DATE(r_a10.a10_fecha_comp)
			INTO val_mes_c
			FROM dual
		LET long    = LENGTH(val_mes_c)
		LET val_mes = val_mes_c[long - 1, long]
		LET val_ano = val_mes_c[1, long - 3] * 12
		LET val_mes = val_mes + val_ano
		IF val_mes = 0 THEN
			LET val_mes = 1
		END IF
		--}
		LET val_mes = vm_mes
		LET dias    = NULL
		LET fecha   = NULL
		IF vm_anio = vm_anopro THEN
			IF vm_mes > vm_mespro THEN
				LET val_mes = rm_a00.a00_mespro
			END IF
			IF vm_anio = YEAR(r_a10.a10_fecha_comp) THEN
				LET val_mes = val_mes -
						MONTH(r_a10.a10_fecha_comp)
				LET fecha   = retorna_fecha_dep(
						   YEAR(r_a10.a10_fecha_comp),
						   MONTH(r_a10.a10_fecha_comp))
				LET dias    = fecha - r_a10.a10_fecha_comp
			END IF
		END IF
		LET r_report.dep_acum_act   = r_report.a10_val_dep_mb * val_mes
		IF vm_anio = YEAR(r_a10.a10_fecha_comp) THEN
			LET r_report.dep_acum_act = r_report.dep_acum_act +
				((r_report.a10_val_dep_mb * dias) / DAY(fecha))
		END IF
		LET r_report.a10_tot_dep_mb = r_report.a13_val_dep_acum +
						r_report.dep_acum_act
		OUTPUT TO REPORT report_activos(r_report.*, r_a10.a10_grupo_act)
		IF int_flag THEN
			EXIT FOREACH
		END IF
		INITIALIZE r_a10.*, r_a13.* TO NULL
	END FOREACH
	FINISH REPORT report_activos
END WHILE 

END FUNCTION



FUNCTION retorna_expr_est()
DEFINE expr		VARCHAR(100)

LET expr = NULL
IF rm_a10.a10_estado <> 'T' THEN
	IF rm_a10.a10_estado <> 'X' THEN
		LET expr = '   AND a10_estado = "', rm_a10.a10_estado, '"'
	ELSE
		LET expr = '   AND a10_estado IN ("S", "D") '
	END IF
ELSE
	LET expr = '   AND a10_estado IN ("A", "B", "S", "D", "V", "E") '
END IF
RETURN expr

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_a01		RECORD LIKE actt001.*
DEFINE r_a02		RECORD LIKE actt002.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE anio		SMALLINT
DEFINE mes		SMALLINT
DEFINE mes_pro		VARCHAR(10)

INITIALIZE r_a01.*, r_a02.* TO NULL
LET int_flag = 0
INPUT BY NAME vm_anio, vm_mes, rm_a10.a10_localidad, rm_a10.a10_grupo_act,
	rm_a10.a10_tipo_act, rm_a10.a10_estado
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
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
			CALL fl_ayuda_tipo_activo(vg_codcia) 
				RETURNING r_a02.a02_tipo_act, r_a02.a02_nombre
			IF r_a02.a02_tipo_act IS NOT NULL THEN
				LET rm_a10.a10_tipo_act = r_a02.a02_tipo_act
				DISPLAY BY NAME rm_a10.a10_tipo_act
				DISPLAY r_a02.a02_nombre TO tit_tipo_act
			END IF 
		END IF
		LET int_flag = 0
	BEFORE FIELD vm_anio
		LET anio = vm_anio
	BEFORE FIELD vm_mes
		LET mes = vm_mes
	AFTER FIELD vm_anio
		IF vm_anio IS NOT NULL THEN
			IF vm_anio > vm_anopro THEN
				CALL fl_mostrar_mensaje('El año no puede ser mayor al año vigente de Activos Fijos.', 'exclamation')
				NEXT FIELD vm_anio
			END IF
			IF vm_anio > YEAR(TODAY) THEN
				CALL fl_mostrar_mensaje('El año no puede ser mayor al año vigente.', 'exclamation')
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
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT

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
	LET modulo      = "MODULO: ACTIVOS FIJOS"
	CALL fl_justifica_titulo('D', 'USUARIO: ' || vg_usuario, 19)
		RETURNING usuario
	CALL fl_justifica_titulo('C', 'LISTADO DEPRECIACION DE ACTIVOS FIJOS',
				80)
		RETURNING titulo
	LET titulo      = modulo, titulo
	print ASCII escape;
	print ASCII act_comp
	PRINT COLUMN 001, rg_cia.g01_razonsocial,
	      COLUMN 122, 'PAGINA: ', PAGENO USING '&&&'
	PRINT COLUMN 001, titulo CLIPPED,
	      COLUMN 126, UPSHIFT(vg_proceso)
	SKIP 1 LINES
	PRINT COLUMN 034, 'ANIO               : ', 
	      COLUMN 055, vm_anio	USING "<<<&"
	PRINT COLUMN 034, 'MES                : ', 
	      COLUMN 055, vm_mes	USING "<&", ' ',
			fl_justifica_titulo ('I', tit_mes, 10)
	IF rm_a10.a10_localidad IS NOT NULL THEN
		CALL fl_lee_localidad(vg_codcia, rm_a10.a10_localidad)
			RETURNING r_g02.*
		PRINT COLUMN 034, 'LOCALIDAD          : ',
		      COLUMN 055, rm_a10.a10_localidad USING "<<<<<&", ' ',
				r_g02.g02_nombre
	END IF
	IF rm_a10.a10_grupo_act IS NOT NULL THEN
		CALL fl_lee_grupo_activo(vg_codcia, rm_a10.a10_grupo_act)
			RETURNING r_a01.*
		PRINT COLUMN 034, 'GRUPO DE ACTIVO    : ',
		      COLUMN 055, rm_a10.a10_grupo_act USING "<<<<<&", ' ',
				r_a01.a01_nombre
	END IF
	IF rm_a10.a10_tipo_act IS NOT NULL THEN
		CALL fl_lee_tipo_activo(vg_codcia, rm_a10.a10_tipo_act)
			RETURNING r_a02.*
		PRINT COLUMN 034, 'TIPO DE ACTIVO     : ',
		      COLUMN 055, rm_a10.a10_tipo_act USING "<<<<<&", ' ',
				r_a02.a02_nombre
	END IF
	CALL retorna_estado() RETURNING desc_est
	PRINT COLUMN 034, 'ESTADO DEL ACTIVO  : ',
	      COLUMN 055, desc_est
	SKIP 1 LINES
	PRINT COLUMN 001, 'FECHA DE IMPRESION : ',
	      COLUMN 022, TODAY USING 'dd-mm-yyyy', 1 SPACES, TIME,
	      COLUMN 114, usuario
	PRINT '------------------------------------------------------------------------------------------------------------------------------------'
	PRINT COLUMN 001, 'CODIGO',
	      COLUMN 008, 'E',
	      COLUMN 010, 'DESCRIPCION DEL BIEN',
	      COLUMN 044, 'FECHA ADQ.',
	      COLUMN 056, '  VALOR BIEN',
	      COLUMN 070, '% DEP.',
	      COLUMN 078, 'V. DEPR. MES',
	      COLUMN 092, 'DEP. ANIO A.',
	      COLUMN 106, 'D. ACUM.ACT.',
	      COLUMN 120, 'DEPREC. ACUM.'
	PRINT '------------------------------------------------------------------------------------------------------------------------------------'

BEFORE GROUP OF a10_grupo_act
	SKIP TO TOP OF PAGE
	LET vm_tot_val  = 0
	LET vm_val_dep  = 0
	LET vm_tot_acum = 0
	LET vm_tot_act  = 0
	LET vm_tot_dep  = 0
	CALL fl_lee_grupo_activo(vg_codcia, a10_grupo_act) RETURNING r_a01.*
	PRINT COLUMN 001, 'GRUPO DE ACTIVO: ', a10_grupo_act USING "<<<<<&",
		' ', r_a01.a01_nombre
	SKIP 1 LINES
	
ON EVERY ROW
	NEED 5 LINES 
	PRINT COLUMN 001, r_report.a10_codigo_bien	USING "<<<<<&",
	      COLUMN 008, r_report.a10_estado,
	      COLUMN 010, r_report.a10_descripcion[1, 33],
	      COLUMN 044, r_report.a10_fecha_comp	USING "dd-mm-yyyy",
	      COLUMN 056, r_report.a10_valor_mb		USING "#,###,##&.##",
	      COLUMN 070, r_report.a10_porc_deprec	USING "##&.##",
	      COLUMN 078, r_report.a10_val_dep_mb	USING "#,###,##&.##",
	      COLUMN 092, r_report.a13_val_dep_acum	USING "#,###,##&.##",
	      COLUMN 106, r_report.dep_acum_act		USING "#,###,##&.##",
	      COLUMN 120, r_report.a10_tot_dep_mb	USING "##,###,##&.##"
	LET vm_tot_val  = vm_tot_val  + r_report.a10_valor_mb
	LET vm_val_dep  = vm_val_dep  + r_report.a10_val_dep_mb
	LET vm_tot_acum = vm_tot_acum + r_report.a13_val_dep_acum
	LET vm_tot_act  = vm_tot_act  + r_report.dep_acum_act
	LET vm_tot_dep  = vm_tot_dep  + r_report.a10_tot_dep_mb

AFTER GROUP OF a10_grupo_act
	NEED 4 LINES
	LET vm_tot_valor  = vm_tot_valor  + vm_tot_val
	LET vm_val_dep_g  = vm_val_dep_g  + vm_val_dep
	LET vm_tot_acum_g = vm_tot_acum_g + vm_tot_acum
	LET vm_tot_act_g  = vm_tot_act_g  + vm_tot_act
	LET vm_tot_dep_g  = vm_tot_dep_g  + vm_tot_dep
	PRINT COLUMN 055, '-------------',
	      COLUMN 077, '-------------',
	      COLUMN 091, '-------------',
	      COLUMN 105, '-------------',
	      COLUMN 119, '--------------'
	PRINT COLUMN 055, vm_tot_val                    USING "##,###,##&.##",
	      COLUMN 077, vm_val_dep			USING "##,###,##&.##",
	      COLUMN 091, vm_tot_acum			USING "##,###,##&.##",
	      COLUMN 105, vm_tot_act			USING "##,###,##&.##",
	      COLUMN 119, vm_tot_dep			USING "###,###,##&.##"
	SKIP 1 LINES

ON LAST ROW
	NEED 2 LINES
	PRINT COLUMN 055, '-------------',
	      COLUMN 077, '-------------',
	      COLUMN 091, '-------------',
	      COLUMN 105, '-------------',
	      COLUMN 119, '--------------'
	PRINT COLUMN 032, 'TOTALES GENERALES ==>  ',
	      COLUMN 055, vm_tot_valor                  USING "##,###,##&.##",
	      COLUMN 077, vm_val_dep_g			USING '##,###,##&.##',
	      COLUMN 091, vm_tot_acum_g			USING "##,###,##&.##",
	      COLUMN 105, vm_tot_act_g			USING "##,###,##&.##",
	      COLUMN 119, vm_tot_dep_g			USING '###,###,##&.##';
	print ASCII escape;
	print ASCII desact_comp 

END REPORT



FUNCTION retorna_estado()

IF rm_a10.a10_estado = 'A' THEN
	RETURN 'ACTIVO'
END IF
IF rm_a10.a10_estado = 'B' THEN
	RETURN 'BLOQUEADO'
END IF
IF rm_a10.a10_estado = 'S' THEN
	RETURN 'CON STOCK'
END IF
IF rm_a10.a10_estado = 'D' THEN
	RETURN 'DEPRECIADO'
END IF
IF rm_a10.a10_estado = 'V' THEN
	RETURN 'VENDIDO'
END IF
IF rm_a10.a10_estado = 'E' THEN
	RETURN 'ELIMINADO'
END IF
IF rm_a10.a10_estado = 'X' THEN
	RETURN 'EN DEPRECIACION Y DEPRECIADOS'
END IF
IF rm_a10.a10_estado = 'T' THEN
	RETURN 'T O D O S'
END IF

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
