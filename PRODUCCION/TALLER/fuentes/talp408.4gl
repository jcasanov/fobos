------------------------------------------------------------------------------
-- Titulo           : talp408.4gl - Resumen de costos de Ordenes de Trabajo     
-- Elaboracion      : 23-DIC-2003
-- Autor            : JCM
-- Formato Ejecucion: fglrun talp408 base módulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_par	RECORD
	fecha_desde	DATE,
	fecha_hasta	DATE,
	t04_linea	LIKE talt004.t04_linea,
	t01_nombre	LIKE talt001.t01_nombre,
	t23_moneda	LIKE talt023.t23_moneda,
	nom_moneda	LIKE gent013.g13_nombre,
	t23_orden	LIKE talt023.t23_orden,
	t23_nom_cliente	LIKE talt023.t23_nom_cliente,
	t03_mecanico	LIKE talt003.t03_mecanico,
	nom_mecanico	LIKE talt003.t03_nombres,
	imprimir	CHAR(1)
END RECORD
DEFINE rm_t03		RECORD LIKE talt003.*

DEFINE vm_top		SMALLINT
DEFINE vm_left		SMALLINT
DEFINE vm_right		SMALLINT
DEFINE vm_bottom	SMALLINT
DEFINE vm_page		SMALLINT
DEFINE total_grupo	DECIMAL(12,2)
DEFINE total_total	DECIMAL(12,2)

DEFINE tot_hn_lv	SMALLINT
DEFINE tot_he_lv	SMALLINT
DEFINE porc_hn_lv	DECIMAL(5,2)
DEFINE porc_he_lv	DECIMAL(5,2)

DEFINE tot_hn_fs	SMALLINT
DEFINE tot_he_fs	SMALLINT
DEFINE porc_hn_fs	DECIMAL(35,30)
DEFINE porc_he_fs	DECIMAL(35,30)



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/talp408.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'talp408'
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
OPEN FORM f_rep FROM "../forms/talf408_1"
DISPLAY FORM f_rep
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE comando 		VARCHAR(100)

DEFINE r_g13		RECORD LIKE gent013.*

LET vm_top    = 0
LET vm_left   = 1
LET vm_right  = 220
LET vm_bottom = 0
LET vm_page   = 42

LET rm_par.fecha_hasta 	 = TODAY
LET rm_par.fecha_desde 	 = TODAY
LET rm_par.t23_moneda	 = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_par.t23_moneda) RETURNING r_g13.*
LET rm_par.nom_moneda	 = r_g13.g13_nombre
LET rm_par.imprimir      = 'D'
DISPLAY BY NAME rm_par.* 

WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF

	CASE rm_par.imprimir  
		WHEN 'D' 
			CALL imprimir_detallado(comando)
		WHEN 'R'
			CALL imprimir_resumido(comando)
	END CASE
END WHILE 
END FUNCTION



FUNCTION imprimir_detallado(comando)
DEFINE comando 		VARCHAR(100)
DEFINE expr_ot		VARCHAR(125)
DEFINE expr_mecanico	VARCHAR(125)
DEFINE query		VARCHAR(1000)

DEFINE r_report		RECORD
	fecha		LIKE talt034.t34_fecha,	
	orden		LIKE talt034.t34_orden,	
	descrip		LIKE talt024.t24_descripcion,	
	hora_ini	LIKE talt034.t34_hora_ini,	
	hora_fin	LIKE talt034.t34_hora_fin,
	mecanico	LIKE talt024.t24_mecanico	
END RECORD

	LET expr_ot = ' '
	IF rm_par.t23_orden IS NOT NULL THEN
		LET expr_ot = ' AND t23_orden = ', rm_par.t23_orden
	END IF

	LET expr_mecanico = ' '
	IF rm_par.t03_mecanico IS NOT NULL THEN
		LET expr_mecanico = ' AND t24_mecanico = ', rm_par.t03_mecanico
	END IF

	LET query = 'SELECT t34_fecha, t34_orden, t24_descripcion, ',
		'           t34_hora_ini, t34_hora_fin, t24_mecanico ', 
		'	FROM talt023, talt024, talt034 ',
		'	WHERE t23_compania  = ', vg_codcia,
		'	  AND t23_localidad = ', vg_codloc,
		expr_ot CLIPPED,
		'	  AND t23_moneda    = "', rm_par.t23_moneda, '"',
		'	  AND t24_compania  = ', vg_codcia,
		'	  AND t24_localidad = ', vg_codloc,
		'	  AND t24_orden     = t23_orden ',
		'         AND t24_modelo   IN (',
					'SELECT t04_modelo FROM talt004 ',
					' WHERE t04_compania = ', vg_codcia,
					'   AND t04_linea    = "',
						rm_par.t04_linea, '")', 
		expr_mecanico CLIPPED,
		'	  AND t34_compania  = t24_compania  ',
		'	  AND t34_localidad = t24_localidad ',
		'	  AND t34_orden     = t24_orden     ',
		'	  AND t34_modelo    = t24_modelo    ',
		'	  AND t34_codtarea  = t24_codtarea  ',
		'	  AND t34_secuencia = t24_secuencia ',
		'	  AND t34_fecha BETWEEN "', rm_par.fecha_desde, '"',
		   		  	 '  AND "', rm_par.fecha_hasta, '"',
		' ORDER BY t24_mecanico, t34_fecha, t34_hora_ini '

	PREPARE cons_detallado FROM query
	DECLARE q_detallado CURSOR FOR cons_detallado
	OPEN  q_detallado
	FETCH q_detallado
	IF STATUS = NOTFOUND THEN
		CLOSE q_detallado
		FREE  q_detallado
		CALL fl_mensaje_consulta_sin_registros()
		RETURN        
	END IF
	CLOSE q_detallado
	LET total_total = 0
	START REPORT report_detallado TO PIPE comando
	FOREACH q_detallado INTO r_report.* 
		OUTPUT TO REPORT report_detallado(r_report.*)
	END FOREACH
	FINISH REPORT report_detallado
END FUNCTION



FUNCTION imprimir_resumido(comando)
DEFINE comando 		VARCHAR(100)
DEFINE expr_ot		VARCHAR(125)
DEFINE expr_mecanico	VARCHAR(125)
DEFINE query		VARCHAR(1000)
DEFINE min_extra	SMALLINT
DEFINE min_norm		SMALLINT
DEFINE r_t03		RECORD LIKE talt003.*

DEFINE hora_ini		LIKE talt034.t34_hora_ini
DEFINE hora_fin		LIKE talt034.t34_hora_fin
DEFINE costo_me		DECIMAL(12,2)
DEFINE costo_mn		DECIMAL(12,2)
DEFINE costo_hn		DECIMAL(25,20)
DEFINE costo_he		DECIMAL(25,20)


DEFINE r_report		RECORD
	codtarea	LIKE talt024.t24_codtarea,	
	orden		LIKE talt024.t24_orden,
	fecha		LIKE talt034.t34_fecha,
	hora_ini	LIKE talt034.t34_hora_ini,	
	hora_fin	LIKE talt034.t34_hora_fin,
	mecanico	LIKE talt024.t24_mecanico,
	mn		SMALLINT,
	me		SMALLINT,
	vmn		DECIMAL(25,20),	
	vme		DECIMAL(25,20)	
END RECORD

DEFINE r_report2	RECORD
	dia_semana	SMALLINT,
	codtarea	CHAR(2),	
	hn		DECIMAL(7,2),
	he		DECIMAL(7,2),
	vhn		DECIMAL(7,2),	
	vhe		DECIMAL(7,2)	
END RECORD

LET expr_ot = ' '
IF rm_par.t23_orden IS NOT NULL THEN
	LET expr_ot = ' AND t23_orden = ', rm_par.t23_orden
END IF

LET expr_mecanico = ' '
IF rm_par.t03_mecanico IS NOT NULL THEN
	LET expr_mecanico = ' AND t24_mecanico = ', rm_par.t03_mecanico
END IF

LET query = 'SELECT t24_codtarea, t24_orden, t34_fecha, t34_hora_ini, t34_hora_fin, ',
		'   t24_mecanico, 0 as te_mn, 0 as te_me, 0 as te_vhn, ',
		'   0 as te_vhe ', 
	'	FROM talt023, talt024, talt034 ',
	'	WHERE t23_compania  = ', vg_codcia,
	'	  AND t23_localidad = ', vg_codloc,
	expr_ot CLIPPED,
	'	  AND t23_moneda    = "', rm_par.t23_moneda, '"',
	'	  AND t24_compania  = ', vg_codcia,
	'	  AND t24_localidad = ', vg_codloc,
	'	  AND t24_orden     = t23_orden ',
	'         AND t24_modelo   IN (',
				'SELECT t04_modelo FROM talt004 ',
				' WHERE t04_compania = ', vg_codcia,
				'   AND t04_linea    = "',
					rm_par.t04_linea, '")', 
	'	  AND t24_codtarea IN (',
				'SELECT t35_codtarea FROM talt035 ',
				' WHERE t35_compania = ', vg_codcia, 
				')', 
	expr_mecanico CLIPPED,
	'	  AND t34_compania  = t24_compania  ',
	'	  AND t34_localidad = t24_localidad ',
	'	  AND t34_orden     = t24_orden     ',
	'	  AND t34_modelo    = t24_modelo    ',
	'	  AND t34_codtarea  = t24_codtarea  ',
	'	  AND t34_secuencia = t24_secuencia ',
	'	  AND t34_fecha BETWEEN "', rm_par.fecha_desde, '"',
	   		  	 '  AND "', rm_par.fecha_hasta, '"',
	' INTO TEMP te_tareas '

PREPARE stmnt FROM query
EXECUTE stmnt

DECLARE q_hora CURSOR FOR SELECT * FROM te_tareas 

FOREACH q_hora INTO r_report.*
	CALL fl_lee_mecanico(vg_codcia, r_report.mecanico) RETURNING r_t03.*
	LET costo_mn = 0
	LET costo_me = 0

	IF WEEKDAY(r_report.fecha) >= 1 AND WEEKDAY(r_report.fecha) <= 5 THEN
		LET costo_hn = r_t03.t03_cost_htn / 60
		LET costo_he = r_t03.t03_cost_hte / 60
	ELSE
		LET costo_hn = r_t03.t03_fact_htn / 60
		LET costo_he = r_t03.t03_fact_hte / 60
	END IF

	LET hora_ini = r_report.hora_ini
	LET hora_fin = r_report.hora_fin

	LET min_extra = 0
	IF hora_ini < r_t03.t03_hora_ini THEN
		LET min_extra = convertir_horas_numero(
				r_t03.t03_hora_ini - hora_ini)	
		LET hora_ini = r_t03.t03_hora_ini
	END IF  	
	IF hora_fin > r_t03.t03_hora_fin THEN
		LET min_extra = min_extra + convertir_horas_numero(
				hora_fin - r_t03.t03_hora_fin)	
		LET hora_fin = r_t03.t03_hora_fin
	END IF

	LET costo_me = min_extra * costo_he	
	LET min_norm = convertir_horas_numero(hora_fin - hora_ini)	
	LET costo_mn = costo_mn + (min_norm * costo_hn)	

	UPDATE te_tareas SET te_mn  = min_norm,
			     te_me  = min_extra,
			     te_vhn = costo_mn,
			     te_vhe = costo_me 
		WHERE t24_codtarea = r_report.codtarea
		  AND t24_orden    = r_report.orden
		  AND t34_fecha    = r_report.fecha
		  AND t34_hora_ini = r_report.hora_ini
		  AND t24_mecanico = r_report.mecanico
END FOREACH

LET query = 'SELECT t35_codtarea[1,2] FROM talt035 ',
	    '   GROUP BY 1 ORDER BY 1 '

PREPARE cons FROM query
DECLARE q_reporte CURSOR FOR cons 
	OPEN q_reporte 
	FETCH q_reporte
	IF STATUS = NOTFOUND THEN
		CLOSE q_reporte
		FREE  q_reporte
		CALL fl_mensaje_consulta_sin_registros()
		DROP TABLE te_tareas
		RETURN        
	END IF
	CLOSE q_reporte

	SELECT NVL(SUM(te_mn), 0), NVL(SUM(te_me), 0) 
		INTO tot_hn_lv, tot_he_lv FROM te_tareas
		WHERE WEEKDAY(t34_fecha) BETWEEN 1 AND 5	

	SELECT NVL(SUM(te_mn), 0), NVL(SUM(te_me), 0) 
		INTO tot_hn_fs, tot_he_fs FROM te_tareas
		WHERE WEEKDAY(t34_fecha) BETWEEN 6 AND 7	

	LET porc_hn_lv = (tot_hn_lv * 100) / (tot_hn_lv + tot_he_lv + tot_hn_fs + tot_he_fs)
	LET porc_he_lv = (tot_he_lv * 100) / (tot_hn_lv + tot_he_lv + tot_hn_fs + tot_he_fs)
	LET porc_hn_fs = (tot_hn_fs * 100) / (tot_hn_lv + tot_he_lv + tot_hn_fs + tot_he_fs)
	LET porc_he_fs = 100 - (porc_hn_lv + porc_he_lv + porc_hn_fs)

	START REPORT report_resumen TO PIPE comando
	FOREACH q_reporte INTO r_report2.codtarea 
		OUTPUT TO REPORT report_resumen(r_report2.codtarea, 'D')
	END FOREACH
	OUTPUT TO REPORT report_resumen('--', '-')
	FOREACH q_reporte INTO r_report2.codtarea 
		OUTPUT TO REPORT report_resumen(r_report2.codtarea, 'R')
	END FOREACH
	FINISH REPORT report_resumen
	DROP TABLE te_tareas

END FUNCTION


FUNCTION lee_parametros()
DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_t01		RECORD LIKE talt001.*
DEFINE r_t03		RECORD LIKE talt003.*
DEFINE r_t04		RECORD LIKE talt004.*
DEFINE r_t23		RECORD LIKE talt023.*

OPTIONS INPUT NO WRAP
LET int_flag = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	ON KEY(F2)
		IF INFIELD(t23_moneda) THEN
			CALL fl_ayuda_monedas()
				RETURNING r_g13.g13_moneda, r_g13.g13_nombre, 
					  r_g13.g13_decimales
			IF r_g13.g13_moneda IS NOT NULL THEN
				LET rm_par.t23_moneda = r_g13.g13_moneda
				LET rm_par.nom_moneda = r_g13.g13_nombre
				DISPLAY BY NAME rm_par.t23_moneda,
						rm_par.nom_moneda
			END IF
		END IF
		IF INFIELD(t04_linea) THEN
			CALL fl_ayuda_marcas_taller(vg_codcia)
				RETURNING r_t01.t01_linea, r_t01.t01_nombre
			IF r_t01.t01_linea IS NOT NULL THEN
				LET rm_par.t04_linea  = r_t01.t01_linea
				LET rm_par.t01_nombre = r_t01.t01_nombre
				DISPLAY BY NAME rm_par.t04_linea,
						rm_par.t01_nombre
			END IF
		END IF
		IF INFIELD(t23_orden) THEN
			CALL fl_ayuda_orden_trabajo(vg_codcia, vg_codloc, 'T')
				RETURNING r_t23.t23_orden, r_t23.t23_nom_cliente
			IF r_t23.t23_orden IS NOT NULL THEN
				LET rm_par.t23_orden       = r_t23.t23_orden
				LET rm_par.t23_nom_cliente = 
							r_t23.t23_nom_cliente
				DISPLAY BY NAME rm_par.t23_orden, 
						rm_par.t23_nom_cliente
			END IF	
		END IF
		IF INFIELD(t03_mecanico) THEN
			CALL fl_ayuda_mecanicos(vg_codcia, 'T')
				RETURNING r_t03.t03_mecanico, r_t03.t03_nombres
			IF r_t03.t03_mecanico IS NOT NULL THEN
				LET rm_par.t03_mecanico = r_t03.t03_mecanico
				LET rm_par.nom_mecanico = r_t03.t03_nombres
				DISPLAY BY NAME rm_par.t03_mecanico,
				                rm_par.nom_mecanico
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD t23_moneda
		IF rm_par.t23_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.t23_moneda) RETURNING r_g13.*
			IF r_g13.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe la moneda en la Compañía.','exclamation')
				CLEAR nom_moneda
				NEXT FIELD t23_moneda
			ELSE
				LET rm_par.t23_moneda = r_g13.g13_moneda
				LET rm_par.nom_moneda = r_g13.g13_nombre
				DISPLAY BY NAME rm_par.t23_moneda,
						rm_par.nom_moneda
			END IF
		ELSE
			CLEAR nom_moneda
		END IF
	AFTER FIELD t04_linea
		IF rm_par.t04_linea IS NOT NULL THEN
			CALL fl_lee_linea_taller(vg_codcia, rm_par.t04_linea)
				RETURNING r_t01.*
			IF r_t01.t01_linea IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe esa Línea en la Compañía.','exclamation')
				NEXT FIELD t04_linea
			END IF
			LET rm_par.t04_linea  = r_t01.t01_linea
			LET rm_par.t01_nombre = r_t01.t01_nombre
			DISPLAY BY NAME rm_par.t04_linea,
					rm_par.t01_nombre
		ELSE
			CLEAR t01_nombre
		END IF
	AFTER FIELD t23_orden 
		IF rm_par.t23_orden IS NOT NULL THEN
			CALL fl_lee_orden_trabajo(vg_codcia, vg_codloc, 
				rm_par.t23_orden) RETURNING r_t23.*		
			IF r_t23.t23_orden IS NULL THEN
				CALL fgl_winmessage(vg_producto,'No existe la Orden de Trabajo en la Compañía.','exclamation')
				CLEAR t23_nom_cliente
				NEXT FIELD t23_orden
			ELSE
				LET rm_par.t23_orden       = r_t23.t23_orden
				LET rm_par.t23_nom_cliente = 
					r_t23.t23_nom_cliente
				DISPLAY BY NAME rm_par.t23_orden,
						rm_par.t23_nom_cliente 
			END IF
		ELSE
			CLEAR t23_nom_cliente
		END IF
	AFTER FIELD t03_mecanico
		IF rm_par.t03_mecanico IS NOT NULL THEN
			CALL fl_lee_mecanico(vg_codcia, rm_par.t03_mecanico)	
				RETURNING r_t03.*
			IF r_t03.t03_mecanico IS NULL THEN
				CLEAR nom_mecanico
				CALL fgl_winmessage(vg_producto,'No existe Mecánico en la Compañía.','exclamation')
				NEXT FIELD t03_mecanico
			ELSE
				LET rm_par.t03_mecanico = r_t03.t03_mecanico
				LET rm_par.nom_mecanico = r_t03.t03_nombres
				DISPLAY BY NAME rm_par.t03_mecanico,
						rm_par.nom_mecanico 
			END IF
		ELSE
			CLEAR nom_mecanico
		END IF
	AFTER INPUT 
		IF rm_par.fecha_desde > rm_par.fecha_hasta THEN
			CALL fgl_winmessage(vg_producto,'La fecha desde debe ser menor a la fecha hasta','exclamation')
			NEXT FIELD fecha_desde
		END IF
		IF rm_par.fecha_hasta > TODAY THEN
			CALL fgl_winmessage(vg_producto,'La fecha hasta debe ser menor hoy día','exclamation')
			NEXT FIELD fecha_hasta
		END IF
		IF rm_par.fecha_desde IS NULL THEN
			NEXT FIELD fecha_desde
		END IF
		IF rm_par.fecha_hasta IS NULL THEN
			NEXT FIELD fecha_hasta
		END IF
		IF rm_par.t04_linea IS NULL THEN
			NEXT FIELD t04_linea
		END IF
END INPUT

END FUNCTION



REPORT report_detallado(r_report)
DEFINE r_report 	RECORD
	fecha		LIKE talt034.t34_fecha,	
	orden		LIKE talt034.t34_orden,	
	descrip		LIKE talt024.t24_descripcion,	
	hora_ini	LIKE talt034.t34_hora_ini,	
	hora_fin	LIKE talt034.t34_hora_fin,	
	mecanico	LIKE talt024.t24_mecanico	
END RECORD
DEFINE costo		DECIMAL(12,2)
DEFINE costo_hn		DECIMAL(25,20)
DEFINE costo_he		DECIMAL(25,20)
DEFINE hora_ini		LIKE talt034.t34_hora_ini
DEFINE hora_fin		LIKE talt034.t34_hora_fin
DEFINE dif_horas	SMALLINT                     

DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE long		SMALLINT

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
	--print '&k2S'	                -- Letra condensada (16 cpi)
	print '&k4S'	        -- Letra (12 cpi)

	LET modulo     = "Módulo: Taller"
	LET long       = LENGTH(modulo)
	LET usuario    = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I','DETALLE DE COSTOS DE ORDENES DE TRABAJO',80)
		RETURNING titulo
	PRINT COLUMN 1,   rg_cia.g01_razonsocial,
	      COLUMN 121, 'Página: ', PAGENO USING '&&&'
	PRINT COLUMN 1,   modulo CLIPPED,
	      COLUMN 40,  titulo CLIPPED,
	      COLUMN 125, UPSHIFT(vg_proceso) CLIPPED 
	PRINT COLUMN 40,  '** Moneda          : ', rm_par.t23_moneda, ' ',
					 	 rm_par.nom_moneda
	PRINT COLUMN 40,  '** Línea (Marca)   : ', rm_par.t04_linea, ' ',
						 rm_par.t01_nombre
	IF rm_par.t23_orden IS NULL THEN
		PRINT COLUMN 40,  '** Orden De Trabajo: T O D A S'
	ELSE
		PRINT COLUMN 40,  '** Orden De Trabajo: ',
				rm_par.t23_orden, ' ', rm_par.t23_nom_cliente
	END IF
	PRINT COLUMN 40,  '** Fecha Inicial   : ', 
			rm_par.fecha_desde USING 'dd-mm-yyyy'
	PRINT COLUMN 40,  '** Fecha Final     : ', 
			rm_par.fecha_hasta USING 'dd-mm-yyyy'
	PRINT COLUMN 1, 'Fecha Impresión: ', TODAY
					  USING 'dd-mm-yyyy', 1 SPACES, TIME,
	      COLUMN 113, usuario
	SKIP 1 LINES
	PRINT COLUMN 40, ' T R A B A J O S   R E A L I Z A D O S '
	SKIP 1 LINES

BEFORE GROUP OF r_report.mecanico
	NEED 5 LINES
	LET total_grupo = 0
	CALL fl_lee_mecanico(vg_codcia, r_report.mecanico) RETURNING rm_t03.*

	PRINT COLUMN 1,  'Mecanico: ', rm_t03.t03_mecanico, ' ',
				 	rm_t03.t03_nombres

	PRINT '==================================================================================================================================='
	PRINT COLUMN 1,   'Fecha',
	      COLUMN 13,  '# Orden',
	      COLUMN 22,  'Actividad      ',
	      COLUMN 80,  'Hora Inicio',
	      COLUMN 93,  'Hora Fin',
	      COLUMN 103, 'Tiempo Real',
	      COLUMN 116, '      Costos h/h'
	PRINT '==================================================================================================================================='

AFTER GROUP OF r_report.mecanico
	LET total_total = total_total + total_grupo
	PRINT COLUMN 100, 'Subtotal: ',
	      COLUMN 116, total_grupo USING '#,###,###,##&.##' 

ON EVERY ROW
	NEED 2 LINES
	LET costo = 0

-- OjO falta determinar si debo usar costos de viaje
	IF WEEKDAY(r_report.fecha) >= 1 AND WEEKDAY(r_report.fecha) <= 5 THEN
		LET costo_hn = rm_t03.t03_cost_htn / 60
		LET costo_he = rm_t03.t03_cost_hte / 60
	ELSE
		LET costo_hn = rm_t03.t03_fact_htn / 60
		LET costo_he = rm_t03.t03_fact_hte / 60
	END IF

	LET hora_ini = r_report.hora_ini
	LET hora_fin = r_report.hora_fin

	IF hora_ini < rm_t03.t03_hora_ini THEN
		LET dif_horas = convertir_horas_numero(
				rm_t03.t03_hora_ini - hora_ini)	
		LET costo = costo + (dif_horas * costo_he)	
		LET hora_ini = rm_t03.t03_hora_ini
	END IF  	
	IF hora_fin > rm_t03.t03_hora_fin THEN
		LET dif_horas = convertir_horas_numero(
				hora_fin - rm_t03.t03_hora_fin)	
		LET costo = costo + (dif_horas * costo_he)	
		LET hora_fin = rm_t03.t03_hora_fin
	END IF
	LET dif_horas = convertir_horas_numero(hora_fin - hora_ini)	
	LET costo = costo + (dif_horas * costo_hn)	
	LET total_grupo = total_grupo + costo

	PRINT COLUMN 1,	  r_report.fecha	USING 'dd-mm-yy',
	      COLUMN 13,  r_report.orden  	USING '######&',
	      COLUMN 22,  r_report.descrip[1,55] CLIPPED, 
	      COLUMN 86,  r_report.hora_ini 	CLIPPED,
	      COLUMN 96,  r_report.hora_fin	CLIPPED,
	      COLUMN 108, (r_report.hora_fin - r_report.hora_ini) CLIPPED, 
	      COLUMN 116, costo USING '#,###,###,##&.##' 


ON LAST ROW
	SKIP 1 LINES
	PRINT COLUMN 100, 'Total: ',
	      COLUMN 116, total_total USING '#,###,###,##&.##' 
		
END REPORT



REPORT report_resumen(codtarea, flag)
DEFINE	codtarea	CHAR(2)	
DEFINE flag 		CHAR(1)
DEFINE r_report		RECORD
	dia_semana	SMALLINT,
	codtarea	CHAR(2),	
	hn		SMALLINT,
	he		SMALLINT,
	vhn		DECIMAL(7,2),	
	vhe		DECIMAL(7,2)	
END RECORD
DEFINE r_valores	RECORD
	hn_lv		SMALLINT,
	he_lv		SMALLINT,
	vhn_lv		DECIMAL(7,2),
	vhe_lv		DECIMAL(7,2),
	hn_fs		SMALLINT,
	he_fs		SMALLINT,
	vhn_fs		DECIMAL(7,2),
	vhe_fs		DECIMAL(7,2)
END RECORD
DEFINE tipo_horas	VARCHAR(50)
DEFINE horas		SMALLINT
DEFINE minutos		SMALLINT

DEFINE porc_subhn_lv	DECIMAL(5,2)
DEFINE porc_subhe_lv	DECIMAL(5,2)
DEFINE porc_tothn_lv	DECIMAL(5,2)
DEFINE porc_tothe_lv	DECIMAL(5,2)

DEFINE porc_subhn_fs	DECIMAL(5,2)
DEFINE porc_subhe_fs	DECIMAL(5,2)
DEFINE porc_tothn_fs	DECIMAL(5,2)
DEFINE porc_tothe_fs	DECIMAL(5,2)

DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE long		SMALLINT

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
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I','RESUMEN DE COSTOS DE ORDENES DE TRABAJO',80)
		RETURNING titulo
	PRINT COLUMN 1,   rg_cia.g01_razonsocial,
	      COLUMN 166, 'Página: ', PAGENO USING '&&&'
	PRINT COLUMN 1,   modulo CLIPPED,
	      COLUMN 65,  titulo CLIPPED,
	      COLUMN 170, UPSHIFT(vg_proceso) CLIPPED 
	PRINT COLUMN 65,  '** Moneda          : ', rm_par.t23_moneda, ' ',
					 	 rm_par.nom_moneda
	PRINT COLUMN 65,  '** Línea (Marca)   : ', rm_par.t04_linea, ' ',
						 rm_par.t01_nombre
	IF rm_par.t23_orden IS NULL THEN
		PRINT COLUMN 65,  '** Orden De Trabajo: T O D A S'
	ELSE
		PRINT COLUMN 65,  '** Orden De Trabajo: ',
				rm_par.t23_orden, ' ', rm_par.t23_nom_cliente
	END IF
	PRINT COLUMN 65,  '** Fecha Inicial   : ', 
			rm_par.fecha_desde USING 'dd-mm-yyyy'
	PRINT COLUMN 65,  '** Fecha Final     : ', 
			rm_par.fecha_hasta USING 'dd-mm-yyyy'
	IF rm_par.t03_mecanico IS NULL THEN
		PRINT COLUMN 65,  '** Mecanico        : T O D O S'
	ELSE
		PRINT COLUMN 65,  '** Mecanico        : ',
				rm_par.t03_mecanico, ' ', rm_par.nom_mecanico
	END IF
	PRINT COLUMN 1, 'Fecha Impresión: ', TODAY
					  USING 'dd-mm-yyyy', 1 SPACES, TIME,
	      COLUMN 158, usuario
	SKIP 1 LINES
	PRINT COLUMN 65, ' D E T A L L E   H O R A S / V A L O R E S'
	SKIP 1 LINES
	LET porc_tothn_lv = 0
	LET porc_tothe_lv = 0
	LET porc_tothn_fs = 0
	LET porc_tothe_fs = 0

	LET r_valores.hn_lv = 0
	LET r_valores.he_lv = 0
	LET r_valores.vhn_lv = 0
	LET r_valores.vhe_lv = 0
	LET r_valores.hn_fs = 0
	LET r_valores.he_fs = 0
	LET r_valores.vhn_fs = 0
	LET r_valores.vhe_fs = 0

	PRINT '=================================================================================================================================================================================='
	PRINT COLUMN 55,  'Horas N',
	      COLUMN 64,  'Valores N',
	      COLUMN 75,  'Horas E',
	      COLUMN 84,  'Valores E',
	      COLUMN 95,  'Horas N',
	      COLUMN 104, 'Valores N',
	      COLUMN 115, 'Horas E',
	      COLUMN 124, 'Valores E',
	      COLUMN 135, '% Horas N',
	      COLUMN 146, '% Horas E',
	      COLUMN 157, '% Horas N',
	      COLUMN 168, '% Horas E'

	PRINT COLUMN 55,  ' L - V ',
	      COLUMN 64,  '  L - V  ',
	      COLUMN 75,  ' L - V ',
	      COLUMN 84,  '  L - V  ',
	      COLUMN 95,  'Fin Sem',
	      COLUMN 104, ' Fin Sem ',
	      COLUMN 115, 'Fin Sem',
	      COLUMN 124, ' Fin Sem ',
	      COLUMN 135, '  L - V  ',
	      COLUMN 146, '  L - V  ',
	      COLUMN 157, ' Fin Sem ',
	      COLUMN 168, ' Fin Sem '
	PRINT '=================================================================================================================================================================================='


ON EVERY ROW

	LET r_report.codtarea = codtarea
	CASE r_report.codtarea
		WHEN 'HF'
			LET tipo_horas = 'Horas Hombre Facturables'
		WHEN 'HD'
			LET tipo_horas = 'Horas Hombre Transferibles a Otros Departamentos'
		WHEN 'HO'
			LET tipo_horas = 'Horas Hombre Otras'
		WHEN 'HS'
			LET tipo_horas = 'Horas Hombre Departamento de Servicios'
		OTHERWISE
			LET tipo_horas = ' '
	END CASE	

	PRINT COLUMN 1,	  tipo_horas    	CLIPPED; 

	CASE flag
		WHEN 'D' 
	LET r_report.hn  = 0
	LET r_report.he  = 0
	LET r_report.vhn = 0
	LET r_report.vhe = 0
	SELECT NVL(SUM(te_mn), 0), NVL(SUM(te_vhn), 0), NVL(SUM(te_me), 0), 
	       NVL(SUM(te_vhe), 0)
		INTO r_report.hn, r_report.vhn, r_report.he, r_report.vhe
		FROM te_tareas
		WHERE t24_codtarea[1,2] = r_report.codtarea
		  AND WEEKDAY(t34_fecha) BETWEEN 1 AND 5

	LET horas   = r_report.hn  /  60
	LET minutos = r_report.hn MOD 60
	PRINT COLUMN 55,  horas	USING '#&&', ':', minutos USING '&&',
	      COLUMN 64,  r_report.vhn USING '##,##&.##'; 

	LET horas   = r_report.he  /  60
	LET minutos = r_report.he MOD 60
	PRINT COLUMN 75,  horas	USING '#&&', ':', minutos USING '&&',
	      COLUMN 84,  r_report.vhe USING '##,##&.##'; 

	LET porc_subhn_lv = (r_report.hn * porc_hn_lv) / tot_hn_lv
	LET porc_subhe_lv = (r_report.he * porc_he_lv) / tot_he_lv

	LET porc_tothn_lv = porc_tothn_lv + porc_subhn_lv
	LET porc_tothe_lv = porc_tothe_lv + porc_subhe_lv

	LET r_valores.hn_lv  = r_valores.hn_lv  + r_report.hn
	LET r_valores.he_lv  = r_valores.he_lv  + r_report.he
	LET r_valores.vhn_lv = r_valores.vhn_lv + r_report.vhn
	LET r_valores.vhe_lv = r_valores.vhe_lv + r_report.vhe


	LET r_report.hn  = 0
	LET r_report.he  = 0
	LET r_report.vhn = 0
	LET r_report.vhe = 0
	SELECT NVL(SUM(te_mn), 0), NVL(SUM(te_vhn), 0), NVL(SUM(te_me), 0), 
	       NVL(SUM(te_vhe), 0)
		INTO r_report.hn, r_report.vhn, r_report.he, r_report.vhe
		FROM te_tareas
		WHERE t24_codtarea[1,2] = r_report.codtarea
		  AND WEEKDAY(t34_fecha) BETWEEN 6 AND 7

	LET horas   = r_report.hn  /  60
	LET minutos = r_report.hn MOD 60
	PRINT COLUMN 95,  horas	USING '#&&', ':', minutos USING '&&',
	      COLUMN 104, r_report.vhn USING '##,##&.##'; 

	LET horas   = r_report.he  /  60
	LET minutos = r_report.he MOD 60
	PRINT COLUMN 115, horas	USING '#&&', ':', minutos USING '&&',
	      COLUMN 124, r_report.vhe USING '##,##&.##'; 

	LET porc_subhn_fs = (r_report.hn * porc_hn_fs) / tot_hn_fs
	LET porc_subhe_fs = (r_report.he * porc_he_fs) / tot_he_fs

	LET porc_tothn_fs = porc_tothn_fs + porc_subhn_fs
	LET porc_tothe_fs = porc_tothe_fs + porc_subhe_fs
	
	LET r_valores.hn_fs  = r_valores.hn_fs  + r_report.hn
	LET r_valores.he_fs  = r_valores.he_fs  + r_report.he
	LET r_valores.vhn_fs = r_valores.vhn_fs + r_report.vhn
	LET r_valores.vhe_fs = r_valores.vhe_fs + r_report.vhe

	PRINT COLUMN 138, porc_subhn_lv USING '##&.##',
	      COLUMN 149, porc_subhe_lv USING '##&.##',
	      cOLUMN 160, porc_subhn_fs USING '##&.##',
	      COLUMN 171, porc_subhe_fs USING '##&.##'

	WHEN 'R'

	LET r_report.hn  = 0
	LET r_report.he  = 0
	LET r_report.vhn = 0
	LET r_report.vhe = 0
	SELECT NVL(SUM(te_mn + te_me), 0), NVL(SUM(te_vhn + te_vhe), 0)  
		INTO r_report.hn, r_report.vhn
		FROM te_tareas
		WHERE t24_codtarea[1,2] = r_report.codtarea

	LET horas   = r_report.hn  /  60
	LET minutos = r_report.hn MOD 60
	PRINT COLUMN 55,  horas	USING '#&&', ':', minutos USING '&&',
	      COLUMN 64,  r_report.vhn USING '##,##&.##' 

	LET r_valores.hn_lv  = r_valores.hn_lv  + r_report.hn
	LET r_valores.vhn_lv = r_valores.vhn_lv + r_report.vhn

	OTHERWISE

	PRINT COLUMN 55,  ' ----- ',
	      COLUMN 64,  '---------',
	      COLUMN 75,  ' ----- ',
	      COLUMN 84,  '---------',
	      COLUMN 95,  ' ----- ',
	      COLUMN 104, '---------',
	      COLUMN 115, ' ----- ',
	      COLUMN 124, '---------',
	      COLUMN 135, '   ------',
	      COLUMN 146, '   ------',
	      COLUMN 157, '   ------',
	      COLUMN 168, '   ------'

	PRINT COLUMN 40, 'TOTALES: ';

	LET horas   = r_valores.hn_lv  /  60
	LET minutos = r_valores.hn_lv MOD 60
	PRINT COLUMN 55,  horas	USING '#&&', ':', minutos USING '&&',
	      COLUMN 64,  r_valores.vhn_lv USING '##,##&.##'; 

	LET horas   = r_valores.he_lv  /  60
	LET minutos = r_valores.he_lv MOD 60
	PRINT COLUMN 75,  horas	USING '#&&', ':', minutos USING '&&',
	      COLUMN 84,  r_valores.vhe_lv USING '##,##&.##'; 

	LET horas   = r_valores.hn_fs  /  60
	LET minutos = r_valores.hn_fs MOD 60
	PRINT COLUMN 95,  horas	USING '#&&', ':', minutos USING '&&',
	      COLUMN 104, r_valores.vhn_fs USING '##,##&.##'; 

	LET horas   = r_valores.he_fs  /  60
	LET minutos = r_valores.he_fs MOD 60
	PRINT COLUMN 115, horas	USING '#&&', ':', minutos USING '&&',
	      COLUMN 124, r_valores.vhe_fs USING '##,##&.##'; 

	PRINT COLUMN 138, porc_tothn_lv USING '##&.##',
	      COLUMN 149, porc_tothe_lv USING '##&.##',
	      COLUMN 160, porc_tothn_fs USING '##&.##',
	      COLUMN 171, porc_tothe_fs USING '##&.##'



		--print '&k2S'-- Letra condensada (16 cpi)
		print '&k4S'	        -- Letra (12 cpi)

		SKIP 2 LINES
		PRINT COLUMN 40, ' R E S U M E N   H O R A S / V A L O R E S'
		SKIP 1 LINES
		LET porc_tothn_lv = 0
		LET porc_tothe_lv = 0
		LET porc_tothn_fs = 0
		LET porc_tothe_fs = 0
	
		LET r_valores.hn_lv = 0
		LET r_valores.he_lv = 0
		LET r_valores.vhn_lv = 0
		LET r_valores.vhe_lv = 0
		LET r_valores.hn_fs = 0
		LET r_valores.he_fs = 0
		LET r_valores.vhn_fs = 0
		LET r_valores.vhe_fs = 0

		PRINT '==========================================================================='
		PRINT COLUMN 55,  ' Horas ',
		      COLUMN 64,  '  Valores '

		PRINT '==========================================================================='

	END CASE 

ON LAST ROW

	PRINT COLUMN 55,  ' ----- ',
	      COLUMN 64,  '---------'

	PRINT COLUMN 40, 'TOTALES: ';

	LET horas   = r_valores.hn_lv  /  60
	LET minutos = r_valores.hn_lv MOD 60
	PRINT COLUMN 55,  horas	USING '#&&', ':', minutos USING '&&',
	      COLUMN 64,  r_valores.vhn_lv USING '##,##&.##'; 

END REPORT



FUNCTION convertir_horas_numero(hora)
DEFINE hora		CHAR(6)	
DEFINE fraccion		SMALLINT
DEFINE num_hora		SMALLINT	

LET fraccion = obtener_fraccion_horas(hora)
LET num_hora = fraccion * 60

LET fraccion = obtener_fraccion_minutos(hora)
LET num_hora = num_hora + fraccion

RETURN num_hora

END FUNCTION



FUNCTION obtener_fraccion_horas(hora)
DEFINE hora		CHAR(6)	
DEFINE fraccion		SMALLINT

	LET fraccion = hora[2,2] * 10
	IF fraccion IS NULL THEN
		LET fraccion = 0
	END IF
	LET fraccion = fraccion + (hora[3,3] * 1)

	RETURN fraccion
END FUNCTION



FUNCTION obtener_fraccion_minutos(hora)
DEFINE hora		CHAR(6)	
DEFINE fraccion		SMALLINT

	LET fraccion = fraccion + (hora[5,5] * 10)
	LET fraccion = fraccion + (hora[6,6] * 1)

	RETURN fraccion
END FUNCTION



FUNCTION borrar_cabecera()

CLEAR FORM
INITIALIZE rm_par.* TO NULL

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
