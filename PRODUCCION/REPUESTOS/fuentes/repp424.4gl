{*
 * Titulo           : repp424.4gl - Listado análisis pto de reorden
 * Elaboracion      : 02-mar-2010
 * Autor            : JCM
 * Formato Ejecucion: fglrun repp400 base módulo compañía localidad 
 *}
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE vm_fecha_ini	DATE
DEFINE vm_fecha_fin	DATE



MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp424.error')
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
LET vg_proceso = 'repp424'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)

CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPEN WINDOW w_mas AT 3,5 WITH 05 ROWS, 70 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rep FROM "../forms/repf424_1"
DISPLAY FORM f_rep
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE i,col		SMALLINT
DEFINE query		VARCHAR(2000)
DEFINE comando		VARCHAR(100)

DEFINE item			LIKE rept010.r10_codigo
DEFINE nomitem		LIKE rept010.r10_nombre
DEFINE clasif		CHAR(1)
DEFINE lead_time	LIKE rept104.r104_valor_default
DEFINE unid_vend	LIKE rept020.r20_cant_ven
DEFINE stock_disp	LIKE rept011.r11_stock_act
DEFINE stock_min	LIKE rept106.r106_stock_min
DEFINE pto_reorden	LIKE rept106.r106_pto_reorden

LET vm_fecha_ini = TODAY
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
	CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*

	LET query = 'SELECT r20_item, r10_nombre, ',
            	'       (SELECT CASE NVL(r105_valor, r104_valor_default) ',
                		'        WHEN 0 THEN "E" ',
                		'        WHEN 1 THEN "A" ',
                		'        WHEN 2 THEN "B" ',
                		'        WHEN 3 THEN "C" ',
                		'        ELSE NULL ',
            			'       END ',
						'  FROM rept104, OUTER rept105 ',                          
            			' WHERE r104_compania  = r20_compania ',
			            '   AND r104_codigo    = "ABC" ',
        			    '   AND r105_compania  = r104_compania ',
        			    '   AND r105_parametro = r104_codigo ',
        			    '   AND r105_item      = r20_item ',
        			    '   AND r105_fecha_fin IS NULL) as clasif, ',
            	'       (SELECT NVL(r105_valor, r104_valor_default) ',
						'  FROM rept104, OUTER rept105 ',                          
            			' WHERE r104_compania  = r20_compania ',
			            '   AND r104_codigo    = "LT" ',
        			    '   AND r105_compania  = r104_compania ',
        			    '   AND r105_parametro = r104_codigo ',
        			    '   AND r105_item      = r20_item ',
        			    '   AND r105_fecha_fin IS NULL) as lead_time, ',
					'   SUM(r20_cant_ven), 0, 0, 0',
			'FROM rept020, rept010 ',
			'WHERE r20_compania   = ', vg_codcia,
			'  AND r20_localidad  = ', vg_codloc,
			'  AND r20_cod_tran   = "FA" ',
			'  AND DATE(r20_fecing) BETWEEN "', vm_fecha_ini, '" AND "',
                                                vm_fecha_fin, '"',
			'  AND r10_compania   = r20_compania ',
			'  AND r10_codigo     = r20_item ',
			' GROUP BY 1, 2, 3, 4 ',
			' ORDER BY 1'

	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	OPEN q_deto
	FETCH q_deto
	IF STATUS = NOTFOUND THEN
		CLOSE q_deto
		CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	CLOSE q_deto
	START REPORT rep_reorden TO PIPE comando
	FOREACH q_deto INTO item, nomitem, clasif, lead_time, unid_vend, stock_disp, stock_min, 
						pto_reorden 
		OUTPUT TO REPORT rep_reorden(item, nomitem, clasif, lead_time, unid_vend, stock_disp, 
									 stock_min, pto_reorden)
	END FOREACH
	FINISH REPORT rep_reorden
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE fecha_ini	DATE
DEFINE fecha_fin	DATE

LET int_flag = 0
INPUT BY NAME vm_fecha_ini, vm_fecha_fin
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN
	BEFORE FIELD vm_fecha_ini
		LET fecha_ini = vm_fecha_ini
	BEFORE FIELD vm_fecha_fin
		LET fecha_fin = vm_fecha_fin
	AFTER FIELD vm_fecha_ini 
		IF vm_fecha_ini IS NOT NULL THEN
			IF vm_fecha_ini > TODAY THEN
				CALL fgl_winmessage(vg_producto,'La fecha de inicio no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_ini
			END IF
		ELSE
			LET vm_fecha_ini = fecha_ini
			DISPLAY BY NAME vm_fecha_ini
		END IF
	AFTER FIELD vm_fecha_fin 
		IF vm_fecha_fin IS NOT NULL THEN
			IF vm_fecha_fin > TODAY THEN
				CALL fgl_winmessage(vg_producto,'La fecha de término no puede ser mayor a la de hoy.','exclamation')
				NEXT FIELD vm_fecha_fin
			END IF
		ELSE
			LET vm_fecha_fin = fecha_fin
			DISPLAY BY NAME vm_fecha_fin
		END IF
	AFTER INPUT
		IF vm_fecha_ini > vm_fecha_fin THEN
			CALL fgl_winmessage(vg_producto,'Fecha inicial debe ser menor a fecha final.','exclamation')
			NEXT FIELD vm_fecha_ini
		END IF
END INPUT

END FUNCTION



REPORT rep_reorden(item, nomitem, clasif, lead_time, unid_vend, stock_disp, stock_min, pto_reorden)

DEFINE item			LIKE rept010.r10_codigo
DEFINE nomitem		LIKE rept010.r10_nombre
DEFINE clasif		CHAR(1)
DEFINE lead_time	LIKE rept104.r104_valor_default
DEFINE unid_vend	LIKE rept020.r20_cant_ven
DEFINE stock_disp	LIKE rept011.r11_stock_act
DEFINE stock_min	LIKE rept106.r106_stock_min
DEFINE pto_reorden	LIKE rept106.r106_pto_reorden

DEFINE r_r106		RECORD LIKE rept106.*

DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT
DEFINE fecha		DATE
DEFINE factura		VARCHAR(15)
DEFINE tipo		CHAR(1)

OUTPUT
	TOP MARGIN		1
	LEFT MARGIN		2
	RIGHT MARGIN	90
	BOTTOM MARGIN	4
	PAGE LENGTH		66
FORMAT
PAGE HEADER
	print 'E'; print '&l26A';	-- Indica que voy a trabajar con hojas A4
	print '&k4S'	                -- Letra (12 cpi)
	LET modulo  = "Módulo: Repuestos"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I', 'LISTADO ANALISIS PTO DE REORDEN', 80)
		RETURNING titulo
	{FOR i = 1 TO long
		LET titulo[i,i] = modulo[i,i]
	END FOR}
--	LET titulo = modulo, titulo 
	PRINT COLUMN 1, rm_cia.g01_razonsocial,
  	      COLUMN 120, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, modulo CLIPPED,
	      COLUMN 52, titulo CLIPPED,
	      COLUMN 124, "REPP424" 
	PRINT COLUMN 48, "** Fecha Inicial : ", vm_fecha_ini USING "dd-mm-yyyy"
	PRINT COLUMN 48, "** Fecha Final   : ", vm_fecha_fin USING "dd-mm-yyyy"
	PRINT COLUMN 01, "Fecha  : ", TODAY USING "dd-mm-yyyy", 1 SPACES, TIME,
	      COLUMN 112, usuario
	SKIP 1 LINES
	print '&k2S'	                -- Letra condensada (16 cpi)
	PRINT COLUMN 1,   "Item",
	      COLUMN 18,  "Descripción",
		  COLUMN 55,  "Clasif.",
		  COLUMN 64,  "Lead Time",
	      COLUMN 75,  "Unidades",
	      COLUMN 85,  "Stock Disp.",
	      COLUMN 98,  "Stock Min.",
	      COLUMN 110, "Pto. Reorden"
	PRINT "----------------------------------------------------------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 2 LINES

	DECLARE q_r106 CURSOR FOR
		SELECT * FROM rept106
		 WHERE r106_compania  = vg_codcia
		   AND r106_localidad = vg_codloc
		   AND r106_item      = item
		 ORDER BY r106_compania, r106_anio DESC, r106_mes DESC 

	INITIALIZE r_r106.* TO NULL
	OPEN  q_r106
	FETCH q_r106 INTO r_r106.*
	CLOSE q_r106
	FREE  q_r106

	IF r_r106.r106_compania IS NULL THEN
		LET r_r106.r106_stock_min = 0
		LET r_r106.r106_pto_reorden = 0
	END IF

	PRINT COLUMN 1,   item,
	      COLUMN 18,  nomitem,
	      COLUMN 58,  clasif CLIPPED,
	      COLUMN 64,  lead_time,
		  COLUMN 75,  unid_vend,
	      COLUMN 85,  fl_lee_stock_disponible_rep(vg_codcia, vg_codloc,
                                                  item, 'R')
								USING "-,---,--&",
	      COLUMN 98,  r_r106.r106_stock_min USING "-,---,--&",
	      COLUMN 110, r_r106.r106_pto_reorden USING "-,---,--&"
	
END REPORT



FUNCTION borrar_cabecera()

CLEAR vm_fecha_ini, vm_fecha_fin
INITIALIZE vm_fecha_ini, vm_fecha_fin TO NULL

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
