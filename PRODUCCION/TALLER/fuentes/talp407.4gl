--------------------------------------------------------------------------------
-- Titulo           : talp407.4gl - Listado de Gastos de Viaje por Mecánico   --
-- Elaboracion      : 12-ABR-2002					      --
-- Autor            : GVA						      --
-- Formato Ejecucion: fglrun talp407 base módulo compañía localidad	      --
-- Ultima Correccion: 							      --
-- Motivo Correccion: 							      --
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_t23		RECORD LIKE talt023.*
DEFINE rm_t03		RECORD LIKE talt003.*

DEFINE rm_g13		RECORD LIKE gent013.*

DEFINE vm_top		SMALLINT
DEFINE vm_left		SMALLINT
DEFINE vm_right		SMALLINT
DEFINE vm_bottom	SMALLINT
DEFINE vm_page		SMALLINT

DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE
DEFINE vm_moneda	LIKE gent013.g13_moneda

DEFINE expr_fecha	VARCHAR(250)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp407.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   	-- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.',
			    'stop')
	EXIT PROGRAM
END IF

LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)

LET vg_proceso = 'talp407'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPEN WINDOW w_mas AT 3,2 WITH 10 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST + 2, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT NO WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rep FROM '../forms/talf407_1'
DISPLAY FORM f_rep
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE query		VARCHAR(600)
DEFINE comando 		VARCHAR(100)

DEFINE r_report 		RECORD
	num_gasto		LIKE talt030.t30_num_gasto,
	ot			LIKE talt023.t23_orden,
	origen			LIKE talt030.t30_origen,
	destino			LIKE talt030.t30_destino
	END RECORD

LET vm_top    = 0
LET vm_left   = 20
LET vm_right  = 90
LET vm_bottom = 4
LET vm_page   = 66

LET vm_moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(vm_moneda) RETURNING rm_g13.*
DISPLAY rm_g13.g13_nombre TO nom_moneda
LET vm_fecha_fin = TODAY

WHILE TRUE

	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF

	LET query = 'SELECT t30_num_gasto, t30_num_ot, t30_origen,',
			' t30_destino',
			' FROM talt030, talt032',
			'WHERE t30_compania  =',vg_codcia,
			'  AND t30_localidad =',vg_codloc,
			'  AND t30_moneda    ="',vm_moneda,'"',
			'  AND t30_estado    = "A"',
			'  AND DATE(t30_fecing) BETWEEN "',vm_fecha_ini,'"',
			'  AND "',vm_fecha_fin,'"',
			'  AND t30_compania  = t32_compania',
			'  AND t30_localidad = t32_localidad',
			'  AND t30_num_gasto = t32_num_gasto',
			'  AND t32_mecanico  =',rm_t03.t03_mecanico
			 
	PREPARE reporte FROM query
	DECLARE q_reporte CURSOR FOR reporte
	OPEN    q_reporte
	FETCH   q_reporte

	IF STATUS = NOTFOUND THEN
		CLOSE q_reporte
		FREE  q_reporte
		CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF

	START REPORT report_viajes_mecanico TO PIPE comando
	CLOSE q_reporte

	FOREACH q_reporte INTO r_report.* 
		OUTPUT TO REPORT report_viajes_mecanico(r_report.*)
		IF int_flag THEN
			EXIT FOREACH
		END IF
	END FOREACH
	FINISH REPORT report_viajes_mecanico
END WHILE 

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_t03		RECORD LIKE talt003.*

INITIALIZE r_t03.* TO NULL

OPTIONS INPUT WRAP
LET int_flag = 0
INPUT BY NAME rm_t03.t03_mecanico, vm_fecha_ini, vm_fecha_fin, vm_moneda  
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF INFIELD(t03_mecanico) THEN
			CALL fl_ayuda_mecanicos(vg_codcia, 'T')
				RETURNING r_t03.t03_mecanico, r_t03.t03_nombres
			IF r_t03.t03_mecanico IS NOT NULL THEN
				LET rm_t03.t03_mecanico = r_t03.t03_mecanico
				DISPLAY BY NAME rm_t03.t03_mecanico
				DISPLAY r_t03.t03_nombres TO nom_mecanico
			END IF
		END IF
		IF INFIELD(vm_moneda) THEN
        		CALL fl_ayuda_monedas()
	               		RETURNING rm_g13.g13_moneda, rm_g13.g13_nombre,
					  rm_g13.g13_decimales
			IF rm_g13.g13_moneda IS NOT NULL THEN
				LET vm_moneda = rm_g13.g13_moneda
				DISPLAY BY NAME vm_moneda
				DISPLAY rm_g13.g13_nombre TO nom_moneda
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD t03_mecanico
		IF rm_t03.t03_mecanico IS NOT NULL THEN
			CALL fl_lee_mecanico(vg_codcia, rm_t03.t03_mecanico)	
				RETURNING r_t03.*
			IF r_t03.t03_mecanico IS NULL THEN
				CLEAR nom_mecanico
				CALL fgl_winmessage(vg_producto,'No existe Mecánico en la Compañía.','exclamation')
				NEXT FIELD t03_mecanico
			ELSE
				LET rm_t03.* = r_t03.*
				DISPLAY r_t03.t03_nombres TO nom_mecanico
			END IF
		ELSE
			CLEAR nom_mecanico
		END IF
	AFTER FIELD vm_moneda
		IF vm_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(vm_moneda)
				RETURNING rm_g13.*
			IF rm_g13.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe la moneda en la Compañía.','exclamation')
				CLEAR nom_moneda
				NEXT FIELD vm_moneda
			ELSE
				LET vm_moneda = rm_g13.g13_moneda
				DISPLAY BY NAME vm_moneda
				DISPLAY rm_g13.g13_nombre TO nom_moneda
			END IF
		ELSE
			CLEAR nom_moneda
		END IF
	AFTER INPUT 
		IF vm_fecha_ini IS NULL THEN
			NEXT FIELD vm_fecha_ini
		END IF
		IF vm_fecha_fin IS NULL THEN
			NEXT FIELD vm_fecha_fin
		END IF
		IF vm_moneda IS NULL THEN
			NEXT FIELD vm_moneda
		END IF
		IF vm_fecha_fin < vm_fecha_ini THEN
			CALL fgl_winmessage(vg_producto,'La fecha final debe ser menor a la fecha inicial.','exclamation')
			NEXT FIELD vm_fecha_fin
		END IF
		LET expr_fecha = 'DATE(t23_fecing) BETWEEN "',vm_fecha_ini,'"', ' AND ', '"',vm_fecha_fin,'"'
END INPUT

END FUNCTION



REPORT report_viajes_mecanico(num_gasto, ot, origen, destino)
DEFINE	num_gasto		LIKE talt030.t30_num_gasto
DEFINE	ot			LIKE talt023.t23_orden
DEFINE	origen			LIKE talt030.t30_origen
DEFINE	destino			LIKE talt030.t30_destino

DEFINE fecha			LIKE talt033.t33_fecha
DEFINE hora_salida		LIKE talt033.t33_hor_sal_viaje
DEFINE hora_llegada		LIKE talt033.t33_hor_lleg_dest1
DEFINE hora_salida_rep		LIKE talt033.t33_hor_sal_rep

DEFINE titulo		VARCHAR(80)

OUTPUT
	TOP MARGIN	vm_top
	LEFT MARGIN	vm_left
	RIGHT MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE LENGTH	vm_page
FORMAT
PAGE HEADER

	print 'E'; print '&l26A';  -- Indica que voy a trabajar con hojas A4
	print '&k4S'	                -- Letra condensada (12 cpi)

	CALL fl_justifica_titulo('C',
				'LISTADO DE GASTOS DE MECANICO EN VIAJES',60)
		RETURNING titulo

	PRINT COLUMN 1, rg_cia.g01_razonsocial
	PRINT COLUMN 1, titulo CLIPPED
	PRINT COLUMN 1, 'Fecha de Impresión: ', TODAY USING 'dd-mm-yyyy',
			 1 SPACES, TIME,
		COLUMN 48, 'Página: ', PAGENO USING '&&&'

	SKIP 1 LINES

	print '&k2S'	                -- Letra condensada (16 cpi)

	PRINT COLUMN 01, 'Mecánico:', 
	      COLUMN 20, fl_justifica_titulo('I',rm_t03.t03_mecanico,6),
			 '  ', rm_t03.t03_nombres 
	PRINT COLUMN 01, 'Fecha Inicial:',
	      COLUMN 20, vm_fecha_ini,
	      COLUMN 60, 'Fecha Final: ', 
	      COLUMN 80, vm_fecha_fin

	PRINT COLUMN 01, 'Moneda:  ',
	      COLUMN 20,  rm_g13.g13_nombre 

	SKIP 1 LINES

ON EVERY ROW

	CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc, ot)
		RETURNING rm_t23.*

	DECLARE q_talt033 CURSOR FOR
		SELECT t33_fecha, t33_hor_sal_viaje, t33_hor_lleg_dest1,
		       t33_hor_sal_rep
			 FROM talt033 
			WHERE t33_compania  = vg_codcia
			  AND t33_localidad = vg_codloc
			  AND t33_num_gasto = num_gasto 
	FOREACH q_talt033 INTO fecha, hora_salida, hora_llegada,hora_salida_rep
		PRINT COLUMN 01, '** HORAS TRABAJO'
		PRINT COLUMN 10, 'O.T.',
		      COLUMN 20, 'Origen',
		      COLUMN 37, 'Destino',
		      COLUMN 49, 'Fecha',
		      COLUMN 61, 'Inicio',
		      COLUMN 68, 'Fin',
		      COLUMN 75, 'Costo',
		      COLUMN 85, 'Facturable'
		PRINT COLUMN 10, '---------------------------------------------------------------------------------'
		PRINT COLUMN 10, fl_justifica_titulo('I',ot,8),
		PRINT COLUMN 20, Origen[1,15],
		      COLUMN 37, Destino[1,15],
		      COLUMN 49, fecha USING 'dd-mm-yyyy',
		      COLUMN 61, hora_llegada,
		      COLUMN 68, hora_salida,
		CALL control_horas_normales(hora_llegada, hora_salida)
		CALL control_horas_extras()
		PRINT COLUMN 61, 'Horas Normales:', 

	END FOREACH


ON LAST ROW

END REPORT



FUNCTION control_horas_normales(hora_ini, hora_fin)
DEFINE hora_ini		LIKE talt033.t33_hor_sal_viaje
DEFINE hora_fin		LIKE talt033.t33_hor_sal_viaje

DEFINE horas_normales		DECIMAL(2,0)
DEFINE hora_extras		DECIMAL(2,0)

IF rm_t03.t03_hora_ini 

END FUNCTION



FUNCTION control_horas_extras()
END FUNCTION



FUNCTION borrar_cabecera()

CLEAR FORM
INITIALIZE rm_t03.*, vm_fecha_ini, vm_fecha_fin TO NULL

END FUNCTION



FUNCTION validar_parametros()

CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'stop')
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
