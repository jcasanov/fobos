--------------------------------------------------------------------------------
-- Titulo           : rolp403.4gl - Listado de nomina por tipo de pago
-- Elaboracion      : 01-Sep-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp403 base módulo compañía
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_n00		RECORD LIKE rolt000.*
DEFINE rm_n32		RECORD LIKE rolt032.*
DEFINE rm_n33		RECORD LIKE rolt033.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE rm_loc		RECORD LIKE gent002.*
DEFINE vm_tipo_pago	CHAR(1)
DEFINE tit_mes		VARCHAR(10)
DEFINE tot_banco	DECIMAL(14,2)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp403.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN
	-- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp403'
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
LET num_rows = 15
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_rol AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_rol FROM "../forms/rolf403_1"
ELSE
	OPEN FORM f_rol FROM "../forms/rolf403_1c"
END IF
DISPLAY FORM f_rol
CALL cargar_datos_liq() RETURNING resul
IF resul THEN
	RETURN
END IF
WHILE TRUE
	CALL mostrar_datos_liq()
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_reporte()
END WHILE

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
		WHERE n32_compania    = r_n05.n05_compania
		  AND n32_cod_liqrol  = r_n05.n05_proceso
		  AND n32_estado     <> 'E'
		ORDER BY n32_fecha_ini DESC
OPEN q_ultliq
FETCH q_ultliq INTO r_n32.*
LET rm_n32.n32_cod_liqrol  = r_n32.n32_cod_liqrol
LET rm_n32.n32_fecha_ini   = r_n32.n32_fecha_ini
LET rm_n32.n32_fecha_fin   = r_n32.n32_fecha_fin
LET rm_n32.n32_ano_proceso = r_n32.n32_ano_proceso
LET rm_n32.n32_mes_proceso = r_n32.n32_mes_proceso
CALL retorna_mes()
LET vm_tipo_pago = 'D'
RETURN 0

END FUNCTION



FUNCTION mostrar_datos_liq()
DEFINE r_n03		RECORD LIKE rolt003.*

DISPLAY BY NAME rm_n32.n32_cod_liqrol, rm_n32.n32_fecha_ini,
		rm_n32.n32_fecha_fin, rm_n32.n32_ano_proceso,
		rm_n32.n32_mes_proceso, tit_mes, vm_tipo_pago
CALL fl_lee_proceso_roles(rm_n32.n32_cod_liqrol) RETURNING r_n03.*
DISPLAY BY NAME r_n03.n03_nombre

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE anio		LIKE rolt032.n32_ano_proceso
DEFINE mes		LIKE rolt032.n32_mes_proceso
DEFINE mes_aux		LIKE rolt032.n32_mes_proceso

LET int_flag = 0
INPUT BY NAME rm_n32.n32_cod_liqrol, rm_n32.n32_ano_proceso,
	rm_n32.n32_mes_proceso, vm_tipo_pago
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
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
	BEFORE FIELD n32_ano_proceso
		LET anio = rm_n32.n32_ano_proceso
	BEFORE FIELD n32_mes_proceso
		LET mes = rm_n32.n32_mes_proceso
	AFTER FIELD n32_cod_liqrol
		IF rm_n32.n32_cod_liqrol IS NOT NULL THEN
   			CALL fl_lee_proceso_roles(rm_n32.n32_cod_liqrol)
                        	RETURNING r_n03.*
			IF r_n03.n03_proceso IS NULL THEN
				CALL fl_mostrar_mensaje('No existe el código de liquidación en la Compañía.','exclamation')
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

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
CASE vm_tipo_pago
	WHEN 'D'
		CALL imprimir_tipo_pago2(comando)
	WHEN 'E'
		CALL imprimir_tipo_pago1('E', comando)
	WHEN 'C'
		CALL imprimir_tipo_pago1('C', comando)
	WHEN 'T'
		CALL imprimir_tipo_pago2(comando)
		CALL imprimir_tipo_pago1('E', comando)
		CALL imprimir_tipo_pago1('C', comando)
END CASE

END FUNCTION



FUNCTION preparar_query(tipo)
DEFINE tipo		CHAR(1)
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE r_n36		RECORD LIKE rolt036.*
DEFINE r_n48		RECORD LIKE rolt048.*
DEFINE nombres		LIKE rolt030.n30_nombres
DEFINE query		CHAR(800)
DEFINE expr_tipo	VARCHAR(100)
DEFINE expr_orden	VARCHAR(100)
DEFINE mensaje		VARCHAR(150)
DEFINE tip_pag		VARCHAR(27)
DEFINE tabla		VARCHAR(7)
DEFINE pre		VARCHAR(3)
DEFINE liq		VARCHAR(25)
DEFINE codl		VARCHAR(11)

IF rm_n32.n32_cod_liqrol[1] = 'S' OR rm_n32.n32_cod_liqrol[1] = 'Q' OR
   rm_n32.n32_cod_liqrol[1] = 'M' THEN
	LET tabla = 'rolt032'
	LET pre   = 'n32'
	LET codl  = '_cod_liqrol'
	LET liq   = ' la liquidación.'
END IF
IF rm_n32.n32_cod_liqrol = 'DT' OR rm_n32.n32_cod_liqrol = 'DC' THEN
	LET tabla = 'rolt036'
	LET pre   = 'n36'
	LET codl  = '_proceso'
	LET liq   = ' el décimo tercero.'
	IF rm_n32.n32_cod_liqrol = 'DC' THEN
		LET liq   = 'el décimo cuarto.'
	END IF
END IF
IF rm_n32.n32_cod_liqrol = 'JU' THEN
	LET tabla = 'rolt048'
	LET pre   = 'n48'
	LET codl  = '_proceso'
	LET liq   = ' el proceso de jubilados.'
END IF
LET expr_tipo  = NULL
LET expr_orden = ' ORDER BY n30_nombres '
CASE tipo
	WHEN 'D'
		LET tip_pag    = 'con Depósito a Cuenta, '
		LET expr_tipo  = '   AND ', pre, '_tipo_pago = "T"'
		LET expr_orden = ' ORDER BY ', pre, '_bco_empresa, n30_nombres '
	WHEN 'E'
		LET expr_tipo  = '   AND ', pre, '_tipo_pago = "E"'
		LET tip_pag    = 'en Efectivo, '
	WHEN 'C'
		LET expr_tipo  = '   AND ', pre, '_tipo_pago = "C"'
		LET tip_pag    = 'con Cheque, '
END CASE
LET query = 'SELECT ', tabla, '.*, n30_nombres FROM ', tabla, ', rolt030 ',
		' WHERE ', pre, '_compania   = ', vg_codcia,
		'   AND ', pre, codl, ' = "', rm_n32.n32_cod_liqrol, '"',
		'   AND ', pre, '_fecha_ini  = "', rm_n32.n32_fecha_ini, '"',
		'   AND ', pre, '_fecha_fin  = "', rm_n32.n32_fecha_fin, '"',
		'   AND ', pre, '_estado     <> "E" ',
		expr_tipo CLIPPED,
		'   AND ', pre, '_compania   = n30_compania ',
		'   AND ', pre, '_cod_trab   = n30_cod_trab ',
		expr_orden CLIPPED
PREPARE reporte FROM query
IF rm_n32.n32_cod_liqrol[1] = 'S' OR rm_n32.n32_cod_liqrol[1] = 'Q' OR
   rm_n32.n32_cod_liqrol[1] = 'M' THEN
	DECLARE q_n32 CURSOR FOR reporte
	OPEN q_n32
	FETCH q_n32 INTO r_n32.*, nombres
END IF
IF rm_n32.n32_cod_liqrol = 'DT' OR rm_n32.n32_cod_liqrol = 'DC' THEN
	DECLARE q_n36 CURSOR FOR reporte
	OPEN q_n36
	FETCH q_n36 INTO r_n36.*, nombres
END IF
IF rm_n32.n32_cod_liqrol = 'JU' THEN
	DECLARE q_n48 CURSOR FOR reporte
	OPEN q_n48
	FETCH q_n48 INTO r_n48.*, nombres
END IF
IF STATUS = NOTFOUND THEN
	IF rm_n32.n32_cod_liqrol[1] = 'S' OR rm_n32.n32_cod_liqrol[1] = 'Q' OR
	   rm_n32.n32_cod_liqrol[1] = 'M' THEN
		CLOSE q_n32
		FREE q_n32
	END IF
	IF rm_n32.n32_cod_liqrol = 'DT' OR rm_n32.n32_cod_liqrol = 'DC' THEN
		CLOSE q_n36
		FREE q_n36
	END IF
	IF rm_n32.n32_cod_liqrol = 'JU' THEN
		CLOSE q_n48
		FREE q_n48
	END IF
	LET mensaje = 'No se ha pagado a ningún empleado ', tip_pag CLIPPED,
			liq CLIPPED
	CALL fl_mostrar_mensaje(mensaje, 'exclamation')
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION imprimir_tipo_pago2(comando)
DEFINE comando		VARCHAR(100)
DEFINE r_report		RECORD
				bco_empresa	INTEGER,
				cta_empresa	CHAR(15),
				cod_trab	INTEGER,
				cta_trabaj	CHAR(15),
				tot_neto	DECIMAL(12,2)
			END RECORD
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE r_n36		RECORD LIKE rolt036.*
DEFINE r_n48		RECORD LIKE rolt048.*
DEFINE nombres		LIKE rolt030.n30_nombres
DEFINE resul	 	SMALLINT

CALL preparar_query('D') RETURNING resul
IF resul THEN
	RETURN
END IF
START REPORT reporte_nomina_tipo_pago2 TO PIPE comando
IF rm_n32.n32_cod_liqrol[1] = 'S' OR rm_n32.n32_cod_liqrol[1] = 'Q' OR
   rm_n32.n32_cod_liqrol[1] = 'M' THEN
	FOREACH q_n32 INTO r_n32.*, nombres
		IF r_n32.n32_tot_neto <= 0 THEN
			CONTINUE FOREACH
		END IF
		LET r_report.bco_empresa = r_n32.n32_bco_empresa
		LET r_report.cta_empresa = r_n32.n32_cta_empresa
		LET r_report.cod_trab    = r_n32.n32_cod_trab
		LET r_report.cta_trabaj  = r_n32.n32_cta_trabaj
		LET r_report.tot_neto    = r_n32.n32_tot_neto
		OUTPUT TO REPORT reporte_nomina_tipo_pago2(r_report.*, nombres)
	END FOREACH
END IF
IF rm_n32.n32_cod_liqrol = 'DT' OR rm_n32.n32_cod_liqrol = 'DC' THEN
	FOREACH q_n36 INTO r_n36.*, nombres
		IF r_n36.n36_valor_neto <= 0 THEN
			CONTINUE FOREACH
		END IF
		LET r_report.bco_empresa = r_n36.n36_bco_empresa
		LET r_report.cta_empresa = r_n36.n36_cta_empresa
		LET r_report.cod_trab    = r_n36.n36_cod_trab
		LET r_report.cta_trabaj  = r_n36.n36_cta_trabaj
		LET r_report.tot_neto    = r_n36.n36_valor_neto
		OUTPUT TO REPORT reporte_nomina_tipo_pago2(r_report.*, nombres)
	END FOREACH
END IF
IF rm_n32.n32_cod_liqrol = 'JU' THEN
	FOREACH q_n48 INTO r_n48.*, nombres
		IF r_n48.n48_val_jub_pat <= 0 THEN
			CONTINUE FOREACH
		END IF
		LET r_report.bco_empresa = r_n48.n48_bco_empresa
		LET r_report.cta_empresa = r_n48.n48_cta_empresa
		LET r_report.cod_trab    = r_n48.n48_cod_trab
		LET r_report.cta_trabaj  = r_n48.n48_cta_trabaj
		LET r_report.tot_neto    = r_n48.n48_val_jub_pat
		OUTPUT TO REPORT reporte_nomina_tipo_pago2(r_report.*, nombres)
	END FOREACH
END IF
FINISH REPORT reporte_nomina_tipo_pago2

END FUNCTION



FUNCTION imprimir_tipo_pago1(tipo, comando)
DEFINE tipo		CHAR(1)
DEFINE comando		VARCHAR(100)
DEFINE r_report		RECORD
				cod_trab	INTEGER,
				tot_neto	DECIMAL(12,2)
			END RECORD
DEFINE r_n32		RECORD LIKE rolt032.*
DEFINE r_n36		RECORD LIKE rolt036.*
DEFINE r_n48		RECORD LIKE rolt048.*
DEFINE nombres		LIKE rolt030.n30_nombres
DEFINE resul	 	SMALLINT

CALL preparar_query(tipo) RETURNING resul
IF resul THEN
	RETURN
END IF
START REPORT reporte_nomina_tipo_pago1 TO PIPE comando
IF rm_n32.n32_cod_liqrol[1] = 'S' OR rm_n32.n32_cod_liqrol[1] = 'Q' OR
   rm_n32.n32_cod_liqrol[1] = 'M' THEN
	FOREACH q_n32 INTO r_n32.*, nombres
		IF r_n32.n32_tot_neto <= 0 THEN
			CONTINUE FOREACH
		END IF
		LET r_report.cod_trab = r_n32.n32_cod_trab
		LET r_report.tot_neto = r_n32.n32_tot_neto
		OUTPUT TO REPORT reporte_nomina_tipo_pago1(r_report.*, nombres,
								tipo)
	END FOREACH
END IF
IF rm_n32.n32_cod_liqrol = 'DT' OR rm_n32.n32_cod_liqrol = 'DC' THEN
	FOREACH q_n36 INTO r_n36.*, nombres
		IF r_n36.n36_valor_neto <= 0 THEN
			CONTINUE FOREACH
		END IF
		LET r_report.cod_trab = r_n36.n36_cod_trab
		LET r_report.tot_neto = r_n36.n36_valor_neto
		OUTPUT TO REPORT reporte_nomina_tipo_pago1(r_report.*, nombres,
								tipo)
	END FOREACH
END IF
IF rm_n32.n32_cod_liqrol = 'JU' THEN
	FOREACH q_n48 INTO r_n48.*, nombres
		IF r_n48.n48_val_jub_pat <= 0 THEN
			CONTINUE FOREACH
		END IF
		LET r_report.cod_trab = r_n48.n48_cod_trab
		LET r_report.tot_neto = r_n48.n48_val_jub_pat
		OUTPUT TO REPORT reporte_nomina_tipo_pago1(r_report.*, nombres,
								tipo)
	END FOREACH
END IF
FINISH REPORT reporte_nomina_tipo_pago1

END FUNCTION



REPORT reporte_nomina_tipo_pago2(r_report, nombres)
DEFINE r_report		RECORD
				bco_empresa	INTEGER,
				cta_empresa	CHAR(15),
				cod_trab	INTEGER,
				cta_trabaj	CHAR(15),
				tot_neto	DECIMAL(12,2)
			END RECORD
DEFINE nombres		LIKE rolt030.n30_nombres
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_g08		RECORD LIKE gent008.*
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(20)
DEFINE usuario		VARCHAR(19)
DEFINE postit, maxcol	SMALLINT
DEFINE escape		SMALLINT
DEFINE act_neg, des_neg	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	80
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresión
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	LET titulo      = "NOMINA POR TIPO DE PAGO"
	LET modulo      = "MODULO: NOMINA"
	LET usuario     = 'USUARIO: ', vg_usuario
	LET maxcol      = 80
	LET postit      = (maxcol / 2) - LENGTH(titulo) / 2
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	print ASCII escape;
	print ASCII act_neg
	PRINT COLUMN 001, rm_cia.g01_razonsocial,
  	      COLUMN maxcol - 10, "PAGINA: ", PAGENO USING "&&&"
	SKIP 1 LINES
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN postit, titulo,
	      COLUMN maxcol - 6, UPSHIFT(vg_proceso) CLIPPED
	CALL fl_lee_proceso_roles(rm_n32.n32_cod_liqrol) RETURNING r_n03.*
	LET titulo = "PROCESO DE NOMINA: ", rm_n32.n32_cod_liqrol, " ",
			r_n03.n03_nombre_abr CLIPPED, " del ",
			rm_n32.n32_fecha_ini USING "dd-mm-yyyy",
			' al ', rm_n32.n32_fecha_fin USING "dd-mm-yyyy"
	LET postit = (maxcol / 2) - LENGTH(titulo) / 2
	SKIP 1 LINES
	PRINT COLUMN postit, titulo
	LET titulo = "TIPO DE PAGO: DEPOSITO A CUENTA"
	LET postit = (maxcol / 2) - LENGTH(titulo) / 2
	PRINT COLUMN postit, titulo
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
		1 SPACES, TIME,
	      COLUMN maxcol - 18, usuario
	PRINT COLUMN 001, "--------------------------------------------------------------------------------"
	PRINT COLUMN 001, "COD",
	      COLUMN 007, "            E M P L E A D O",
	      COLUMN 050, "CTA. EMPLEADO",
	      COLUMN 067, "NETO A RECIBIR"
	PRINT COLUMN 001, "--------------------------------------------------------------------------------";
	print ASCII escape;
	print ASCII des_neg

BEFORE GROUP OF r_report.bco_empresa
	NEED 6 LINES
	CALL fl_lee_banco_general(r_report.bco_empresa) RETURNING r_g08.*
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 002, "CTA. EMPRESA: ", r_report.cta_empresa CLIPPED,
			" DEL BANCO: ", r_g08.g08_nombre;
	print ASCII escape;
	print ASCII des_neg
	LET tot_banco = 0

ON EVERY ROW
	NEED 5 LINES
	PRINT COLUMN 001, r_report.cod_trab	USING "&&&",
	      COLUMN 007, nombres[1, 40],
	      COLUMN 050, r_report.cta_trabaj,
	      COLUMN 067, r_report.tot_neto	USING "---,---,--&.##"
	LET tot_banco = tot_banco + r_report.tot_neto

AFTER GROUP OF r_report.bco_empresa
	NEED 4 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 067, 2 SPACES, "--------------"
	PRINT COLUMN 050, "TOTAL BANCO ==>  ", tot_banco USING "---,---,--&.##";
	print ASCII escape;
	print ASCII des_neg
	SKIP 1 LINES

ON LAST ROW
	NEED 2 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 067, 2 SPACES, "--------------"
	PRINT COLUMN 048, "TOTAL GENERAL ==>  ", SUM(r_report.tot_neto)
						USING "---,---,--&.##";
	print ASCII escape;
	print ASCII des_neg

END REPORT



REPORT reporte_nomina_tipo_pago1(r_report, nombres, tipo)
DEFINE r_report		RECORD
				cod_trab	INTEGER,
				tot_neto	DECIMAL(12,2)
			END RECORD
DEFINE nombres		LIKE rolt030.n30_nombres
DEFINE tipo		CHAR(1)
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(20)
DEFINE usuario		VARCHAR(19)
DEFINE postit, maxcol	SMALLINT
DEFINE escape		SMALLINT
DEFINE act_neg, des_neg	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	80
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresión
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	LET titulo      = "NOMINA POR TIPO DE PAGO"
	LET modulo      = "MODULO: NOMINA"
	LET usuario     = 'USUARIO: ', vg_usuario
	LET maxcol      = 80
	LET postit      = (maxcol / 2) - LENGTH(titulo) / 2
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	print ASCII escape;
	print ASCII act_neg
	PRINT COLUMN 001, rm_cia.g01_razonsocial,
  	      COLUMN maxcol - 10, "PAGINA: ", PAGENO USING "&&&"
	SKIP 1 LINES
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN postit, titulo,
	      COLUMN maxcol - 6, UPSHIFT(vg_proceso) CLIPPED
	CALL fl_lee_proceso_roles(rm_n32.n32_cod_liqrol) RETURNING r_n03.*
	LET titulo = "PROCESO DE NOMINA: ", rm_n32.n32_cod_liqrol, " ",
			r_n03.n03_nombre_abr CLIPPED, " del ",
			rm_n32.n32_fecha_ini USING "dd-mm-yyyy",
			' al ', rm_n32.n32_fecha_fin USING "dd-mm-yyyy"
	LET postit = (maxcol / 2) - LENGTH(titulo) / 2
	SKIP 1 LINES
	PRINT COLUMN postit, titulo
	CASE tipo
		WHEN 'E'
			LET titulo = "TIPO DE PAGO: EFECTIVO"
		WHEN 'C'
			LET titulo = "TIPO DE PAGO: CHEQUE"
	END CASE
	LET postit = (maxcol / 2) - LENGTH(titulo) / 2
	PRINT COLUMN postit, titulo
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
		1 SPACES, TIME,
	      COLUMN maxcol - 18, usuario
	PRINT COLUMN 001, "--------------------------------------------------------------------------------"
	PRINT COLUMN 001, "COD",
	      COLUMN 010, "               E M P L E A D O",
	      COLUMN 067, "NETO A RECIBIR"
	PRINT COLUMN 001, "--------------------------------------------------------------------------------";
	print ASCII escape;
	print ASCII des_neg

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, r_report.cod_trab	USING "&&&",
	      COLUMN 010, nombres,
	      COLUMN 067, r_report.tot_neto	USING "---,---,--&.##"

ON LAST ROW
	NEED 2 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 067, 2 SPACES, "--------------"
	PRINT COLUMN 048, "TOTAL GENERAL ==>  ", SUM(r_report.tot_neto)
						USING "---,---,--&.##";
	print ASCII escape;
	print ASCII des_neg

END REPORT



FUNCTION retorna_mes()

CALL fl_justifica_titulo('I', fl_retorna_nombre_mes(rm_n32.n32_mes_proceso), 10)
	RETURNING tit_mes

END FUNCTION 



FUNCTION mostrar_fechas()

CALL fl_retorna_rango_fechas_proceso(vg_codcia, rm_n32.n32_cod_liqrol,
				rm_n32.n32_ano_proceso, rm_n32.n32_mes_proceso)
	RETURNING rm_n32.n32_fecha_ini, rm_n32.n32_fecha_fin
IF rm_n32.n32_cod_liqrol = "JU" THEN
	LET rm_n32.n32_fecha_ini = MDY(rm_n32.n32_mes_proceso, 01,
					rm_n32.n32_ano_proceso)
	LET rm_n32.n32_fecha_fin = rm_n32.n32_fecha_ini + 1 UNITS MONTH
					- 1 UNITS DAY
END IF
DISPLAY BY NAME rm_n32.n32_fecha_ini, rm_n32.n32_fecha_fin

END FUNCTION 
