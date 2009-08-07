{*
 * Titulo           : cmsp201.4gl - Consultar liquidacion para pago
 *									de comisiones
 * Elaboracion      : 19-jun-2009
 * Autor            : JCM
 * Formato Ejecucion: fglrun cmsp201 base módulo compañía 
 *}
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_max_loc       SMALLINT
DEFINE vm_max_comi      SMALLINT
DEFINE vm_num_loc       SMALLINT
DEFINE vm_num_comi      SMALLINT
DEFINE vm_scr_lin       SMALLINT
DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT

DEFINE vm_top   	INTEGER 
DEFINE vm_left   	INTEGER
DEFINE vm_right  	INTEGER
DEFINE vm_bottom 	INTEGER
DEFINE vm_page   	INTEGER

DEFINE rm_par	RECORD
	anio		SMALLINT,
	mes			SMALLINT
END RECORD	
DEFINE rm_loc 		ARRAY [1000] OF RECORD
	localidad		LIKE gent002.g02_localidad,
	nom_localidad	LIKE gent002.g02_nombre,
	linea_loc		LIKE gent020.g20_grupo_linea,
	tot_localidad	DECIMAL(12,2),
	dev_localidad	DECIMAL(12,2) 
END RECORD
DEFINE rm_comi		ARRAY [1000] OF RECORD
	codcomi			LIKE cmst002.c02_codigo,
	nomcomi			LIKE cmst002.c02_nombres,
	categoria	  	LIKE cmst001.c01_categoria,
	linea_comi		LIKE gent020.g20_grupo_linea,
	tot_comi	   	DECIMAL(12, 2),	
	dev_comi	   	DECIMAL(12, 2)	
END RECORD




MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/cmsp201.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'cmsp201'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE i		SMALLINT

CALL fl_nivel_isolation()
LET vm_max_loc  = 1000
LET vm_max_comi = 1000
OPEN WINDOW cmsw201_1 AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0,BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM cmsf201_1 FROM "../forms/cmsf201_1"
DISPLAY FORM cmsf201_1
CALL mostrar_cabecera_forma()

FOR i = 1 TO vm_max_loc
	INITIALIZE rm_loc[i].* TO NULL
END FOR
FOR i = 1 TO vm_max_comi
	INITIALIZE rm_comi[i].* TO NULL
END FOR
INITIALIZE rm_par.* TO NULL
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET vm_num_loc = 0
LET vm_num_comi = 0
LET vm_scr_lin = 0
CALL muestra_contadores_cab(0)
CALL muestra_contadores_det(0)
MENU 'OPCIONES'
	COMMAND KEY ('C') 'Consultar'
		HIDE OPTION 'Localidades'
		HIDE OPTION 'Comisionistas'
		CALL control_consulta()
		IF vm_num_loc > 0 THEN
			SHOW OPTION 'Localidades'
		END IF
		IF vm_num_comi > 0 THEN
			SHOW OPTION 'Comisionistas'
		END IF
	COMMAND KEY ('L') 'Localidades'
		CALL mostrar_arreglo_localidades(FALSE)
	COMMAND KEY ('O') 'Comisionistas'
		CALL mostrar_arreglo_comisionistas(FALSE)
	COMMAND KEY ('I') 'Imprimir'	
		CALL imprimir_totales()
	COMMAND KEY ('C') 'Cerrar'
--		CALL cerrar_liquidacion()
	COMMAND KEY('S') 'Salir'
        EXIT MENU
END MENU

END FUNCTION



FUNCTION mostrar_cabecera_forma()

DISPLAY 'Cod'         TO tit_col1
DISPLAY 'Nombre'      TO tit_col2
DISPLAY 'Linea'		  TO tit_col3
DISPLAY 'Cobrado'     TO tit_col4
DISPLAY 'Devolución'  TO tit_col5

DISPLAY 'Cod'         TO tit_col6
DISPLAY 'Nombre'      TO tit_col7
DISPLAY 'Cat'	      TO tit_col8
DISPLAY 'Linea'	      TO tit_col9
DISPLAY 'Cobrado'     TO tit_col10
DISPLAY 'Devolución'  TO tit_col11

END FUNCTION



FUNCTION control_consulta()
DEFINE j,l,col		SMALLINT
DEFINE ant_comi		LIKE cmst002.c02_codigo
DEFINE query		VARCHAR(1500)

LET vm_num_loc   = 1
LET vm_num_comi  = 1
LET rm_orden[1]  = 'ASC'
LET vm_columna_1 = 2
LET vm_columna_2 = 3
LET col          = 2
CALL borrar_localidades()
CALL borrar_comisionistas()
CALL mostrar_cabecera_forma()
LET int_flag = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	AFTER INPUT
		IF rm_par.anio IS NULL THEN
			CONTINUE INPUT
		END IF		
		IF rm_par.mes IS NULL THEN
			CONTINUE INPUT
		END IF		
END INPUT	

LET query = 'SELECT g02_localidad, g02_nombre, c11_linea, SUM(c11_valor_pago),',
			'		0 ',
			'  FROM cmst011, OUTER gent002 ',
			' WHERE c11_anio      = ', rm_par.anio,
			'   AND c11_mes       = ', rm_par.mes,
			'   AND c11_compania  = ', vg_codcia,
			'	AND c11_tipo_trn  IN ("PR", "AJ", "PG") ',
			'   AND g02_compania  = c11_compania ',
			'   AND g02_localidad = c11_loca_comi ',
			' GROUP BY g02_localidad, g02_nombre, c11_linea ',
			' ORDER BY g02_localidad, c11_linea '

PREPARE stmt1 FROM query
DECLARE q_loc CURSOR FOR stmt1

FOREACH q_loc INTO rm_loc[vm_num_loc].*
	SELECT SUM(c11_valor_pago) INTO rm_loc[vm_num_loc].dev_localidad 
	  FROM cmst011
	 WHERE c11_anio      = rm_par.anio
	   AND c11_mes       = rm_par.mes
	   AND c11_compania  = vg_codcia
	   AND c11_tipo_trn  IN ("DF", "AF") 
	   AND c11_loca_comi = rm_loc[vm_num_loc].localidad
	   AND c11_linea     = rm_loc[vm_num_loc].linea_loc

	IF rm_loc[vm_num_loc].dev_localidad IS NULL THEN
		LET rm_loc[vm_num_loc].dev_localidad = 0
	END IF

	LET vm_num_loc = vm_num_loc + 1
	IF vm_num_loc > vm_max_loc THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_loc = vm_num_loc - 1

CALL mostrar_arreglo_localidades(TRUE)

LET query = 'SELECT c12_codcomi, (SELECT c02_nombres FROM cmst002 ',
           				         ' WHERE c02_compania = c12_compania ',
                			     '   AND c02_codigo   = c12_codcomi), ',
			'       c11_categoria, c11_linea, SUM(c11_valor_pago), 0 ',
			'  FROM cmst011, OUTER cmst012 ',
			' WHERE c11_anio = ', rm_par.anio,
			'   AND c11_mes  = ', rm_par.mes,
			'   AND c11_compania = ', vg_codcia,
			'	AND c11_tipo_trn  IN ("PR", "AJ", "PG") ',
			'   AND c12_anio = c11_anio ',
			'   AND c12_mes  = c11_mes ',
			'   AND c12_compania = c11_compania ',
			'   AND c12_codcli   = c11_codcli ',
			'	and c12_linea    = c11_linea ',
			' GROUP BY 1, 2, 3, 4 ',
			' ORDER BY c12_codcomi, c11_categoria, c11_linea '

LET ant_comi = 0
PREPARE stmt2 FROM query
DECLARE q_comi CURSOR FOR stmt2
FOREACH q_comi INTO rm_comi[vm_num_comi].*
	LET query = 'SELECT SUM(c11_valor_pago) ', 
				'  FROM cmst011 ',
				' WHERE c11_anio      = ', rm_par.anio,
				'   AND c11_mes       = ', rm_par.mes,
				'   AND c11_compania  = ', vg_codcia,
				'   AND c11_tipo_trn  IN ("DF", "AF") '

	IF rm_comi[vm_num_comi].codcomi IS NULL THEN
		LET query = query CLIPPED, 
	   			'	AND c11_linea     = "', rm_comi[vm_num_comi].linea_comi, '"',
				'   AND c11_vendedor NOT IN (SELECT c02_vendrep ',
											'  FROM cmst002, cmst012 ',
										    ' WHERE c02_compania = ', vg_codcia,
 											'   AND c12_compania = c02_compania ',
 											'   AND c12_anio     = c11_anio ',
 											'   AND c12_mes      = c11_mes ',
 											'   AND c12_codcomi  = c02_codigo)'
	ELSE
		LET query = query CLIPPED, 
				'   AND EXISTS (SELECT 1 FROM cmst002 ',
							   ' WHERE c02_compania = ', vg_codcia,
							   '   AND c02_codigo   = ', rm_comi[vm_num_comi].codcomi,
							   '   AND c02_vendrep  = c11_vendedor)'
	END IF

	IF ant_comi <> rm_comi[vm_num_comi].codcomi OR 
	   rm_comi[vm_num_comi].codcomi IS NULL
	THEN
		IF rm_comi[vm_num_comi].codcomi IS NOT NULL THEN
			LET ant_comi = rm_comi[vm_num_comi].codcomi
		END IF
		PREPARE stmt3 FROM query
		EXECUTE stmt3 INTO rm_comi[vm_num_comi].dev_comi 

		IF rm_comi[vm_num_comi].dev_comi IS NULL THEN
			LET rm_comi[vm_num_comi].dev_comi = 0
		END IF
	END IF

	LET vm_num_comi = vm_num_comi + 1
	IF vm_num_comi > vm_max_comi THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_comi = vm_num_comi - 1

CALL mostrar_arreglo_comisionistas(TRUE)

END FUNCTION



FUNCTION mostrar_arreglo_localidades(salir_inmediato)
DEFINE salir_inmediato 	INTEGER
DEFINE i				INTEGER

IF vm_num_loc = 0 THEN
	RETURN
END IF

LET int_flag = 0
CALL SET_COUNT(vm_num_loc)

DISPLAY ARRAY rm_loc TO rm_loc.*
	BEFORE DISPLAY
		IF salir_inmediato THEN
			EXIT DISPLAY
		END IF
		CALL dialog.keysetlabel('F5', 'Imprimir detalle')	
	BEFORE ROW 
		LET i = arr_curr()
	ON KEY (INTERRUPT)
		LET INT_FLAG = 0
		EXIT DISPLAY
	ON KEY(F5)
		CALL imprimir_detalle_localidad(rm_loc[i].localidad, 
										rm_loc[i].linea_loc,
										NULL)
		LET INT_FLAG = 0									
END DISPLAY

END FUNCTION



FUNCTION mostrar_arreglo_comisionistas(salir_inmediato)
DEFINE salir_inmediato 	INTEGER
DEFINE i				INTEGER

IF vm_num_comi = 0 THEN
	RETURN
END IF

LET int_flag = 0
CALL SET_COUNT(vm_num_comi)

DISPLAY ARRAY rm_comi TO rm_comi.*
	BEFORE DISPLAY
		IF salir_inmediato THEN
			EXIT DISPLAY
		END IF
		CALL dialog.keysetlabel('F5', 'Imprimir detalle')	
	BEFORE ROW 
		LET i = arr_curr()
	ON KEY (INTERRUPT)
		LET INT_FLAG = 0
		EXIT DISPLAY
	ON KEY(F5)
		CALL imprimir_detalle_comisionista(rm_comi[i].codcomi, 
										   rm_comi[i].categoria, 
										   rm_comi[i].linea_comi,
										   NULL)
		LET INT_FLAG = 0									
END DISPLAY

END FUNCTION



FUNCTION borrar_localidades()
DEFINE i  		SMALLINT

CALL muestra_contadores_cab(0)
FOR i = 1 TO fgl_scr_size('rm_loc')
	INITIALIZE rm_loc[i].* TO NULL
    CLEAR rm_loc[i].*
END FOR

END FUNCTION



FUNCTION borrar_comisionistas()
DEFINE i  		SMALLINT

CALL muestra_contadores_det(0)
LET vm_scr_lin = fgl_scr_size('rm_comi')
FOR i = 1 TO vm_scr_lin
        INITIALIZE rm_comi[i].* TO NULL
        CLEAR rm_comi[i].*
END FOR

END FUNCTION



FUNCTION muestra_contadores_cab(cor)
DEFINE cor	           SMALLINT

DISPLAY "" AT 1,61
DISPLAY cor, " de ", vm_num_loc AT 1, 65

END FUNCTION



FUNCTION muestra_contadores_det(cor)
DEFINE cor	           SMALLINT

DISPLAY "" AT 7,61
DISPLAY cor, " de ", vm_num_comi AT 7, 65

END FUNCTION



FUNCTION imprimir_totales()
DEFINE i		SMALLINT          
DEFINE comando		VARCHAR(100)

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN          
END IF

LET vm_top    = 1
LET vm_left   =	2
LET vm_right  =	90
LET vm_bottom =	4
LET vm_page   = 66

START REPORT rep_tot_comi TO PIPE comando 
	FOR i = 1 TO vm_num_loc 
		OUTPUT TO REPORT rep_tot_comi('L', rm_loc[i].localidad,
										   rm_loc[i].nom_localidad,
										   NULL,
										   rm_loc[i].linea_loc,
										   rm_loc[i].tot_localidad,
										   rm_loc[i].dev_localidad)	 
	END FOR
	FOR i = 1 TO vm_num_comi
		OUTPUT TO REPORT rep_tot_comi('C', rm_comi[i].*)
	END FOR
FINISH REPORT rep_tot_comi

END FUNCTION



REPORT rep_tot_comi(tipo ,codigo, nombre, categoria, linea, cobrado, devolu)

DEFINE tipo			CHAR(1)
DEFINE codigo		INTEGER	
DEFINE nombre		VARCHAR(30)	
DEFINE categoria	CHAR(3)	
DEFINE linea		CHAR(5)
DEFINE cobrado		DECIMAL(12,2)	
DEFINE devolu		DECIMAL(12,2)	
DEFINE r_c10		RECORD LIKE cmst010.*
DEFINE tot_cobrado	DECIMAL(12,2)
DEFINE tot_devuelto	DECIMAL(12,2)

DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT

OUTPUT
	TOP    MARGIN	vm_top
	LEFT   MARGIN	vm_left
	RIGHT  MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE   LENGTH	vm_page
FORMAT
PAGE HEADER
	print 'E'; print '&l26A'		-- Indica que voy a trabajar con hojas A4
	print '&k2S'	                	-- Letra  (12 cpi)
	LET modulo  = "Módulo: Comisiones"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', 'RESUMEN COBROS PARA PAGO DE COMISIONES', 80)
		RETURNING titulo

	LET tot_cobrado  = 0
	LET tot_devuelto = 0
	CALL fl_lee_liquidacion_comisiones(vg_codcia, rm_par.anio, rm_par.mes)
		RETURNING r_c10.*

	LET titulo = modulo, titulo
	PRINT COLUMN 1, rg_cia.g01_razonsocial,
	      COLUMN 90, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, titulo CLIPPED,
	      COLUMN 94, UPSHIFT(vg_proceso)
	      
	SKIP 1 LINES
	PRINT COLUMN 10, "** Año          : ", r_c10.c10_anio
	PRINT COLUMN 10, "** Mes          : ", r_c10.c10_mes

	SKIP 1 LINES
	PRINT COLUMN 10, "** Se consideran los pagos de las facturas emitidas ",
					 "en el siguiente rango: " 
	PRINT COLUMN 10, "** Fecha Inicial: ", r_c10.c10_fecini_fact USING "dd-mm-yyyy",
	      COLUMN 51, "** Fecha Final  : ", r_c10.c10_fecfin_fact USING "dd-mm-yyyy"

	SKIP 1 LINES
	PRINT COLUMN 01, "Fecha de Impresión: ", TODAY USING "dd-mm-yyyy", 
			1 SPACES, TIME,
	      COLUMN 82, usuario
	      
	BEFORE GROUP OF tipo	  
	SKIP 1 LINES
	IF tipo = 'L' THEN
		PRINT COLUMN 1,  "Localidad",
		      COLUMN 29, "Linea",
		      COLUMN 36, fl_justifica_titulo("D", "Cobrado", 16), 
		      COLUMN 54, fl_justifica_titulo("D", "Devoluciones", 16), 
		      COLUMN 72, fl_justifica_titulo("D", "Neto", 16) 

		PRINT COLUMN 1,  "-------------------------------",
		      COLUMN 29, "-------",
		      COLUMN 36, "------------------",
		      COLUMN 54, "------------------",
		      COLUMN 72, "----------------"
	ELSE		  
		-- tipo = C
		PRINT COLUMN 1,  "Comisionista",
			  COLUMN 39, "Cat",
		      COLUMN 44, "Linea",
		      COLUMN 51, fl_justifica_titulo("D", "Cobrado", 16), 
		      COLUMN 69, fl_justifica_titulo("D", "Devoluciones", 16), 
		      COLUMN 87, fl_justifica_titulo("D", "Neto", 16) 

		PRINT COLUMN 1,  "-----------------------------------------",
		      COLUMN 39, "-----",
			  COLUMN 44, "-------",
		      COLUMN 51, "------------------",
		      COLUMN 69, "------------------",
		      COLUMN 87, "----------------"
	END IF

ON EVERY ROW
	IF tipo = 'L' THEN
		LET tot_cobrado  = tot_cobrado  + cobrado
		LET tot_devuelto = tot_devuelto + devolu
		PRINT COLUMN 1,  codigo USING "#####", 
		      COLUMN 7,  nombre CLIPPED,
		      COLUMN 29, linea,
		      COLUMN 36, cobrado USING "#,###,###,##&.&&",
		      COLUMN 54, devolu  USING "#,###,###,##&.&&",
		      COLUMN 72, cobrado - devolu  USING "#,###,###,##&.&&"
	ELSE
		-- tipo = 'C'
		PRINT COLUMN 1,  codigo USING "#####", 
		      COLUMN 7,  nombre CLIPPED,
			  COLUMN 39, categoria,
		      COLUMN 44, linea,
		      COLUMN 51, cobrado USING "#,###,###,##&.&&",
		      COLUMN 69, devolu  USING "#,###,###,##&.&&",
		      COLUMN 87, cobrado - devolu  USING "#,###,###,##&.&&"
	END IF	

AFTER GROUP OF tipo
	NEED 2 LINES
	IF tipo = 'L' THEN
		PRINT COLUMN 36, "----------------",
			  COLUMN 54, "----------------",
			  COLUMN 72, "----------------"
		PRINT COLUMN 36, tot_cobrado  USING "#,###,###,##&.&&",
		      COLUMN 54, tot_devuelto USING "#,###,###,##&.&&",
		      COLUMN 72, tot_cobrado - tot_devuelto USING "-,---,---,--&.&&"
	END IF	

END REPORT



FUNCTION imprimir_detalle_localidad(codloc, linea, comando_impresion)
DEFINE comando_impresion	VARCHAR(100)
DEFINE codloc				LIKE cmst011.c11_loca_comi
DEFINE linea				LIKE cmst011.c11_linea
DEFINE r_c11				RECORD LIKE cmst011.*

IF comando_impresion IS NULL THEN
	CALL fl_control_reportes() RETURNING comando_impresion
	IF int_flag THEN
		RETURN          
	END IF
END IF

DECLARE q_det_fact_loc CURSOR FOR
	SELECT * 
	  FROM cmst011
	 WHERE c11_anio      = rm_par.anio 
	   AND c11_mes       = rm_par.mes
	   AND c11_compania  = vg_codcia
	   AND c11_loca_comi = codloc
	   AND c11_linea	 = linea
	   AND c11_tipo_trn  IN ("PR", "AJ", "PG") 
	 ORDER BY c11_fecha_pago, c11_tipo_doc, c11_num_doc, c11_div_doc

DECLARE q_det_dev_loc CURSOR FOR
	SELECT * 
	  FROM cmst011
	 WHERE c11_anio      = rm_par.anio 
	   AND c11_mes       = rm_par.mes
	   AND c11_compania  = vg_codcia
	   AND c11_loca_comi = codloc
	   AND c11_linea     = linea
	   AND c11_tipo_trn  IN ("DF", "AF") 
	 ORDER BY c11_fecha_pago, c11_tipo_doc, c11_num_doc, c11_div_doc

LET vm_top    = 1
LET vm_left   =	2
LET vm_right  =	90
LET vm_bottom =	4
LET vm_page   = 66

START REPORT rep_det_loc TO PIPE comando_impresion 
	-- Primero los pagos de facturas
	FOREACH q_det_fact_loc INTO r_c11.*
		OUTPUT TO REPORT rep_det_loc('F', codloc, linea,
										  r_c11.c11_codcli, r_c11.c11_nomcli,
										  r_c11.c11_tipo_doc,
										  r_c11.c11_num_doc, r_c11.c11_div_doc,
										  r_c11.c11_fecha_emi, 
										  r_c11.c11_valor_doc,	
										  r_c11.c11_fecha_pago,
										  r_c11.c11_valor_pago)
	END FOREACH

	-- Luego las devoluciones
	FOREACH q_det_dev_loc INTO r_c11.*
		OUTPUT TO REPORT rep_det_loc('D', codloc, linea,
										  r_c11.c11_codcli, r_c11.c11_nomcli,
										  r_c11.c11_tipo_doc,
										  r_c11.c11_num_doc, r_c11.c11_div_doc,
										  r_c11.c11_fecha_emi, 
										  r_c11.c11_valor_doc,	
										  r_c11.c11_fecha_pago,
										  r_c11.c11_valor_pago)
	END FOREACH
FINISH REPORT rep_det_loc

END FUNCTION



REPORT rep_det_loc(tipo, codloc, linea, codcli, nomcli, tipo_doc, num_doc, 
				   div_doc, fecha_emi, valor_doc, fecha_pago, valor_pago)

DEFINE tipo			CHAR(1)
DEFINE codloc		LIKE cmst011.c11_loca_comi
DEFINE linea		LIKE cmst011.c11_linea
DEFINE codcli		LIKE cmst011.c11_codcli	
DEFINE nomcli		LIKE rept019.r19_nomcli
DEFINE tipo_doc		LIKE cmst011.c11_tipo_doc
DEFINE num_doc		LIKE cmst011.c11_num_doc
DEFINE div_doc		LIKE cmst011.c11_div_doc
DEFINE fecha_emi	LIKE cmst011.c11_fecha_emi
DEFINE valor_doc	LIKE cmst011.c11_valor_doc
DEFINE fecha_pago	LIKE cmst011.c11_fecha_pago
DEFINE valor_pago	LIKE cmst011.c11_valor_pago

DEFINE tot_cobrado	DECIMAL(12,2)
DEFINE tot_devuelto	DECIMAL(12,2)

DEFINE r_g02		RECORD LIKE gent002.*
DEFINE r_c10		RECORD LIKE cmst010.*

DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT

OUTPUT
	TOP    MARGIN	vm_top
	LEFT   MARGIN	vm_left
	RIGHT  MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE   LENGTH	vm_page
FORMAT
PAGE HEADER
	LET modulo  = "Módulo: Comisiones"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', 'DETALLE COBROS PARA PAGO DE COMISIONES', 80)
		RETURNING titulo

	CALL fl_lee_liquidacion_comisiones(vg_codcia, rm_par.anio, rm_par.mes)
		RETURNING r_c10.*
	CALL fl_lee_localidad(vg_codcia, codloc) RETURNING r_g02.*	

	LET titulo = modulo, titulo
	PRINT COLUMN 1, rg_cia.g01_razonsocial,
	      COLUMN 90, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, titulo CLIPPED,
	      COLUMN 94, UPSHIFT(vg_proceso)
	      
	SKIP 1 LINES
	PRINT COLUMN 10, "** Año          : ", r_c10.c10_anio
	PRINT COLUMN 10, "** Mes          : ", r_c10.c10_mes
	PRINT COLUMN 10, "** Localidad    : ", codloc, " - ", r_g02.g02_nombre CLIPPED
	PRINT COLUMN 10, "** Linea        : ", linea

	SKIP 1 LINES
	PRINT COLUMN 10, "** Se consideran los pagos de las facturas emitidas ",
					 "en el siguiente rango: " 
	PRINT COLUMN 10, "** Fecha Inicial: ", r_c10.c10_fecini_fact USING "dd-mm-yyyy",
	      COLUMN 51, "** Fecha Final  : ", r_c10.c10_fecfin_fact USING "dd-mm-yyyy"

	SKIP 1 LINES
	PRINT COLUMN 01, "Fecha de Impresión: ", TODAY USING "dd-mm-yyyy", 
			1 SPACES, TIME,
	      COLUMN 82, usuario

	SKIP 1 LINES
	IF tipo = 'F' THEN
		PRINT COLUMN 1,  "Cliente",
		      COLUMN 33, "Factura",
			  COLUMN 47, "Fecha Fact",
		      COLUMN 59, fl_justifica_titulo("D", "Valor Fact", 16), 
		      COLUMN 77, "Fecha Pago",
		      COLUMN 89, fl_justifica_titulo("D", "Valor Pago", 16) 

		PRINT COLUMN 1,  "--------------------------------",
		      COLUMN 33, "--------------",
		      COLUMN 47, "------------",
		      COLUMN 59, "------------------",
		      COLUMN 77, "------------",
		      COLUMN 89, "------------------"
	ELSE		  
		-- tipo = D
		PRINT COLUMN 1,  "Cliente",
		      COLUMN 33, "Factura",
			  COLUMN 47, "Fecha Fact",
		      COLUMN 59, fl_justifica_titulo("D", "Valor Fact", 16), 
		      COLUMN 77, "Fecha Dev",
		      COLUMN 89, fl_justifica_titulo("D", "Valor Dev", 16) 

		PRINT COLUMN 1,  "--------------------------------",
		      COLUMN 33, "--------------",
		      COLUMN 47, "------------",
		      COLUMN 59, "------------------",
		      COLUMN 77, "------------",
		      COLUMN 89, "------------------"
	END IF		  
	      
BEFORE GROUP OF tipo	  
	IF tipo = 'F' THEN
		LET tot_cobrado = 0
	ELSE		  
		-- tipo = D
		LET tot_devuelto = 0
	END IF

ON EVERY ROW

	IF tipo = 'F' THEN
		LET tot_cobrado = tot_cobrado + valor_pago
	ELSE
		LET tot_devuelto = tot_devuelto + valor_pago
	END IF	

	PRINT COLUMN 1,  nomcli[1, 30] CLIPPED, 
	      COLUMN 33, tipo_doc CLIPPED, " ", num_doc CLIPPED, "-", 
		  			 div_doc USING "&&",
	      COLUMN 47, fecha_emi  USING "dd-mm-yyyy",
	      COLUMN 59, valor_doc  USING "#,###,###,##&.&&",
	      COLUMN 77, fecha_pago USING "dd-mm-yyyy",
	      COLUMN 89, valor_pago USING "#,###,###,##&.&&"

AFTER GROUP OF tipo
	NEED 2 LINES
	PRINT COLUMN 89, "----------------"
	IF tipo = 'F' THEN
		PRINT COLUMN 89, tot_cobrado  USING "#,###,###,##&.&&"
		SKIP TO TOP OF PAGE
	ELSE		
		PRINT COLUMN 89, tot_devuelto USING "#,###,###,##&.&&"
	END IF	

END REPORT



FUNCTION imprimir_detalle_comisionista(codcomi, categoria, linea, 
									   comando_impresion)
DEFINE comando_impresion	VARCHAR(100)
DEFINE codcomi				LIKE cmst002.c02_codigo
DEFINE categoria			LIKE cmst011.c11_categoria
DEFINE linea				LIKE cmst011.c11_linea
DEFINE r_c11				RECORD LIKE cmst011.*
DEFINE query				VARCHAR(1500)

IF comando_impresion IS NULL THEN
	CALL fl_control_reportes() RETURNING comando_impresion
	IF int_flag THEN
		RETURN          
	END IF
END IF

IF codcomi IS NULL THEN
	LET query = 'SELECT cmst011.* ', 
				'  FROM cmst011 ',
				' WHERE c11_anio      = ', rm_par.anio, 
				'   AND c11_mes       = ', rm_par.mes,
				'   AND c11_compania  = ', vg_codcia,
				'   AND c11_categoria = "', categoria, '"',
				'   AND c11_linea	  = "', linea, '"',
				'   AND c11_tipo_trn  IN ("PR", "AJ", "PG") ',
				'   AND c11_vendedor NOT IN (SELECT c02_vendrep ',
											'  FROM cmst002, cmst012 ',
										    ' WHERE c02_compania = ', vg_codcia,
 											'   AND c12_compania = c02_compania ',
 											'   AND c12_anio     = c11_anio ',
 											'   AND c12_mes      = c11_mes ',
--											'   AND c12_codcli   = c11_codcli ', 
											'   AND c12_linea    = c11_linea ',
											'   AND c12_categoria = c11_categoria ',
 											'   AND c12_codcomi  = c02_codigo)',
				' ORDER BY c11_fecha_pago, c11_tipo_doc, c11_num_doc, ',
				'          c11_div_doc '
ELSE
	LET query = 'SELECT cmst011.* ', 
				'  FROM cmst011, cmst012 ',
				' WHERE c11_anio      = ', rm_par.anio, 
				'   AND c11_mes       = ', rm_par.mes,
				'   AND c11_compania  = ', vg_codcia,
				'   AND c11_linea	  = "', linea, '"',
				'   AND c11_categoria = "', categoria, '"',
				'   AND c11_tipo_trn  IN ("PR", "AJ", "PG") ',
				'   AND c12_anio      = c11_anio ',
				'   AND c12_mes       = c11_mes ',
				'   AND c12_compania  = c11_compania ', 
				'   AND c12_codcomi   = ', codcomi,
				'   AND c12_codcli    = c11_codcli ', 
				'   AND c12_categoria = c11_categoria ', 
				'   AND c12_linea     = c11_linea ',
				' ORDER BY c11_fecha_pago, c11_tipo_doc, c11_num_doc, ',
				'          c11_div_doc '
END IF

PREPARE stmt4 FROM query 
DECLARE q_det_fact_comi CURSOR FOR stmt4

IF codcomi IS NULL THEN
	LET query = 'SELECT cmst011.* ', 
				'  FROM cmst011 ',
				' WHERE c11_anio      = ', rm_par.anio, 
				'   AND c11_mes       = ', rm_par.mes,
				'   AND c11_compania  = ', vg_codcia,
				'   AND c11_linea	  = "', linea, '"',
				'   AND c11_categoria = "', categoria, '"',
				'   AND c11_tipo_trn  IN ("AF", "DF") ',
				'   AND c11_vendedor NOT IN (SELECT c02_vendrep ',
											'  FROM cmst002, cmst012 ',
										    ' WHERE c02_compania = ', vg_codcia,
 											'   AND c12_compania = c02_compania ',
 											'   AND c12_anio     = c11_anio ',
 											'   AND c12_mes      = c11_mes ',
--											'   AND c12_codcli   = c11_codcli ', 
											'   AND c12_linea    = c11_linea ',
											'   AND c12_categoria = c11_categoria ',
 											'   AND c12_codcomi  = c02_codigo)',
				' ORDER BY c11_fecha_pago, c11_tipo_doc, c11_num_doc, ',
				'          c11_div_doc '
ELSE
	LET query = 'SELECT cmst011.* ', 
				'  FROM cmst011, cmst012 ',
				' WHERE c11_anio      = ', rm_par.anio, 
				'   AND c11_mes       = ', rm_par.mes,
				'   AND c11_compania  = ', vg_codcia,
				'   AND c11_linea	  = "', linea, '"',
				'   AND c11_categoria = "', categoria, '"',
				'   AND c11_tipo_trn  IN ("AF", "DF") ',
				'   AND c12_anio      = c11_anio ',
				'   AND c12_mes       = c11_mes ',
				'   AND c12_compania  = c11_compania ', 
				'   AND c12_codcomi   = ', codcomi,
				'   AND c12_codcli    = c11_codcli ', 
--				'   AND c12_categoria = c11_categoria ',
--				'   AND c12_linea     = c11_linea ',
				' ORDER BY c11_fecha_pago, c11_tipo_doc, c11_num_doc, ',
				'          c11_div_doc '
END IF

PREPARE stmt5 FROM query
DECLARE q_det_dev_comi CURSOR FOR stmt5

LET vm_top    = 1
LET vm_left   =	2
LET vm_right  =	90
LET vm_bottom =	4
LET vm_page   = 66

START REPORT rep_det_comi TO PIPE comando_impresion 
	-- Primero los pagos de facturas
	FOREACH q_det_fact_comi INTO r_c11.*
		OUTPUT TO REPORT rep_det_comi('F', codcomi, linea,
										  r_c11.c11_codcli, r_c11.c11_nomcli,
										  r_c11.c11_tipo_doc,
										  r_c11.c11_num_doc, r_c11.c11_div_doc,
										  r_c11.c11_fecha_emi, 
										  r_c11.c11_valor_doc,	
										  r_c11.c11_fecha_pago,
										  r_c11.c11_valor_pago)
	END FOREACH

	-- Luego las devoluciones
	FOREACH q_det_dev_comi INTO r_c11.*
		OUTPUT TO REPORT rep_det_comi('D', codcomi, linea,
										  r_c11.c11_codcli, r_c11.c11_nomcli,
										  r_c11.c11_tipo_doc,
										  r_c11.c11_num_doc, r_c11.c11_div_doc,
										  r_c11.c11_fecha_emi, 
										  r_c11.c11_valor_doc,	
										  r_c11.c11_fecha_pago,
										  r_c11.c11_valor_pago)
	END FOREACH
FINISH REPORT rep_det_comi

END FUNCTION



REPORT rep_det_comi(tipo, codcomi, linea, codcli, nomcli, tipo_doc, num_doc, 
				   div_doc, fecha_emi, valor_doc, fecha_pago, valor_pago)

DEFINE tipo			CHAR(1)
DEFINE codcomi		LIKE cmst002.c02_codigo
DEFINE linea		LIKE cmst011.c11_linea
DEFINE codcli		LIKE cmst011.c11_codcli	
DEFINE nomcli		LIKE rept019.r19_nomcli
DEFINE tipo_doc		LIKE cmst011.c11_tipo_doc
DEFINE num_doc		LIKE cmst011.c11_num_doc
DEFINE div_doc		LIKE cmst011.c11_div_doc
DEFINE fecha_emi	LIKE cmst011.c11_fecha_emi
DEFINE valor_doc	LIKE cmst011.c11_valor_doc
DEFINE fecha_pago	LIKE cmst011.c11_fecha_pago
DEFINE valor_pago	LIKE cmst011.c11_valor_pago

DEFINE tot_cobrado	DECIMAL(12,2)
DEFINE tot_devuelto	DECIMAL(12,2)

DEFINE r_c02		RECORD LIKE cmst002.*
DEFINE r_c10		RECORD LIKE cmst010.*

DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT

OUTPUT
	TOP    MARGIN	vm_top
	LEFT   MARGIN	vm_left
	RIGHT  MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE   LENGTH	vm_page
FORMAT
PAGE HEADER
	LET modulo  = "Módulo: Comisiones"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', 'DETALLE COBROS PARA PAGO DE COMISIONES', 80)
		RETURNING titulo

	CALL fl_lee_liquidacion_comisiones(vg_codcia, rm_par.anio, rm_par.mes)
		RETURNING r_c10.*
	CALL fl_lee_comisionistas(vg_codcia, codcomi) RETURNING r_c02.*	

	LET titulo = modulo, titulo
	PRINT COLUMN 1, rg_cia.g01_razonsocial,
	      COLUMN 90, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, titulo CLIPPED,
	      COLUMN 94, UPSHIFT(vg_proceso)
	      
	SKIP 1 LINES
	PRINT COLUMN 10, "** Año          : ", r_c10.c10_anio
	PRINT COLUMN 10, "** Mes          : ", r_c10.c10_mes
	PRINT COLUMN 10, "** Comisionista : ", codcomi, " - ", r_c02.c02_nombres CLIPPED
	PRINT COLUMN 10, "** Linea        : ", linea

	SKIP 1 LINES
	PRINT COLUMN 10, "** Se consideran los pagos de las facturas emitidas ",
					 "en el siguiente rango: " 
	PRINT COLUMN 10, "** Fecha Inicial: ", r_c10.c10_fecini_fact USING "dd-mm-yyyy",
	      COLUMN 51, "** Fecha Final  : ", r_c10.c10_fecfin_fact USING "dd-mm-yyyy"

	SKIP 1 LINES
	PRINT COLUMN 01, "Fecha de Impresión: ", TODAY USING "dd-mm-yyyy", 
			1 SPACES, TIME,
	      COLUMN 82, usuario

	SKIP 1 LINES
	IF tipo = 'F' THEN
		PRINT COLUMN 1,  "Cliente",
		      COLUMN 33, "Factura",
			  COLUMN 47, "Fecha Fact",
		      COLUMN 59, fl_justifica_titulo("D", "Valor Fact", 16), 
		      COLUMN 77, "Fecha Pago",
		      COLUMN 89, fl_justifica_titulo("D", "Valor Pago", 16) 

		PRINT COLUMN 1,  "--------------------------------",
		      COLUMN 33, "--------------",
		      COLUMN 47, "------------",
		      COLUMN 59, "------------------",
		      COLUMN 77, "------------",
		      COLUMN 89, "------------------"
	ELSE		  
		-- tipo = D
		PRINT COLUMN 1,  "Cliente",
		      COLUMN 33, "Factura",
			  COLUMN 47, "Fecha Fact",
		      COLUMN 59, fl_justifica_titulo("D", "Valor Fact", 16), 
		      COLUMN 77, "Fecha Dev",
		      COLUMN 89, fl_justifica_titulo("D", "Valor Dev", 16) 

		PRINT COLUMN 1,  "--------------------------------",
		      COLUMN 33, "--------------",
		      COLUMN 47, "------------",
		      COLUMN 59, "------------------",
		      COLUMN 77, "------------",
		      COLUMN 89, "------------------"
	END IF		  
	      
BEFORE GROUP OF tipo	  
	IF tipo = 'F' THEN
		LET tot_cobrado = 0
	ELSE		  
		-- tipo = D
		LET tot_devuelto = 0
	END IF

ON EVERY ROW

	IF tipo = 'F' THEN
		LET tot_cobrado = tot_cobrado + valor_pago
	ELSE
		LET tot_devuelto = tot_devuelto + valor_pago
	END IF	

	PRINT COLUMN 1,  nomcli[1, 30] CLIPPED, 
	      COLUMN 33, tipo_doc CLIPPED, " ", num_doc CLIPPED, "-", 
		  			 div_doc USING "&&",
	      COLUMN 47, fecha_emi  USING "dd-mm-yyyy",
	      COLUMN 59, valor_doc  USING "#,###,###,##&.&&",
	      COLUMN 77, fecha_pago USING "dd-mm-yyyy",
	      COLUMN 89, valor_pago USING "#,###,###,##&.&&"

AFTER GROUP OF tipo
	NEED 2 LINES
	PRINT COLUMN 89, "----------------"
	IF tipo = 'F' THEN
		PRINT COLUMN 89, tot_cobrado  USING "#,###,###,##&.&&"
		SKIP TO TOP OF PAGE
	ELSE		
		PRINT COLUMN 89, tot_devuelto USING "#,###,###,##&.&&"
	END IF	

END REPORT



	
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
