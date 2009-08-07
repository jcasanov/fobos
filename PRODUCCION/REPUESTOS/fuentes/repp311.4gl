{*
 * Titulo           : repp311.4gl - Consulta Items con Stock y sin Ventas
 * Elaboracion      : 14-ene-2008
 * Autor            : JCM
 * Formato Ejecucion: fglrun repp311 base módulo compañía localidad
 *}
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_r10		RECORD LIKE rept010.*
DEFINE rm_r11		RECORD LIKE rept011.*

DEFINE vm_bodega	LIKE rept011.r11_bodega
DEFINE vm_fecha		DATE
DEFINE vm_linea		LIKE rept010.r10_linea
DEFINE vm_rotacion	LIKE rept010.r10_rotacion
DEFINE vm_tipo		LIKE rept010.r10_tipo
DEFINE sin_ventas	CHAR(1)

DEFINE r_detalle	ARRAY[150000] OF RECORD
	r10_codigo		LIKE rept010.r10_codigo,
	r10_nombre		LIKE rept010.r10_nombre,
	fec_ult_ing		DATE,
	fec_ult_vta		DATE, 
	r11_stock_act	LIKE rept011.r11_stock_act,
	r10_costo_mb	LIKE rept010.r10_costo_mb
	END RECORD


MAIN

DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN

CALL startlog('../logs/repp311.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()

IF num_args() <> 4 THEN   -- Validar # parámetros correcto
        CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto.', 'st
op')
        EXIT PROGRAM
END IF

LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'repp311'

CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
--CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)


CALL fl_nivel_isolation()
OPEN WINDOW w_311 AT 3,2 WITH 22 ROWS, 80 COLUMNS
    ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE 0, BORDER,
              MESSAGE LINE LAST - 2)
OPTIONS INPUT WRAP,
        ACCEPT KEY      F12
OPEN FORM f_repf311 FROM "../forms/repf311_1"
DISPLAY FORM f_repf311

INITIALIZE rm_r11.*, rm_r10.*, vm_fecha, vm_linea, vm_tipo, vm_rotacion,
	   vm_bodega TO NULL

LET vm_fecha = TODAY

DISPLAY 'Item'        TO tit_col1
DISPLAY 'Descripci¢n' TO tit_col2
DISPLAY 'Ult. Ing.'   TO tit_col3
DISPLAY 'Ult. Vta.'   TO tit_col4
DISPLAY 'Stock'       TO tit_col5
DISPLAY 'Costo'       TO tit_col6

WHILE TRUE
	CALL funcion_master()
END WHILE

END MAIN




FUNCTION funcion_master()

DEFINE r_r02 		RECORD LIKE rept002.*		--BODEGAS
DEFINE r_r03 		RECORD LIKE rept003.*		--LINEAS
DEFINE r_r04 		RECORD LIKE rept004.*		--ROTACION
DEFINE r_r06 		RECORD LIKE rept006.*		--TIPO

INITIALIZE r_r02.*, r_r03.*, r_r04.*, r_r06.* TO NULL
LET sin_ventas = 'N'

LET int_flag = 0

INPUT BY NAME vm_bodega, vm_fecha, sin_ventas, vm_linea, vm_rotacion, vm_tipo
	      WITHOUT DEFAULTS

	ON KEY(INTERRUPT)
		IF NOT field_touched(vm_bodega, vm_fecha, 
				     vm_linea, vm_rotacion, vm_tipo) THEN
			EXIT PROGRAM
		ELSE
			RETURN
		END IF

	ON KEY(F2)

		IF INFIELD(vm_bodega) THEN
			CALL fl_ayuda_bodegas_rep(vg_codcia, NULL, 'T')
				RETURNING r_r02.r02_codigo, r_r02.r02_nombre
			IF r_r02.r02_codigo IS NOT NULL THEN
				LET vm_bodega = r_r02.r02_codigo
				DISPLAY BY NAME vm_bodega
				DISPLAY r_r02.r02_nombre TO nom_bodega
			END IF
		END IF

		IF INFIELD(vm_linea) THEN
			CALL fl_ayuda_lineas_rep(vg_codcia)
				RETURNING r_r03.r03_codigo, r_r03.r03_nombre
			IF r_r03.r03_codigo IS NOT NULL THEN
				LET vm_linea = r_r03.r03_codigo
				DISPLAY BY NAME vm_linea
				DISPLAY r_r03.r03_nombre TO nom_linea
			END IF
		END IF

		IF INFIELD(vm_rotacion) THEN
			CALL fl_ayuda_clases(vg_codcia)
				RETURNING r_r04.r04_rotacion, r_r04.r04_nombre
			IF r_r04.r04_rotacion IS NOT NULL THEN
				LET vm_rotacion = r_r04.r04_rotacion
				DISPLAY BY NAME vm_rotacion
				DISPLAY r_r04.r04_nombre TO nom_rotacion
			END IF
		END IF

		IF INFIELD(vm_tipo) THEN
			CALL fl_ayuda_tipo_item()
				RETURNING r_r06.r06_codigo, r_r06.r06_nombre
			IF r_r06.r06_codigo IS NOT NULL THEN
				LET vm_tipo = r_r06.r06_codigo
				DISPLAY BY NAME vm_tipo
				DISPLAY r_r06.r06_nombre TO nom_tipo
			END IF
		END IF

		LET int_flag = 0

	AFTER FIELD vm_bodega
		IF vm_bodega IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, vm_bodega)	
				RETURNING r_r02.*
			IF r_r02.r02_codigo IS NULL THEN
				CLEAR nom_bodega
				CALL fgl_winmessage(vg_producto, 'No existe la Bodega en la Compa¤¡a.', 'exclamation')
				NEXT FIELD vm_bodega
			ELSE 
				DISPLAY r_r02.r02_nombre TO nom_bodega
			END IF
		ELSE
			CLEAR nom_bodega
		END IF

	AFTER FIELD vm_linea
		IF vm_linea IS NOT NULL THEN
			CALL fl_lee_linea_rep(vg_codcia, vm_linea)
				RETURNING r_r03.*
			IF r_r03.r03_codigo IS NULL THEN
				CLEAR nom_linea 
				CALL fgl_winmessage(vg_producto, 'No existe Linea de Venta en la Compa¤¡a.','exclamation')
				NEXT FIELD vm_linea
			ELSE
				DISPLAY r_r03.r03_nombre TO nom_linea
			END IF
		ELSE
			CLEAR nom_linea
		END IF
		
	AFTER FIELD vm_rotacion
		IF vm_rotacion IS NOT NULL THEN
			CALL fl_lee_indice_rotacion(vg_codcia, vm_rotacion)
				RETURNING r_r04.*
			IF r_r04.r04_rotacion IS NULL THEN
				CLEAR nom_rotacion
				CALL fgl_winmessage(vg_producto,'No existe la Rotaci¢n en la Compa¤¡a.','exclamation')
				NEXT FIELD vm_rotacion
			ELSE
				DISPLAY r_r04.r04_nombre TO nom_rotacion
			END IF
		ELSE
			CLEAR nom_rotacion
		END IF
	
	AFTER FIELD vm_tipo
		IF vm_tipo IS NOT NULL THEN
			CALL fl_lee_tipo_item(vm_tipo)
				RETURNING r_r06.*
			IF r_r06.r06_codigo IS NULL THEN
				CLEAR nom_tipo
				CALL fgl_winmessage(vg_producto,'No existe el tipo de item en la Compan¡a.','exclamation')
				NEXT FIELD vm_tipo
			ELSE
				DISPLAY r_r06.r06_nombre TO nom_tipo
			END IF
		ELSE
			CLEAR nom_tipo
		END IF

	AFTER FIELD vm_fecha
		IF vm_fecha IS NOT NULL THEN
			IF vm_fecha < '01-01-2000' THEN
				CALL fgl_winmessage(vg_producto,'No puede ingresar una fecha menor a 01-01-2000.','exclamation')
				NEXT FIELD vm_fecha
			END IF
			LET sin_ventas = 'N'
			DISPLAY BY NAME sin_ventas 
		END IF

	AFTER FIELD sin_ventas
		IF sin_ventas IS NOT NULL THEN
			IF sin_ventas = 'S' THEN
				INITIALIZE vm_fecha TO NULL
				DISPLAY BY NAME vm_fecha
			END IF
		END IF

	AFTER INPUT 
		IF vm_bodega IS NULL THEN
			NEXT FIELD vm_bodega
		END IF
		IF vm_fecha IS NULL AND sin_ventas ='N' THEN
			NEXT FIELD vm_fecha
		END IF
		CALL control_display_array()

END INPUT

END FUNCTION




FUNCTION control_display_array()
DEFINE expr_sql 	VARCHAR(1500)
DEFINE sq_ulting 	VARCHAR(500)
DEFINE sq_ultvta 	VARCHAR(500)

DEFINE item		LIKE rept010.r10_codigo
DEFINE fec_ulting	LIKE rept011.r11_fec_ulting
DEFINE fec_ultvta	LIKE rept011.r11_fec_ultvta
DEFINE stock		LIKE rept011.r11_stock_act

DEFINE i,j 		SMALLINT

DEFINE r_r10		RECORD LIKE rept010.*

DEFINE r_orden		ARRAY[5] OF CHAR(4)
DEFINE columna		SMALLINT

CREATE TEMP TABLE tmp_items
	(item		VARCHAR(15),
	 nombre		VARCHAR(40),
	 fec_ulting	DATE,
	 fec_ultvta	DATE,
	 stock		SMALLINT,
	 costo		DECIMAL(11,2))

LET expr_sql = 'SELECT r11_item, r11_fec_ulting as ulting, r11_fec_ultvta, ',
                     ' r11_stock_act ',
		' FROM rept011 ',
		'WHERE r11_compania   =',vg_codcia,
		'  AND r11_bodega     ="',vm_bodega,'"',
		'  AND r11_stock_act  > 0'
IF sin_ventas = 'N' THEN
	LET expr_sql = expr_sql CLIPPED, '  AND r11_fec_ultvta <= "',vm_fecha,'"'
ELSE
	LET expr_sql = expr_sql CLIPPED, '  AND r11_fec_ultvta IS NULL '
END IF

PREPARE consulta FROM expr_sql
DECLARE q_consulta CURSOR FOR consulta
		
LET i = 1
FOREACH q_consulta INTO item, fec_ulting, fec_ultvta, stock
	IF fec_ultvta > vm_fecha THEN
		CONTINUE FOREACH
	END IF
	CALL fl_lee_item(vg_codcia, item) RETURNING r_r10.*

	IF vm_linea IS NOT NULL AND vm_linea <> r_r10.r10_linea THEN
		CONTINUE FOREACH
	END IF
	IF vm_rotacion IS NOT NULL AND vm_rotacion <> r_r10.r10_rotacion THEN
		CONTINUE FOREACH
	END IF
	IF vm_tipo IS NOT NULL AND vm_tipo <> r_r10.r10_tipo THEN
		CONTINUE FOREACH
	END IF

	LET r_detalle[i].r10_codigo    = item
	LET r_detalle[i].r10_nombre    = r_r10.r10_nombre
	LET r_detalle[i].fec_ult_ing   = fec_ulting
	LET r_detalle[i].fec_ult_vta   = fec_ultvta
	LET r_detalle[i].r11_stock_act = stock			
	LET r_detalle[i].r10_costo_mb  = r_r10.r10_costo_mb			
	
	INSERT INTO tmp_items VALUES(r_detalle[i].*)

	LET i = i + 1
	IF i > 150000 THEN
		EXIT FOREACH
	END IF

END FOREACH

LET i = i - 1
IF i = 0 THEN
	DROP TABLE tmp_items
	CALL fl_mensaje_consulta_sin_registros()
	RETURN
END IF


LET columna = 1

FOR i = 1 TO 5
	LET r_orden[i] = 'ASC'
END FOR


WHILE TRUE
	LET expr_sql = 'SELECT * FROM tmp_items ',
			'ORDER BY ',columna, ' ',r_orden[columna]

	PREPARE consulta_2 FROM expr_sql
	DECLARE q_consulta_2 CURSOR FOR consulta_2
	
	LET i = 1
	FOREACH q_consulta_2 INTO r_detalle[i].*
		LET i = i + 1
	END FOREACH

	LET i = i - 1

	CALL set_count(i)
	DISPLAY ARRAY r_detalle TO r_detalle.*

		BEFORE DISPLAY 
			CALL dialog.keysetlabel('ACCEPT','')
			CALL dialog.keysetlabel("F6","Imprimir")

		BEFORE ROW
			LET j = arr_curr()
			DISPLAY '' AT 08,1
			DISPLAY j, ' de ', i AT 08,60  
	
		ON KEY(INTERRUPT)
			DISPLAY '' AT 08,1
			LET int_flag = 0
			DROP TABLE tmp_items
			RETURN
		ON KEY(F5)
			CALL control_ver_movimientos(r_detalle[j].r10_codigo)
		ON KEY(F6)
			CALL imprimir(i)		
			LET int_flag = 0

		ON KEY(F15)
			LET columna = 1
			EXIT DISPLAY
		ON KEY(F16)
			LET columna = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET columna = 3
			EXIT DISPLAY
		ON KEY(F18)
			LET columna = 4
			EXIT DISPLAY
		ON KEY(F19)
			LET columna = 5
			EXIT DISPLAY

		AFTER DISPLAY
			CONTINUE DISPLAY
		
	END DISPLAY

	IF r_orden[columna] = 'ASC' THEN
		LET r_orden[columna] = 'DESC'
	ELSE
		LET r_orden[columna] = 'ASC'
	END IF 

END WHILE

END FUNCTION



FUNCTION control_ver_movimientos(item)
DEFINE item		LIKE rept010.r10_codigo
DEFINE fecha	DATE
DEFINE command_run 	VARCHAR(200)

IF sin_ventas THEN
	LET fecha = TODAY
ELSE
	LET fecha = vm_fecha
END IF

LET command_run = 'fglrun repp307 ',vg_base, ' ',vg_modulo, ' ',
		  vg_codcia, ' ', vg_codloc, ' ',vm_bodega, ' ',item, ' ',
		 '01-01-2000', ' ', fecha
RUN command_run

END FUNCTION



FUNCTION imprimir(maxelm)
DEFINE i		SMALLINT          
DEFINE maxelm		SMALLINT          
DEFINE comando		VARCHAR(100)

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN          
END IF

START REPORT rep_stock_sv TO PIPE comando 
	FOR i = 1 TO (maxelm)
		OUTPUT TO REPORT rep_stock_sv(i)
	END FOR
FINISH REPORT rep_stock_sv

END FUNCTION



REPORT rep_stock_sv(numelm)
DEFINE numelm		SMALLINT
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT
DEFINE fecha		DATE

DEFINE r_r02		RECORD LIKE rept002.*
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE r_r04		RECORD LIKE rept004.*
DEFINE r_r06		RECORD LIKE rept006.*

OUTPUT
	TOP MARGIN	1
	LEFT MARGIN	2
	RIGHT MARGIN	90
	BOTTOM MARGIN	4
	PAGE LENGTH	66
FORMAT
PAGE HEADER
	print 'E'; print '&l26A';	-- Indica que voy a trabajar con hojas A4
	print '&k4S'	                -- Letra (12 cpi)
	LET modulo  = "Módulo: Repuestos"
	LET long    = LENGTH(modulo)
	LET usuario = 'Usuario: ', vg_usuario
	CALL fl_justifica_titulo('D', usuario, 19) RETURNING usuario
	CALL fl_justifica_titulo('I', 'LISTADO STOCK SIN VENTAS', 80)
		RETURNING titulo

	CALL fl_lee_bodega_rep(vg_codcia, vm_bodega) RETURNING r_r02.*
	CALL fl_lee_linea_rep(vg_codcia, vm_linea) RETURNING r_r03.*
	CALL fl_lee_indice_rotacion(vg_codcia, vm_rotacion) RETURNING r_r04.*
	CALL fl_lee_tipo_item(vm_tipo) RETURNING r_r06.*

	PRINT COLUMN 1, rg_cia.g01_razonsocial,
  	      COLUMN 82, "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, modulo CLIPPED,
	      COLUMN 86, "REPP311" 
	PRINT COLUMN 30, titulo CLIPPED
	SKIP 1 LINES
	PRINT COLUMN 30, "** Bodega        : ", vm_bodega, " ", r_r02.r02_nombre
	PRINT COLUMN 30, "** Ult. Vta. <= a: ", vm_fecha USING 'dd-mm-yyyy'

	PRINT COLUMN 30, "** Linea Venta   : ", vm_linea, " ", r_r03.r03_nombre 
	PRINT COLUMN 30, "** Ind. Rotacion : ", vm_rotacion, " ", r_r04.r04_nombre 
	PRINT COLUMN 30, "** Tipo Articulo : ", vm_tipo, " ", r_r06.r06_nombre 

	PRINT COLUMN 01, "Fecha  : ", TODAY USING "dd-mm-yyyy", 1 SPACES, TIME,
	      COLUMN 70, usuario
	SKIP 1 LINES
--	print '&k2S'	                -- Letra condensada (16 cpi)
	PRINT COLUMN 1,   "Item",
	      COLUMN 18,  "Descripcion",
	      COLUMN 55,  "Ult. Ingreso",
	      COLUMN 73,  "Ult. Venta",
	      COLUMN 86,  "Stock",
	      COLUMN 93,  "Costo"
	PRINT "------------------------------------------------------------------------------------------------------------------------------------"
ON EVERY ROW
	NEED 2 LINES
	PRINT COLUMN 1,   r_detalle[numelm].r10_codigo,
	      COLUMN 18,  r_detalle[numelm].r10_nombre,
	      COLUMN 55,  r_detalle[numelm].fec_ult_ing USING "dd-mm-yyyy",
	      COLUMN 73,  r_detalle[numelm].fec_ult_vta USING "dd-mm-yyyy",
	      COLUMN 86,  r_detalle[numelm].r11_stock_act USING "####&", 
	      COLUMN 93,  r_detalle[numelm].r10_costo_mb USING "###,##&.&&" 

END REPORT



FUNCTION validar_parametros()
                                                                                
CALL fl_lee_modulo(vg_modulo) RETURNING rg_mod.*
IF rg_mod.g50_modulo IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe módulo: ' || vg_modulo, 'sto
p')
        EXIT PROGRAM
END IF
CALL fl_lee_compania(vg_codcia) RETURNING rg_cia.*
IF rg_cia.g01_compania IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe compañía: '|| vg_codcia, 'st
op')
        EXIT PROGRAM
END IF
IF rg_cia.g01_estado <> 'A' THEN
     CALL fgl_winmessage(vg_producto, 'Compañía no está activa: ' || vg_codcia, 			 'stop')
     EXIT PROGRAM
END IF
IF vg_codloc IS NULL THEN
        LET vg_codloc   = fl_retorna_agencia_default(vg_codcia)
END IF
CALL fl_lee_localidad(vg_codcia, vg_codloc) RETURNING rg_loc.*
IF rg_loc.g02_localidad IS NULL THEN
        CALL fgl_winmessage(vg_producto, 'No existe localidad: ' || vg_codloc,
			    'stop')
        EXIT PROGRAM
END IF
IF rg_loc.g02_estado <> 'A' THEN
      CALL fgl_winmessage(vg_producto, 'Localidad no está activa: '|| vg_codloc, 			  'stop')
      EXIT PROGRAM
END IF
                                                                                
END FUNCTION

