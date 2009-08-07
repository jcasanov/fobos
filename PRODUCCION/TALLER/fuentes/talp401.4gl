------------------------------------------------------------------------------
-- Titulo           : talp401.4gl - Listado de Costo de Facturas de Taller
-- Elaboracion      : 13-Ago-2002
-- Autor            : NPC
-- Formato Ejecucion: fglrun talp401 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_t23		RECORD LIKE talt023.*
DEFINE rm_t04		RECORD LIKE talt004.*
DEFINE vm_tipo_ot	LIKE talt023.t23_tipo_ot
DEFINE fecha_desde	DATE
DEFINE fecha_hasta	DATE
DEFINE rm_g13		RECORD LIKE gent013.*

DEFINE vm_top		SMALLINT
DEFINE vm_left		SMALLINT
DEFINE vm_right		SMALLINT
DEFINE vm_bottom	SMALLINT
DEFINE vm_page		SMALLINT


MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp401.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'talp401'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPEN WINDOW w_mas AT 3,2 WITH 16 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rep FROM "../forms/talf401_1"
DISPLAY FORM f_rep
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE query		VARCHAR(1000)
DEFINE comando 		VARCHAR(100)
DEFINE r_report 	RECORD
				fecha		DATETIME YEAR TO SECOND,
				orden		LIKE talt023.t23_orden,
				factura		LIKE talt023.t23_num_factura,
				cliente		LIKE talt023.t23_nom_cliente,
				mo_ci_ext	DECIMAL (12,2),
				rep_ci_ext	DECIMAL (12,2),
				rep_alm		LIKE talt023.t23_val_rp_alm,
				viaticos	LIKE talt023.t23_val_otros1,
				suministros	LIKE talt023.t23_val_otros2,
				tot_neto	LIKE talt023.t23_tot_neto
			END RECORD
DEFINE fecha		VARCHAR(30)
DEFINE expr_condic	VARCHAR(120)
DEFINE expr_estado	VARCHAR(100)
DEFINE expr_tablas	VARCHAR(60)
DEFINE expr_tipo	VARCHAR(60)

LET vm_top    = 0
LET vm_left   = 1
LET vm_right  = 220
LET vm_bottom = 0
LET vm_page   = 45

LET fecha_hasta 	= TODAY
LET fecha_desde 	= TODAY
LET rm_t23.t23_estado 	= "A"
LET rm_t23.t23_moneda 	= rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_t23.t23_moneda)
	RETURNING rm_g13.*
DISPLAY rm_g13.g13_nombre TO nom_mon
DISPLAY BY NAME rm_t23.t23_estado

WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF

	IF rm_t23.t23_estado = 'A' THEN
		LET fecha = 't23_fecing'
	END IF
	IF rm_t23.t23_estado = 'C' THEN
		LET fecha = 't23_fec_cierre'
	END IF
	LET expr_estado = '  AND t23_estado    = "', rm_t23.t23_estado, '"'
	IF rm_t23.t23_estado = 'F' THEN
		LET fecha	= 't23_fec_factura'
		LET expr_estado = '  AND t23_estado    IN ("F","D") '
	END IF
	LET expr_tablas = ' FROM talt004, talt023 '
	LET expr_condic = NULL
	IF rm_t23.t23_estado = 'D' THEN
		LET fecha 	= 't28_fec_anula'
		LET expr_tablas = ' FROM talt028, talt004, talt023 '
		LET expr_condic = '  AND t28_compania  = t23_compania ',
				  '  AND t28_localidad = t23_localidad ',
				  '  AND t28_ot_ant    = t23_orden '
	END IF	
	LET expr_tipo = NULL
	IF vm_tipo_ot IS NOT NULL THEN
		LET expr_tipo = '  AND t23_tipo_ot   = "', vm_tipo_ot, '"'
	END IF

	LET query = 'SELECT ', fecha, ', t23_orden, t23_num_factura,',
			' t23_nom_cliente, t23_val_mo_cti + t23_val_mo_ext,',
			' t23_val_rp_tal + t23_val_rp_ext + t23_val_rp_cti,',
			' t23_val_rp_alm, t23_val_otros1, t23_val_otros2,',
			' t23_tot_neto ',
			expr_tablas,
			'WHERE t23_compania  = ', vg_codcia,
			'  AND t23_localidad = ', vg_codloc,
			expr_estado,
			expr_tipo,
			'  AND t23_moneda    = "', rm_t23.t23_moneda, '"',
			expr_condic,
			'  AND t04_compania  = t23_compania ',
			'  AND t04_modelo    = t23_modelo ',
			'  AND t04_linea     = "', rm_t04.t04_linea, '"',
			'  AND DATE(', fecha, ') BETWEEN  "', fecha_desde, '"',
		        '  AND "', fecha_hasta, '"',
			' ORDER BY 1'

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
	CLOSE q_reporte
	START REPORT report_facturas_taller TO PIPE comando
	FOREACH q_reporte INTO r_report.* 
		OUTPUT TO REPORT report_facturas_taller(r_report.*)
	END FOREACH
	FINISH REPORT report_facturas_taller
END WHILE 
END FUNCTION



FUNCTION lee_parametros()
DEFINE r_t01		RECORD LIKE talt001.*
DEFINE r_t05		RECORD LIKE talt005.*
DEFINE r_t04		RECORD LIKE talt004.*

OPTIONS INPUT NO WRAP
INITIALIZE r_t01.*, r_t05.*, r_t04.* TO NULL
LET int_flag = 0
INPUT BY NAME rm_t23.t23_moneda, rm_t04.t04_linea, vm_tipo_ot,
	      fecha_desde, fecha_hasta, rm_t23.t23_estado
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF INFIELD(t23_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING rm_g13.g13_moneda, rm_g13.g13_nombre, 
					  rm_g13.g13_decimales
			IF rm_g13.g13_moneda IS NOT NULL THEN
				LET rm_t23.t23_moneda = rm_g13.g13_moneda
				DISPLAY BY NAME rm_t23.t23_moneda
				DISPLAY rm_g13.g13_nombre TO nom_mon
			END IF
		END IF
		IF INFIELD(t04_linea) THEN
			CALL fl_ayuda_marcas_taller(vg_codcia)
				RETURNING r_t01.t01_linea, r_t01.t01_nombre
			IF r_t01.t01_linea IS NOT NULL THEN
				LET rm_t04.t04_linea = r_t01.t01_linea
				DISPLAY BY NAME rm_t04.t04_linea,
						r_t01.t01_nombre
			END IF
		END IF
		IF INFIELD(vm_tipo_ot) THEN
			CALL fl_ayuda_tipo_orden_trabajo(vg_codcia) 
				RETURNING r_t05.t05_tipord, r_t05.t05_nombre
			IF r_t05.t05_tipord IS NOT NULL THEN
				LET vm_tipo_ot = r_t05.t05_tipord
				DISPLAY BY NAME vm_tipo_ot
				DISPLAY r_t05.t05_nombre TO nom_tipo_ot  
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD t23_moneda
		IF rm_t23.t23_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_t23.t23_moneda)
				RETURNING rm_g13.*
			IF rm_g13.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe la moneda en la Compañía.','exclamation')
				CLEAR nom_mon
				NEXT FIELD t23_moneda
			ELSE
				LET rm_t23.t23_moneda = rm_g13.g13_moneda
				DISPLAY BY NAME rm_t23.t23_moneda
				DISPLAY rm_g13.g13_nombre TO nom_mon
			END IF
		ELSE
			CLEAR nom_mon
		END IF
	AFTER FIELD t04_linea
		IF rm_t04.t04_linea IS NOT NULL THEN
			CALL fl_lee_linea_taller(vg_codcia, rm_t04.t04_linea)
				RETURNING r_t01.*
			IF r_t01.t01_linea IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe esa Línea en la Compañía.','exclamation')
				NEXT FIELD t04_linea
			END IF
			DISPLAY BY NAME r_t01.t01_nombre
		ELSE
			CLEAR t01_nombre
		END IF
	AFTER FIELD vm_tipo_ot
		IF vm_tipo_ot IS NOT NULL THEN
			CALL fl_lee_tipo_orden_taller(vg_codcia, 
						      vm_tipo_ot)
				RETURNING r_t05.*
			IF r_t05.t05_tipord IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe el Tipo de Orden de Trabajo en la Compañía.','exclamation')
				NEXT FIELD vm_tipo_ot
			END IF
			DISPLAY r_t05.t05_nombre TO nom_tipo_ot
		ELSE
			CLEAR nom_tipo_ot
		END IF
	AFTER INPUT 
		IF fecha_desde > fecha_hasta THEN
			CALL fgl_winmessage(vg_producto,'La fecha desde debe ser menor a la fecha hasta','exclamation')
			NEXT FIELD fecha_desde
		END IF
		IF fecha_hasta > TODAY THEN
			CALL fgl_winmessage(vg_producto,'La fecha hasta debe ser menor hoy día','exclamation')
			NEXT FIELD fecha_hasta
		END IF
		IF fecha_desde IS NULL THEN
			NEXT FIELD fecha_desde
		END IF
		IF fecha_hasta IS NULL THEN
			NEXT FIELD fecha_hasta
		END IF
		IF rm_t04.t04_linea IS NULL THEN
			NEXT FIELD t04_linea
		END IF
END INPUT

END FUNCTION



REPORT report_facturas_taller (r_report)
DEFINE r_report 	RECORD
				fecha		DATETIME YEAR TO SECOND,
				orden		LIKE talt023.t23_orden,
				factura		LIKE talt023.t23_num_factura,
				cliente		LIKE talt023.t23_nom_cliente,
				mo_ci_ext	DECIMAL (12,2),
				rep_ci_ext	DECIMAL (12,2),
				rep_alm		LIKE talt023.t23_val_rp_alm,
				viaticos	LIKE talt023.t23_val_otros1,
				suministros	LIKE talt023.t23_val_otros2,
				tot_neto	LIKE talt023.t23_tot_neto
			END RECORD
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE long		SMALLINT
DEFINE r_t01		RECORD LIKE talt001.*
DEFINE r_t05		RECORD LIKE talt005.*
DEFINE nom_estado	VARCHAR(15)

OUTPUT
	TOP MARGIN	vm_top
	LEFT MARGIN	vm_left
	RIGHT MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE LENGTH	vm_page
FORMAT

PAGE HEADER
	print 'E'; 
	print '&l26A';	-- Indica que voy a trabajar con hojas A4
	print '&l1O';		-- Modo landscape
	print '&k2S'	                -- Letra condensada (16 cpi)
	--print '&k4S'	        -- Letra (12 cpi)

	LET modulo     = "Módulo: Taller"
	LET long       = LENGTH(modulo)
	LET usuario    = 'Usuario: ', vg_usuario
	LET nom_estado = muestra_estado()
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I','LISTADO COSTO DE FACTRURAS DE TALLER',80)
		RETURNING titulo
	CALL fl_lee_linea_taller(vg_codcia, rm_t04.t04_linea)
		RETURNING r_t01.*
	CALL fl_lee_tipo_orden_taller(vg_codcia, vm_tipo_ot)
		RETURNING r_t05.*
	PRINT COLUMN 1,   rg_cia.g01_razonsocial,
	      COLUMN 122, 'Página: ', PAGENO USING '&&&'
	PRINT COLUMN 1,   modulo CLIPPED,
	      COLUMN 49,  titulo CLIPPED,
	      COLUMN 126, UPSHIFT(vg_proceso) 
	PRINT COLUMN 47,  '** Moneda        : ', rm_t23.t23_moneda, ' ',
					 	 rm_g13.g13_nombre
	PRINT COLUMN 47,  '** Línea (Marca) : ', rm_t04.t04_linea, ' ',
						 r_t01.t01_nombre
	IF vm_tipo_ot IS NOT NULL THEN
		PRINT COLUMN 47, '** Tipo de Orden : ', vm_tipo_ot, ' ',
			  			        r_t05.t05_nombre
	END IF
	PRINT COLUMN 47,  '** Estado        : ', rm_t23.t23_estado, ' ',
						 nom_estado 
	PRINT COLUMN 47,  '** Fecha Inicial : ', fecha_desde USING 'dd-mm-yyyy'
	PRINT COLUMN 47,  '** Fecha Final   : ', fecha_hasta USING 'dd-mm-yyyy'
	PRINT COLUMN 1, 'Fecha Impresión: ', TODAY
					  USING 'dd-mm-yyyy', 1 SPACES, TIME,
	      COLUMN 113, usuario
	SKIP 1 LINES
	PRINT '==================================================================================================================================='
	PRINT COLUMN 1,   'Fecha',
	      COLUMN 10,  '  Orden',
	      COLUMN 18,  '        Factura',
	      COLUMN 34,  'Cliente',
	      COLUMN 55,  'M.O. Externa',
	      COLUMN 68,  'Rep.Externos',
	      COLUMN 81,  'Rep. Almacen',
	      COLUMN 94,  '    Viaticos',
	      COLUMN 107, ' Suministros',
	      COLUMN 120, '  Total Neto'
	PRINT '==================================================================================================================================='

ON EVERY ROW
	NEED 3 LINES
	PRINT COLUMN 1,	  DATE(r_report.fecha)	USING 'dd-mm-yy',
	      COLUMN 10,  r_report.orden  	USING '######&',
	      COLUMN 18,  r_report.factura	USING '##############&',
	      COLUMN 34,  r_report.cliente[1,20],
	      COLUMN 55,  r_report.mo_ci_ext	USING '#,###,##&.##',
	      COLUMN 68,  r_report.rep_ci_ext 	USING '#,###,##&.##',
	      COLUMN 81,  r_report.rep_alm	USING '#,###,##&.##',
	      COLUMN 94,  r_report.viaticos	USING '#,###,##&.##',
	      COLUMN 107, r_report.suministros	USING '#,###,##&.##',
	      COLUMN 120, r_report.tot_neto	USING '#,###,##&.##'

ON LAST ROW
	--print '&k4S'	        -- Letra (12 cpi)
	PRINT COLUMN 55,  '------------',
	      COLUMN 68,  '------------',
	      COLUMN 81,  '------------',
	      COLUMN 94,  '------------',
	      COLUMN 107, '------------',
	      COLUMN 120, '------------'
	PRINT COLUMN 42, 'TOTALES ==>  ',
	      COLUMN 55,  SUM(r_report.mo_ci_ext)	USING '#,###,##&.##',
	      COLUMN 68,  SUM(r_report.rep_ci_ext) 	USING '#,###,##&.##',
	      COLUMN 81,  SUM(r_report.rep_alm)		USING '#,###,##&.##',
	      COLUMN 94,  SUM(r_report.viaticos)	USING '#,###,##&.##',
	      COLUMN 107, SUM(r_report.suministros)	USING '#,###,##&.##',
	      COLUMN 120, SUM(r_report.tot_neto)  	USING '#,###,##&.##'

END REPORT



FUNCTION borrar_cabecera()

CLEAR FORM
INITIALIZE rm_t23.*, rm_t04.* TO NULL

END FUNCTION



FUNCTION muestra_estado()

IF rm_t23.t23_estado = 'A' THEN
	RETURN 'ACTIVAS'
END IF
IF rm_t23.t23_estado = 'C' THEN
	RETURN 'CERRADAS'
END IF
IF rm_t23.t23_estado = 'F' THEN
	RETURN 'FACTURADAS'
END IF
IF rm_t23.t23_estado = 'D' THEN
	RETURN 'DEVUELTAS'
END IF

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo,
			    'stop')
	EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 'stop')
	EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
	LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc, 'stop')
	EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
	CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 'stop')
	EXIT PROGRAM
END IF

END FUNCTION
