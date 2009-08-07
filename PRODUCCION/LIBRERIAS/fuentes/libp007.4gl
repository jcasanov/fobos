-- LIBRERIAS GENERALES DEL SISTEMA
GLOBALS "../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl"

FUNCTION fl_mostrar_reservas_items(cod_cia, cod_loc, item)
DEFINE cod_cia			LIKE rept023.r23_compania
DEFINE cod_loc			LIKE rept023.r23_localidad
DEFINE item				LIKE rept010.r10_codigo

DEFINE r_r10			RECORD LIKE rept010.*
DEFINE tot_reserva		LIKE rept024.r24_cant_ped

DEFINE i				INTEGER
DEFINE r_reserva ARRAY[1000] OF RECORD
	fecha				DATE,
	vendedor			LIKE rept001.r01_iniciales,
	cliente				LIKE rept021.r21_nomcli,
	proforma			LIKE rept021.r21_numprof,
	preventa			LIKE rept023.r23_numprev,
	facturado			CHAR(1),
	reserva				LIKE rept024.r24_cant_ped
END RECORD

CALL fl_lee_item(cod_cia, item) RETURNING r_r10.*
IF r_r10.r10_compania IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'El item no existe.', 'stop')
	RETURN
END IF

OPEN WINDOW w_rep_reservitm AT 6,2 WITH FORM "../../../PRODUCCION/LIBRERIAS/forms/ayuf305"
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)

	DISPLAY 'Fecha', 'Ven', 'Cliente', 'Prof.', 'Prev.', 'F', 'Cant'
	     TO tit_col1, tit_col2, tit_col3, tit_col4, tit_col5, tit_col6, tit_col7

	DISPLAY r_r10.r10_codigo, r_r10.r10_nombre TO item, item_desc

    SELECT DATE(r102_fecing) fecha, r01_iniciales, r23_nomcli, r102_numprof, 
		   r23_numprev, ' ' facturado, r24_cant_ped cantidad
      FROM rept023, rept024, rept102, rept001
     WHERE r23_compania   = cod_cia
       AND r23_localidad  = cod_loc
       AND r23_estado     = 'P'
       AND r24_compania   = r23_compania
       AND r24_localidad  = r23_localidad
       AND r24_numprev    = r23_numprev
       AND r24_item       = item
	   AND r102_compania  = r23_compania
	   AND r102_localidad = r23_localidad
	   AND r102_numprev   = r23_numprev
       AND r01_compania   = r23_compania
       AND r01_codigo     = r23_vendedor
	  INTO TEMP temp_reserva

	INSERT INTO temp_reserva
    SELECT DATE(r20_fecing), r01_iniciales, r19_nomcli, r102_numprof, 
		   r23_numprev, 'S', r116_cantidad
      FROM rept116, rept019, rept020, rept023, rept102, rept001
     WHERE r116_compania   = cod_cia
       AND r116_localidad  = cod_loc
	   AND r116_cod_tran   = 'FA'
       AND r116_item_fact  = item
       AND r116_cantidad   > 0
       AND r19_compania    = r116_compania
       AND r19_localidad   = r116_localidad
       AND r19_cod_tran    = r116_cod_tran
       AND r19_num_tran    = r116_num_tran
       AND r20_compania    = r19_compania 
       AND r20_localidad   = r19_localidad
       AND r20_cod_tran    = r19_cod_tran 
       AND r20_num_tran    = r19_num_tran 
       AND r20_item        = r116_item_fact
       AND r23_compania    = r19_compania
       AND r23_localidad   = r19_localidad
       AND r23_cod_tran    = r19_cod_tran 
       AND r23_num_tran    = r19_num_tran 
       AND r23_estado     = 'F'
	   AND r102_compania  = r23_compania
	   AND r102_localidad = r23_localidad
	   AND r102_numprev   = r23_numprev
       AND r01_compania   = r19_compania
       AND r01_codigo     = r19_vendedor

DECLARE q_reserva CURSOR FOR
	SELECT * FROM temp_reserva ORDER BY fecha

LET tot_reserva = 0
LET i = 1
FOREACH q_reserva INTO r_reserva[i].*
	LET tot_reserva = tot_reserva + r_reserva[i].reserva
	LET i = i + 1
	IF i > 1000 THEN
		CALL fl_mensaje_arreglo_incompleto()
		EXIT FOREACH
	END IF
END FOREACH 
FREE q_reserva

DROP TABLE temp_reserva

LET i = i - 1

CALL set_count(i)
DISPLAY ARRAY r_reserva TO r_reserva.*
	BEFORE ROW
		DISPLAY BY NAME tot_reserva
END DISPLAY

CLOSE WINDOW w_rep_reservitm

END FUNCTION



FUNCTION fl_mostrar_estadisticas_items(cod_cia, cod_loc, item)
DEFINE cod_cia		LIKE rept019.r19_compania
DEFINE cod_loc		LIKE rept019.r19_localidad
DEFINE item			LIKE rept020.r20_item

DEFINE r_g13		RECORD LIKE gent013.*
DEFINE r_r00		RECORD LIKE rept000.*
DEFINE r_r02		RECORD LIKE rept002.*

DEFINE r_par RECORD
	r12_moneda	LIKE rept012.r12_moneda,
	n_moneda	LIKE gent013.g13_nombre,
	anho		SMALLINT,
	bodega		LIKE rept002.r02_codigo,
	n_bodega	LIKE rept002.r02_nombre
END RECORD

IF item IS NULL THEN
	CALL fgl_winmessage(vg_producto, 'Debe consultar un item primero.', 'exclamation')
	RETURN
END IF

INITIALIZE r_par.* TO NULL
CALL fl_lee_compania_repuestos(cod_cia)                RETURNING r_r00.*
CALL fl_lee_moneda(rg_gen.g00_moneda_base)             RETURNING r_g13.*
CALL fl_lee_bodega_rep(cod_cia, r_r00.r00_bodega_fact) RETURNING r_r02.*
LET r_par.r12_moneda = rg_gen.g00_moneda_base
LET r_par.n_moneda   = r_g13.g13_nombre 
LET r_par.bodega     = r_r00.r00_bodega_fact
LET r_par.n_bodega   = r_r02.r02_nombre
LET r_par.anho       = YEAR(TODAY)

OPEN WINDOW w_estad_item AT 5,13 WITH 20 ROWS, 57 COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, BORDER) 
OPEN FORM f_estad_item FROM '../../../PRODUCCION/LIBRERIAS/forms/ayuf307'
DISPLAY FORM f_estad_item

DISPLAY 'Mes' 		TO bt_mes
DISPLAY 'Ventas '	TO bt_vend
DISPLAY 'Demanda'	TO bt_dema
DISPLAY 'Pérdida'	TO bt_perd
DISPLAY 'Total'		TO bt_total

LET int_flag = 0
INPUT BY NAME r_par.* WITHOUT DEFAULTS
	ON KEY(F2)
		IF infield(r12_moneda) THEN
			CALL fl_ayuda_monedas() RETURNING r_g13.g13_moneda,
							  r_g13.g13_nombre,
							  r_g13.g13_decimales
			IF r_g13.g13_moneda IS NOT NULL THEN
				LET r_par.r12_moneda = r_g13.g13_moneda
				LET r_par.n_moneda   = r_g13.g13_nombre
				DISPLAY BY NAME r_par.*
			END IF
		END IF
		IF infield(bodega) THEN
			CALL fl_ayuda_bodegas_rep(cod_cia, NULL, 'T') 
				RETURNING r_r02.r02_codigo,
					  r_r02.r02_nombre
			IF r_r02.r02_codigo IS NOT NULL THEN
				LET r_par.bodega   = r_r02.r02_codigo
				LET r_par.n_bodega = r_r02.r02_nombre
				DISPLAY BY NAME r_par.*
			END IF
		END IF
		LET int_flag = 0
	AFTER FIELD r12_moneda
		IF r_par.r12_moneda IS NOT NULL THEN
			CALL fl_lee_moneda(r_par.r12_moneda) RETURNING r_g13.*
			IF r_g13.g13_moneda IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
					'Moneda no existe', 
					'exclamation')
				NEXT FIELD r12_moneda
			END IF
			LET r_par.n_moneda = r_g13.g13_nombre
			DISPLAY BY NAME r_par.n_moneda
		ELSE
			LET r_par.n_moneda = NULL
			CLEAR n_moneda
		END IF
	AFTER FIELD bodega
		IF r_par.bodega IS NOT NULL THEN
			CALL fl_lee_bodega_rep(cod_cia, r_par.bodega) 
				RETURNING r_r02.*
			IF r_r02.r02_codigo IS NULL THEN
				CALL fgl_winmessage(vg_producto, 
					'Bodega no existe', 
					'exclamation')
				NEXT FIELD bodega
			END IF
			LET r_par.n_bodega = r_r02.r02_nombre
			DISPLAY BY NAME r_par.n_bodega
		ELSE
			LET r_par.n_bodega = NULL
			CLEAR n_bodega
		END IF
		AFTER FIELD anho
			IF r_par.anho <= 1900 THEN
				CALL fgl_winmessage(vg_producto,
					'El año debe ser mayor a 1900.',
					'exclamation')
				NEXT FIELD anho
			END IF
END INPUT
IF int_flag THEN
	CLOSE WINDOW w_estad_item
	RETURN
END IF

CALL fl_consulta_estadisticas(cod_cia, cod_loc, item, r_par.*)

CLOSE WINDOW w_estad_item

END FUNCTION



FUNCTION fl_consulta_estadisticas(cod_cia, cod_loc, item, r_par)
DEFINE cod_cia		LIKE rept012.r12_compania
DEFINE cod_loc		LIKE rept019.r19_localidad
DEFINE item			LIKE rept012.r12_item
DEFINE i		SMALLINT
DEFINE query		VARCHAR(700)
DEFINE mes		SMALLINT
DEFINE expr_sql		VARCHAR(200)
DEFINE expr_bod		VARCHAR(100)
DEFINE expr_anho 	VARCHAR(50)

DEFINE num_rows		SMALLINT

DEFINE unid_vend	LIKE rept012.r12_uni_venta
DEFINE unid_dema	LIKE rept012.r12_uni_deman
DEFINE unid_perd	LIKE rept012.r12_uni_perdi

DEFINE tot_vend		LIKE rept012.r12_uni_venta
DEFINE tot_dema		LIKE rept012.r12_uni_deman
DEFINE tot_perd		LIKE rept012.r12_uni_perdi
DEFINE total		SMALLINT
DEFINE fec_ini, fec_fin DATE
DEFINE r_par RECORD
	r12_moneda	LIKE rept012.r12_moneda,
	n_moneda	LIKE gent013.g13_nombre,
	anho		SMALLINT,
	bodega		LIKE rept002.r02_codigo,
	n_bodega	LIKE rept002.r02_nombre
END RECORD

DEFINE r_estat ARRAY[12] OF RECORD
	mes		CHAR(10), 
	unid_vend	LIKE rept012.r12_uni_venta, 
	unid_dema	LIKE rept012.r12_uni_deman, 
	unid_perd	LIKE rept012.r12_uni_perdi, 
	subtotal	SMALLINT        
END RECORD

LET num_rows = 12
LET i = 1
INITIALIZE mes, r_estat[i].* TO NULL
LET tot_vend = 0 
LET tot_perd = 0
LET tot_dema = 0 

FOR i = 1 TO num_rows
	LET r_estat[i].mes 	 = 
		fl_justifica_titulo('I', fl_retorna_nombre_mes(i), 10)
	LET r_estat[i].unid_vend = 0
	LET r_estat[i].unid_dema = 0
	LET r_estat[i].unid_perd = 0
	LET r_estat[i].subtotal  = 0
END FOR

ERROR 'Generando consulta . . . espere por favor' ATTRIBUTE(NORMAL)
LET expr_bod = ' 1 = 1 '
IF r_par.bodega IS NOT NULL THEN
	LET expr_bod = "r19_bodega_ori = '", r_par.bodega CLIPPED, "'"
END IF

LET query = 'SELECT MONTH(r19_fecing), SUM(r20_cant_ven - r20_cant_dev), ',
	    '	    COUNT(r20_cant_ped), SUM(r20_cant_ped - r20_cant_ven) ',
	    '	FROM rept019, rept020 ',
	    '	WHERE r19_compania    = ',  cod_cia CLIPPED, 
		'     AND r19_cod_tran     = "FA" ',
	    '	  AND r19_moneda      = "', r_par.r12_moneda, '"',
	    '  	  AND YEAR(r19_fecing) = ',  r_par.anho CLIPPED,
	    '	  AND ', expr_bod CLIPPED, 
		'     AND r20_compania     = r19_compania ',
		'     AND r20_localidad    = r19_localidad ',
		'     AND r20_cod_tran     = r19_cod_tran ',
		'     AND r20_num_tran     = r19_num_tran ',
	    '	  AND r20_item = "', item, '"',
	    ' 	GROUP BY 1 ',
	    '	ORDER BY 1 '
	    
PREPARE cit FROM query
DECLARE q_cit CURSOR FOR cit

FOREACH	q_cit INTO mes, unid_vend, unid_dema, unid_perd
	LET r_estat[mes].unid_vend = unid_vend
	LET r_estat[mes].unid_dema = unid_dema
	LET r_estat[mes].unid_perd = unid_perd
	LET r_estat[mes].subtotal  = unid_vend + unid_dema + unid_perd
	LET tot_vend = tot_vend + unid_vend
	LET tot_dema = tot_dema + unid_dema
	LET tot_perd = tot_perd + unid_perd
END FOREACH

ERROR ' ' ATTRIBUTE(NORMAL)

LET int_flag = 0
CALL set_count(num_rows)
DISPLAY ARRAY r_estat TO r_estat.*
	BEFORE ROW
		LET i = arr_curr()
	BEFORE DISPLAY
		CALL dialog.keysetlabel('F8', 'Movimientos')
		CALL dialog.keysetlabel("ACCEPT","")
		LET total = tot_vend + tot_dema + tot_perd
		DISPLAY BY NAME tot_vend, tot_dema, tot_perd, total
	AFTER DISPLAY
		CONTINUE DISPLAY
	ON KEY(INTERRUPT)
		EXIT DISPLAY
	ON KEY(F8)
	LET fec_ini = MDY(i, 01, r_par.anho)
        LET fec_fin = MDY(i, 01, r_par.anho) + 1 UNITS MONTH - 1 UNITS DAY
		CALL fl_mostrar_movimientos_item(cod_cia, cod_loc, item, 
						r_par.bodega,
						r_par.r12_moneda,
						fec_ini, fec_fin)

		CONTINUE DISPLAY
END DISPLAY

END FUNCTION



FUNCTION fl_mostrar_movimientos_item(cod_cia, cod_loc, item, bodega, moneda, fec_ini, fec_fin)
DEFINE cod_cia		LIKE rept010.r10_compania
DEFINE cod_loc		LIKE rept019.r19_localidad
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
OPEN WINDOW w_mov AT 3,5 WITH FORM "../../../PRODUCCION/LIBRERIAS/forms/ayuf308"
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MESSAGE LINE LAST, BORDER)
ERROR "Generando consulta . . . espere por favor." ATTRIBUTE(NORMAL)
CALL fl_lee_item(cod_cia, item) RETURNING r_item.*
CALL fl_lee_moneda(moneda) RETURNING r_mon.*
CALL fl_lee_bodega_rep(cod_cia, bodega) RETURNING r_bod.*
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
	WHERE r20_compania = cod_cia AND r20_localidad = cod_loc AND 
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
	CALL fl_lee_cabecera_transaccion_rep(cod_cia, cod_loc, 
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
			       	cod_cia || ' ' ||
			       	cod_loc || ' ' || r_mov[i].tipo || ' ' ||
			       	r_mov[i].numero
			RUN comando
		ON KEY(F6)
			LET comando = 'fglrun repp108 ', vg_base, ' RE ', 
			               cod_cia, ' "',
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
