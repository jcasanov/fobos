{*
 * Titulo           : repp310.4gl - Consulta Análisis Movimiento Items
 * Elaboracion      : 16-feb-2009
 * Autor            : JCM
 * Formato Ejecucion: fglrun repp310 base_datos modulo compañía localidad
 *}
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE vm_campo_orden	SMALLINT
DEFINE vm_tipo_orden	CHAR(4)
DEFINE rm_cons ARRAY[40000] OF RECORD
	cod_bod		LIKE rept002.r02_codigo,
	item		LIKE rept010.r10_codigo,
	descri_item	LIKE rept010.r10_nombre,
	ult_vta		DATE,
	unidad		INTEGER,
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
	tit_indrot	VARCHAR(30),
	tipo_valor	CHAR(1)
	END RECORD
DEFINE vm_max_rows	SMALLINT
DEFINE rm_color ARRAY[10] OF VARCHAR(10)



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp310.error')
CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fgl_winmessage(vg_producto, 'Número de parámetros incorrecto', 'stop')
	EXIT PROGRAM
END IF
LET vg_base     = arg_val(1)
LET vg_modulo   = arg_val(2)
LET vg_codcia   = arg_val(3)
LET vg_codloc   = arg_val(4)
LET vg_proceso = 'repp310'
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

INITIALIZE rm_par.* TO NULL
CALL fl_lee_configuracion_facturacion() RETURNING r.*
LET rm_par.moneda = r.g00_moneda_base
CALL fl_lee_moneda(rm_par.moneda) RETURNING r_mon.* 
OPEN WINDOW w_imp AT 3,2 WITH 21 ROWS, 80 COLUMNS
	ATTRIBUTE(FORM LINE FIRST + 1, COMMENT LINE LAST, MENU LINE FIRST,
		  BORDER, MESSAGE LINE LAST) 
OPEN FORM f_cons FROM '../forms/repf310_1'
DISPLAY FORM f_cons
LET rm_par.tit_mon = r_mon.g13_nombre
DISPLAY BY NAME rm_par.tit_mon
LET vm_max_rows = 40000
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

DEFINE r_g04		RECORD LIKE gent004.*
DEFINE r_g05		RECORD LIKE gent005.*

DISPLAY 'Bd'          TO tit_col1
DISPLAY 'Item'        TO tit_col2
DISPLAY 'Descripción' TO tit_col3
DISPLAY 'Ult.Vta.'    TO tit_col4
DISPLAY 'Unid.'       TO tit_col5
DISPLAY 'Valor'       TO tit_col6

LET rm_par.tipo_valor = 'V' 

CALL fl_lee_usuario(vg_usuario)             RETURNING r_g05.*
CALL fl_lee_grupo_usuario(r_g05.g05_grupo) RETURNING r_g04.*

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
		CALL FGL_WINQUESTION(vg_producto, 
                                     'Desea salir de la consulta',
                                     'No', 'Yes|No|Cancel',
                                     'question', 1) RETURNING resp
		IF resp = 'Yes' THEN
			LET INT_FLAG = 1
			RETURN
		END IF
	ON KEY(F2)
		IF infield(moneda) THEN
			CALL fl_ayuda_monedas() RETURNING mon_aux,rm_par.tit_mon,
							  num_dec
			IF mon_aux IS NOT NULL THEN
				LET rm_par.moneda = mon_aux
				DISPLAY BY NAME rm_par.moneda, rm_par.tit_mon
			END IF
		END IF
		IF infield(bodega) THEN
			CALL fl_ayuda_bodegas_rep(vg_codcia, NULL, 'T') RETURNING bod_aux,rm_par.tit_bod
			IF bod_aux IS NOT NULL THEN
				LET rm_par.bodega = bod_aux
				DISPLAY BY NAME rm_par.bodega, rm_par.tit_bod
			END IF
		END IF
		IF infield(linea) THEN
			CALL fl_ayuda_lineas_rep(vg_codcia) RETURNING lin_aux,rm_par.tit_lin
			IF lin_aux IS NOT NULL THEN
				LET rm_par.linea = lin_aux
				DISPLAY BY NAME rm_par.linea, rm_par.tit_lin
			END IF
		END IF
		IF infield(indrot) THEN
			CALL fl_ayuda_clases(vg_codcia) RETURNING ind_aux,rm_par.tit_indrot
			IF ind_aux IS NOT NULL THEN
				LET rm_par.indrot = ind_aux
				DISPLAY BY NAME rm_par.indrot, rm_par.tit_indrot
			END IF
		END IF
		IF infield(tipo_item) THEN
			CALL fl_ayuda_tipo_item() RETURNING cod_aux,rm_par.tit_tipo_item
			IF cod_aux IS NOT NULL THEN
				LET rm_par.tipo_item = cod_aux
				DISPLAY BY NAME rm_par.tipo_item, rm_par.tit_tipo_item
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
				CALL fgl_winmessage(vg_producto, 'Bodega no existe', 'exclamation')
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
				CALL fgl_winmessage(vg_producto, 'Línea no existe', 'exclamation')
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
				CALL fgl_winmessage(vg_producto, 'Tipo de item no existe', 'exclamation')
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
				CALL fgl_winmessage(vg_producto, 'Indice de rotación no existe', 'exclamation')
				NEXT FIELD indrot
			END IF
			LET rm_par.tit_indrot = r_ind.r04_nombre
			DISPLAY BY NAME rm_par.tit_indrot
		ELSE
			LET rm_par.tit_indrot = NULL
			CLEAR tit_indrot
		END IF
	AFTER FIELD tipo_valor
		IF r_g04.g04_ver_costo = 'N' THEN
			CALL fgl_winmessage(vg_producto, 'Usuario no puede ver costos.', 'information')
			LET rm_par.tipo_valor = 'V'
			NEXT FIELD tipo_valor
		END IF
	AFTER INPUT 
		IF rm_par.fec_ini > rm_par.fec_fin THEN
			CALL fgl_winmessage(vg_producto, 'Fecha final debe ser mayor a la inicial', 'exclamation')
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
DEFINE query		VARCHAR(1200)
DEFINE i, nuevo_display	SMALLINT
DEFINE pos_pantalla  	SMALLINT
DEFINE pos_arreglo   	SMALLINT
DEFINE item_aux         LIKE rept010.r10_codigo

DEFINE sum_valor	DECIMAL(14,2)
DEFINE columna_valor	VARCHAR(50)

IF rm_par.tipo_valor = 'V' THEN
	DISPLAY 'Valor Venta' TO tit_col6 
ELSE
	DISPLAY 'Valor Costo' TO tit_col6 
END IF

ERROR "Generando consulta . . . espere por favor." ATTRIBUTE(NORMAL)
LET vm_campo_orden = 6
LET vm_tipo_orden  = 'ASC'

LET expr1 = '     r19_compania   = ? AND r19_localidad = ? ', 
            ' AND DATE(r19_fecing) BETWEEN ? AND ? '
LET expr2 = '1 = 1'
LET expr3 = '1 = 1'
LET expr4 = '1 = 1'
LET expr5 = '1 = 1'
LET expr6 = '1 = 1'
IF rm_par.moneda IS NOT NULL THEN
	LET expr2 = "r19_moneda = '", rm_par.moneda, "'"
END IF
IF rm_par.bodega IS NOT NULL THEN
	LET expr3 = "r19_bodega_ori = '", rm_par.bodega, "'"
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

{*
 * Este codigo me permite generar la consulta viendo costos o precios de
 * venta segun sea el caso.
 *}
LET columna_valor = 'r20_precio' 
IF rm_par.tipo_valor = 'C' THEN
	LET columna_valor = 'r20_costo' 
END IF

LET query = 'SELECT r19_bodega_ori te_cod_bod, r20_item te_item, r10_nombre te_descri_item, ',
		' MAX(r19_fecing) te_ult_vta, ',
		' SUM(CASE r20_cod_tran WHEN "FA" THEN r20_cant_ven ELSE r20_cant_ven * (-1) END) te_unidad, ',
		' SUM((CASE r20_cod_tran WHEN "FA" THEN r20_cant_ven ELSE r20_cant_ven * (-1) END) * ', columna_valor CLIPPED, ') te_valor ',
		' FROM rept019, rept010, rept020 ',
		' WHERE ', expr1 CLIPPED,
		' AND ', expr2 CLIPPED,
		' AND r19_cod_tran IN ("FA", "DF", "AF") ',
		' AND ', expr3 CLIPPED,
		' AND r20_compania  = r19_compania ',
		' AND r20_localidad = r19_localidad ',
		' AND r20_cod_tran  = r19_cod_tran ',
		' AND r20_num_tran  = r19_num_tran ',
		' AND r10_compania  = r20_compania ',
		' AND r10_codigo    = r20_item ',
		' AND ', expr4 CLIPPED,
		' AND ', expr5 CLIPPED,
		' AND ', expr6 CLIPPED,
		' GROUP BY 1, 2, 3',
		' INTO TEMP temp_item '

PREPARE cons FROM query
EXECUTE cons USING vg_codcia, vg_codloc, rm_par.fec_ini, rm_par.fec_fin 

DELETE FROM temp_item WHERE te_unidad = 0

SELECT COUNT(*) INTO num_rows FROM temp_item 
IF num_rows = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	DROP TABLE temp_item
	RETURN
END IF

SELECT SUM(te_valor) INTO sum_valor FROM temp_item
DISPLAY BY NAME sum_valor

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
		IF i = 40000 THEN
			CALL fgl_winmessage(vg_producto, 'No se muestran todos los registros porque exceden el limite de 40000.', 'info')
			EXIT FOREACH
		END IF
	END FOREACH
	LET i = 1
	CALL set_count(num_rows)
	DISPLAY ARRAY rm_cons TO rm_cons.*
		BEFORE DISPLAY 
			CALL dialog.keysetlabel("F7","Imprimir")
		AFTER DISPLAY 
			CONTINUE DISPLAY
		BEFORE ROW
			LET i = arr_curr()
			MESSAGE i, ' de ', num_rows
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			CALL muestra_movimientos_item(rm_cons[i].item, 
				rm_cons[i].cod_bod, rm_par.moneda, rm_par.fec_ini,
				rm_par.fec_fin)
		ON KEY(F6)
			CALL muestra_grafico_barras()
		ON KEY(F7)
			CALL imprimir(num_rows)		
			LET int_flag = 2
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
END WHILE
DROP TABLE temp_item
FOR i = 1 TO fgl_scr_size('rm_cons') 
	CLEAR rm_cons[i].*
END FOR
CLEAR sum_valor

END FUNCTION



FUNCTION imprimir(maxelm)
DEFINE i		SMALLINT          
DEFINE maxelm		SMALLINT          
DEFINE comando		VARCHAR(100)

CALL fl_control_reportes() RETURNING comando
IF int_flag THEN
	RETURN          
END IF

START REPORT rep_analisis TO PIPE comando 
	FOR i = 1 TO (maxelm - 1)
		OUTPUT TO REPORT rep_analisis(i)
	END FOR
FINISH REPORT rep_analisis

END FUNCTION



REPORT rep_analisis(numelm)
DEFINE numelm		SMALLINT
DEFINE usuario		VARCHAR(19,15)
DEFINE titulo		VARCHAR(80)
DEFINE modulo		VARCHAR(40)
DEFINE i,long		SMALLINT
DEFINE fecha		DATE

DEFINE col		VARCHAR(15)

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
	CALL fl_justifica_titulo('I', 'LISTADO ANALISIS VENTAS ITEMS', 70)
		RETURNING titulo

	PRINT COLUMN 1, rg_cia.g01_razonsocial,
  	      COLUMN 82 , "Página: ", PAGENO USING "&&&"
	PRINT COLUMN 1, modulo CLIPPED,
	      COLUMN 33, titulo CLIPPED,
	      COLUMN 86 , "REPP310" 
	PRINT COLUMN 30, "** Moneda        : ", rm_par.moneda,
						" ", rm_par.tit_mon
	PRINT COLUMN 30, "** Fecha Inicial : ", rm_par.fec_ini USING "dd-mm-yyyy"
	PRINT COLUMN 30, "** Fecha Final   : ", rm_par.fec_fin USING "dd-mm-yyyy"
	PRINT COLUMN 01, "Fecha  : ", TODAY USING "dd-mm-yyyy", 1 SPACES, TIME,
	      COLUMN 74, usuario CLIPPED
	SKIP 1 LINES
--	print '&k2S'	                -- Letra condensada (16 cpi)
	IF rm_par.tipo_valor = 'C' THEN
		LET col = '   Valor Costo'
	ELSE
		LET col = '   Valor Venta'
	END IF
	PRINT COLUMN 1,  "Bodega",
	      COLUMN 9,  "Item",
	      COLUMN 26, "Descripcion",
	      COLUMN 58, "Ultima Venta",
	      COLUMN 72, "Cant.",
	      COLUMN 80, col CLIPPED  
	PRINT "---------------------------------------------------------------------------------------------"
ON EVERY ROW
	NEED 2 LINES
	PRINT COLUMN 3,  rm_cons[numelm].cod_bod,
	      COLUMN 9,  rm_cons[numelm].item,
	      COLUMN 26,  rm_cons[numelm].descri_item[1,30],
	      COLUMN 58,  rm_cons[numelm].ult_vta USING "dd-mm-yyyy",
	      COLUMN 72,  rm_cons[numelm].unidad USING "##,##&",
	      COLUMN 80,  rm_cons[numelm].valor USING "--,---,--&.&&" 
ON LAST ROW
	PRINT COLUMN 80, ' ------------- ' 
	PRINT COLUMN 60, ' Total Facturado: ',
	      COLUMN 80,  SUM(rm_cons[numelm].valor) USING "--,---,--&.&&" 

END REPORT



FUNCTION muestra_movimientos_item(item, bodega, moneda, fec_ini, fec_fin)
DEFINE item		LIKE rept010.r10_codigo
DEFINE bodega		LIKE rept002.r02_codigo
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE fec_ini, fec_fin	DATE
DEFINE r_item		RECORD LIKE rept010.*
DEFINE r_mon		RECORD LIKE gent013.*
DEFINE r_bod		RECORD LIKE rept002.*
DEFINE r_trn		RECORD LIKE rept019.*
DEFINE num_rows, i	SMALLINT
DEFINE max_rows		SMALLINT
DEFINE tot_uni		INTEGER
DEFINE tot_val		DECIMAL(14,2)
DEFINE comando		VARCHAR(140)
DEFINE columna_act	SMALLINT
DEFINE columna_ant	SMALLINT
DEFINE orden_act	CHAR(4)
DEFINE orden_ant	CHAR(4)
DEFINE orden		VARCHAR(100)
DEFINE query		VARCHAR(300)
DEFINE rt		RECORD LIKE gent021.*
DEFINE r_mov ARRAY[800] OF RECORD
	fecha		DATE,
	tipo		LIKE rept019.r19_cod_tran,
	numero		LIKE rept019.r19_num_tran,
	cliente		VARCHAR(30),
	unidades	INTEGER,
	valor		DECIMAL(14,2)
	END RECORD

CREATE TEMP TABLE temp_mov
	(te_fecha	DATETIME YEAR TO SECOND,
	 te_tipo	CHAR(2),
	 te_numero	INTEGER,
	 te_cliente	VARCHAR(30),
	 te_unidades	INTEGER,
	 te_valor	DECIMAL(14,2))
LET max_rows = 800
OPEN WINDOW w_mov AT 3,5 WITH FORM "../forms/repf310_2"
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
ERROR "Generando consulta . . . espere por favor." ATTRIBUTE(NORMAL)
CALL fl_lee_item(vg_codcia, item) RETURNING r_item.*
CALL fl_lee_moneda(moneda) RETURNING r_mon.*
CALL fl_lee_bodega_rep(vg_codcia, bodega) RETURNING r_bod.*
DISPLAY 'Fecha'       TO tit_col1
DISPLAY 'Tp'          TO tit_col2
DISPLAY '# Documento' TO tit_col3
DISPLAY 'Cliente'     TO tit_col4
DISPLAY 'Uni.'        TO tit_col5
DISPLAY 'V a l o r'   TO tit_col6
DISPLAY BY NAME item, fec_ini, fec_fin
DISPLAY r_item.r10_nombre TO name_item
DISPLAY r_mon.g13_nombre TO tit_mon
DISPLAY r_bod.r02_nombre TO tit_bod
DECLARE q_det CURSOR FOR SELECT r20_fecing, r20_cod_tran, r20_num_tran,
	'', r20_cant_ven, (r20_precio * r20_cant_ven) - r20_val_descto
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
	FETCH q_det INTO r_mov[num_rows].*
	IF status = NOTFOUND THEN
		EXIT WHILE
	END IF
	CALL fl_lee_cod_transaccion(r_mov[num_rows].tipo) RETURNING rt.*
	IF rt.g21_act_estad <> 'S' THEN
		CONTINUE WHILE
	END IF
	CALL fl_lee_cabecera_transaccion_rep(vg_codcia, vg_codloc, 
		r_mov[num_rows].tipo, r_mov[num_rows].numero)
		RETURNING r_trn.*
	IF r_trn.r19_bodega_ori <> bodega THEN
		CONTINUE WHILE
	END IF
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
		BEFORE DISPLAY 
			CALL dialog.keysetlabel("ACCEPT","")
		AFTER DISPLAY 
			CONTINUE DISPLAY
		BEFORE ROW
			LET i = arr_curr()
			MESSAGE i, ' de ', num_rows
		ON KEY(INTERRUPT)
			EXIT DISPLAY
		ON KEY(F5)
			LET i = arr_curr()
			LET comando = 'fglrun repp308 ' || vg_base || ' RE ' || 
			       	vg_codcia || ' ' ||
			       	vg_codloc || ' ' || r_mov[i].tipo || ' ' ||
			       	r_mov[i].numero
			RUN comando
		ON KEY(F6)
			LET comando = 'fglrun repp108 ', vg_base, ' RE ', 
			               vg_codcia, ' "',
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



FUNCTION muestra_grafico_barras()
DEFINE inicio_x		SMALLINT
DEFINE inicio_y		SMALLINT
DEFINE maximo_x		SMALLINT
DEFINE maximo_y		SMALLINT
DEFINE factor_y		DECIMAL(16,6)
DEFINE max_barras	SMALLINT
DEFINE ancho_barra	SMALLINT
DEFINE num_barras	SMALLINT

DEFINE inicio2_x	SMALLINT
DEFINE inicio2_y	SMALLINT

DEFINE max_elementos	SMALLINT
DEFINE max_valor	DECIMAL(14,2)
DEFINE filas_procesadas	SMALLINT

DEFINE bodega		LIKE rept002.r02_codigo
DEFINE item		LIKE rept010.r10_codigo
DEFINE descri		VARCHAR(35)
DEFINE valor		DECIMAL(14,2)
DEFINE key_n		SMALLINT
DEFINE key_c		CHAR(3)
DEFINE key_f30		SMALLINT
DEFINE cant_val		CHAR(1)
DEFINE query		VARCHAR(200)
DEFINE i, indice	SMALLINT
DEFINE tecla		CHAR(1)
DEFINE titulo, tit_pos	CHAR(75)
DEFINE tit_val		CHAR(16)
DEFINE r_obj ARRAY[8] OF RECORD
	bodega		LIKE rept002.r02_codigo,
	item		LIKE rept010.r10_codigo,
	nombre		LIKE rept010.r10_nombre,
	valor		DECIMAL(14,2),
	id_obj_rec1	SMALLINT,
	id_obj_rec2	SMALLINT
	END RECORD

CALL carga_colores()
LET max_barras = 8
LET inicio_x   = 50
LET inicio_y   = 80
LET maximo_x   = 500
LET maximo_y   = 750
LET inicio2_x  = 910

LET cant_val = 'V'
WHILE TRUE
	LET titulo = 'POR ITEM DURANTE EL PERIODO: ', 
		      rm_par.fec_ini USING 'dd-mm-yyyy', ' - ', 
		      rm_par.fec_fin USING 'dd-mm-yyyy'
	IF cant_val = 'C' THEN
		LET titulo = 'UNIDADES VENDIDAS ', titulo CLIPPED
		SELECT COUNT(*), MAX(te_unidad) INTO max_elementos, max_valor
			FROM temp_item
		LET query = 'SELECT te_cod_bod, te_item, te_descri_item, ',
				'te_unidad FROM temp_item ',
				'ORDER BY 4 DESC'
	ELSE
		LET titulo = '	VALORES VENDIDOS ', titulo CLIPPED
		SELECT COUNT(*), MAX(te_valor) INTO max_elementos, max_valor
			FROM temp_item
		LET query = 'SELECT te_cod_bod, te_item, te_descri_item, ',
				'te_valor FROM temp_item ',
				'ORDER BY 4 DESC'
	END IF
	PREPARE bar FROM query
	DECLARE q_bar SCROLL CURSOR FOR bar
	CALL drawinit()
	OPEN WINDOW w_gr1 AT 3,2 WITH FORM "../forms/repf304_3"
		ATTRIBUTE(BORDER, FORM LINE FIRST, COMMENT LINE LAST)
	CALL drawselect('c001')
	CALL drawanchor('w')
	CALL DrawFillColor("blue")
	LET i = drawline(inicio_y, inicio_x, 0, maximo_x)
	LET i = drawline(inicio_y, inicio_x, maximo_y, 0)
--
	LET factor_y         = maximo_y / max_valor 
	LET filas_procesadas = 0
	OPEN q_bar
	WHILE TRUE
		LET i = drawtext(960,10,titulo CLIPPED)
		LET num_barras = max_elementos - filas_procesadas
		IF num_barras >= max_barras THEN
			LET num_barras = max_barras
		END IF
		LET ancho_barra = maximo_x / num_barras 
		LET indice = 0
		LET inicio2_y  = maximo_y + 70 
		WHILE indice < num_barras 
			FETCH q_bar INTO bodega, item, descri, valor
			IF status = NOTFOUND THEN
				EXIT WHILE
			END IF
			LET r_obj[indice + 1].bodega = bodega
			LET r_obj[indice + 1].item   = item
			LET r_obj[indice + 1].nombre = descri
			LET r_obj[indice + 1].valor  = valor
        		CALL DrawFillColor(rm_color[indice+1])
			LET r_obj[indice + 1].id_obj_rec1 =
				drawrectangle(inicio_y, inicio_x + (ancho_barra * 
				      	indice), factor_y * valor, ancho_barra)
			LET r_obj[indice + 1].id_obj_rec2 =
				drawrectangle(inicio2_y, inicio2_x, 25, 75)
			LET descri = justifica_titulo_derecha(descri[1,35])
			LET i = drawtext(inicio2_y + 53, inicio2_x - 385, descri)
			LET tit_val = valor USING "#,###,###,##&.##"
			LET i = drawtext(inicio2_y + 15, inicio2_x - 215, tit_val)
			LET indice = indice + 1
			LET filas_procesadas = filas_procesadas + 1
			LET inicio2_y = inicio2_y - 110
		END WHILE
		LET tit_pos = filas_procesadas, ' de ', max_elementos
		LET i = drawtext(900,05, tit_pos)
		LET i = drawtext(30,10,'Haga click sobre un item para ver detalles')
		FOR i = 1 TO indice
			LET key_n = i + 30
			LET key_c = 'F', key_n
			CALL drawbuttonleft(r_obj[i].id_obj_rec1, key_c)
			CALL drawbuttonleft(r_obj[i].id_obj_rec2, key_c)
		END FOR
		LET key_f30 = FGL_KEYVAL("F30")
		LET int_flag = 0
		IF filas_procesadas >= max_elementos THEN
			CALL fgl_keysetlabel("F3","")
		ELSE
			CALL fgl_keysetlabel("F3","Avanzar")
		END IF
		IF filas_procesadas <= max_barras THEN
			CALL fgl_keysetlabel("F4","")
		ELSE
			CALL fgl_keysetlabel("F4","Retroceder")
		END IF
		INPUT BY NAME tecla
			BEFORE INPUT
				IF filas_procesadas <= max_barras THEN
					IF cant_val = 'V' THEN
						CALL dialog.keysetlabel("F1","Unidades")
					ELSE
						CALL dialog.keysetlabel("F1","Valores")
					END IF
				ELSE
					CALL dialog.keysetlabel("F1","")
				END IF
				CALL dialog.keysetlabel("ACCEPT","")
				CALL dialog.keysetlabel("F31","")
				CALL dialog.keysetlabel("F32","")
				CALL dialog.keysetlabel("F33","")
				CALL dialog.keysetlabel("F34","")
				CALL dialog.keysetlabel("F35","")
				CALL dialog.keysetlabel("F36","")
				CALL dialog.keysetlabel("F37","")
				CALL dialog.keysetlabel("F38","")
			ON KEY(F1)
				IF filas_procesadas <= max_barras THEN
					IF cant_val = 'C' THEN
						LET cant_val = 'V'
					ELSE
						LET cant_val = 'C'
					END IF
					LET int_flag = 2
					EXIT INPUT
				END IF
			ON KEY(F3)
				IF filas_procesadas < max_elementos THEN
					CALL drawclear()
					EXIT INPUT
				END IF
			ON KEY(F4)
				IF filas_procesadas > max_barras THEN
					LET filas_procesadas = filas_procesadas
						- (indice + max_barras)
					IF filas_procesadas = 0 THEN
						CLOSE q_bar
						OPEN q_bar
					ELSE
						FOR i = 1 TO indice + max_barras 
							FETCH PREVIOUS q_bar 
						END FOR
					END IF
					CALL drawclear()
					EXIT INPUT
				END IF
			ON KEY(F31,F32,F33,F34,F35,F36,F37,F38)
				LET i = FGL_LASTKEY() - key_f30
				CALL muestra_movimientos_item(r_obj[i].item, 
					r_obj[i].bodega, rm_par.moneda, 
					rm_par.fec_ini, rm_par.fec_fin)
			AFTER FIELD tecla
				NEXT FIELD tecla	
		END INPUT
		IF int_flag THEN
			CLOSE q_bar
			EXIT WHILE
		END IF
	END WHILE
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
END WHILE
CLOSE WINDOW w_gr1
	
END FUNCTION



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
