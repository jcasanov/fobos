------------------------------------------------------------------------------
-- Titulo           : repp404.4gl - Reporte de lista de precios
-- Elaboracion      : 21-dic-2001
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp404 base módulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_demonios	VARCHAR(12)
DEFINE vm_nuevoprog     VARCHAR(400)
DEFINE rm_rep		RECORD LIKE rept010.*
DEFINE rm_rep2		RECORD LIKE rept011.*
DEFINE vm_moneda	LIKE gent000.g00_moneda_base
DEFINE vm_moneda_des	LIKE gent013.g13_nombre
DEFINE vm_tipo		LIKE rept006.r06_nombre
DEFINE vm_bodega_des	LIKE rept002.r02_nombre
DEFINE tit_stock_imp	CHAR(1)
DEFINE tit_stock_may	CHAR(1)
DEFINE vm_bodega	VARCHAR(100)
DEFINE vm_stock		VARCHAR(100)
DEFINE vm_tipo_sql	VARCHAR(100)

MAIN

DEFER QUIT 
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN   -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'repp404'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()

CALL fl_nivel_isolation()
OPEN WINDOW w_mas AT 3,2 WITH 12 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
	      MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
	ACCEPT KEY	F12
OPEN FORM f_rep FROM "../forms/repf404_1"
DISPLAY FORM f_rep
CALL borrar_cabecera()
CALL control_reporte()

END FUNCTION



FUNCTION control_reporte()
DEFINE i,col		SMALLINT
DEFINE query		VARCHAR(800)
DEFINE query_2		VARCHAR(500)
DEFINE expr_sql         VARCHAR(600)
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE codigo		LIKE rept010.r10_codigo
DEFINE descripcion	LIKE rept010.r10_nombre
DEFINE stock		LIKE rept011.r11_stock_act
DEFINE ubicacion	LIKE rept011.r11_ubicacion
DEFINE precio		LIKE rept010.r10_precio_mb
DEFINE total		DECIMAL(14,2)
DEFINE comando		VARCHAR(100)
DEFINE r_r10		RECORD LIKE rept010.*

LET tit_stock_imp = 'N'
LET tit_stock_may = 'N'
LET vm_moneda     = rg_gen.g00_moneda_base
CALL fl_lee_moneda(vm_moneda) RETURNING r_mon.*
IF r_mon.g13_moneda IS NULL THEN
       	CALL fgl_winmessage(vg_producto,'Moneda no existe moneda base.','stop')
        EXIT PROGRAM
END IF
DISPLAY r_mon.g13_nombre TO tit_moneda
LET vm_moneda_des = r_mon.g13_nombre
WHILE TRUE
	LET total = 0
	CALL lee_parametros() RETURNING expr_sql
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL fl_control_reportes() RETURNING comando
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	LET query = 'SELECT r11_item, r11_ubicacion, r11_stock_act', 
			' FROM rept011 ', 
			'WHERE r11_compania =',vg_codcia,
			vm_bodega CLIPPED,
			vm_stock CLIPPED,
		        ' ORDER BY r11_item '

	PREPARE deto FROM query
	DECLARE q_deto CURSOR FOR deto
	OPEN q_deto
	FETCH q_deto
	IF STATUS = NOTFOUND THEN
		CLOSE q_deto
		FREE q_deto
		CALL fl_mensaje_consulta_sin_registros()
		CONTINUE WHILE
	END IF
	CLOSE q_deto
	START REPORT rep_precios TO PIPE comando
	
	FOREACH q_deto INTO codigo, ubicacion, stock
		CALL fl_lee_item(vg_codcia, codigo)
			RETURNING r_r10.*

		IF r_r10.r10_linea <> rm_rep.r10_linea THEN
			CONTINUE FOREACH
		END IF
		IF rm_rep.r10_tipo IS NOT NULL THEN
			IF r_r10.r10_tipo <> rm_rep.r10_tipo THEN
				CONTINUE FOREACH
			END IF
		END IF
		IF vm_moneda = rg_gen.g00_moneda_base THEN
			LET precio = r_r10.r10_precio_mb
		END IF
		IF vm_moneda = rg_gen.g00_moneda_alt THEN
			LET precio = r_r10.r10_precio_ma
		END IF

		LET total = total + precio * stock
		LET descripcion = r_r10.r10_nombre
  		OUTPUT TO REPORT rep_precios(codigo, descripcion, ubicacion, 
  					     stock, precio, total)
		IF int_flag THEN
			EXIT FOREACH
		END IF
	END FOREACH
	FINISH REPORT rep_precios
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

INITIALIZE mone_aux, codtip, codlin, codbog, expr_sql, vm_tipo, vm_tipo_sql,
	vm_bodega_des TO NULL
LET int_flag = 0
INPUT BY NAME vm_moneda, rm_rep.r10_linea, rm_rep.r10_tipo, tit_stock_imp,
	tit_stock_may, rm_rep2.r11_bodega
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
	AFTER FIELD tit_stock_may 
		IF tit_stock_may = 'S' THEN
			LET tit_stock_imp = 'S'
		END IF
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
			LET vm_bodega_des = r_bod.r02_nombre
		ELSE
			CLEAR tit_bodega
                END IF
	AFTER INPUT
		INITIALIZE vm_tipo_sql, vm_bodega, vm_stock TO NULL
		IF tit_stock_imp = 'S' THEN
			IF rm_rep2.r11_bodega IS NULL THEN
                               	CALL fgl_winmessage(vg_producto,'Ingrese la Bodega.','exclamation')
				NEXT FIELD r11_bodega
			END IF
		END IF
		IF tit_stock_may = 'S' THEN
			IF rm_rep2.r11_bodega IS NULL THEN
                               	CALL fgl_winmessage(vg_producto,'Ingrese la Bodega.','exclamation')
				NEXT FIELD r11_bodega
			ELSE
				LET vm_stock = '  AND r11_stock_act > 0'
			END IF
		END IF
		IF rm_rep.r10_tipo IS NOT NULL THEN
			LET vm_tipo_sql = '  AND r10_tipo     = "',
					rm_rep.r10_tipo, '"'
                       	CALL fl_lee_tipo_item(rm_rep.r10_tipo) RETURNING r_tip.*
			LET vm_tipo = r_tip.r06_nombre
		END IF
		IF rm_rep2.r11_bodega IS NOT NULL THEN
			LET vm_bodega = '  AND r11_bodega = "',
					rm_rep2.r11_bodega, '"'
		ELSE
			NEXT FIELD r11_bodega
		END IF
END INPUT
IF vm_moneda = rg_gen.g00_moneda_base THEN
	RETURN ' r10_precio_mb '
END IF
IF vm_moneda = rg_gen.g00_moneda_alt THEN
	RETURN ' r10_precio_ma '
END IF

END FUNCTION



REPORT rep_precios(codigo, descripcion, ubicacion, stock, precio, total)
DEFINE codigo		LIKE rept010.r10_codigo
DEFINE descripcion	LIKE rept010.r10_nombre
DEFINE ubicacion	LIKE rept011.r11_ubicacion
DEFINE stock		LIKE rept011.r11_stock_act
DEFINE precio		LIKE rept010.r10_precio_mb
DEFINE total		DECIMAL(14,2)
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	15
	RIGHT MARGIN	90
	BOTTOM MARGIN	4
	PAGE LENGTH	66
FORMAT
PAGE HEADER
	print 'E'; 
	print '&l26A';	-- Indica que voy a trabajar con hojas A4
	print '&k2S'	        -- Letra condensada (16 cpi)

	LET modulo  = "Módulo: Repuestos"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('C', 'LISTA DE PRECIOS', 78)
		RETURNING titulo
	FOR i = 1 TO long
		LET titulo[i,i] = modulo[i,i]
	END FOR
	PRINT COLUMN 1, rg_cia.g01_razonsocial,
	      COLUMN 72, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, titulo CLIPPED,
	      COLUMN 76, "REPP404"
	PRINT COLUMN 20, "** Moneda        : ", vm_moneda, " ", vm_moneda_des
	IF vm_bodega IS NOT NULL THEN
		PRINT COLUMN 20, "** Bodega        : ", rm_rep2.r11_bodega,
							" ", vm_bodega_des
	END IF
	PRINT COLUMN 20, "** Línea de Venta: ", rm_rep.r10_linea
	IF vm_tipo IS NOT NULL THEN
		PRINT COLUMN 20, "** Tipo          : ", vm_tipo
	END IF
	PRINT COLUMN 01, "Fecha  : ", TODAY USING "dd-mm-yyyy", 1 SPACES, TIME,
	      COLUMN 64, usuario

	print '&k2S'	                -- Letra condensada (16 cpi)

	PRINT "=================================================================================="
	IF tit_stock_imp = 'N' THEN
		PRINT COLUMN 1,   "Código",
		      COLUMN 23,  "Descripción",
		      COLUMN 73,  "Precio"
	ELSE
		PRINT COLUMN 1,   "Código",
		      COLUMN 17,  "Descripción",
		      COLUMN 40,  "Percha",
		      COLUMN 47,  'Ubicación',
		      COLUMN 59,  'Stock',
		      COLUMN 77,  "Precio"
	END IF
	PRINT "=================================================================================="

ON EVERY ROW
	IF tit_stock_imp = 'N' THEN
		PRINT COLUMN 1,  codigo,
		      COLUMN 22, descripcion,
		      COLUMN 63, precio USING "#,###,###,##&.##"
	ELSE
		PRINT COLUMN 1,  codigo,
		      COLUMN 17, descripcion[1,20],
		      COLUMN 40, ubicacion[1,3], ' ',
		      COLUMN 47, ubicacion[4,10], 
		      COLUMN 59, stock USING "####&",
		      COLUMN 67, precio USING "#,###,###,##&.##"
	END IF
	
ON LAST ROW
	PRINT COLUMN 67, "----------------"
	PRINT COLUMN 53, "TOTAL ==>  ", total USING "###,###,###,##&.##"

END REPORT



FUNCTION borrar_cabecera()

CLEAR vm_moneda, tit_moneda, r10_tipo, tit_tipo, r10_linea, tit_linea
INITIALIZE rm_rep.*, vm_moneda TO NULL

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
