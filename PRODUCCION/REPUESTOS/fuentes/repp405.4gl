{*
 * -- Titulo           : repp405.4gl - Reporte minimos y maximos
 * -- Elaboracion      : 30-jun-2008
 * -- Autor            : JCM
 * -- Formato Ejecucion: fglrun repp405 base módulo compañía
 *}

GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_rep		RECORD LIKE rept010.*
DEFINE rm_rep2		RECORD LIKE rept011.*
DEFINE rm_cia		RECORD LIKE gent001.*
DEFINE vm_moneda	LIKE gent000.g00_moneda_base
DEFINE vm_moneda_des	LIKE gent013.g13_nombre
DEFINE vm_tipo		LIKE rept006.r06_nombre
DEFINE vm_bodega_des	LIKE rept002.r02_nombre
DEFINE vm_tipo_sql	VARCHAR(100)

DEFINE vm_page		SMALLINT	-- PAGE   LENGTH
DEFINE vm_top		SMALLINT	-- TOP    MARGIN
DEFINE vm_left		SMALLINT	-- LEFT   MARGIN
DEFINE vm_right		SMALLINT	-- RIGHT  MARGIN
DEFINE vm_bottom	SMALLINT	-- BOTTOM MARGIN

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp405.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'repp405'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()

LET vm_top    = 1
LET vm_left   =	3
LET vm_right  =	80 
LET vm_bottom =	2
LET vm_page   = 66

OPEN WINDOW repw405_1 AT 3,2 WITH 14 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM repf405_1 FROM "../forms/repf405_1"
DISPLAY FORM repf405_1
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE i,col		SMALLINT
DEFINE linea		LIKE rept010.r10_linea
DEFINE query		VARCHAR(1000)
DEFINE query2		VARCHAR(1000)
DEFINE expr_sql         VARCHAR(600)
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE compania		LIKE rept010.r10_compania
DEFINE codigo		LIKE rept010.r10_codigo
DEFINE descripcion	LIKE rept010.r10_nombre
DEFINE stock		LIKE rept011.r11_stock_act
DEFINE cantped		LIKE rept010.r10_cantped
DEFINE comando		VARCHAR(100)

DEFINE r_r106		RECORD LIKE rept106.*

DEFINE resp		CHAR(6)

LET vm_moneda       = rg_gen.g00_moneda_base
CALL fl_lee_moneda(vm_moneda) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
       	CALL fgl_winmessage(vg_producto,'Moneda no existe moneda base.','stop')
        EXIT PROGRAM
END IF
DISPLAY r_mon.g13_nombre TO tit_moneda
LET vm_moneda_des = r_mon.g13_nombre
WHILE TRUE
	CALL lee_parametros() RETURNING expr_sql
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	CALL fl_lee_compania(vg_codcia) RETURNING rm_cia.*
	LET query = 'SELECT r10_codigo, r10_nombre, r11_stock_act, ', 
				' r10_linea, r10_cantped ',
				' FROM rept010, rept011 ',
				' WHERE r10_compania = ', vg_codcia,
		        '   AND r11_compania = r10_compania ', 
		        '   AND r11_item     = r10_codigo ', 
				'   AND r11_bodega   = "', rm_rep2.r11_bodega, '"',
				vm_tipo_sql CLIPPED,
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

	START REPORT rep_costos TO PIPE comando
	FOREACH q_deto INTO codigo, descripcion, stock, linea, cantped
		IF rm_rep.r10_linea IS NOT NULL AND
			rm_rep.r10_linea <> linea THEN
			CONTINUE FOREACH
		END IF

		-- Verificar el stock minimo
		LET query = 'SELECT FIRST 1 * FROM rept106 ',
					' WHERE r106_compania  = ', vg_codcia,
		        	'   AND r106_localidad = ', vg_codloc,
					'   AND MDY(r106_mes, 1, r106_anio) <= TODAY ', 
					'   AND r106_item      = "', codigo CLIPPED, '"',
					' ORDER BY r106_compania, r106_localidad, r106_anio DESC, ',
					' 		   r106_mes DESC '

		INITIALIZE r_r106.* TO NULL
		PREPARE cons FROM query
		DECLARE q106 CURSOR FOR cons
		OPEN  q106
		FETCH q106 INTO r_r106.*
		CLOSE q106
		FREE  q106

		OUTPUT TO REPORT rep_costos(codigo, descripcion, stock, cantped,
						r_r106.r106_stock_min, linea)

	END FOREACH
	FINISH REPORT rep_costos
	FREE q_deto
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_tip		RECORD LIKE rept006.*
DEFINE r_lin		RECORD LIKE rept003.*
DEFINE r_bod		RECORD LIKE rept002.*
DEFINE mone_aux         LIKE gent013.g13_moneda
DEFINE nomm_aux         LIKE gent013.g13_nombre
DEFINE deci_aux         LIKE gent013.g13_decimales
DEFINE codtip		LIKE rept006.r06_codigo
DEFINE nomtip		LIKE rept006.r06_nombre
DEFINE codlin		LIKE rept003.r03_codigo
DEFINE nomlin		LIKE rept003.r03_nombre
DEFINE codbog		LIKE rept002.r02_codigo
DEFINE nombog		LIKE rept002.r02_nombre
DEFINE expr_sql		VARCHAR(100)

INITIALIZE mone_aux, codtip, codlin, expr_sql, vm_tipo, vm_tipo_sql TO NULL
LET int_flag = 0
INPUT BY NAME vm_moneda, rm_rep2.r11_bodega, rm_rep.r10_linea, rm_rep.r10_tipo
	WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		LET int_flag = 1
		RETURN expr_sql
	ON KEY(F2)
		IF INFIELD(vm_moneda) THEN
               		CALL fl_ayuda_monedas()
                       		RETURNING mone_aux, nomm_aux, deci_aux
       		      	LET int_flag = 0
                      	IF mone_aux IS NOT NULL THEN
                              	LET vm_moneda = mone_aux
                               	DISPLAY BY NAME vm_moneda
                               	DISPLAY nomm_aux TO tit_moneda
                       	END IF
                END IF
		IF INFIELD(r10_tipo) THEN
                     	CALL fl_ayuda_tipo_item()
				RETURNING codtip, nomtip
       		      	LET int_flag = 0
                       	IF codtip IS NOT NULL THEN
                             	LET rm_rep.r10_tipo = codtip
                               	DISPLAY BY NAME rm_rep.r10_tipo
                               	DISPLAY nomtip TO tit_tipo
                        END IF
                END IF
		IF INFIELD(r10_linea) THEN
                     	CALL fl_ayuda_lineas_rep(vg_codcia)
				RETURNING codlin, nomlin
       		      	LET int_flag = 0
                       	IF codlin IS NOT NULL THEN
                             	LET rm_rep.r10_linea = codlin
                               	DISPLAY BY NAME rm_rep.r10_linea
                               	DISPLAY nomtip TO tit_linea
                        END IF
                END IF
		IF INFIELD(r11_bodega) THEN
                     	CALL fl_ayuda_bodegas_rep(vg_codcia, NULL, 'T')
				RETURNING codbog, nombog
       		      	LET int_flag = 0
                       	IF codbog IS NOT NULL THEN
                             	LET rm_rep2.r11_bodega = codbog
                               	DISPLAY BY NAME rm_rep2.r11_bodega
                               	DISPLAY nombog TO tit_bodega
                        END IF
             END IF
			LET int_flag = 0
	AFTER FIELD vm_moneda
               	IF vm_moneda IS NOT NULL THEN
                       	CALL fl_lee_moneda(vm_moneda)
                               	RETURNING r_mon.*
                       	IF r_mon.g13_moneda IS NULL THEN
                               	CALL fgl_winmessage(vg_producto,'Moneda no existe.','exclamation')
                               	NEXT FIELD vm_moneda
                       	END IF
                       	IF vm_moneda <> rg_gen.g00_moneda_base
                       	AND vm_moneda <> rg_gen.g00_moneda_alt THEN
                               	CALL fgl_winmessage(vg_producto,'La moneda solo puede ser moneda base o alterna.','exclamation')
                               	NEXT FIELD vm_moneda
			END IF
               	ELSE
                       	LET vm_moneda = rg_gen.g00_moneda_base
                       	CALL fl_lee_moneda(vm_moneda)
				RETURNING r_mon.*
                       	DISPLAY BY NAME vm_moneda
               	END IF
               	DISPLAY r_mon.g13_nombre TO tit_moneda
		LET vm_moneda_des = r_mon.g13_nombre
	AFTER FIELD r10_tipo
               	IF rm_rep.r10_tipo IS NOT NULL THEN
                       	CALL fl_lee_tipo_item(rm_rep.r10_tipo)
                     		RETURNING r_tip.*
                        IF r_tip.r06_codigo IS NULL THEN
                               	CALL fgl_winmessage(vg_producto,'Tipo no existe.','exclamation')
                               	NEXT FIELD r10_tipo
                        END IF
			DISPLAY r_tip.r06_nombre TO tit_tipo
		ELSE
			CLEAR tit_tipo
        END IF
	AFTER FIELD r10_linea
               	IF rm_rep.r10_linea IS NOT NULL THEN
                       	CALL fl_lee_linea_rep(vg_codcia, rm_rep.r10_linea)
                     		RETURNING r_lin.*
                        IF r_lin.r03_compania IS NULL THEN
                               	CALL fgl_winmessage(vg_producto,'Línea no existe.','exclamation')
                               	NEXT FIELD r10_linea
                        END IF
			DISPLAY r_lin.r03_nombre TO tit_linea
		ELSE
			CLEAR tit_linea
                END IF
	AFTER FIELD r11_bodega
               	IF rm_rep2.r11_bodega IS NOT NULL THEN
                       	CALL fl_lee_bodega_rep(vg_codcia, rm_rep2.r11_bodega)
                     		RETURNING r_bod.*
                        IF r_bod.r02_compania IS NULL THEN
                               	CALL fgl_winmessage(vg_producto,'Bodega no existe.','exclamation')
                               	NEXT FIELD r11_bodega
                        END IF
			DISPLAY r_bod.r02_nombre TO tit_bodega
		ELSE
			CLEAR tit_bodega
		END IF
	AFTER INPUT
		INITIALIZE vm_tipo_sql TO NULL
		IF rm_rep.r10_tipo IS NOT NULL THEN
			LET vm_tipo_sql = '  AND r10_tipo = "',
					rm_rep.r10_tipo, '"'
            CALL fl_lee_tipo_item(rm_rep.r10_tipo) RETURNING r_tip.*
			LET vm_tipo = r_tip.r06_nombre
		END IF
END INPUT
IF vm_moneda = rg_gen.g00_moneda_base THEN
	RETURN ' r10_costo_mb '
END IF
IF vm_moneda = rg_gen.g00_moneda_alt THEN
	RETURN ' r10_costo_ma '
END IF

END FUNCTION



REPORT rep_costos(codigo, descripcion, stock, cantped, stock_min, linea)
DEFINE codigo		LIKE rept010.r10_codigo
DEFINE descripcion	LIKE rept010.r10_nombre
DEFINE cantped		LIKE rept010.r10_cantped	
DEFINE linea		LIKE rept010.r10_linea	
DEFINE stock		LIKE rept011.r11_stock_act
DEFINE stock_min	LIKE rept106.r106_stock_min
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT

OUTPUT
	TOP MARGIN	vm_top
	LEFT MARGIN	vm_left
	RIGHT MARGIN	vm_right
	BOTTOM MARGIN	vm_bottom
	PAGE LENGTH	vm_page
FORMAT
PAGE HEADER
	print 'E'; print '&l26A'		-- Indica que voy a trabajar con hojas A4
	print '&k2S'	                	-- Letra  (12 cpi)

	LET modulo  = "Módulo: Repuestos"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', 'LISTADO DE MINIMOS Y MAXIMOS', 78)
		RETURNING titulo
	FOR i = 1 TO long
		LET titulo[i,i] = modulo[i,i]
	END FOR
	PRINT COLUMN 1, rm_cia.g01_razonsocial,
	      COLUMN 68, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, titulo CLIPPED,
	      COLUMN 72, "REPP403"
	PRINT COLUMN 20, "** Moneda        : ", vm_moneda, " ", vm_moneda_des
	PRINT COLUMN 20, "** Bodega        : ", rm_rep2.r11_bodega,
						" ", vm_bodega_des
	PRINT COLUMN 20, "** Línea de Venta: ", rm_rep.r10_linea
	IF vm_tipo IS NOT NULL THEN
		PRINT COLUMN 20, "** tipo          : ", vm_tipo
	END IF
	PRINT COLUMN 01, "Fecha  : ", TODAY USING "dd-mm-yyyy", 1 SPACES, TIME,
	      COLUMN 60, usuario
	SKIP 1 LINES
	PRINT COLUMN 1,   "Código",
	      COLUMN 17,  "Descripción",
	      COLUMN 42,  "Stock",
	      COLUMN 49,  "Transito",
	      COLUMN 59,  "Stock min.",
	      COLUMN 71,  "Dif."
	PRINT "------------------------------------------------------------------------------"

ON EVERY ROW
	NEED 2 LINES
	PRINT COLUMN 1,  codigo,
	      COLUMN 17, descripcion[1,24],
	      COLUMN 42, stock USING "####&",
	      COLUMN 49, cantped USING "####&",
	      COLUMN 59, stock_min USING "####&",
	      COLUMN 71, stock + cantped - stock_min USING "----&"
	
END REPORT



FUNCTION borrar_cabecera()

CLEAR vm_moneda, tit_moneda, r10_tipo, tit_tipo, r10_linea, tit_linea, r11_bodega
INITIALIZE rm_rep.*, rm_rep2.*, vm_moneda TO NULL

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
