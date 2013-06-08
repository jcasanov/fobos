--------------------------------------------------------------------------------
-- Titulo           : rolp442.4gl - Listado Aportaciones Mensual Fondo Censatía
-- Elaboracion      : 27-Nov-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp442 base módulo compañía [año] [mes]
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_n80		RECORD LIKE rolt080.*
DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE rm_g02		RECORD LIKE gent002.*
DEFINE vm_aport_patr	LIKE rolt001.n01_porc_aporte
DEFINE vm_subtit1	LIKE rolt003.n03_nombre_abr
DEFINE vm_subtit2	LIKE rolt003.n03_nombre_abr
DEFINE vm_aport_trab	LIKE rolt007.n07_factor
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
LET vg_proceso = 'rolp442'
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
	OPEN FORM f_rol FROM "../forms/rolf442_1"
ELSE
	OPEN FORM f_rol FROM "../forms/rolf442_1c"
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
				acum_mes_ant	DECIMAL(14,2),
				q1_trab		DECIMAL(14,2),
				q1_patr		DECIMAL(14,2),
				q2_trab		DECIMAL(14,2),
				q2_patr		DECIMAL(14,2),
				total		DECIMAL(14,2),
				tot_mes_ant	DECIMAL(14,2)
			END RECORD
DEFINE r_n01		RECORD LIKE rolt001.*
DEFINE r_n03		RECORD LIKE rolt003.*
DEFINE r_n80		RECORD LIKE rolt080.*
DEFINE ano		LIKE rolt080.n80_ano
DEFINE mes		LIKE rolt080.n80_mes
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
CALL fl_lee_compania_roles(vg_codcia) RETURNING r_n01.*
LET vm_aport_patr = r_n01.n01_porc_aporte
CALL fl_lee_proceso_roles('Q1') RETURNING r_n03.*
LET vm_subtit1 = r_n03.n03_nombre_abr
CALL fl_lee_proceso_roles('Q2') RETURNING r_n03.*
LET vm_subtit2 = r_n03.n03_nombre_abr
INITIALIZE vm_aport_trab TO NULL
SELECT n07_factor * 100 INTO vm_aport_trab FROM rolt007
	WHERE n07_cod_rubro IN
		(SELECT n06_cod_rubro FROM rolt006
			WHERE n06_flag_ident = 'FC')
START REPORT reporte_fondo_aport_men TO PIPE comando
--START REPORT reporte_fondo_aport_men TO FILE "fondo_aport_men.txt"
LET num_empl = 0
FOREACH q_rolt080 INTO r_n80.*, nom
	LET rm_n80.n80_moneda    = r_n80.n80_moneda
	LET r_report.cod_trab    = r_n80.n80_cod_trab
	LET r_report.nombres     = nom
	LET ano = rm_n80.n80_ano
	LET mes = rm_n80.n80_mes - 1
	IF mes = 0 THEN
		LET ano = rm_n80.n80_ano - 1
		LET mes = 12
	END IF
	SELECT NVL((n80_q1_trab + n80_q1_patr + n80_q2_trab + n80_q2_patr), 0)
		INTO r_report.acum_mes_ant
		FROM rolt080
		WHERE n80_compania = r_n80.n80_compania
		  AND n80_ano      = ano
		  AND n80_mes      = mes
		  AND n80_cod_trab = r_n80.n80_cod_trab
	LET r_report.q1_trab     = r_n80.n80_q1_trab
	LET r_report.q1_patr     = r_n80.n80_q1_patr
	LET r_report.q2_trab     = r_n80.n80_q2_trab
	LET r_report.q2_patr     = r_n80.n80_q2_patr
	LET r_report.total       = r_report.q1_trab + r_report.q1_patr +
				   r_report.q2_trab + r_report.q2_patr
	LET r_report.tot_mes_ant = r_report.total + r_report.acum_mes_ant
	OUTPUT TO REPORT reporte_fondo_aport_men(r_report.*)
END FOREACH
FINISH REPORT reporte_fondo_aport_men

END FUNCTION



REPORT reporte_fondo_aport_men(r_report)
DEFINE r_report		RECORD
				cod_trab	LIKE rolt080.n80_cod_trab,
				nombres		LIKE rolt030.n30_nombres,
				acum_mes_ant	DECIMAL(14,2),
				q1_trab		DECIMAL(14,2),
				q1_patr		DECIMAL(14,2),
				q2_trab		DECIMAL(14,2),
				q2_patr		DECIMAL(14,2),
				total		DECIMAL(14,2),
				tot_mes_ant	DECIMAL(14,2)
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
	RIGHT MARGIN	132
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
	CALL fl_justifica_titulo('I', "LISTADO APORTACIONES MENSUAL FONDO CENSATIA", 80)
		RETURNING titulo
	CALL fl_lee_moneda(rm_n80.n80_moneda) RETURNING r_g13.*
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 001, rm_g01.g01_razonsocial,
  	      COLUMN 122, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 039, titulo CLIPPED,
	      COLUMN 126, UPSHIFT(vg_proceso)
	SKIP 1 LINES
	PRINT COLUMN 049, "** ANIO   : ", rm_n80.n80_ano USING '&&&&'
	PRINT COLUMN 049, "** MES    : ", rm_n80.n80_mes USING '&&', ' ',
			fl_justifica_titulo('I', tit_mes, 10)
	PRINT COLUMN 049, "** MONEDA : ", rm_n80.n80_moneda, ' ',
			r_g13.g13_nombre
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
		1 SPACES, TIME,
	      COLUMN 114, usuario
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 050, retorna_subtit(vm_subtit1, 27, '-'),
	      COLUMN 078, retorna_subtit(vm_subtit2, 27, '-')
	PRINT COLUMN 001, "COD.",
	      COLUMN 006, "   E  M  P  L  E  A  D  O",
	      COLUMN 036, "SAL. MES ANT.",
	      COLUMN 050, vm_aport_trab USING '&.##', "% PERSON.",
	      COLUMN 064, vm_aport_patr USING '&.##', "% PATRON.",
	      COLUMN 078, vm_aport_trab USING '&.##', "% PERSON.",
	      COLUMN 092, vm_aport_patr USING '&.##', "% PATRON.",
	      COLUMN 106, "    T O T A L",
	      COLUMN 120, "TOT. ACU. MES"
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------";
	print ASCII escape;
	print ASCII des_neg

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 001, r_report.cod_trab		USING "&&&&",
	      COLUMN 006, r_report.nombres[1, 29],
	      COLUMN 036, r_report.acum_mes_ant		USING "--,---,--&.##",
	      COLUMN 050, r_report.q1_trab 		USING "--,---,--&.##",
	      COLUMN 064, r_report.q1_patr 		USING "--,---,--&.##",
	      COLUMN 078, r_report.q2_trab 		USING "--,---,--&.##",
	      COLUMN 092, r_report.q2_patr 		USING "--,---,--&.##",
	      COLUMN 106, r_report.total 		USING "--,---,--&.##",
	      COLUMN 120, r_report.tot_mes_ant 		USING "--,---,--&.##"
	LET num_empl = num_empl + 1

ON LAST ROW
	NEED 2 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 036, 2 SPACES, "-------------",
	      COLUMN 050, 2 SPACES, "-------------",
	      COLUMN 064, 2 SPACES, "-------------",
	      COLUMN 078, 2 SPACES, "-------------",
	      COLUMN 092, 2 SPACES, "-------------",
	      COLUMN 106, 2 SPACES, "-------------",
	      COLUMN 120, 2 SPACES, "-------------"
	PRINT COLUMN 001, num_empl USING "#,##&", " EMPLEADOS",
	      COLUMN 024, "TOTALES ==> ",
	      COLUMN 036, SUM(r_report.acum_mes_ant)	USING "--,---,--&.##",
	      COLUMN 050, SUM(r_report.q1_trab)		USING "--,---,--&.##",
	      COLUMN 064, SUM(r_report.q1_patr)		USING "--,---,--&.##",
	      COLUMN 078, SUM(r_report.q2_trab)		USING "--,---,--&.##",
	      COLUMN 092, SUM(r_report.q2_patr)		USING "--,---,--&.##",
	      COLUMN 106, SUM(r_report.total)		USING "--,---,--&.##",
	      COLUMN 120, SUM(r_report.tot_mes_ant)	USING "--,---,--&.##";
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII desact_comp

END REPORT



FUNCTION retorna_subtit(subtit_p, lim, car)
DEFINE subtit_p		LIKE rolt003.n03_nombre_abr
DEFINE lim		SMALLINT
DEFINE car		CHAR(1)
DEFINE i, l		SMALLINT
DEFINE subtit		VARCHAR(30)

LET l      = lim - LENGTH(subtit_p)
LET subtit = car
FOR i = 1 TO (l / 2) - 2
	LET subtit = subtit, car
END FOR
LET subtit = subtit, ' ', subtit_p, ' '
LET l      = LENGTH(subtit) + 2
FOR i = l TO lim
	LET subtit = subtit, car
END FOR
RETURN subtit

END FUNCTION
