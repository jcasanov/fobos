{*
 * Titulo           : repp306.4gl - Consulta de stocks Detallada de Items
 * Elaboracion      : 26-nov-2008
 * Autor            : JCM
 * Formato Ejecucion: fglrun repp306 base_datos modulo compañía localidad [item]
 *}
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_orden ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE rm_item ARRAY[1000] OF RECORD
	r10_codigo		LIKE rept010.r10_codigo,
	r10_nombre		LIKE rept010.r10_nombre,
	precio			DECIMAL(12,2),
	r11_stock_act	LIKE rept011.r11_stock_act,
	stock_disp		LIKE rept011.r11_stock_act,
	stock_tdb		LIKE rept011.r11_stock_act
	END RECORD
DEFINE rm_par RECORD
	moneda		LIKE gent013.g13_moneda,
	tit_moneda	CHAR(20),
	bodega		LIKE rept002.r02_codigo,
	tit_bodega	VARCHAR(20),
	linea		LIKE rept003.r03_codigo,
	r10_filtro	LIKE rept010.r10_filtro
	END RECORD
DEFINE vm_max_rows	SMALLINT

DEFINE rm_g04		RECORD LIKE gent004.*
DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE vm_item		LIKE rept010.r10_codigo



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp306.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 AND num_args() <> 5 THEN  -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
INITIALIZE vm_item TO NULL
IF num_args() = 5 THEN
	LET vm_item = arg_val(5)
END IF
LET vg_proceso = 'repp306'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE r		RECORD LIKE gent000.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_rep		RECORD LIKE rept000.*
DEFINE r_bod		RECORD LIKE rept002.*
DEFINE i		SMALLINT

CREATE TEMP TABLE temp_item
	(te_item	CHAR(15),
	 te_descripcion CHAR(40),
	 te_precio	DECIMAL(14,2),
	 te_stock	INTEGER,
	 te_stock_disp	INTEGER,
	 te_stock_tbd	INTEGER)

CALL fl_lee_usuario(vg_usuario)             RETURNING rm_g05.*
CALL fl_lee_grupo_usuario(rm_g05.g05_grupo) RETURNING rm_g04.*

INITIALIZE rm_par.* TO NULL
LET rm_par.moneda = rg_gen.g00_moneda_base
CALL fl_lee_moneda(rm_par.moneda) RETURNING r_mon.* 
LET rm_par.tit_moneda = r_mon.g13_nombre
CALL fl_lee_compania_repuestos(vg_codcia) RETURNING r_rep.* 
LET rm_par.bodega = r_rep.r00_bodega_fact
CALL fl_lee_bodega_rep(vg_codcia, r_rep.r00_bodega_fact) RETURNING r_bod.*
LET rm_par.tit_bodega = r_bod.r02_nombre
OPEN WINDOW w_imp AT 3,2 WITH 22 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_cons FROM '../forms/repf306_1'
DISPLAY FORM f_cons
LET vm_max_rows = 1000
DISPLAY 'Item'           TO tit_col1
DISPLAY 'Descripción'    TO tit_col2
DISPLAY 'Prec. Unit.'    TO tit_col3
DISPLAY 'St. Bd.'		 TO tit_col4
DISPLAY 'St. Disp.'    	 TO tit_col5
DISPLAY 'St. Tot.'    	 TO tit_col6
WHILE TRUE
	FOR i = 1 TO fgl_scr_size('rm_item')
		CLEAR rm_item[i].*
	END FOR

	-- Se esta llamando a la pantalla indicandole el item como parametro
	IF vm_item IS NULL THEN
		CALL lee_parametros1()
		IF int_flag THEN
			RETURN
		END IF
	END IF
	CALL lee_parametros2()
	IF int_flag THEN
		CONTINUE WHILE
	END IF
	CALL muestra_consulta()
	IF vm_item IS NOT NULL THEN
		EXIT WHILE
	END IF
END WHILE

END FUNCTION



FUNCTION lee_parametros1()
DEFINE resp		CHAR(3)
DEFINE mon_aux		LIKE gent013.g13_moneda
DEFINE bod_aux		LIKE rept002.r02_codigo
DEFINE lin_aux		LIKE rept003.r03_codigo
DEFINE tit_aux		VARCHAR(30)
DEFINE num_dec		SMALLINT
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_bod		RECORD LIKE rept002.*
DEFINE r_lin		RECORD LIKE rept003.*

LET int_flag = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(F2)
		IF infield(moneda) THEN
			CALL fl_ayuda_monedas() RETURNING mon_aux, tit_aux,
							  num_dec
			IF mon_aux IS NOT NULL THEN
				LET rm_par.moneda     = mon_aux
				LET rm_par.tit_moneda = tit_aux
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		IF infield(bodega) THEN
			CALL fl_ayuda_bodegas_rep(vg_codcia, NULL, 'T') RETURNING bod_aux, tit_aux
			IF bod_aux IS NOT NULL THEN
				LET rm_par.bodega     = bod_aux
				LET rm_par.tit_bodega = tit_aux
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		IF infield(linea) THEN
			CALL fl_ayuda_lineas_rep(vg_codcia) RETURNING lin_aux, tit_aux
			IF lin_aux IS NOT NULL THEN
				LET rm_par.linea = lin_aux
				DISPLAY BY NAME rm_par.*
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda) RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Moneda no existe', 'exclamation')
				NEXT FIELD moneda
			END IF
			LET rm_par.tit_moneda = r_mon.g13_nombre
			DISPLAY BY NAME rm_par.tit_moneda
		ELSE
			LET rm_par.tit_moneda = NULL
			CLEAR tit_moneda
		END IF
	AFTER FIELD bodega
		IF rm_par.bodega IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, rm_par.bodega) RETURNING r_bod.*
			IF r_bod.r02_codigo IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Bodega no existe', 'exclamation')
				NEXT FIELD bodega
			END IF
			LET rm_par.tit_bodega = r_bod.r02_nombre
			DISPLAY BY NAME rm_par.tit_bodega
		ELSE
			LET rm_par.tit_bodega = NULL
			CLEAR tit_bodega
		END IF
	AFTER FIELD linea
		IF rm_par.linea IS NOT NULL THEN
			CALL fl_lee_linea_rep(vg_codcia, rm_par.linea) RETURNING r_lin.*
			IF r_lin.r03_codigo IS NULL THEN
				CALL fgl_winmessage(vg_producto, 'Línea no existe', 'exclamation')
				NEXT FIELD linea
			END IF
		END IF
END INPUT

END FUNCTION



FUNCTION lee_parametros2()
DEFINE i		SMALLINT
DEFINE query		VARCHAR(700)
DEFINE campos		VARCHAR(50)
DEFINE expr_sql		VARCHAR(200)
DEFINE expr_lin		VARCHAR(100)
DEFINE expr_filtro 	VARCHAR(150)
DEFINE te_codigo	CHAR(15)
DEFINE te_nombre 	CHAR(40)
DEFINE te_precio	DECIMAL(14,2)
DEFINE te_stock		INTEGER
DEFINE te_stock_disp	INTEGER
DEFINE te_stock_tbd		INTEGER
DEFINE costo			INTEGER
DEFINE rs		RECORD LIKE rept011.*

DEFINE len 		SMALLINT
DEFINE expr_stock	VARCHAR(50)
DEFINE expr_item	VARCHAR(50)
DEFINE tabla_stock 	VARCHAR(15)
DEFINE join_stock	VARCHAR(200)
DEFINE expr_sql2	VARCHAR(200)

DELETE FROM temp_item
LET int_flag = 0

IF vm_item IS NULL THEN
	IF rm_par.moneda = rg_gen.g00_moneda_base THEN
		LET campos = 'r10_precio_mb precio '
		CONSTRUCT expr_sql ON r10_codigo, r10_nombre, 
				      r10_precio_mb, r11_stock_act FROM 
				      r10_codigo, r10_nombre, precio, r11_stock_act
	ELSE
		LET campos = 'r10_precio_ma precio '
		CONSTRUCT expr_sql ON r10_codigo, r10_nombre, 
				      r10_precio_ma, r11_stock_act FROM 
				      r10_codigo, r10_nombre, precio, r11_stock_act
	END IF
	IF int_flag THEN
		RETURN
	END IF
ELSE
		LET campos = 'r10_precio_mb precio '
END IF

ERROR 'Generando consulta . . . espere por favor' ATTRIBUTE(NORMAL)
LET expr_lin = ' '
IF rm_par.linea IS NOT NULL THEN
	LET expr_lin = " AND r10_linea = '", rm_par.linea CLIPPED, "'"
END IF
LET expr_filtro = ' '
IF rm_par.r10_filtro IS NOT NULL THEN
	LET expr_filtro = " AND r10_filtro = '", rm_par.r10_filtro CLIPPED, "'"
	FOR i = 1 TO LENGTH(rm_par.r10_filtro)
		IF rm_par.r10_filtro[i,i] = '*' THEN
			LET expr_filtro = " AND r10_filtro MATCHES '", rm_par.r10_filtro CLIPPED, "'"
			EXIT FOR
		END IF
	END FOR
END IF

INITIALIZE expr_stock TO NULL
LET expr_sql2 = expr_sql
	
FOR i = 1 TO LENGTH(expr_sql) 
	IF expr_sql[i,i+12] = 'r11_stock_act' THEN
		LET expr_stock = expr_sql[i,i+40] 
		LET expr_stock = ' AND ', expr_stock
		IF i > 1 THEN
			LET expr_sql2 = expr_sql[1,i-1]
		ELSE
			LET expr_sql2 = ' '
		END IF
		EXIT FOR
	END IF
END FOR

LET expr_item = ""
IF vm_item IS NOT NULL THEN
	LET expr_item = " AND r10_codigo = '", vm_item CLIPPED, "' "
ELSE
	LET expr_sql2 = " AND ", expr_sql2
END IF

LET query = "SELECT r10_codigo, r10_nombre,", campos, ", r11_stock_act, r10_costo_mb ", 
		  " FROM rept010, OUTER rept011 ",
		  " WHERE r10_compania  = ", vg_codcia, 
			expr_item CLIPPED,
		    expr_lin CLIPPED,  
		    expr_filtro CLIPPED, 
			expr_sql2 CLIPPED, 
  	      "   AND r11_compania = r10_compania ",
		  "   AND r11_bodega = '", rm_par.bodega, "'",
		  "   AND r11_item    = r10_codigo ",
		    expr_stock CLIPPED

PREPARE cit FROM query
DECLARE q_cit CURSOR FOR cit
LET i = 0
FOREACH q_cit INTO te_codigo, te_nombre, te_precio, te_stock, costo
	LET i = i + 1
	IF i > vm_max_rows THEN
		EXIT FOREACH
	END IF
	IF te_stock IS NULL THEN
		LET te_stock = 0
	END IF

	LET te_stock_disp = fl_lee_stock_disponible_rep(vg_codcia, vg_codloc, 
													te_codigo, 'R') 
	IF te_stock_disp < 0 THEN
		LET te_stock_disp = 0
	END IF

	LET te_stock_tbd = fl_lee_stock_total_localidades_rep(vg_codcia,  
													te_codigo, 'R') 

	IF te_precio < costo THEN
		LET te_precio = te_precio * (-1)
	END IF
	INSERT INTO temp_item VALUES (te_codigo, te_nombre, te_precio,
								  te_stock, te_stock_disp, te_stock_tbd)
END FOREACH
SELECT COUNT(*) INTO i FROM temp_item
IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET int_flag = 1
	RETURN
END IF
ERROR ' ' ATTRIBUTE(NORMAL)

END FUNCTION
 


FUNCTION muestra_consulta()
DEFINE i		SMALLINT
DEFINE j		SMALLINT
DEFINE query		VARCHAR(300)
DEFINE num_rows		INTEGER
DEFINE comando		VARCHAR(1000)
DEFINE sustituye	SMALLINT
DEFINE r_r10		RECORD LIKE rept010.*

FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET vm_columna_1 = 5
LET vm_columna_2 = 1
LET rm_orden[vm_columna_1] = 'DESC'
LET rm_orden[vm_columna_2] = 'ASC'
WHILE TRUE
	LET query = 'SELECT * FROM temp_item ',
			'ORDER BY ',
			vm_columna_1, ' ', rm_orden[vm_columna_1], ',', 
			vm_columna_2, ' ', rm_orden[vm_columna_2] 
	PREPARE crep FROM query
	DECLARE q_crep CURSOR FOR crep 
	LET i = 1
	FOREACH q_crep INTO rm_item[i].*
		LET i = i + 1
		IF i > vm_max_rows THEN
			EXIT FOREACH
		END IF
	END FOREACH
	FREE q_crep
	LET num_rows = i - 1
	CALL set_count(num_rows)
	DISPLAY ARRAY rm_item TO rm_item.*
		BEFORE ROW
			LET i = arr_curr()
			CALL fl_lee_item(vg_codcia, rm_item[i].r10_codigo)
				RETURNING r_r10.*
			DISPLAY r_r10.r10_filtro TO filtro
			IF r_r10.r10_estado = 'S' THEN
				CALL dialog.keysetlabel('F5', 'Sustituido Por')
			ELSE
				CALL dialog.keysetlabel('F5', '')
			END IF			
			
			SELECT COUNT(r14_item_ant) INTO sustituye FROM rept014
				WHERE r14_compania = vg_codcia
				  AND r14_item_nue = r_r10.r10_codigo
			IF sustituye > 0 THEN
				CALL dialog.keysetlabel('F6', 'Sustituye a')
			ELSE
				CALL dialog.keysetlabel('F6', '')
			END IF			
			CALL dialog.keysetlabel('F7', 'Ubicacion')
			CALL dialog.keysetlabel('F8', 'Pedidos')
			CALL dialog.keysetlabel('F9', 'Reservas')
			CALL dialog.keysetlabel('F10', 'Estadisticas')

			MESSAGE i, ' de ', num_rows
		BEFORE DISPLAY
			CALL dialog.keysetlabel("ACCEPT","")
		AFTER DISPLAY
			CONTINUE DISPLAY
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			CALL sustituido(r_r10.*)
			LET int_flag = 0
		ON KEY(F6)
			CALL sustituye(r_r10.*)
			LET int_flag = 0
		ON KEY(F7)
			CALL control_ver_ubicacion(r_r10.r10_codigo, 
						   r_r10.r10_nombre)
			LET int_flag = 0
		ON KEY(F8)
			CALL control_pedidos(rm_item[i].r10_codigo,
					     r_r10.r10_nombre)
			LET int_flag = 0
		ON KEY(F9)
			CALL fl_mostrar_reservas_items(vg_codcia, vg_codloc, 
										   rm_item[i].r10_codigo)
			LET int_flag = 0
		ON KEY(F10)
			CALL fl_mostrar_estadisticas_items(vg_codcia, vg_codloc, 
										   rm_item[i].r10_codigo)
			LET int_flag = 0
		ON KEY(F15)
			LET i = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET i = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET i = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET i = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET i = 5
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET i = 6
			LET int_flag = 2
			EXIT DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF i <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1 = i 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE
                                                                                
END FUNCTION



FUNCTION control_pedidos(item, nombre)
DEFINE item		LIKE rept010.r10_codigo
DEFINE nombre		LIKE rept010.r10_nombre

DEFINE i		SMALLINT

DEFINE r_pedido ARRAY[100] OF RECORD
	pedido		LIKE rept016.r16_pedido, 
	proveedor	LIKE rept016.r16_proveedor, 
	fecha_lleg	LIKE rept016.r16_fec_llegada, 
	cantidad	LIKE rept017.r17_cantped
END RECORD

OPEN WINDOW w_300_4 AT 8,34 WITH 13 ROWS, 45 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
OPEN FORM f_300_4 FROM '../forms/repf300_4'
DISPLAY FORM f_300_4

DISPLAY 'Pedido' TO bt_pedido
DISPLAY 'Proveedor' TO bt_proveedor
DISPLAY 'Fec. Lleg.' TO bt_fecha
DISPLAY 'Cant.' TO bt_cantidad

DISPLAY item TO item
DISPLAY nombre TO n_item

DECLARE q_pedido CURSOR FOR
	SELECT r17_pedido, r16_proveedor, r16_fec_llegada, r17_cantped
      FROM rept016, rept017
	 WHERE r17_compania  = vg_codcia
	   AND r17_item      = item
	   AND r17_estado    NOT IN ('A', 'P', 'N')
	   AND r16_compania  = r17_compania
	   AND r16_localidad = r17_localidad
	   AND r16_pedido    = r17_pedido
	   AND r16_estado    NOT IN ('N')

LET i = 1
FOREACH q_pedido INTO r_pedido[i].*
	LET i = i + 1
	IF i > 100 THEN
		EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1
IF i = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_300_4
        RETURN
END IF

LET int_flag = 0
CALL set_count(i)
DISPLAY ARRAY r_pedido TO ra_pedido.*
	ON KEY(INTERRUPT)
		EXIT DISPLAY
	BEFORE DISPLAY
		CALL dialog.keysetlabel('ACCEPT', '')
	AFTER DISPLAY
		CONTINUE DISPLAY
END DISPLAY

CLOSE WINDOW w_300_4

END FUNCTION



FUNCTION sustituye(r_item)

DEFINE i		SMALLINT
DEFINE max_items	SMALLINT
DEFINE r_item		RECORD LIKE rept010.*
DEFINE r_items ARRAY[100] OF RECORD 
	item		LIKE rept010.r10_codigo, 
	nombre		LIKE rept010.r10_nombre, 	
	fecha		DATE
END RECORD

LET max_items = 100

OPEN WINDOW w_300_2 AT 9,8 WITH 12 ROWS, 68 COLUMNS 
	ATTRIBUTE(FORM LINE FIRST + 1, BORDER, MESSAGE LINE LAST - 1)
OPEN FORM f_300_2 FROM '../forms/repf300_2'
DISPLAY FORM f_300_2

DISPLAY fl_justifica_titulo('D', 'Sustituto', 10) TO lbl_item
DISPLAY 'Sustituidos' TO bt_item
DISPLAY 'Fecha'       TO bt_fecha

DISPLAY r_item.r10_codigo TO item1
DISPLAY r_item.r10_nombre TO n_item1

-- Cursor que obtiene los items sustituidos por este item,
-- es decir, a quienes sustituye
DECLARE q_sustituidos2 CURSOR FOR 
	SELECT r14_item_ant, r10_nombre, DATE(r14_fecing) 
		FROM rept014, rept010
		WHERE r14_compania = vg_codcia
		  AND r14_item_nue = r_item.r10_codigo
		  AND r10_compania = r14_compania 
		  AND r10_codigo   = r14_item_ant

LET i = 1
FOREACH q_sustituidos2 INTO r_items[i].*
	LET i = i + 1
	IF i > max_items THEN
		EXIT FOREACH
	END IF
END FOREACH

LET i = i - 1
LET int_flag = 0
CALL set_count(i)
DISPLAY ARRAY r_items TO ra_items.*

CLOSE WINDOW w_300_2

END FUNCTION



FUNCTION sustituido(r_item)

DEFINE i		SMALLINT
DEFINE max_items	SMALLINT
DEFINE r_item		RECORD LIKE rept010.*
DEFINE r_items ARRAY[100] OF RECORD
	item		LIKE rept010.r10_codigo, 
	nombre		LIKE rept010.r10_nombre, 	
	fecha		DATE
END RECORD

LET max_items = 100

OPEN WINDOW w_300_2 AT 9,8 WITH 12 ROWS, 68 COLUMNS 
	ATTRIBUTE(FORM LINE FIRST + 1, BORDER, MESSAGE LINE LAST - 1)
OPEN FORM f_300_2 FROM '../forms/repf300_2'
DISPLAY FORM f_300_2

DISPLAY fl_justifica_titulo('D', 'Sustituido', 10) TO lbl_item
DISPLAY 'Sustituto' TO bt_item
DISPLAY 'Fecha'     TO bt_fecha

DISPLAY r_item.r10_codigo TO item1
DISPLAY r_item.r10_nombre TO n_item1

-- Cursor que obtiene los items sustitutos para este item,
-- es decir, por quienes fue sustituido
DECLARE q_sustitutos2 CURSOR FOR 
	SELECT r14_item_nue, r10_nombre, DATE(r14_fecing) FROM rept014, rept010
		WHERE r14_compania = vg_codcia
		  AND r14_item_ant = r_item.r10_codigo
		  AND r10_compania = r14_compania 
		  AND r10_codigo   = r14_item_nue
		  
LET i = 1
FOREACH q_sustitutos2 INTO r_items[i].*
	LET i = i + 1
	IF i > max_items THEN
		EXIT FOREACH
	END IF
END FOREACH

LET i = i - 1

LET int_flag = 0
CALL set_count(i)
DISPLAY ARRAY r_items TO ra_items[i].*

CLOSE WINDOW w_300_2

END FUNCTION



FUNCTION control_ver_ubicacion(item, nombre)
DEFINE item 		LIKE rept010.r10_codigo
DEFINE nombre 		LIKE rept010.r10_nombre
DEFINE i 		SMALLINT
DEFINE r_detalle	ARRAY[100] OF RECORD
	bodega		LIKE rept011.r11_bodega,
	n_bodega	LIKE rept002.r02_nombre,
	stock		LIKE rept011.r11_stock_act,
	ubicacion	LIKE rept011.r11_ubicacion	
	END RECORD

OPEN WINDOW w_300_3 AT 8,34 WITH 12 ROWS, 45 COLUMNS 
	ATTRIBUTE(FORM LINE FIRST , BORDER, MESSAGE LINE LAST - 1)
OPEN FORM f_300_3 FROM '../forms/repf300_3'
DISPLAY FORM f_300_3

DISPLAY 'Bodega'    TO bt_bodega
DISPLAY 'Stock'     TO bt_stock
DISPLAY 'Ubicación' TO bt_ubicacion

DISPLAY item TO item
DISPLAY nombre TO n_item

DECLARE q_ubicacion CURSOR FOR
	SELECT r11_bodega, r02_nombre, r11_stock_act, r11_ubicacion
		 FROM rept011, rept002
		WHERE r11_compania = vg_codcia
		  AND r11_item     = item
		  AND r11_compania = r02_compania
		  AND r11_bodega   = r02_codigo		
LET i = 1
FOREACH q_ubicacion INTO r_detalle[i].*
	LET i = i + 1
	IF i > 100 THEN
		EXIT FOREACH
	END IF
END FOREACH
LET i = i - 1

CALL set_count(i)
DISPLAY ARRAY r_detalle TO r_detalle[i].*

CLOSE WINDOW w_300_3

END FUNCTION



FUNCTION ventas_perdidas(item, bodega)
DEFINE item		LIKE rept010.r10_codigo
DEFINE bodega		LIKE rept002.r02_codigo
DEFINE comando 		CHAR(500)

	LET comando = 'fglrun repp201 ', vg_base, ' RE ', 
        	       vg_codcia, ' ', vg_codloc, ' ', 
        	       item CLIPPED, ' ', bodega  

	RUN comando

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
