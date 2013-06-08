------------------------------------------------------------------------------
-- Titulo           : repp310.4gl - Consulta Análisis Movimiento Items
-- Elaboracion      : 30-ago-2001
-- Autor            : YEC
-- Formato Ejecucion: fglrun repp310.4gl base_datos modulo compañía
-- Ultima Correccion: 
-- Motivo Correccion: 
------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_campo_orden	SMALLINT
DEFINE vm_tipo_orden	CHAR(4)
DEFINE vm_size_arr	INTEGER
DEFINE rm_cons ARRAY[3001] OF RECORD
	cod_bod		LIKE rept002.r02_codigo,
	item		LIKE rept010.r10_codigo,
	descri_item	LIKE rept010.r10_nombre,
	ult_vta		DATE,
	unidad		DECIMAL (8,2),
	valor		DECIMAL(14,2)
	END RECORD
DEFINE rm_par RECORD
	fec_ini		DATE,
	fec_fin		DATE,
	moneda		LIKE gent013.g13_moneda,
	tit_mon		VARCHAR(30),
	bodega		LIKE rept002.r02_codigo,
	tit_bod		VARCHAR(30),
	linea		LIKE rept003.r03_codigo,
	tit_lin		VARCHAR(30),
	tipo_item	LIKE rept006.r06_codigo,
	tit_tipo_item	VARCHAR(30),
	indrot		LIKE rept004.r04_rotacion,
	tit_indrot	VARCHAR(30)
	END RECORD
DEFINE vm_max_rows	SMALLINT
DEFINE rm_color ARRAY[10] OF VARCHAR(10)

MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/errores')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 3 THEN          -- Validar # parámetros correcto
	--CALL fgl_winmessage(vg_producto,'Número de parámetros incorrecto.','stop')
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_proceso = 'repp310'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE r		RECORD LIKE gent000.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT

INITIALIZE rm_par.* TO NULL
CALL fl_lee_configuracion_facturacion() RETURNING r.*
LET rm_par.moneda = r.g00_moneda_base
CALL fl_lee_moneda(rm_par.moneda) RETURNING r_mon.* 
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 21
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_imp AT row_ini, 2 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE lin_menu,
		  MESSAGE LINE LAST - 1, BORDER) 
IF vg_gui = 1 THEN
	OPEN FORM f_cons FROM '../forms/repf310_1'
ELSE
	OPEN FORM f_cons FROM '../forms/repf310_1c'
END IF
DISPLAY FORM f_cons
LET rm_par.tit_mon = r_mon.g13_nombre
DISPLAY BY NAME rm_par.tit_mon
LET vm_max_rows = 3000
WHILE TRUE
	CALL lee_parametros()
	IF int_flag THEN
		RETURN
	END IF
	CALL muestra_consulta()
END WHILE

END FUNCTION



FUNCTION lee_parametros()
DEFINE resp		CHAR(3)
DEFINE mon_aux		LIKE gent013.g13_moneda
DEFINE bod_aux		LIKE rept002.r02_codigo
DEFINE lin_aux		LIKE rept003.r03_codigo
DEFINE ind_aux		LIKE rept004.r04_rotacion
DEFINE cod_aux		LIKE rept006.r06_codigo
DEFINE num_dec		SMALLINT
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_bod		RECORD LIKE rept002.*
DEFINE r_lin		RECORD LIKE rept003.*
DEFINE r_tip		RECORD LIKE rept006.*
DEFINE r_ind		RECORD LIKE rept004.*

--#DISPLAY 'Bd'          TO tit_col1
--#DISPLAY 'Item'        TO tit_col2
--#DISPLAY 'Descripción' TO tit_col3
--#DISPLAY 'Ult.Vta.'    TO tit_col4
--#DISPLAY 'Unid.'       TO tit_col5
--#DISPLAY 'Valor Venta' TO tit_col6
LET int_flag = 0
INPUT BY NAME rm_par.* WITHOUT DEFAULTS
	ON KEY(INTERRUPT)
		IF NOT FIELD_TOUCHED(rm_par.fec_ini, rm_par.fec_fin,
				     rm_par.moneda, rm_par.bodega,
				     rm_par.linea, rm_par.tipo_item,
				     rm_par.indrot) THEN
			RETURN
		END IF
		LET INT_FLAG = 0
		--CALL FGL_WINQUESTION(vg_producto,'Desea salir de la consulta','No','Yes|No|Cancel','question',1)
		CALL fl_hacer_pregunta('Desea salir de la consulta','No')
			RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(moneda) THEN
			CALL fl_ayuda_monedas() RETURNING mon_aux,rm_par.tit_mon,
							  num_dec
			IF mon_aux IS NOT NULL THEN
				LET rm_par.moneda = mon_aux
				DISPLAY BY NAME rm_par.moneda, rm_par.tit_mon
			END IF
		END IF
		IF INFIELD(bodega) THEN
			CALL fl_ayuda_bodegas_rep(vg_codcia, vg_codloc, 'T', 'T', 'A', 'T', '2')
				RETURNING bod_aux,rm_par.tit_bod
			IF bod_aux IS NOT NULL THEN
				LET rm_par.bodega = bod_aux
				DISPLAY BY NAME rm_par.bodega, rm_par.tit_bod
			END IF
		END IF
		IF INFIELD(linea) THEN
			CALL fl_ayuda_lineas_rep(vg_codcia) RETURNING lin_aux,rm_par.tit_lin
			IF lin_aux IS NOT NULL THEN
				LET rm_par.linea = lin_aux
				DISPLAY BY NAME rm_par.linea, rm_par.tit_lin
			END IF
		END IF
		IF INFIELD(indrot) THEN
			CALL fl_ayuda_clases(vg_codcia) RETURNING ind_aux,rm_par.tit_indrot
			IF ind_aux IS NOT NULL THEN
				LET rm_par.indrot = ind_aux
				DISPLAY BY NAME rm_par.indrot, rm_par.tit_indrot
			END IF
		END IF
		IF INFIELD(tipo_item) THEN
			CALL fl_ayuda_tipo_item() RETURNING cod_aux,rm_par.tit_tipo_item
			IF cod_aux IS NOT NULL THEN
				LET rm_par.tipo_item = cod_aux
				DISPLAY BY NAME rm_par.tipo_item, rm_par.tit_tipo_item
			END IF
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD moneda
		IF rm_par.moneda IS NOT NULL THEN
			CALL fl_lee_moneda(rm_par.moneda) RETURNING r_mon.*
			IF r_mon.g13_moneda IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Moneda no existe.','exclamation')
				CALL fl_mostrar_mensaje('Moneda no existe.','exclamation')
				NEXT FIELD moneda
			END IF
			LET rm_par.tit_mon = r_mon.g13_nombre
			DISPLAY BY NAME rm_par.tit_mon
		ELSE
			LET rm_par.tit_mon = NULL
			CLEAR tit_mon
		END IF
	AFTER FIELD bodega
		IF rm_par.bodega IS NOT NULL THEN
			CALL fl_lee_bodega_rep(vg_codcia, rm_par.bodega) RETURNING r_bod.*
			IF r_bod.r02_codigo IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Bodega no existe.','exclamation')
				CALL fl_mostrar_mensaje('Bodega no existe.','exclamation')
				NEXT FIELD bodega
			END IF
			LET rm_par.tit_bod = r_bod.r02_nombre
			DISPLAY BY NAME rm_par.tit_bod
		ELSE
			LET rm_par.tit_bod = NULL
			CLEAR tit_bod
		END IF
	AFTER FIELD linea
		IF rm_par.linea IS NOT NULL THEN
			CALL fl_lee_linea_rep(vg_codcia, rm_par.linea) RETURNING r_lin.*
			IF r_lin.r03_codigo IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Línea no existe.','exclamation')
				CALL fl_mostrar_mensaje('Línea no existe.','exclamation')
				NEXT FIELD linea
			END IF
			LET rm_par.tit_lin = r_lin.r03_nombre
			DISPLAY BY NAME rm_par.tit_lin
		ELSE
			LET rm_par.tit_lin = NULL
			CLEAR tit_lin
		END IF
	AFTER FIELD tipo_item
		IF rm_par.tipo_item IS NOT NULL THEN
			CALL fl_lee_tipo_item(rm_par.tipo_item) RETURNING r_tip.*
			IF r_tip.r06_codigo IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Tipo de item no existe.','exclamation')
				CALL fl_mostrar_mensaje('Tipo de item no existe.','exclamation')
				NEXT FIELD tipo_item
			END IF
			LET rm_par.tit_tipo_item = r_tip.r06_nombre
			DISPLAY BY NAME rm_par.tit_tipo_item
		ELSE
			LET rm_par.tit_tipo_item = NULL
			CLEAR tit_tipo_item
		END IF
	AFTER FIELD indrot
		IF rm_par.indrot IS NOT NULL THEN
			CALL fl_lee_indice_rotacion(vg_codcia, rm_par.indrot) RETURNING r_ind.*
			IF r_ind.r04_rotacion IS NULL THEN
				--CALL fgl_winmessage(vg_producto,'Indice de rotación no existe.', 'exclamation')
				CALL fl_mostrar_mensaje('Indice de rotación no existe.', 'exclamation')
				NEXT FIELD indrot
			END IF
			LET rm_par.tit_indrot = r_ind.r04_nombre
			DISPLAY BY NAME rm_par.tit_indrot
		ELSE
			LET rm_par.tit_indrot = NULL
			CLEAR tit_indrot
		END IF
	AFTER INPUT 
		IF rm_par.fec_ini > rm_par.fec_fin THEN
			--CALL fgl_winmessage(vg_producto,'Fecha final debe ser mayor a la inicial.','exclamation')
			CALL fl_mostrar_mensaje('Fecha final debe ser mayor a la inicial.','exclamation')
			NEXT FIELD fec_ini
		END IF
			
END INPUT

END FUNCTION



FUNCTION muestra_consulta()
DEFINE num_rows		SMALLINT
DEFINE expr1, expr2	VARCHAR(90)
DEFINE expr3, expr4	VARCHAR(90)
DEFINE expr5, expr6	VARCHAR(90)
DEFINE orden		VARCHAR(20)
DEFINE query		CHAR(500)
DEFINE i, nuevo_DISPLAY	SMALLINT
DEFINE pos_pantalla  	SMALLINT
DEFINE pos_arreglo   	SMALLINT
DEFINE item_aux         LIKE rept010.r10_codigo

ERROR "Generando consulta . . . espere por favor." ATTRIBUTE(NORMAL)
LET vm_campo_orden = 6
LET vm_tipo_orden  = 'ASC'
CREATE TEMP TABLE temp_item
	(te_cod_bod	CHAR(2),
	te_item		VARCHAR(15),
	te_descri_item	VARCHAR(40),
	te_ult_vta	DATE,
	te_unidad	DECIMAL (8,2),
	te_valor	DECIMAL(14,2))
LET expr1 = 'r12_compania = ', vg_codcia, ' AND r12_fecha BETWEEN ? AND ? '
LET expr2 = '1 = 1'
LET expr3 = '1 = 1'
LET expr4 = '1 = 1'
LET expr5 = '1 = 1'
LET expr6 = '1 = 1'
IF rm_par.moneda IS NOT NULL THEN
	LET expr2 = "r12_moneda = '", rm_par.moneda, "'"
END IF
IF rm_par.bodega IS NOT NULL THEN
	LET expr3 = "r12_bodega = '", rm_par.bodega, "'"
END IF
IF rm_par.linea IS NOT NULL THEN
	LET expr4 = "r10_linea = '", rm_par.linea CLIPPED, "'"
END IF
IF rm_par.tipo_item IS NOT NULL THEN
	LET expr5 = "r10_tipo = ", rm_par.tipo_item
END IF
IF rm_par.indrot IS NOT NULL THEN
	LET expr6 = "r10_rotacion = '", rm_par.indrot CLIPPED, "'"
END IF
LET query = 'SELECT r12_bodega, r12_item, r10_nombre, ',
		' MAX(r12_fecha), ',
		' SUM(r12_uni_venta - r12_uni_dev), ',
		' SUM(r12_val_venta - r12_val_dev) ',
		' FROM rept012, rept010 ',
		' WHERE ', expr1 CLIPPED,
		' AND ', expr2 CLIPPED,
		' AND ', expr3 CLIPPED,
		' AND ', expr4 CLIPPED,
		' AND ', expr5 CLIPPED,
		' AND ', expr6 CLIPPED,
		' AND r12_compania = r10_compania AND r12_item = r10_codigo ',
		' GROUP BY 1, 2, 3'
PREPARE cons FROM query
DECLARE q_cons CURSOR FOR cons
OPEN q_cons USING rm_par.fec_ini, rm_par.fec_fin 
LET num_rows = 1
WHILE TRUE
	FETCH q_cons INTO rm_cons[num_rows].*
	IF status = NOTFOUND THEN
		EXIT WHILE
	END IF
	INSERT INTO temp_item VALUES (rm_cons[num_rows].*)
	LET num_rows = num_rows + 1
	IF num_rows = vm_max_rows + 1 THEN
		EXIT WHILE
	END IF
END WHILE
CLOSE q_cons
LET num_rows = num_rows - 1
IF num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	DROP TABLE temp_item
	RETURN
END IF
LET nuevo_DISPLAY = 0
ERROR ' '
WHILE TRUE
	LET i = 0
	IF vm_tipo_orden = 'ASC' THEN
		LET vm_tipo_orden = 'DESC'
	ELSE
		LET vm_tipo_orden = 'ASC'
	END IF
	LET orden = 'ORDER BY ', vm_campo_orden, ' ', vm_tipo_orden
	LET query = 'SELECT * FROM temp_item ', orden
	PREPARE tit FROM query
	DECLARE q_tit CURSOR FOR tit
	LET i = 1
	FOREACH q_tit INTO rm_cons[i].*
		LET i = i + 1
	END FOREACH
	IF nuevo_DISPLAY THEN
		IF num_rows > vm_size_arr THEN
			FOR i = 1 TO num_rows
				IF rm_cons[i].item = item_aux THEN
					LET pos_arreglo = i
					EXIT FOR
				END IF
			END FOR
		END IF
	END IF
	CALL set_count(num_rows)
	DISPLAY ARRAY rm_cons TO rm_cons.*
		--#BEFORE DISPLAY 
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#AFTER DISPLAY 
			--#CONTINUE DISPLAY
		--#BEFORE ROW
			--#IF nuevo_DISPLAY THEN
				--#CALL dialog.setcurrline(pos_pantalla,pos_arreglo)
				--#LET nuevo_DISPLAY = 0
			--#END IF
			--#LET i = arr_curr()
			--#MESSAGE i, ' de ', num_rows
		ON KEY(INTERRUPT)
			EXIT DISPLAY
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1() 
		ON KEY(F5)
			LET i = arr_curr()
			CALL muestra_movimientos_item(rm_cons[i].item, 
				rm_cons[i].cod_bod, rm_par.moneda, rm_par.fec_ini,
				rm_par.fec_fin)
		--#ON KEY(F6)
			--#CALL muestra_grafico_barras()
		ON KEY(F15)
			LET vm_campo_orden = 1
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET vm_campo_orden = 2
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET vm_campo_orden = 3
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET vm_campo_orden = 4
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET vm_campo_orden = 5
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET vm_campo_orden = 6
			LET int_flag = 2
			EXIT DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF int_flag = 2 THEN
		LET nuevo_DISPLAY = 1
		LET pos_pantalla  = scr_line()
		LET pos_arreglo   = arr_curr()
		LET item_aux      = rm_cons[pos_arreglo].item
	END IF
END WHILE
DROP TABLE temp_item
FOR i = 1 TO vm_size_arr 
	CLEAR rm_cons[i].*
END FOR

END FUNCTION



FUNCTION muestra_movimientos_item(item, bodega, moneda, fec_ini, fec_fin)
DEFINE item		LIKE rept010.r10_codigo
DEFINE bodega, bod	LIKE rept002.r02_codigo
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE fec_ini, fec_fin	DATE
DEFINE r_item		RECORD LIKE rept010.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_bod		RECORD LIKE rept002.*
DEFINE r_trn		RECORD LIKE rept019.*
DEFINE num_rows, i	SMALLINT
DEFINE max_rows		SMALLINT
DEFINE tot_uni		DECIMAL (8,2)
DEFINE tot_val		DECIMAL(14,2)
DEFINE comando		VARCHAR(140)
DEFINE columna_act	SMALLINT
DEFINE columna_ant	SMALLINT
DEFINE orden_act	CHAR(4)
DEFINE orden_ant	CHAR(4)
DEFINE orden		VARCHAR(100)
DEFINE query		CHAR(300)
DEFINE rt		RECORD LIKE gent021.*
DEFINE r_mov ARRAY[800] OF RECORD
	fecha		DATE,
	tipo		LIKE rept019.r19_cod_tran,
	numero		LIKE rept019.r19_num_tran,
	cliente		VARCHAR(30),
	unidades	DECIMAL (8,2),
	valor		DECIMAL(14,2)
	END RECORD
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows2 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE run_prog		CHAR(10)

CREATE TEMP TABLE temp_mov
	(te_fecha	DATETIME YEAR TO SECOND,
	 te_tipo	CHAR(2),
	 te_numero	INTEGER,
	 te_cliente	VARCHAR(30),
	 te_unidades	DECIMAL (8,2),
	 te_valor	DECIMAL(14,2))
LET max_rows = 800
LET lin_menu = 0
LET row_ini  = 3
LET num_rows2 = 21
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows2 = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_mov AT row_ini, 2 WITH num_rows2 ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
IF vg_gui = 1 THEN
	OPEN FORM f_repf310_2 FROM "../forms/repf310_2"
ELSE
	OPEN FORM f_repf310_2 FROM "../forms/repf310_2c"
END IF
DISPLAY FORM f_repf310_2
ERROR "Generando consulta . . . espere por favor." ATTRIBUTE(NORMAL)
CALL fl_lee_item(vg_codcia, item) RETURNING r_item.*
CALL fl_lee_moneda(moneda) RETURNING r_mon.*
CALL fl_lee_bodega_rep(vg_codcia, bodega) RETURNING r_bod.*
--#DISPLAY 'Fecha'       TO tit_col1
--#DISPLAY 'Tp'          TO tit_col2
--#DISPLAY '# Documento' TO tit_col3
--#DISPLAY 'Cliente'     TO tit_col4
--#DISPLAY 'Uni.'        TO tit_col5
--#DISPLAY 'V a l o r'   TO tit_col6
DISPLAY BY NAME item, fec_ini, fec_fin
DISPLAY r_item.r10_nombre TO name_item
DISPLAY r_mon.g13_nombre TO tit_mon
DISPLAY r_bod.r02_nombre TO tit_bod
DECLARE q_det CURSOR FOR SELECT r20_fecing, r20_cod_tran, r20_num_tran,
	'', r20_cant_ven, (r20_precio * r20_cant_ven) - r20_val_descto, 
	r20_bodega
	FROM rept020
	WHERE r20_compania = vg_codcia AND r20_localidad = vg_codloc AND 
	      r20_item = item AND
	      r20_fecing BETWEEN EXTEND(fec_ini, YEAR TO SECOND) AND
	      EXTEND(fec_fin, YEAR TO SECOND) + 23 UNITS HOUR + 59 UNITS MINUTE
					      + 59 UNITS SECOND
	ORDER BY r20_fecing
LET num_rows = 1
OPEN q_det 
LET tot_uni = 0
LET tot_val = 0
WHILE TRUE
	FETCH q_det INTO r_mov[num_rows].*, bod
	IF status = NOTFOUND THEN
		EXIT WHILE
	END IF
	CALL fl_lee_cod_transaccion(r_mov[num_rows].tipo) RETURNING rt.*
	IF rt.g21_act_estad <> 'S' THEN
		CONTINUE WHILE
	END IF
	IF bod <> bodega THEN
		CONTINUE WHILE
	END IF
	CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc, 
		r_mov[num_rows].tipo, r_mov[num_rows].numero)
		RETURNING r_trn.*
	IF r_trn.r19_moneda <> moneda THEN
		CONTINUE WHILE
	END IF
	IF rt.g21_tipo = 'I' THEN
		LET r_mov[num_rows].unidades = r_mov[num_rows].unidades * -1
		LET r_mov[num_rows].valor    = r_mov[num_rows].valor    * -1
	END IF	
	LET r_mov[num_rows].cliente = r_trn.r19_nomcli
	INSERT INTO temp_mov VALUES (r_mov[num_rows].*)
	LET tot_uni = tot_uni + r_mov[num_rows].unidades
	LET tot_val = tot_val + r_mov[num_rows].valor
	LET num_rows = num_rows + 1
	IF num_rows = max_rows + 1 THEN
		EXIT WHILE
	END IF
END WHILE
CLOSE q_det
LET num_rows = num_rows - 1
IF num_rows = 0 THEN
	DROP TABLE temp_mov
	CALL fl_mensaje_consulta_sin_registros()
	CLOSE WINDOW w_mov
	RETURN
END IF
DISPLAY BY NAME tot_uni, tot_val
LET orden_act = 'DESC'
LET orden_ant = 'ASC'
LET columna_act = 1
LET columna_ant = 4
{-- ESTO PARA LLAMAR AL PROGRAMA SEGÚN SEA EL AMBIENTE --}
LET run_prog = 'fglrun '
IF vg_gui = 0 THEN
	LET run_prog = 'fglgo '
END IF
{--- ---}
ERROR ' '
WHILE TRUE
	IF orden_act = 'ASC' THEN
		LET orden_act = 'DESC'
	ELSE
		LET orden_act = 'ASC'
	END IF
	LET orden = columna_act, ' ', orden_act, ', ', columna_ant, ' ',
		    orden_ant 
	LET query = 'SELECT * FROM temp_mov ORDER BY ', orden CLIPPED
	PREPARE mt FROM query
	DECLARE q_mt CURSOR FOR mt
	LET  i = 1
	FOREACH q_mt INTO r_mov[i].*
		LET i = i + 1
	END FOREACH 
	CALL set_count(num_rows)
	LET int_flag = 0
	DISPLAY ARRAY r_mov TO r_mov.*
		--#BEFORE DISPLAY 
			--#CALL dialog.keysetlabel("ACCEPT","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		--#AFTER DISPLAY 
			--#CONTINUE DISPLAY
		--#BEFORE ROW
			--#LET i = arr_curr()
			--#MESSAGE i, ' de ', num_rows
		ON KEY(INTERRUPT)
			EXIT DISPLAY
        	ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_2() 
		ON KEY(F5)
			LET i = arr_curr()
			LET comando = run_prog, 'repp308 ' || vg_base ||
				' RE ' || vg_codcia || ' ' ||
			       	vg_codloc || ' ' || r_mov[i].tipo || ' ' ||
			       	r_mov[i].numero
			RUN comando
		ON KEY(F6)
			LET comando = run_prog, 'repp108 ', vg_base, ' RE ', 
			               vg_codcia, ' ', vg_codloc, ' "',
			               item CLIPPED || '"'
		        RUN comando
		ON KEY(F15)
			LET columna_ant = columna_act
			LET columna_act = 1 
			LET orden_ant   = orden_act
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F16)
			LET columna_ant = columna_act
			LET columna_act = 2 
			LET orden_ant   = orden_act
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F17)
			LET columna_ant = columna_act
			LET columna_act = 3 
			LET orden_ant   = orden_act
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F18)
			LET columna_ant = columna_act
			LET columna_act = 4 
			LET orden_ant   = orden_act
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F19)
			LET columna_ant = columna_act
			LET columna_act = 5 
			LET orden_ant   = orden_act
			LET int_flag = 2
			EXIT DISPLAY
		ON KEY(F20)
			LET columna_ant = columna_act
			LET columna_act = 6 
			LET orden_ant   = orden_act
			LET int_flag = 2
			EXIT DISPLAY
	END DISPLAY
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
END WHILE
CLOSE WINDOW w_mov
DROP TABLE temp_mov
LET int_flag = 0

END FUNCTION



--#FUNCTION muestra_grafico_barras()
--#DEFINE inicio_x		SMALLINT
--#DEFINE inicio_y		SMALLINT
--#DEFINE maximo_x		SMALLINT
--#DEFINE maximo_y		SMALLINT
--#DEFINE factor_y		DECIMAL(16,6)
--#DEFINE max_barras	SMALLINT
--#DEFINE ancho_barra	SMALLINT
--#DEFINE num_barras	SMALLINT

--#DEFINE inicio2_x	SMALLINT
--#DEFINE inicio2_y	SMALLINT

--#DEFINE max_elementos	SMALLINT
--#DEFINE max_valor	DECIMAL(14,2)
--#DEFINE filas_procesadas	SMALLINT

--#DEFINE bodega		LIKE rept002.r02_codigo
--#DEFINE item		LIKE rept010.r10_codigo
--#DEFINE descri		VARCHAR(35)
--#DEFINE valor		DECIMAL(14,2)
--#DEFINE key_n		SMALLINT
--#DEFINE key_c		CHAR(3)
--#DEFINE key_f30		SMALLINT
--#DEFINE cant_val		CHAR(1)
--#DEFINE query		VARCHAR(200)
--#DEFINE i, indice	SMALLINT
--#DEFINE tecla		CHAR(1)
--#DEFINE titulo, tit_pos	CHAR(75)
--#DEFINE tit_val		CHAR(16)
--#DEFINE r_obj ARRAY[8] OF RECORD
	--#bodega		LIKE rept002.r02_codigo,
	--#item		LIKE rept010.r10_codigo,
	--#nombre		LIKE rept010.r10_nombre,
	--#valor		DECIMAL(14,2),
	--#id_obj_rec1	SMALLINT,
	--#id_obj_rec2	SMALLINT
	--#END RECORD

--#CALL carga_colores()
--#LET max_barras = 8
--#LET inicio_x   = 50
--#LET inicio_y   = 80
--#LET maximo_x   = 500
--#LET maximo_y   = 750
--#LET inicio2_x  = 910

--#LET cant_val = 'V'
--#WHILE TRUE
	--#LET titulo = 'POR ITEM DURANTE EL PERIODO: ', 
		      --#rm_par.fec_ini USING 'dd-mm-yyyy', ' - ', 
		      --#rm_par.fec_fin USING 'dd-mm-yyyy'
	--#IF cant_val = 'C' THEN
		--#LET titulo = 'UNIDADES VENDIDAS ', titulo CLIPPED
		--#SELECT COUNT(*), MAX(te_unidad) INTO max_elementos, max_valor
			--#FROM temp_item
		--#LET query = 'SELECT te_cod_bod, te_item, te_descri_item, ',
				--#'te_unidad FROM temp_item ',
				--#'ORDER BY 4 DESC'
	--#ELSE
		--#LET titulo = '	VALORES VENDIDOS ', titulo CLIPPED
		--#SELECT COUNT(*), MAX(te_valor) INTO max_elementos, max_valor
			--#FROM temp_item
		--#LET query = 'SELECT te_cod_bod, te_item, te_descri_item, ',
				--#'te_valor FROM temp_item ',
				--#'ORDER BY 4 DESC'
	--#END IF
	--#PREPARE bar FROM query
	--#DECLARE q_bar SCROLL CURSOR FOR bar
	--#CALL drawinit()
	--#OPEN WINDOW w_gr1 AT 3,2 WITH FORM "../forms/repf304_3"
		--#ATTRIBUTE(BORDER, FORM LINE FIRST, COMMENT LINE LAST)
	--#CALL drawselect('c001')
	--#CALL drawanchor('w')
	--#CALL DrawFillColor("blue")
	--#LET i = drawline(inicio_y, inicio_x, 0, maximo_x)
	--#LET i = drawline(inicio_y, inicio_x, maximo_y, 0)
--
	--#LET factor_y         = maximo_y / max_valor 
	--#LET filas_procesadas = 0
	--#OPEN q_bar
	--#WHILE TRUE
		--#LET i = drawtext(960,10,titulo CLIPPED)
		--#LET num_barras = max_elementos - filas_procesadas
		--#IF num_barras >= max_barras THEN
			--#LET num_barras = max_barras
		--#END IF
		--#LET ancho_barra = maximo_x / num_barras 
		--#LET indice = 0
		--#LET inicio2_y  = maximo_y + 70 
		--#WHILE indice < num_barras 
			--#FETCH q_bar INTO bodega, item, descri, valor
			--#IF status = NOTFOUND THEN
				--#EXIT WHILE
			--#END IF
			--#LET r_obj[indice + 1].bodega = bodega
			--#LET r_obj[indice + 1].item   = item
			--#LET r_obj[indice + 1].nombre = descri
			--#LET r_obj[indice + 1].valor  = valor
        		--#CALL DrawFillColor(rm_color[indice+1])
			--#LET r_obj[indice + 1].id_obj_rec1 =
				--#drawrectangle(inicio_y, inicio_x + (ancho_barra * 
				      	--#indice), factor_y * valor, ancho_barra)
			--#LET r_obj[indice + 1].id_obj_rec2 =
				--#drawrectangle(inicio2_y, inicio2_x, 25, 75)
			--#LET descri = justifica_titulo_derecha(descri[1,35])
			--#LET i = drawtext(inicio2_y + 53, inicio2_x - 385, descri)
			--#LET tit_val = valor USING "#,###,###,##&.##"
			--#LET i = drawtext(inicio2_y + 15, inicio2_x - 215, tit_val)
			--#LET indice = indice + 1
			--#LET filas_procesadas = filas_procesadas + 1
			--#LET inicio2_y = inicio2_y - 110
		--#END WHILE
		--#LET tit_pos = filas_procesadas, ' de ', max_elementos
		--#LET i = drawtext(900,05, tit_pos)
		--#LET i = drawtext(30,10,'Haga click sobre un item para ver detalles')
		--#FOR i = 1 TO indice
			--#LET key_n = i + 30
			--#LET key_c = 'F', key_n
			--#CALL drawbuttonleft(r_obj[i].id_obj_rec1, key_c)
			--#CALL drawbuttonleft(r_obj[i].id_obj_rec2, key_c)
		--#END FOR
		--#LET key_f30 = FGL_KEYVAL("F30")
		--#LET int_flag = 0
		--#IF filas_procesadas >= max_elementos THEN
			--#CALL fgl_keysetlabel("F3","")
		--#ELSE
			--#CALL fgl_keysetlabel("F3","Avanzar")
		--#END IF
		--#IF filas_procesadas <= max_barras THEN
			--#CALL fgl_keysetlabel("F4","")
		--#ELSE
			--#CALL fgl_keysetlabel("F4","Retroceder")
		--#END IF
		--#INPUT BY NAME tecla
			--#BEFORE INPUT
				--#IF filas_procesadas <= max_barras THEN
					--#IF cant_val = 'V' THEN
						--#CALL dialog.keysetlabel("F1","Unidades")
					--#ELSE
						--#CALL dialog.keysetlabel("F1","Valores")
					--#END IF
				--#ELSE
					--#CALL dialog.keysetlabel("F1","")
				--#END IF
				--#CALL dialog.keysetlabel("ACCEPT","")
				--#CALL dialog.keysetlabel("F31","")
				--#CALL dialog.keysetlabel("F32","")
				--#CALL dialog.keysetlabel("F33","")
				--#CALL dialog.keysetlabel("F34","")
				--#CALL dialog.keysetlabel("F35","")
				--#CALL dialog.keysetlabel("F36","")
				--#CALL dialog.keysetlabel("F37","")
				--#CALL dialog.keysetlabel("F38","")
			--#ON KEY(F1)
				--#IF filas_procesadas <= max_barras THEN
					--#IF cant_val = 'C' THEN
						--#LET cant_val = 'V'
					--#ELSE
						--#LET cant_val = 'C'
					--#END IF
					--#LET int_flag = 2
					--#EXIT INPUT
				--#END IF
			--#ON KEY(F3)
				--#IF filas_procesadas < max_elementos THEN
					--#CALL drawclear()
					--#EXIT INPUT
				--#END IF
			--#ON KEY(F4)
				--#IF filas_procesadas > max_barras THEN
					--#LET filas_procesadas = filas_procesadas
						--#- (indice + max_barras)
					--#IF filas_procesadas = 0 THEN
						--#CLOSE q_bar
						--#OPEN q_bar
					--#ELSE
						--#FOR i = 1 TO indice + max_barras 
							--#FETCH PREVIOUS q_bar 
						--#END FOR
					--#END IF
					--#CALL drawclear()
					--#EXIT INPUT
				--#END IF
			--#ON KEY(F31,F32,F33,F34,F35,F36,F37,F38)
				--#LET i = FGL_LASTKEY() - key_f30
				--#CALL muestra_movimientos_item(r_obj[i].item, 
					--#r_obj[i].bodega, rm_par.moneda, 
					--#rm_par.fec_ini, rm_par.fec_fin)
			--#AFTER FIELD tecla
				--#NEXT FIELD tecla	
		--#END INPUT
		--#IF int_flag THEN
			--#CLOSE q_bar
			--#EXIT WHILE
		--#END IF
	--#END WHILE
	--#IF int_flag = 1 THEN
		--#EXIT WHILE
	--#END IF
--#END WHILE
--#CLOSE WINDOW w_gr1
	
--#END FUNCTION



FUNCTION carga_colores()

LET rm_color[01] = 'cyan'
LET rm_color[02] = 'yellow'
LET rm_color[03] = 'green'
LET rm_color[04] = 'red'
LET rm_color[05] = 'snow'
LET rm_color[06] = 'magenta'
LET rm_color[07] = 'pink'
LET rm_color[08] = 'chocolate'
LET rm_color[09] = 'tomato'
LET rm_color[10] = 'blue'

END FUNCTION



FUNCTION justifica_titulo_derecha(titulo)
DEFINE flag 		CHAR(1)
DEFINE titulo, aux	CHAR(35)
DEFINE i, j		SMALLINT

FOR i = 1 TO 35
	LET aux[i,i] = ' '
END FOR
LET i = 35
FOR j = LENGTH(titulo CLIPPED) TO 1 STEP -1
	LET aux[i,i] = titulo[j,j]
	LET i = i - 1
END FOR
RETURN aux

END FUNCTION



FUNCTION retorna_tam_arr()

--#LET vm_size_arr = fgl_scr_size('rm_cons')
IF vg_gui = 0 THEN
	LET vm_size_arr = 10
END IF

END FUNCTION



FUNCTION llamar_visor_teclas()
DEFINE a		CHAR(1)

IF vg_gui = 0 THEN
	CALL fl_visor_teclas_caracter() RETURNING int_flag 
	LET a = fgl_getkey()
	CLOSE WINDOW w_tf
	LET int_flag = 0
END IF

END FUNCTION



FUNCTION control_visor_teclas_caracter_1() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Movimientos de Item'      AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION



FUNCTION control_visor_teclas_caracter_2() 
DEFINE a, fila		INTEGER

CALL fl_visor_teclas_caracter() RETURNING fila
LET a = fila + 2
DISPLAY 'Teclas exclusivas de este proceso:' AT a,2 ATTRIBUTE(REVERSE)	
LET a = a + 1
DISPLAY '<F5>      Comprobante'              AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Item'                     AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
