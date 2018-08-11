--------------------------------------------------------------------------------
-- Titulo           : repp435.4gl - Listado de Guías de Remisión
-- Elaboracion      : 22-Sep-2006
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp435 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_par 		RECORD 
				fecha_ini	DATE,
				fecha_fin	DATE
			END RECORD
DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE vm_fin_mes	DATE



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp435.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parametros correcto
	CALL fl_mostrar_mensaje('Número de parametros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp435'
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
LET lin_menu   = 0
LET row_ini    = 3
LET num_rows   = 6
LET num_cols   = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_repp435 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_repf435_1 FROM "../forms/repf435_1"
ELSE
	OPEN FORM f_repf435_1 FROM "../forms/repf435_1c"
END IF
DISPLAY FORM f_repf435_1
CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()

INITIALIZE rm_par.* TO NULL
SELECT MDY(MONTH(NVL(MAX(DATE(r95_fecing)), vg_fecha)), 01,
	YEAR(NVL(MAX(DATE(r95_fecing)), vg_fecha))) + 1 UNITS MONTH - 1 UNITS DAY
	INTO vm_fin_mes
	FROM rept095
	WHERE r95_compania  = vg_codcia
	  AND r95_localidad = vg_codloc
LET rm_par.fecha_ini = MDY(MONTH(vm_fin_mes), 01, YEAR(vm_fin_mes))
LET rm_par.fecha_fin = vm_fin_mes
WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL control_impresion_guia()
END WHILE
CLOSE WINDOW w_repp435
EXIT PROGRAM

END FUNCTION



FUNCTION lee_parametros()
DEFINE fec_ini		DATE
DEFINE fec_fin		DATE
DEFINE mensaje		VARCHAR(100)

LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
	BEFORE FIELD fecha_ini
		LET fec_ini = rm_par.fecha_ini
	BEFORE FIELD fecha_fin
		LET fec_fin = rm_par.fecha_fin
	AFTER FIELD fecha_ini 
		IF rm_par.fecha_ini IS NOT NULL THEN
			IF rm_par.fecha_ini > vg_fecha THEN
				LET mensaje = 'La fecha inicial no puede ser ',
						'mayor a la fecha: ',
						vm_fin_mes USING "dd-mm-yyyy",
						'.'
				CALL fl_mostrar_mensaje(mensaje, 'exclamation')
				LET rm_par.fecha_ini = fec_ini     
				DISPLAY BY NAME rm_par.fecha_ini
				NEXT FIELD fecha_ini
			END IF
		ELSE
			LET rm_par.fecha_ini = fec_ini     
			DISPLAY BY NAME rm_par.fecha_ini
		END IF
	AFTER FIELD fecha_fin 
		IF rm_par.fecha_fin IS NOT NULL THEN
			IF rm_par.fecha_fin > vg_fecha THEN
				LET mensaje = 'La fecha final no puede ser ',
						'mayor a la fecha: ',
						vm_fin_mes USING "dd-mm-yyyy",
						'.'
				CALL fl_mostrar_mensaje(mensaje, 'exclamation')
				LET rm_par.fecha_fin = vm_fin_mes
				DISPLAY BY NAME rm_par.fecha_fin
				NEXT FIELD fecha_fin
			END IF
		ELSE
			LET rm_par.fecha_fin = fec_fin
			DISPLAY BY NAME rm_par.fecha_fin
		END IF
	AFTER INPUT
		IF rm_par.fecha_ini > rm_par.fecha_fin THEN
			CALL fl_mostrar_mensaje('Fecha inicial debe ser menor a fecha final.','exclamation')
			NEXT FIELD fecha_ini
		END IF
END INPUT

END FUNCTION



FUNCTION control_impresion_guia()
DEFINE r_rep		RECORD
				r95_fecha_emi	LIKE rept095.r95_fecha_emi,
				r20_cant_ven	LIKE rept020.r20_cant_ven,
				r20_item	LIKE rept020.r20_item,
				r72_desc_clase	LIKE rept072.r72_desc_clase,
				r10_nombre	LIKE rept010.r10_nombre,
				r20_precio	LIKE rept020.r20_precio,
				tot_precio	DECIMAL(12,2),
				r95_num_sri	LIKE rept095.r95_num_sri
			END RECORD
DEFINE query		CHAR(4000)
DEFINE comando		VARCHAR(100)

LET query = 'SELECT r95_fecha_emi, r20_cant_ven, r20_item, r72_desc_clase,',
		' r10_nombre, r20_precio, r20_cant_ven * r20_precio,',
		' r95_num_sri ',
		' FROM rept095, rept097, rept020, rept010, rept072 ',
		' WHERE r95_compania      = ', vg_codcia,
		'   AND r95_localidad     = ', vg_codloc,
		'   AND r95_fecha_emi     BETWEEN "', rm_par.fecha_ini,
					   '" AND "', rm_par.fecha_fin,'"',
		'   AND r97_compania      = r95_compania ',
		'   AND r97_localidad     = r95_localidad ',
		'   AND r97_guia_remision = r95_guia_remision ',
		'   AND r20_compania      = r97_compania ',
		'   AND r20_localidad     = r97_localidad ',
		'   AND r20_cod_tran      = r97_cod_tran ',
		'   AND r20_num_tran      = r97_num_tran ',
		'   AND r10_compania      = r20_compania ',
		'   AND r10_codigo        = r20_item ',
		'   AND r72_compania      = r10_compania ',
		'   AND r72_linea         = r10_linea ',
		'   AND r72_sub_linea     = r10_sub_linea ',
		'   AND r72_cod_grupo     = r10_cod_grupo ',
		'   AND r72_cod_clase     = r10_cod_clase ',
		' UNION ALL ',
	'SELECT r95_fecha_emi, r20_cant_ven, r20_item, r72_desc_clase,',
		' r10_nombre, r20_precio, r20_cant_ven * r20_precio,',
		' r95_num_sri ',
		' FROM rept095, rept096, rept036, rept034, rept020, rept010,',
			' rept072 ',
		' WHERE r95_compania      = ', vg_codcia,
		'   AND r95_localidad     = ', vg_codloc,
		'   AND r95_fecha_emi     BETWEEN "', rm_par.fecha_ini,
					   '" AND "', rm_par.fecha_fin,'"',
		'   AND r96_compania      = r95_compania ',
		'   AND r96_localidad     = r95_localidad ',
		'   AND r96_guia_remision = r95_guia_remision ',
		'   AND r36_compania      = r96_compania ',
		'   AND r36_localidad     = r96_localidad ',
		'   AND r36_bodega        = r96_bodega ',
		'   AND r36_num_entrega   = r96_num_entrega ',
		'   AND r34_compania      = r36_compania ',
		'   AND r34_localidad     = r36_localidad ',
		'   AND r34_bodega        = r36_bodega ',
		'   AND r34_num_ord_des   = r36_num_ord_des ',
		'   AND r20_compania      = r34_compania ',
		'   AND r20_localidad     = r34_localidad ',
		'   AND r20_cod_tran      = r34_cod_tran ',
		'   AND r20_num_tran      = r34_num_tran ',
		'   AND r10_compania      = r20_compania ',
		'   AND r10_codigo        = r20_item ',
		'   AND r72_compania      = r10_compania ',
		'   AND r72_linea         = r10_linea ',
		'   AND r72_sub_linea     = r10_sub_linea ',
		'   AND r72_cod_grupo     = r10_cod_grupo ',
		'   AND r72_cod_clase     = r10_cod_clase ',
		' ORDER BY r95_fecha_emi, r95_num_sri '
PREPARE cons_guia FROM query
DECLARE q_guia CURSOR FOR cons_guia
OPEN q_guia
FETCH q_guia INTO r_rep.*
IF STATUS = NOTFOUND THEN
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE q_guia
	FREE q_guia
	RETURN
END IF
CLOSE q_guia
CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN
END IF
START REPORT imprimir_listado TO PIPE comando
FOREACH q_guia INTO r_rep.*
	OUTPUT TO REPORT imprimir_listado(r_rep.*)
END FOREACH
FINISH REPORT imprimir_listado

END FUNCTION



REPORT imprimir_listado(r_rep)
DEFINE r_rep		RECORD
				r95_fecha_emi	LIKE rept095.r95_fecha_emi,
				r20_cant_ven	LIKE rept020.r20_cant_ven,
				r20_item	LIKE rept020.r20_item,
				r72_desc_clase	LIKE rept072.r72_desc_clase,
				r10_nombre	LIKE rept010.r10_nombre,
				r20_precio	LIKE rept020.r20_precio,
				tot_precio	DECIMAL(12,2),
				r95_num_sri	LIKE rept095.r95_num_sri
			END RECORD
DEFINE r_g50		RECORD LIKE gent050.*
DEFINE usuario		VARCHAR(19,15)
DEFINE modulo		VARCHAR(40)
DEFINE escape		SMALLINT
DEFINE act_comp		SMALLINT
DEFINE desact_comp	SMALLINT
DEFINE act_10cpi	SMALLINT
DEFINE act_12cpi	SMALLINT
DEFINE act_neg, des_neg	SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	0
	RIGHT MARGIN	132
	BOTTOM MARGIN	4
	PAGE LENGTH	66

FORMAT

PAGE HEADER
	LET escape	= 27		# Iniciar sec. impresión
	LET act_comp	= 15		# Activar Comprimido.
	LET desact_comp	= 18		# Cancelar Comprimido.
	LET act_neg	= 71		# Activar negrita.
	LET des_neg	= 72		# Desactivar negrita.
	LET act_10cpi	= 80		# Comprimido 10 CPI.
	LET act_12cpi	= 77		# Comprimido 12 CPI.
	CALL fl_lee_modulo(vg_modulo) RETURNING r_g50.*
	LET modulo      = "MODULO: ", r_g50.g50_nombre[1, 19] CLIPPED
	LET usuario     = "USUARIO: ", vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	print ASCII escape;
	print ASCII act_comp;
	print ASCII escape;
	print ASCII act_10cpi;
	PRINT COLUMN 005, rm_g01.g01_razonsocial,
  	      COLUMN 126, "PAGINA: ", PAGENO USING "&&&"
	PRINT COLUMN 001, modulo CLIPPED,
	      COLUMN 049, "LISTADO GUIAS DE REMISISON MENSUALES",
	      COLUMN 126, UPSHIFT(vg_proceso) CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 052, "** FECHA INICIAL : ", rm_par.fecha_ini
							USING "dd-mm-yyyy"
	PRINT COLUMN 052, "** FECHA FINAL   : ", rm_par.fecha_fin
							USING "dd-mm-yyyy"
	SKIP 1 LINES
	PRINT COLUMN 001, "FECHA IMPRESION: ", vg_fecha USING "dd-mm-yyyy",
 		1 SPACES, TIME,
	      COLUMN 114, usuario
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
	PRINT COLUMN 001, "FECHA",
	      COLUMN 012, "   CANTIDAD",
	      COLUMN 024, "CODIGO",
	      COLUMN 046, "DESCRIPCION DE MATERIALES",
	      COLUMN 085, "  PRECIO UNIT.",
	      COLUMN 101, "  TOTAL PRECIO",
	      COLUMN 117, "     NUMERO GUIA"
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 4 LINES
	PRINT COLUMN 001, r_rep.r95_fecha_emi	USING "dd-mm-yyyy",
	      COLUMN 012, r_rep.r20_cant_ven	USING "####,##&.##",
	      COLUMN 024, r_rep.r20_item[1, 6]	CLIPPED,
	      COLUMN 031, r_rep.r72_desc_clase[1, 36]	CLIPPED, ' ',
			  r_rep.r10_nombre[1, 65]	CLIPPED
	PRINT COLUMN 085, r_rep.r20_precio	USING "---,---,--&.##",
	      COLUMN 101, r_rep.tot_precio	USING "---,---,--&.##",
	      COLUMN 117, fl_justifica_titulo('D', r_rep.r95_num_sri, 16)
	
ON LAST ROW
	NEED 2 LINES
	print ASCII escape;
	print ASCII act_neg;
	PRINT COLUMN 014, "-----------",
	      COLUMN 103, "--------------"
	PRINT COLUMN 001, "TOTAL ==>  ",
		SUM(r_rep.r20_cant_ven) USING "----,--&.##",
	      COLUMN 101, SUM(r_rep.tot_precio)		USING "---,---,--&.##";
	print ASCII escape;
	print ASCII des_neg;
	print ASCII escape;
	print ASCII desact_comp

END REPORT
