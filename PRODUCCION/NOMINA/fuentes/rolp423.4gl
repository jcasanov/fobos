--------------------------------------------------------------------------------
-- Titulo           : rolp423.4gl - Lista alfabetica unificada (Empleados)
-- Elaboracion      : 01-Dic-2003
-- Autor            : NPC
-- Formato Ejecucion: fglrun rolp423 base módulo compañía
-- 			[num_año] [agrupado] [con_sueldo] [estado] [[depto]]
-- Ultima Correccion: 
-- Motivo Correccion:
--------------------------------------------------------------------------------

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_n30		RECORD LIKE rolt030.*
DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE rm_g02		RECORD LIKE gent002.*
DEFINE rm_g34		RECORD LIKE gent034.*
DEFINE vm_estado	LIKE rolt030.n30_estado
DEFINE vm_anio_trab	SMALLINT
DEFINE vm_agrupado	CHAR(1)
DEFINE vm_impr_sueldo	CHAR(1)
DEFINE vm_cabecera	SMALLINT



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/rolp423.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 AND num_args() <> 7 AND num_args() <> 8 THEN
	-- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Numero de parametros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_proceso = 'rolp423'
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
LET num_rows = 12
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
	OPEN FORM f_rol FROM "../forms/rolf423_1"
ELSE
	OPEN FORM f_rol FROM "../forms/rolf423_1c"
END IF
DISPLAY FORM f_rol
INITIALIZE rm_n30.* TO NULL
LET vm_anio_trab   = 0
LET vm_agrupado    = 'S'
LET vm_impr_sueldo = 'N'
WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL imprimir()
END WHILE

END FUNCTION



FUNCTION control_reporte_llamada()

INITIALIZE rm_n30.* TO NULL
LET vm_anio_trab   = arg_val(4)
LET vm_agrupado    = arg_val(5)
LET vm_impr_sueldo = arg_val(6)
LET vm_estado      = arg_val(7)
IF num_args() = 8 THEN
	LET rm_n30.n30_cod_depto = arg_val(8)
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



FUNCTION lee_parametros()
DEFINE anio		SMALLINT

LET int_flag = 0
INPUT BY NAME vm_anio_trab, rm_n30.n30_cod_depto, vm_agrupado, vm_impr_sueldo
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF INFIELD(n30_cod_depto) THEN
                        CALL fl_ayuda_departamentos(vg_codcia)
                                RETURNING rm_g34.g34_cod_depto,rm_g34.g34_nombre
                        IF rm_g34.g34_cod_depto IS NOT NULL THEN
				LET rm_n30.n30_cod_depto = rm_g34.g34_cod_depto
                                DISPLAY BY NAME rm_n30.n30_cod_depto,
						rm_g34.g34_nombre
                        END IF
                END IF
		LET int_flag = 0
	BEFORE FIELD vm_anio_trab
		LET anio = vm_anio_trab
	AFTER FIELD vm_anio_trab
		IF vm_anio_trab IS NULL THEN
			LET vm_anio_trab = anio
			DISPLAY BY NAME vm_anio_trab
		END IF
	AFTER FIELD n30_cod_depto
                IF rm_n30.n30_cod_depto IS NOT NULL THEN
                        CALL fl_lee_departamento(vg_codcia,rm_n30.n30_cod_depto)
                                RETURNING rm_g34.*
                        IF rm_g34.g34_compania IS NULL  THEN
                                CALL fgl_winmessage(vg_producto, 'Departamento no existe.','exclamation')
                                NEXT FIELD n30_cod_depto
                        END IF
                        DISPLAY BY NAME rm_g34.g34_nombre
		ELSE
			CLEAR g34_nombre
                END IF
	AFTER INPUT
		IF rm_n30.n30_cod_depto IS NOT NULL THEN
			LET vm_agrupado = 'N'
			DISPLAY BY NAME vm_agrupado
		END IF
END INPUT

END FUNCTION


   
FUNCTION control_reporte(comando)
DEFINE comando		CHAR(100)
DEFINE r_report		RECORD
				cod_trab	LIKE rolt030.n30_cod_trab,
				nombres		LIKE rolt030.n30_nombres,
				cedula		LIKE rolt030.n30_num_doc_id,
				carnet_seg	LIKE rolt030.n30_carnet_seg,
				fecha_nacim	LIKE rolt030.n30_fecha_nacim,
				anios_edad	SMALLINT,
				mes_edad	SMALLINT,
				fecha_ing	LIKE rolt030.n30_fecha_ing,
				anios_antig	SMALLINT,
				mes_antig	SMALLINT,
				sueldo_mes	LIKE rolt030.n30_sueldo_mes
			END RECORD
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE nom		LIKE gent034.g34_nombre
DEFINE query		CHAR(800)
DEFINE expr_est		VARCHAR(100)
DEFINE expr_depto	VARCHAR(100)
DEFINE expr_orden	VARCHAR(100)
DEFINE fecha		DATE
DEFINE dias		SMALLINT

LET fecha      = TODAY - vm_anio_trab UNITS YEAR
LET expr_depto = NULL
IF rm_n30.n30_cod_depto IS NOT NULL THEN
	LET expr_depto = '   AND n30_cod_depto = ', rm_n30.n30_cod_depto
END IF
LET expr_orden = ' ORDER BY g34_nombre, n30_nombres'
IF vm_agrupado = 'N' THEN
	LET expr_orden = ' ORDER BY n30_nombres'
END IF
IF num_args() = 3 THEN
	LET expr_est = '   AND n30_estado    <> "I" '
ELSE
	CALL retorna_estado_expr(vm_estado) RETURNING expr_est
END IF
LET query = 'SELECT rolt030.*, g34_nombre FROM rolt030, gent034 ',
		' WHERE n30_compania   = ', vg_codcia,
		'   AND n30_fecha_ing <= "', fecha, '"',
		expr_est CLIPPED,
		expr_depto CLIPPED,
		'   AND g34_compania   = n30_compania ',
		'   AND g34_cod_depto  = n30_cod_depto ',
		 expr_orden CLIPPED
PREPARE cons FROM query
DECLARE q_rolt030 CURSOR FOR cons
OPEN q_rolt030
FETCH q_rolt030 INTO r_n30.*, nom
IF STATUS = NOTFOUND THEN
	CLOSE q_rolt030
	FREE q_rolt030
	LET int_flag = 1
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF
START REPORT reporte_empleado_alfa TO PIPE comando
--START REPORT reporte_empleado_alfa TO FILE "empleado_alfa.txt"
FOREACH q_rolt030 INTO r_n30.*, nom
	LET r_report.cod_trab    = r_n30.n30_cod_trab
	LET r_report.nombres     = r_n30.n30_nombres
	LET r_report.cedula      = r_n30.n30_num_doc_id
	LET r_report.carnet_seg  = r_n30.n30_carnet_seg
	LET r_report.fecha_nacim = r_n30.n30_fecha_nacim
	CALL fl_retorna_anios_meses_dias(TODAY, r_n30.n30_fecha_nacim)
		RETURNING r_report.anios_edad, r_report.mes_edad, dias
	LET r_report.fecha_ing	 = r_n30.n30_fecha_ing
	CALL fl_retorna_anios_meses_dias(TODAY, r_n30.n30_fecha_ing)
		RETURNING r_report.anios_antig, r_report.mes_antig, dias
	LET r_report.sueldo_mes  = NULL
	IF vm_impr_sueldo = 'S' THEN
		LET r_report.sueldo_mes = r_n30.n30_sueldo_mes
	END IF
	OUTPUT TO REPORT reporte_empleado_alfa(r_report.*, r_n30.n30_cod_depto)
END FOREACH
FINISH REPORT reporte_empleado_alfa

END FUNCTION



FUNCTION retorna_estado_expr(estado)
DEFINE estado		LIKE rolt030.n30_estado
DEFINE expr_est		VARCHAR(100)

CASE estado
	WHEN 'A'
		LET expr_est = '   AND n30_estado = "A"'
	WHEN 'J'
		LET expr_est = '   AND n30_estado = "J"'
	WHEN 'I'
		LET expr_est = '   AND n30_estado = "I"'
	WHEN 'T'
		LET expr_est = '   AND n30_estado IN ("A", "J", "I")'
END CASE
RETURN expr_est

END FUNCTION



REPORT reporte_empleado_alfa(r_report, departamento)
DEFINE r_report		RECORD
				cod_trab	LIKE rolt030.n30_cod_trab,
				nombres		LIKE rolt030.n30_nombres,
				cedula		LIKE rolt030.n30_num_doc_id,
				carnet_seg	LIKE rolt030.n30_carnet_seg,
				fecha_nacim	LIKE rolt030.n30_fecha_nacim,
				anios_edad	SMALLINT,
				mes_edad	SMALLINT,
				fecha_ing	LIKE rolt030.n30_fecha_ing,
				anios_antig	SMALLINT,
				mes_antig	SMALLINT,
				sueldo_mes	LIKE rolt030.n30_sueldo_mes
			END RECORD
DEFINE departamento	LIKE gent034.g34_cod_depto
DEFINE r_g34		RECORD LIKE gent034.*
DEFINE nom_depto	VARCHAR(36)
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
	CALL fl_justifica_titulo('I', "LISTADO REVISION DE DATOS DE EMPLEADOS", 80)
		RETURNING titulo
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 001, rm_g01.g01_razonsocial,
  	      COLUMN 122, "PAGINA: ", PAGENO USING "&&&"
	SKIP 1 LINES
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 044, titulo CLIPPED,
	      COLUMN 126, UPSHIFT(vg_proceso)
	SKIP 1 LINES
	IF vm_anio_trab > 0 THEN
		PRINT COLUMN 041, "** ANIOS ANTIGUEDAD: ", vm_anio_trab
								USING '&&'
	END IF
	IF rm_n30.n30_cod_depto IS NOT NULL THEN
		PRINT COLUMN 041, "** DEPARTAMENTO    : ",
			rm_n30.n30_cod_depto USING '<<<&&',
			' ', rm_g34.g34_nombre
	END IF
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", TODAY USING "dd-mm-yyyy",
		1 SPACES, TIME,
	      COLUMN 114, usuario
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 080, "--- EDAD ---",
	      COLUMN 106, "-ANTIGUEDAD-"
	PRINT COLUMN 001, "COD.",
	      COLUMN 006, "      E  M  P  L  E  A  D  O",
	      COLUMN 043, "CEDULA ID.",
	      COLUMN 055, "CARNET SE.",
	      COLUMN 067, "FECHA NAC.",
	      COLUMN 080, "ANIOS  MESES",
	      COLUMN 094, "FECHA ING.",
	      COLUMN 106, "ANIOS  MESES",
	      COLUMN 120, " SUELDO MENS."
	PRINT COLUMN 001, "------------------------------------------------------------------------------------------------------------------------------------";
	print ASCII escape;
	print ASCII des_neg
	LET vm_cabecera = 1

BEFORE GROUP OF departamento
	IF vm_agrupado = 'S' THEN
		IF NOT vm_cabecera OR PAGENO > 1 THEN
			SKIP 1 LINES
		END IF
		NEED 2 LINES
		CALL fl_lee_departamento(vg_codcia, departamento)
			RETURNING r_g34.*
		LET nom_depto  = '** ', r_g34.g34_nombre CLIPPED, ' **'
		print ASCII escape;
		print ASCII act_neg;
		PRINT COLUMN 002, nom_depto;
		print ASCII escape;
		print ASCII des_neg
		LET vm_cabecera = 0
	END IF

ON EVERY ROW
	NEED 1 LINES
	PRINT COLUMN 001, r_report.cod_trab		USING "&&&&",
	      COLUMN 006, r_report.nombres[1, 35],
	      COLUMN 043, r_report.cedula[1, 10]	USING "&&&&&&&&&&",
	      COLUMN 055, r_report.carnet_seg[1, 10]	USING "&&&&&&&&&&",
	      COLUMN 067, r_report.fecha_nacim		USING "dd-mm-yyyy",
	      COLUMN 082, r_report.anios_edad		USING "&&",
	      COLUMN 088, r_report.mes_edad		USING "&&",
	      COLUMN 094, r_report.fecha_ing		USING "dd-mm-yyyy",
	      COLUMN 108, r_report.anios_antig		USING "&&",
	      COLUMN 114, r_report.mes_antig		USING "&&",
	      COLUMN 120, r_report.sueldo_mes 		USING "##,###,###.##"

ON LAST ROW
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII desact_comp

END REPORT
