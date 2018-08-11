--------------------------------------------------------------------------------
-- Titulo           : rolp441.4gl - Listado Liquidación Fondo de Censatía
-- Elaboracion      : 15-Nov-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp441 base módulo compañía año mes
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_n83		RECORD LIKE rolt083.*
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
IF num_args() <> 5 THEN			-- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base        = arg_val(1)
LET vg_modulo      = arg_val(2)
LET vg_codcia      = arg_val(3)
LET rm_n83.n83_ano = arg_val(4)
LET rm_n83.n83_mes = arg_val(5)
LET vg_proceso     = 'rolp441'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

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



FUNCTION control_reporte(comando)
DEFINE comando		CHAR(100)
DEFINE r_report		RECORD
				cod_trab	LIKE rolt083.n83_cod_trab,
				nombres		LIKE rolt030.n30_nombres,
				capital		DECIMAL(14,2),
				interes		DECIMAL(14,2),
				descuento	DECIMAL(14,2),
				total		DECIMAL(14,2)
			END RECORD
DEFINE r_n83		RECORD LIKE rolt083.*
DEFINE nom		LIKE rolt030.n30_nombres
DEFINE query		CHAR(800)

LET query = 'SELECT rolt083.*, n30_nombres FROM rolt083, rolt030 ',
		' WHERE n83_compania = ', vg_codcia,
		'   AND n83_ano      = ', rm_n83.n83_ano,
		'   AND n83_mes      = ', rm_n83.n83_mes,
		'   AND n83_compania = n30_compania ',
		'   AND n83_cod_trab = n30_cod_trab ',
		' ORDER BY n30_nombres'
PREPARE cons FROM query
DECLARE q_rolt083 CURSOR FOR cons
OPEN q_rolt083
FETCH q_rolt083 INTO r_n83.*, nom
IF STATUS = NOTFOUND THEN
	CLOSE q_rolt083
	FREE q_rolt083
	LET int_flag = 1
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
START REPORT reporte_fondo_liq_pol TO PIPE comando
--START REPORT reporte_fondo_liq_pol TO FILE "fondo_poliza.txt"
LET num_empl = 0
FOREACH q_rolt083 INTO r_n83.*, nom
	LET rm_n83.n83_moneda  = r_n83.n83_moneda
	LET r_report.cod_trab  = r_n83.n83_cod_trab
	LET r_report.nombres   = nom
	LET r_report.capital   = r_n83.n83_cap_trab + r_n83.n83_cap_patr +
				 r_n83.n83_cap_int  + r_n83.n83_cap_dscto
	LET r_report.interes   = r_n83.n83_val_int
	LET r_report.descuento = r_n83.n83_val_dscto
	LET r_report.total     = r_report.capital + r_report.interes +
				 r_report.descuento
	OUTPUT TO REPORT reporte_fondo_liq_pol(r_report.*)
END FOREACH
FINISH REPORT reporte_fondo_liq_pol

END FUNCTION



REPORT reporte_fondo_liq_pol(r_report)
DEFINE r_report		RECORD
				cod_trab	LIKE rolt083.n83_cod_trab,
				nombres		LIKE rolt030.n30_nombres,
				capital		DECIMAL(14,2),
				interes		DECIMAL(14,2),
				descuento	DECIMAL(14,2),
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
	CALL fl_justifica_titulo('I', "LISTADO LIQUIDACION POLIZA FONDO CENSATIA", 80)
		RETURNING titulo
	CALL fl_lee_moneda(rm_n83.n83_moneda) RETURNING r_g13.*
	CALL fl_retorna_nombre_mes(rm_n83.n83_mes) RETURNING tit_mes
	print ASCII escape;
	print ASCII act_neg;
	print ASCII escape;
	print ASCII act_12cpi
	PRINT COLUMN 001, rm_g01.g01_razonsocial,
  	      COLUMN 086, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001,  modulo CLIPPED,
	      COLUMN 028,  titulo CLIPPED,
	      COLUMN 090, UPSHIFT(vg_proceso)
	SKIP 1 LINES
	PRINT COLUMN 034, "** ANIO   : ", rm_n83.n83_ano USING '&&&&'
	PRINT COLUMN 034, "** MES    : ", rm_n83.n83_mes USING '&&', ' ',
			fl_justifica_titulo('I', tit_mes, 10)
	PRINT COLUMN 034, "** MONEDA : ", rm_n83.n83_moneda, ' ',
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
	      COLUMN 069, "    DESCUENTO",
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
	      COLUMN 069, r_report.descuento 		USING "--,---,--&.##",
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
	      COLUMN 069, SUM(r_report.descuento)	USING "--,---,--&.##",
	      COLUMN 084, SUM(r_report.total)		USING "--,---,--&.##";
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII act_10cpi

END REPORT
