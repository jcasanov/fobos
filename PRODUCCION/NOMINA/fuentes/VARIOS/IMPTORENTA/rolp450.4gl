--------------------------------------------------------------------------------
-- Titulo           : rolp450.4gl - Listado Liquidación Impuesto a la Renta
-- Elaboracion      : 24-Nov-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp450 base módulo compañía [año]
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_n84		RECORD LIKE rolt084.*
DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE rm_g02		RECORD LIKE gent002.*
DEFINE num_empl		SMALLINT
DEFINE vm_total_cob	DECIMAL(14,2)
DEFINE vm_total_dev	DECIMAL(14,2)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 4 THEN	-- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp450'
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
	OPEN FORM f_rol FROM "../forms/rolf450_1"
ELSE
	OPEN FORM f_rol FROM "../forms/rolf450_1c"
END IF
DISPLAY FORM f_rol
INITIALIZE rm_n84.* TO NULL
LET rm_n84.n84_ano_proceso = YEAR(TODAY)
WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL imprimir()
END WHILE

END FUNCTION



FUNCTION control_reporte_llamada()

INITIALIZE rm_n84.* TO NULL
LET rm_n84.n84_ano_proceso = arg_val(4)
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
DEFINE anio		LIKE rolt084.n84_ano_proceso

LET int_flag = 0
INPUT BY NAME rm_n84.n84_ano_proceso
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	BEFORE FIELD n84_ano_proceso
		LET anio = rm_n84.n84_ano_proceso
	AFTER FIELD n84_ano_proceso
		IF rm_n84.n84_ano_proceso IS NOT NULL THEN
			IF rm_n84.n84_ano_proceso > YEAR(TODAY) THEN
				CALL fl_mostrar_mensaje('El año no puede ser mayor al año vigente.', 'exclamation')
				NEXT FIELD n84_ano_proceso
			END IF
		ELSE
			LET rm_n84.n84_ano_proceso = anio
			DISPLAY BY NAME rm_n84.n84_ano_proceso
		END IF
END INPUT

END FUNCTION


   
FUNCTION control_reporte(comando)
DEFINE comando		CHAR(100)
DEFINE r_report		RECORD
				cod_trab	LIKE rolt084.n84_cod_trab,
				nombres		LIKE rolt030.n30_nombres,
				ing_roles	DECIMAL(14,2),
				otros_ing	LIKE rolt084.n84_otros_ing,
				aportes		LIKE rolt084.n84_aporte_iess,
				base_impo	DECIMAL(14,2),
				imp_real	LIKE rolt084.n84_imp_real,
				imp_ret		LIKE rolt084.n84_imp_ret,
				a_cobrar	DECIMAL(14,2),
				a_devolver	DECIMAL(14,2)
			END RECORD
DEFINE r_n84		RECORD LIKE rolt084.*
DEFINE nom		LIKE rolt030.n30_nombres
DEFINE query		CHAR(800)
DEFINE impuesto		DECIMAL(14,2)

LET query = 'SELECT rolt084.*, n30_nombres FROM rolt084, rolt030 ',
		' WHERE n84_compania = ', vg_codcia,
		'   AND n84_ano_proceso      = ', rm_n84.n84_ano_proceso,
		'   AND n84_estado   <> "B" ',
		'   AND n30_compania = n84_compania ',
		'   AND n30_cod_trab = n84_cod_trab ',
		' ORDER BY n30_nombres'
PREPARE cons FROM query
DECLARE q_rolt084 CURSOR FOR cons
OPEN q_rolt084
FETCH q_rolt084 INTO r_n84.*, nom
IF STATUS = NOTFOUND THEN
	CLOSE q_rolt084
	FREE q_rolt084
	LET int_flag = 1
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
START REPORT reporte_impuesto_renta TO PIPE comando
--START REPORT reporte_impuesto_renta TO FILE "impuesto_renta.txt"
LET num_empl     = 0
LET vm_total_cob = 0
LET vm_total_dev = 0
FOREACH q_rolt084 INTO r_n84.*, nom
	LET rm_n84.n84_moneda   = r_n84.n84_moneda
	LET rm_n84.n84_estado   = r_n84.n84_estado
	LET r_report.cod_trab   = r_n84.n84_cod_trab
	LET r_report.nombres    = nom
	LET r_report.ing_roles  = r_n84.n84_ing_roles + r_n84.n84_dec_cuarto
				  + r_n84.n84_dec_tercero
				  + r_n84.n84_roles_varios
				  + r_n84.n84_bonificacion
				  + r_n84.n84_vacaciones
				  + r_n84.n84_utilidades
	LET r_report.otros_ing  = r_n84.n84_otros_ing
	LET r_report.aportes    = r_n84.n84_aporte_iess
	LET r_report.base_impo  = r_report.ing_roles + r_report.otros_ing
				  - r_report.aportes
	LET r_report.imp_real   = r_n84.n84_imp_real
	LET r_report.imp_ret    = r_n84.n84_imp_ret
	LET r_report.a_cobrar   = NULL
	LET r_report.a_devolver = NULL
	LET impuesto            = r_report.imp_real - r_report.imp_ret
	IF impuesto > 0 THEN
		LET r_report.a_cobrar = impuesto
		LET vm_total_cob      = vm_total_cob + r_report.a_cobrar
	ELSE
		IF impuesto <> 0 THEN
			LET r_report.a_devolver = impuesto
			LET vm_total_dev = vm_total_dev + r_report.a_devolver
		END IF
	END IF
	OUTPUT TO REPORT reporte_impuesto_renta(r_report.*)
END FOREACH
FINISH REPORT reporte_impuesto_renta

END FUNCTION



REPORT reporte_impuesto_renta(r_report)
DEFINE r_report		RECORD
				cod_trab	LIKE rolt084.n84_cod_trab,
				nombres		LIKE rolt030.n30_nombres,
				ing_roles	DECIMAL(14,2),
				otros_ing	LIKE rolt084.n84_otros_ing,
				aportes		LIKE rolt084.n84_aporte_iess,
				base_impo	DECIMAL(14,2),
				imp_real	LIKE rolt084.n84_imp_real,
				imp_ret		LIKE rolt084.n84_imp_ret,
				a_cobrar	DECIMAL(14,2),
				a_devolver	DECIMAL(14,2)
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
	RIGHT MARGIN	160
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
	CALL fl_justifica_titulo('I', "LISTADO DE IMPUESTO A LA RENTA ANUAL",80)
		RETURNING titulo
	CALL fl_lee_moneda(rm_n84.n84_moneda) RETURNING r_g13.*
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_neg;
	print ASCII escape;
	print ASCII act_12cpi
	PRINT COLUMN 001, rm_g01.g01_razonsocial,
  	      COLUMN 150, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 041, titulo CLIPPED,
	      COLUMN 154, UPSHIFT(vg_proceso)
	SKIP 1 LINES
	PRINT COLUMN 049, "** ANIO   : ", rm_n84.n84_ano_proceso USING '&&&&'
	PRINT COLUMN 049, "** MONEDA : ", rm_n84.n84_moneda, ' ',
			r_g13.g13_nombre
	PRINT COLUMN 049, "** ESTADO : ", rm_n84.n84_estado, ' ',
			retorna_estado()
	SKIP 1 LINES
	PRINT COLUMN 01, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
		1 SPACES, TIME,
	      COLUMN 141, usuario
	PRINT COLUMN 001, "----------------------------------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "COD.",
	      COLUMN 006, "         E  M  P  L  E  A  D  O  S",
	      COLUMN 050, "INGRESO ANUAL",
	      COLUMN 064, "OTROS INGRESO",
	      COLUMN 078, "      APORTES",
	      COLUMN 092, "BASE IMPONIB.",
	      COLUMN 106, "IMPUESTO PAG.",
	      COLUMN 120, "IMPUESTO RET.",
	      COLUMN 134, "     A COBRAR",
	      COLUMN 148, "   A DEVOLVER"
	PRINT COLUMN 001, "----------------------------------------------------------------------------------------------------------------------------------------------------------------";
	print ASCII escape;
	print ASCII des_neg

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, r_report.cod_trab		USING "&&&&",
	      COLUMN 006, r_report.nombres[1, 43],
	      COLUMN 050, r_report.ing_roles 		USING "--,---,--&.##",
	      COLUMN 064, r_report.otros_ing 		USING "--,---,--&.##",
	      COLUMN 078, r_report.aportes 		USING "--,---,--&.##",
	      COLUMN 092, r_report.base_impo 		USING "--,---,--&.##",
	      COLUMN 106, r_report.imp_real 		USING "--,---,--&.##",
	      COLUMN 120, r_report.imp_ret 		USING "--,---,--&.##",
	      COLUMN 134, r_report.a_cobrar 		USING "##,###,###.##",
	      COLUMN 148, r_report.a_devolver 		USING "##,###,###.##"
	LET num_empl = num_empl + 1

ON LAST ROW
	NEED 2 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 050, 2 SPACES, "-------------",
	      COLUMN 064, 2 SPACES, "-------------",
	      COLUMN 078, 2 SPACES, "-------------",
	      COLUMN 092, 2 SPACES, "-------------",
	      COLUMN 106, 2 SPACES, "-------------",
	      COLUMN 120, 2 SPACES, "-------------";
	IF vm_total_cob > 0 THEN
		PRINT COLUMN 134, 2 SPACES, "-------------";
	END IF
	IF vm_total_dev < 0 THEN
		PRINT COLUMN 148, 2 SPACES, "-------------"
	ELSE
		PRINT 1 SPACES
	END IF
	PRINT COLUMN 001, num_empl USING "#,##&", " EMPLEADOS",
	      COLUMN 037, "TOTALES ==>  ",
	      COLUMN 050, SUM(r_report.ing_roles)	USING "--,---,--&.##",
	      COLUMN 064, SUM(r_report.otros_ing)	USING "--,---,--&.##",
	      COLUMN 078, SUM(r_report.aportes)		USING "--,---,--&.##",
	      COLUMN 092, SUM(r_report.base_impo)	USING "--,---,--&.##",
	      COLUMN 106, SUM(r_report.imp_real)	USING "--,---,--&.##",
	      COLUMN 120, SUM(r_report.imp_ret)		USING "--,---,--&.##";
	IF vm_total_cob > 0 THEN
		PRINT COLUMN 134, vm_total_cob 		USING "##,###,###.##";
	END IF
	IF vm_total_dev < 0 THEN
		PRINT COLUMN 148, vm_total_dev 		USING "##,###,###.##";
	END IF
	print ASCII escape;
	print ASCII desact_comp;
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII act_10cpi

END REPORT



FUNCTION retorna_estado()
DEFINE estado		LIKE rolt084.n84_estado
DEFINE est		VARCHAR(10)

LET estado = rm_n84.n84_estado
CASE estado
	WHEN 'A'
		LET est = 'ACTIVO'
	WHEN 'P'
		LET est = 'PROCESADO'
	WHEN 'B'
		LET est = 'BLOQUEADO'
END CASE
RETURN est

END FUNCTION
