--------------------------------------------------------------------------------
-- Titulo           : rolp440.4gl - Listado acumulado de Fondo de Censatía
-- Elaboracion      : 13-Nov-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp440 base módulo compañía [año] [mes]
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_n80		RECORD LIKE rolt080.*
DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE rm_g02		RECORD LIKE gent002.*
DEFINE tit_mes		VARCHAR(10)
DEFINE num_empl		SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 5 THEN	-- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp440'
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
CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
IF rm_g01.g01_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe compañía.','stop')
	EXIT PROGRAM
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rm_g02.*
IF rm_g02.g02_compania IS NULL THEN
	CALL fl_mostrar_mensaje('No existe localidad.','stop')
	EXIT PROGRAM
END IF
IF num_args() <> 3 THEN
	CALL control_reporte_llamada()
	EXIT PROGRAM
END IF
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 6
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
	OPEN FORM f_rol FROM "../forms/rolf440_1"
ELSE
	OPEN FORM f_rol FROM "../forms/rolf440_1c"
END IF
DISPLAY FORM f_rol
INITIALIZE rm_n80.* TO NULL
LET rm_n80.n80_ano = YEAR(TODAY)
LET rm_n80.n80_mes = MONTH(TODAY)
CALL fl_retorna_nombre_mes(rm_n80.n80_mes) RETURNING tit_mes
DISPLAY BY NAME tit_mes
WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL imprimir()
END WHILE

END FUNCTION



FUNCTION control_reporte_llamada()

INITIALIZE rm_n80.* TO NULL
LET rm_n80.n80_ano = arg_val(4)
LET rm_n80.n80_mes = arg_val(5)
CALL fl_retorna_nombre_mes(rm_n80.n80_mes) RETURNING tit_mes
CALL imprimir()

END FUNCTION



FUNCTION imprimir()
DEFINE comando		CHAR(100)

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
CALL control_reporte(comando)

END FUNCTION



FUNCTION lee_parametros()
DEFINE anio		LIKE rolt080.n80_ano
DEFINE mes		LIKE rolt080.n80_mes

LET int_flag = 0
INPUT BY NAME rm_n80.n80_ano, rm_n80.n80_mes
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF INFIELD(n80_mes) THEN
			CALL fl_ayuda_mostrar_meses() RETURNING mes, tit_mes
			IF mes IS NOT NULL THEN
				LET rm_n80.n80_mes = mes
				DISPLAY BY NAME rm_n80.n80_mes, tit_mes
			END IF
                END IF
		LET int_flag = 0
	BEFORE FIELD n80_ano
		LET anio = rm_n80.n80_ano
	BEFORE FIELD n80_mes
		LET mes = rm_n80.n80_mes
	AFTER FIELD n80_ano
		IF rm_n80.n80_ano IS NOT NULL THEN
			IF rm_n80.n80_ano > YEAR(TODAY) THEN
				CALL fl_mostrar_mensaje('El año no puede ser mayor al año vigente.', 'exclamation')
				NEXT FIELD n80_ano
			END IF
		ELSE
			LET rm_n80.n80_ano = anio
			DISPLAY BY NAME rm_n80.n80_ano
		END IF
	AFTER FIELD n80_mes
		IF rm_n80.n80_mes IS NULL THEN
			LET rm_n80.n80_mes = mes
			DISPLAY BY NAME rm_n80.n80_mes
		END IF
		CALL fl_retorna_nombre_mes(rm_n80.n80_mes) RETURNING tit_mes
		DISPLAY BY NAME tit_mes
END INPUT

END FUNCTION


   
FUNCTION control_reporte(comando)
DEFINE comando		CHAR(100)
DEFINE r_report		RECORD
				cod_trab	LIKE rolt080.n80_cod_trab,
				nombres		LIKE rolt030.n30_nombres,
				capital		DECIMAL(14,2),
				interes		DECIMAL(14,2),
				retiro		DECIMAL(14,2),
				total		DECIMAL(14,2)
			END RECORD
DEFINE r_n80		RECORD LIKE rolt080.*
DEFINE nom		LIKE rolt030.n30_nombres
DEFINE query		CHAR(800)

LET query = 'SELECT rolt080.*, n30_nombres FROM rolt080, rolt030 ',
		' WHERE n80_compania = ', vg_codcia,
		'   AND n80_ano      = ', rm_n80.n80_ano,
		'   AND n80_mes      = ', rm_n80.n80_mes,
		'   AND n30_compania = n80_compania ',
		'   AND n30_cod_trab = n80_cod_trab ',
		' ORDER BY n30_nombres'
PREPARE cons FROM query
DECLARE q_rolt080 CURSOR FOR cons
OPEN q_rolt080
FETCH q_rolt080 INTO r_n80.*, nom
IF STATUS = NOTFOUND THEN
	CLOSE q_rolt080
	FREE q_rolt080
	LET int_flag = 1
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
START REPORT reporte_fondo_acum TO PIPE comando
--START REPORT reporte_fondo_acum TO FILE "fondo_acum.txt"
LET num_empl = 0
FOREACH q_rolt080 INTO r_n80.*, nom
	LET rm_n80.n80_moneda  = r_n80.n80_moneda
	LET r_report.cod_trab  = r_n80.n80_cod_trab
	LET r_report.nombres   = nom
	LET r_report.capital   = r_n80.n80_sac_trab + r_n80.n80_sac_patr
	LET r_report.interes   = r_n80.n80_sac_int + r_n80.n80_sac_dscto
	LET r_report.retiro    = r_n80.n80_val_retiro
	LET r_report.total     = r_report.capital + r_report.interes +
				 r_report.retiro
	OUTPUT TO REPORT reporte_fondo_acum(r_report.*)
END FOREACH
FINISH REPORT reporte_fondo_acum

END FUNCTION



REPORT reporte_fondo_acum(r_report)
DEFINE r_report		RECORD
				cod_trab	LIKE rolt080.n80_cod_trab,
				nombres		LIKE rolt030.n30_nombres,
				capital		DECIMAL(14,2),
				interes		DECIMAL(14,2),
				retiro		DECIMAL(14,2),
				total		DECIMAL(14,2)
			END RECORD
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE escape, act_des	SMALLINT
DEFINE act_comp, db_c	SMALLINT
DEFINE desact_comp, db	SMALLINT
DEFINE act_neg, des_neg	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	96
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresi¢n
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	LET act_des	= 0
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	LET modulo  = "MODULO: NOMINA"
	LET usuario = 'USUARIO: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I', "LISTADO ACUMULADO FONDO CENSATIA", 80)
		RETURNING titulo
	CALL fl_lee_moneda(rm_n80.n80_moneda) RETURNING r_g13.*
	print ASCII escape;
	print ASCII act_neg;
	print ASCII escape;
	print ASCII act_12cpi
	PRINT COLUMN 001, rm_g01.g01_razonsocial,
  	      COLUMN 086, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001,  modulo CLIPPED,
	      COLUMN 033,  titulo CLIPPED,
	      COLUMN 090, UPSHIFT(vg_proceso)
	SKIP 1 LINES
	PRINT COLUMN 034, "** ANIO   : ", rm_n80.n80_ano USING '&&&&'
	PRINT COLUMN 034, "** MES    : ", rm_n80.n80_mes USING '&&', ' ',
			fl_justifica_titulo('I', tit_mes, 10)
	PRINT COLUMN 034, "** MONEDA : ", rm_n80.n80_moneda, ' ',
			r_g13.g13_nombre
	SKIP 1 LINES
	PRINT COLUMN 01, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
		1 SPACES, TIME,
	      COLUMN 077, usuario
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "COD.",
	      COLUMN 007, "    E  M  P  L  E  A  D  O",
	      COLUMN 039, "      CAPITAL",
	      COLUMN 054, "      INTERES",
	      COLUMN 069, "       RETIRO",
	      COLUMN 084, "        TOTAL"
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------";
	print ASCII escape;
	print ASCII des_neg

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, r_report.cod_trab		USING "&&&&",
	      COLUMN 007, r_report.nombres[1, 30],
	      COLUMN 039, r_report.capital 		USING "--,---,--&.##",
	      COLUMN 054, r_report.interes 		USING "--,---,--&.##",
	      COLUMN 069, r_report.retiro 		USING "--,---,--&.##",
	      COLUMN 084, r_report.total 		USING "--,---,--&.##"
	LET num_empl = num_empl + 1

ON LAST ROW
	NEED 2 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 039, 2 SPACES, "-------------",
	      COLUMN 054, 2 SPACES, "-------------",
	      COLUMN 069, 2 SPACES, "-------------",
	      COLUMN 084, 2 SPACES, "-------------"
	PRINT COLUMN 001, num_empl USING "#,##&", " EMPLEADOS",
	      COLUMN 027, "TOTALES ==> ",
	      COLUMN 039, SUM(r_report.capital)		USING "--,---,--&.##",
	      COLUMN 054, SUM(r_report.interes)		USING "--,---,--&.##",
	      COLUMN 069, SUM(r_report.retiro)		USING "--,---,--&.##",
	      COLUMN 084, SUM(r_report.total)		USING "--,---,--&.##";
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII act_10cpi

END REPORT
