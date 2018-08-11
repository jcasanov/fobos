--------------------------------------------------------------------------------
-- Titulo           : repp244.4gl - Proceso de Prioridades de Entrega
-- Elaboracion      : 22 ene-2008
-- Autor            : NPC
-- Formato Ejecucion: fglrun repp244 base modulo compañía localidad
-- Ultima Correccion: 
-- Motivo Correccion: 
--------------------------------------------------------------------------------
GLOBALS '../../../PRODUCCION/LIBRERIAS/fuentes/globales.4gl'

DEFINE rm_orden 	ARRAY[10] OF CHAR(4)
DEFINE vm_columna_1	SMALLINT
DEFINE vm_columna_2	SMALLINT
DEFINE vm_size_arr	INTEGER
DEFINE rm_par 		RECORD
				codcli		LIKE cxct001.z01_codcli,
				nomcli		LIKE cxct001.z01_nomcli,
				item_p		LIKE rept010.r10_codigo,
				desc_item	LIKE rept010.r10_nombre,
				clase		LIKE rept072.r72_desc_clase
			END RECORD
DEFINE rm_detalle	ARRAY[3000] OF RECORD
				num_fact	LIKE rept019.r19_num_tran, 
				fec_fact	DATE,
				cliente		LIKE rept019.r19_nomcli, 
				item		LIKE rept020.r20_item,
				cant_pend	LIKE rept020.r20_cant_ven,
				cant_cruc	LIKE rept020.r20_cant_ven,
				prioridad	INTEGER
			END RECORD
DEFINE vm_max_rows	SMALLINT
DEFINE vm_num_rows	SMALLINT
DEFINE vm_stock_pend	SMALLINT
DEFINE vm_expr_loc	VARCHAR(50)
DEFINE rm_g01		RECORD LIKE gent001.*
DEFINE rm_g04		RECORD LIKE gent004.*
DEFINE rm_g05		RECORD LIKE gent005.*
DEFINE rm_r01		RECORD LIKE rept001.*



MAIN
	
DEFER QUIT
DEFER INTERRUPT
CLEAR SCREEN
CALL startlog('../logs/repp244.err')
--#CALL fgl_init4js()
CALL fl_marca_registrada_producto()
IF num_args() <> 4 THEN          -- Validar # parámetros correcto
	CALL fl_mostrar_mensaje('Número de parámetros incorrecto.','stop')
	EXIT PROGRAM
END IF
LET vg_base    = arg_val(1)
LET vg_modulo  = arg_val(2)
LET vg_codcia  = arg_val(3)
LET vg_codloc  = arg_val(4)
LET vg_proceso = 'repp244'
CALL fl_activar_base_datos(vg_base)
CALL fl_seteos_defaults()	
--#CALL fgl_settitle(vg_proceso || ' - ' || vg_producto)
CALL fl_validar_parametros()
CALL fl_cabecera_pantalla(vg_codcia, vg_codloc, vg_modulo, vg_proceso)
CALL funcion_master()

END MAIN



FUNCTION funcion_master()
DEFINE lin_menu		SMALLINT
DEFINE row_ini  	SMALLINT
DEFINE num_rows 	SMALLINT
DEFINE num_cols 	SMALLINT
DEFINE codloc		LIKE gent002.g02_localidad

CALL fl_lee_usuario(vg_usuario)             RETURNING rm_g05.*
CALL fl_lee_grupo_usuario(rm_g05.g05_grupo) RETURNING rm_g04.*
INITIALIZE rm_par.*, rm_r01.* TO NULL
DECLARE qu_vd CURSOR FOR
	SELECT * FROM rept001
		WHERE r01_compania   = vg_codcia
		  AND r01_estado     = 'A'
		  AND r01_user_owner = vg_usuario
OPEN qu_vd 
FETCH qu_vd INTO rm_r01.*
CLOSE qu_vd 
FREE qu_vd 
CALL fl_lee_compania(vg_codcia) RETURNING rm_g01.*
LET lin_menu = 0
LET row_ini  = 3
LET num_rows = 22
LET num_cols = 80
IF vg_gui = 0 THEN
	LET lin_menu = 1
	LET row_ini  = 4
	LET num_rows = 20
	LET num_cols = 78
END IF
OPEN WINDOW w_repf244_1 AT row_ini, 02 WITH num_rows ROWS, num_cols COLUMNS
	ATTRIBUTE(FORM LINE FIRST, COMMENT LINE LAST, MENU LINE lin_menu,
		  BORDER, MESSAGE LINE LAST) 
IF vg_gui = 1 THEN
	OPEN FORM f_repp244_1 FROM '../forms/repf244_1'
ELSE
	OPEN FORM f_repp244_1 FROM '../forms/repf244_1c'
END IF
DISPLAY FORM f_repp244_1
LET vm_max_rows = 3000
--#DISPLAY 'Factura'	TO tit_col1
--#DISPLAY 'Fecha Fact'	TO tit_col2
--#DISPLAY 'Cliente'	TO tit_col3
--#DISPLAY 'Item' 	TO tit_col4
--#DISPLAY 'Cant.Pend.'	TO tit_col5
--#DISPLAY 'Cant.Cruce'	TO tit_col6
--#DISPLAY 'Prio.' 	TO tit_col7
--#LET vm_size_arr = fgl_scr_size('rm_detalle')
IF vg_gui = 0 THEN
	LET vm_size_arr = 8
END IF
LET vm_expr_loc	      = NULL
CASE vg_codloc
	WHEN 1
		LET codloc = 2
	WHEN 2
		LET codloc = 1
	WHEN 3
		LET codloc = 4
	WHEN 4
		LET codloc = 3
END CASE
LET vm_expr_loc = ' r02_localidad IN (', vg_codloc, ', ', codloc, ')'
WHILE TRUE
	CALL borrar_pantalla()
	CALL lee_parametros1()
	IF int_flag THEN
		EXIT WHILE
	END IF
	CALL muestra_consulta()
	DROP TABLE t_r11
	DROP TABLE t_bod
	DROP TABLE temp_item
	IF vm_stock_pend THEN
		DROP TABLE temp_pend
	END IF
END WHILE
LET int_flag = 0
CLOSE WINDOW w_repf244_1
EXIT PROGRAM

END FUNCTION



FUNCTION borrar_pantalla()
DEFINE i		SMALLINT

LET vm_num_rows = 0
FOR i = 1 TO vm_size_arr 
	CLEAR rm_detalle[i].*
END FOR
CLEAR num_row, max_row, descrip_4, nom_item

END FUNCTION



FUNCTION lee_parametros1()
DEFINE r_z01		RECORD LIKE cxct001.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r72		RECORD LIKE rept072.*
DEFINE grupo_linea	LIKE gent020.g20_grupo_linea
DEFINE bodega_p		LIKE rept002.r02_codigo
DEFINE bodega		LIKE rept002.r02_codigo
DEFINE stock		LIKE rept011.r11_stock_act
DEFINE flag		SMALLINT

INITIALIZE grupo_linea, bodega_p TO NULL
LET int_flag = 0
INPUT BY NAME rm_par.*
	WITHOUT DEFAULTS
        ON KEY(INTERRUPT)
		LET int_flag = 1
		EXIT INPUT
        ON KEY(F1,CONTROL-W)
		CALL llamar_visor_teclas()
	ON KEY(F2)
		IF INFIELD(codcli) THEN
			CALL fl_ayuda_cliente_localidad(vg_codcia, vg_codloc)
				RETURNING r_z01.z01_codcli, r_z01.z01_nomcli
			IF r_z01.z01_codcli IS NOT NULL THEN
				LET rm_par.codcli = r_z01.z01_codcli
				LET rm_par.nomcli = r_z01.z01_nomcli
				DISPLAY BY NAME rm_par.codcli, rm_par.nomcli
			END IF
		END IF
		IF INFIELD(item_p) THEN
			CALL fl_ayuda_maestro_items_stock(vg_codcia,
							grupo_linea, bodega_p)
				RETURNING r_r10.r10_codigo, r_r10.r10_nombre,
					  r_r10.r10_linea, r_r10.r10_precio_mb,
					  bodega, stock
			IF r_r10.r10_codigo IS NOT NULL THEN
				CALL fl_retorna_clase_rep(vg_codcia,
							r_r10.r10_cod_clase)
					RETURNING r_r72.*, flag
				LET rm_par.clase     = r_r72.r72_desc_clase
				LET rm_par.item_p    = r_r10.r10_codigo
				LET rm_par.desc_item = r_r10.r10_nombre
				DISPLAY BY NAME rm_par.item_p, rm_par.desc_item,
						rm_par.clase
			END IF 
		END IF
		LET int_flag = 0
	BEFORE INPUT
		--#CALL dialog.keysetlabel("F1","")
		--#CALL dialog.keysetlabel("CONTROL-W","")
	AFTER FIELD codcli
		IF rm_par.codcli IS NOT NULL THEN
			CALL fl_lee_cliente_general(rm_par.codcli)
				RETURNING r_z01.*
			IF r_z01.z01_codcli IS NULL THEN
				CALL fl_mostrar_mensaje('Cliente no existe.', 'exclamation')
				NEXT FIELD codcli
			END IF
			IF r_z01.z01_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD codcli
			END IF
			LET rm_par.nomcli = r_z01.z01_nomcli
			DISPLAY BY NAME rm_par.nomcli
		ELSE
			LET rm_par.nomcli = NULL
			CLEAR nomcli
		END IF
	AFTER FIELD item_p 
		IF rm_par.item_p IS NOT NULL THEN
			CALL fl_lee_item(vg_codcia, rm_par.item_p)
				RETURNING r_r10.* 
			IF r_r10.r10_codigo IS NULL THEN
				CALL fl_mostrar_mensaje('El item no existe en la Compañía.','exclamation')
				NEXT FIELD item_p
			END IF
			IF r_r10.r10_estado = 'B' THEN
				CALL fl_mensaje_estado_bloqueado()
				NEXT FIELD item_p
			END IF
			CALL fl_retorna_clase_rep(vg_codcia,r_r10.r10_cod_clase)
				RETURNING r_r72.*, flag
			LET rm_par.clase     = r_r72.r72_desc_clase
			LET rm_par.desc_item = r_r10.r10_nombre
			DISPLAY BY NAME rm_par.desc_item, rm_par.clase
		ELSE
			LET rm_par.clase     = NULL
			LET rm_par.desc_item = NULL
			CLEAR desc_item, clase
		END IF
	AFTER INPUT
		IF rm_par.item_p IS NULL THEN
			LET rm_par.clase     = NULL
			LET rm_par.desc_item = NULL
			DISPLAY BY NAME rm_par.desc_item, rm_par.clase
		END IF
END INPUT
IF NOT int_flag THEN
	CALL ejecutar_carga_datos_temp()
END IF

END FUNCTION



FUNCTION ejecutar_carga_datos_temp()
DEFINE cuantos		INTEGER
DEFINE query		CHAR(1200)
DEFINE expr_item	VARCHAR(100)

ERROR 'Generando consulta . . . espere por favor' ATTRIBUTE(NORMAL)
LET expr_item = NULL
IF rm_par.item_p IS NOT NULL THEN
	LET expr_item = "   AND r10_codigo    = '", rm_par.item_p CLIPPED, "'"
END IF
SELECT r10_sec_item r10_codigo, r10_nombre, r11_stock_act stock_pend,
	r11_stock_act stock_tot, r11_stock_act stock_loc, r10_stock_max,
	r10_stock_min
	FROM rept010, rept011
	WHERE r10_compania  = 17
	  AND r11_compania  = r10_compania
	  AND r11_item      = r10_codigo
	INTO TEMP t_item
SELECT r10_codigo item, stock_loc stock_l FROM t_item INTO TEMP t_item_loc
SELECT r02_compania, r02_codigo, r02_nombre, r02_localidad
	FROM rept002
	WHERE r02_compania  = vg_codcia
	  AND r02_tipo     <> "S"
	INTO TEMP t_bod
LET query = ' SELECT r10_codigo, r10_nombre, 0 stock_p1, 0 stock_t1, ',
			' 0 stock_l1, r10_stock_max, r10_stock_min ',
		' FROM rept010 ',
		' WHERE r10_compania   = ', vg_codcia,
	          expr_item CLIPPED, 
		' INTO TEMP t_r10 '
PREPARE pre_r10 FROM query
EXECUTE pre_r10
LET query = ' SELECT r11_compania, r11_bodega, r11_item, r11_stock_act ',
		' FROM rept011 ',
		' WHERE r11_compania  = ', vg_codcia,
		'   AND r11_bodega   IN (SELECT r02_codigo FROM t_bod) ',
		'   AND r11_item     IN (SELECT r10_codigo FROM t_r10) ',
		' INTO TEMP t_r11 '
PREPARE pre_r11 FROM query
EXECUTE pre_r11
SELECT r11_item r10_codigo, NVL(SUM(r11_stock_act), 0) stock_t
	FROM t_r11
	GROUP BY 1
	INTO TEMP t_item_tot
LET query = 'INSERT INTO t_item_loc ',
		' SELECT r11_item, NVL(SUM(r11_stock_act), 0) stock_l ',
			' FROM t_r11 ',
			' WHERE r11_bodega IN (SELECT r02_codigo FROM t_bod ',
						' WHERE ', vm_expr_loc CLIPPED,
							') ',
			' GROUP BY 1'
PREPARE cit_loc FROM query
EXECUTE cit_loc
SELECT r10_codigo item_tl, stock_t, NVL(stock_l, 0) stock_l
	FROM t_item_tot, OUTER t_item_loc
	WHERE r10_codigo = item
	INTO TEMP t_totloc
DROP TABLE t_item_tot
DROP TABLE t_item_loc
INSERT INTO t_item
	SELECT r10_codigo, r10_nombre, stock_p1, stock_t, stock_l,
			r10_stock_max, r10_stock_min
		FROM t_r10, t_totloc
		WHERE r10_codigo = item_tl
DROP TABLE t_r10
DROP TABLE t_totloc
SELECT COUNT(*) INTO cuantos FROM t_item
IF cuantos = 0 THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET int_flag = 1
	DROP TABLE t_r11
	DROP TABLE t_bod
	DROP TABLE t_item
	RETURN
END IF
LET vm_stock_pend = obtener_stock_pendiente()
IF NOT vm_stock_pend THEN
	CALL fl_mensaje_consulta_sin_registros()
	LET int_flag = 1
	DROP TABLE t_r11
	DROP TABLE t_bod
	DROP TABLE t_item
	LET vm_stock_pend = 0
	RETURN
END IF
IF vm_stock_pend THEN
	LET query = ' SELECT r10_codigo, r10_nombre, ',
				' NVL(SUM(cant_pend), 0) stock_pend, ',
				'stock_tot, stock_loc, r10_stock_max, ',
				'r10_stock_min ',
			' FROM t_item, temp_pend',
			' WHERE r10_codigo = r20_item ',
			' GROUP BY 1, 2, 4, 5, 6, 7 ',
			' INTO TEMP temp_item'
	PREPARE pre_item FROM query
	EXECUTE pre_item
ELSE
	SELECT * FROM t_item INTO TEMP temp_item
END IF
DROP TABLE t_item
ERROR ' ' ATTRIBUTE(NORMAL)

END FUNCTION



FUNCTION muestra_consulta()
DEFINE r_adi		ARRAY[3000] OF RECORD
				codcli		LIKE rept019.r19_codcli
			END RECORD
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE cant_c		LIKE rept020.r20_cant_ven
DEFINE priori		INTEGER
DEFINE i, j, l, col	SMALLINT
DEFINE resul, salir	SMALLINT
DEFINE resp		CHAR(6)
DEFINE query		CHAR(3500)
DEFINE expr_cli		VARCHAR(100)

OPTIONS
	INSERT KEY F30,
	DELETE KEY F31
FOR i = 1 TO 10
	LET rm_orden[i] = '' 
END FOR
LET col                    = 2
LET vm_columna_1           = col
LET vm_columna_2           = 4
LET rm_orden[vm_columna_1] = 'ASC'
LET rm_orden[vm_columna_2] = 'ASC'
LET expr_cli = NULL
IF rm_par.codcli IS NOT NULL THEN
	LET expr_cli = ' WHERE r19_codcli = ', rm_par.codcli
END IF
LET query = 'SELECT r20_item item_c, cant_desp, ',
			'NVL(SUM(cant_pend), 0) cant_pend, r20_num_tran num_f,',
			' fecha, r19_codcli, r19_nomcli, 9999 prioridad ',
		' FROM temp_pend ',
		expr_cli CLIPPED,
		' GROUP BY 1, 2, 4, 5, 6, 7 ',
		' INTO TEMP tmp_cru '
PREPARE exec_cru FROM query
EXECUTE exec_cru
LET salir = 0
WHILE TRUE
	LET query = 'SELECT num_f, fecha, r19_nomcli, item_c, cant_pend, ',
				'0.00, 0, r19_codcli ',
			' FROM tmp_cru ',
	                ' ORDER BY ', vm_columna_1, ' ', rm_orden[vm_columna_1],
				', ', vm_columna_2, ' ', rm_orden[vm_columna_2] 
	PREPARE cons_fac FROM query
	DECLARE q_fact_c CURSOR FOR cons_fac
	LET vm_num_rows = 1
	FOREACH q_fact_c INTO rm_detalle[vm_num_rows].*, r_adi[vm_num_rows].*
		LET vm_num_rows = vm_num_rows + 1
		IF vm_num_rows > vm_max_rows THEN
			EXIT FOREACH
		END IF
	END FOREACH
	LET vm_num_rows = vm_num_rows - 1
	IF i = 0 THEN
		CALL fl_mensaje_consulta_sin_registros()
		EXIT WHILE
	END IF
	IF vg_gui = 0 THEN
		CALL muestra_contadores_det(1, vm_num_rows)
		DISPLAY r_adi[1].codcli       TO codcli
		DISPLAY rm_detalle[1].cliente TO nomcli
		CALL fl_lee_item(vg_codcia,rm_detalle[1].item) RETURNING r_r10.*
		CALL muestra_descripciones(r_r10.r10_codigo, r_r10.r10_linea,
					r_r10.r10_sub_linea,r_r10.r10_cod_grupo,
					r_r10.r10_cod_clase)
	END IF
	LET int_flag = 0
	CALL set_count(vm_num_rows)
	INPUT ARRAY rm_detalle WITHOUT DEFAULTS FROM rm_detalle.*
		ON KEY(INTERRUPT)
			LET int_flag = 0
			CALL fl_mensaje_abandonar_proceso() RETURNING resp
			IF resp = 'Yes' THEN
				LET int_flag = 1
				EXIT INPUT
			END IF
	    ON KEY(F1,CONTROL-W)
			CALL control_visor_teclas_caracter_1()
		ON KEY(F5)
			LET j = arr_curr()
			LET l = scr_line()
			CALL fl_ver_transaccion_rep(vg_codcia, vg_codloc,
						'FA', rm_detalle[j].num_fact)
			LET int_flag = 0
		ON KEY(F15)
			LET col = 1
			EXIT INPUT
		ON KEY(F16)
			LET col = 2
			EXIT INPUT
		ON KEY(F17)
			LET col = 3
			EXIT INPUT
		ON KEY(F18)
			LET col = 4
			EXIT INPUT
		ON KEY(F19)
			LET col = 5
			EXIT INPUT
		ON KEY(F20)
			LET col = 6
			EXIT INPUT
		ON KEY(F21)
			LET col = 7
			EXIT INPUT
		--#BEFORE INPUT
			--#CALL dialog.keysetlabel("INSERT","")
			--#CALL dialog.keysetlabel("DELETE","")
			--#CALL dialog.keysetlabel("F1","")
			--#CALL dialog.keysetlabel("CONTROL-W","")
		BEFORE DELETE	
			EXIT INPUT
		BEFORE INSERT
			EXIT INPUT	
		BEFORE ROW
			LET j = arr_curr()
			LET l = scr_line()
			CALL muestra_contadores_det(j, vm_num_rows)
			DISPLAY r_adi[j].codcli       TO codcli
			DISPLAY rm_detalle[j].cliente TO nomcli
			CALL fl_lee_item(vg_codcia, rm_detalle[j].item)
				RETURNING r_r10.*
			CALL muestra_descripciones(r_r10.r10_codigo,
					r_r10.r10_linea, r_r10.r10_sub_linea,
					r_r10.r10_cod_grupo,
					r_r10.r10_cod_clase)
		BEFORE FIELD cant_cruc
			LET cant_c = rm_detalle[j].cant_cruc
		BEFORE FIELD prioridad
			LET priori = rm_detalle[j].prioridad
		AFTER FIELD cant_cruc
			IF rm_detalle[j].cant_cruc IS NULL THEN
				LET rm_detalle[j].cant_cruc = cant_c
				DISPLAY rm_detalle[j].cant_cruc TO
					rm_detalle[l].cant_cruc
			END IF
			IF rm_detalle[j].cant_cruc > rm_detalle[j].cant_pend
			THEN
				CALL fl_mostrar_mensaje('La cantidad que se esta poniendo para el CRUCE AUTOMATICO es mayor que la cantidad pendiente de entrega.', 'exclamation')
				NEXT FIELD cant_cruc
			END IF
		AFTER FIELD prioridad
			IF rm_detalle[j].prioridad IS NULL THEN
				LET rm_detalle[j].prioridad = priori
				DISPLAY rm_detalle[j].prioridad TO
					rm_detalle[l].prioridad
			END IF
		AFTER INPUT
			LET salir = 1
	END INPUT
	IF salir THEN
		EXIT WHILE
	END IF
	IF int_flag = 1 THEN
		EXIT WHILE
	END IF
	IF col <> vm_columna_1 THEN
		LET vm_columna_2           = vm_columna_1 
		LET rm_orden[vm_columna_2] = rm_orden[vm_columna_1]
		LET vm_columna_1           = col 
	END IF
	IF rm_orden[vm_columna_1] = 'ASC' THEN
		LET rm_orden[vm_columna_1] = 'DESC'
	ELSE
		LET rm_orden[vm_columna_1] = 'ASC'
	END IF
END WHILE
DROP TABLE tmp_cru

END FUNCTION



FUNCTION muestra_contadores_det(num_row, max_row)
DEFINE num_row, max_row	SMALLINT

DISPLAY BY NAME num_row, max_row

END FUNCTION



FUNCTION obtener_bod_sin_stock()
DEFINE query		CHAR(800)

LET query = 'SELECT r02_codigo FROM rept002 ',
		' WHERE r02_compania  = ', vg_codcia,
		'   AND r02_localidad = ', vg_codloc,
		'   AND r02_factura   = "S" ',
		'   AND r02_tipo      = "S" ',
		'   AND r02_area      = "R" ',
		' INTO TEMP t_bd1 '
PREPARE cons_bod FROM query
EXECUTE cons_bod

END FUNCTION



FUNCTION obtener_stock_pendiente()
DEFINE cuantos		INTEGER
DEFINE query		CHAR(800)

CALL obtener_bod_sin_stock()
SELECT r20_cod_tran, r20_num_tran, DATE(r20_fecing) fecha, r20_bodega, r20_item,
		r20_cant_ven
	FROM rept020
	WHERE r20_compania   = vg_codcia
	  AND r20_localidad  = vg_codloc
	  AND r20_cod_tran  IN ("FA", "DF")
	  AND r20_bodega    IN (SELECT r02_codigo FROM t_bd1)
	  AND r20_item      IN (SELECT r10_codigo FROM t_item)
	INTO TEMP t_r20
SELECT r19_cod_tran, r19_num_tran, r19_codcli, r19_nomcli, r19_tipo_dev,
	r19_num_dev
	FROM rept019
	WHERE r19_compania   = vg_codcia
	  AND r19_localidad  = vg_codloc
	  AND r19_cod_tran   = "FA"
	  AND (r19_tipo_dev  = "DF" OR r19_tipo_dev IS NULL)
UNION ALL
SELECT r19_cod_tran, r19_num_tran, r19_codcli, r19_nomcli, r19_tipo_dev,
	r19_num_dev
	FROM rept019
	WHERE r19_compania   = vg_codcia
	  AND r19_localidad  = vg_codloc
	  AND r19_cod_tran   = "DF"
	INTO TEMP t_r19
SELECT c.*, d.r19_codcli, d.r19_nomcli
	FROM t_r20 c, t_r19 d
	WHERE d.r19_cod_tran = c.r20_cod_tran
	  AND d.r19_num_tran = c.r20_num_tran
	  AND c.r20_cod_tran = "FA"
	INTO TEMP t_f
SELECT a.r19_tipo_dev c_t, a.r19_num_dev n_t, b.r20_bodega bd, b.r20_item ite,
	b.r20_cant_ven cant
	FROM t_r19 a, t_r20 b
	WHERE a.r19_cod_tran = b.r20_cod_tran
	  AND a.r19_num_tran = b.r20_num_tran
	  AND b.r20_cod_tran = "DF"
	INTO TEMP t_d
SELECT r20_cod_tran, r20_num_tran, fecha, r20_bodega, r20_item, r20_cant_ven -
	NVL((SELECT SUM(cant)
		FROM t_d
		WHERE c_t = r20_cod_tran
		  AND n_t = r20_num_tran
		  AND bd  = r20_bodega
		  AND ite = r20_item), 0) r20_cant_ven, r19_codcli, r19_nomcli
	FROM t_f
	INTO TEMP t_t
DROP TABLE t_f
DROP TABLE t_d
SELECT * FROM t_t WHERE r20_cant_ven > 0 INTO TEMP t1
DROP TABLE t_t
DROP TABLE t_bd1
DROP TABLE t_r19
DROP TABLE t_r20
SELECT r34_compania, r34_localidad, r34_bodega, r34_num_ord_des, r34_cod_tran,
		r34_num_tran
	FROM rept034
	WHERE r34_compania   = vg_codcia
	  AND r34_localidad  = vg_codloc
	  AND r34_estado    IN ("A", "P")
	INTO TEMP t_r34
SELECT r20_cod_tran, r20_num_tran, fecha, r20_bodega, r20_item, r20_cant_ven,
		r34_num_ord_des, r19_codcli, r19_nomcli
	FROM t1, t_r34
	WHERE r34_compania  = vg_codcia
	  AND r34_localidad = vg_codloc
	  AND r34_bodega    = r20_bodega
	  AND r34_cod_tran  = r20_cod_tran
	  AND r34_num_tran  = r20_num_tran
	INTO TEMP t2
DROP TABLE t1
DROP TABLE t_r34
SELECT COUNT(*) INTO cuantos FROM t2
IF cuantos = 0 THEN
	DROP TABLE t2
	RETURN 0
END IF
SELECT UNIQUE r35_num_ord_des, r20_bodega bodega, r20_item item,
	SUM(r35_cant_des - r35_cant_ent) cantidad
	FROM rept035, t2
	WHERE r35_compania    = vg_codcia
	  AND r35_localidad   = vg_codloc
	  AND r35_bodega      = r20_bodega
	  AND r35_num_ord_des = r34_num_ord_des
	  AND r35_item        = r20_item
	GROUP BY 1, 2, 3
	HAVING SUM(r35_cant_des - r35_cant_ent) > 0
	INTO TEMP t3
SELECT UNIQUE r20_cod_tran, r20_num_tran, fecha, r35_num_ord_des, r20_bodega,
	r20_item, cantidad cant_pend, r19_codcli, r19_nomcli,
	cantidad cant_desp
	FROM t2, t3
	WHERE r20_bodega      = bodega
	  AND r20_item        = item
	  AND r35_num_ord_des = r34_num_ord_des
	INTO TEMP temp_pend
DROP TABLE t2
DROP TABLE t3
SELECT COUNT(*) INTO cuantos FROM temp_pend
IF cuantos = 0 THEN
	DROP TABLE temp_pend
	RETURN 0
END IF
--
SELECT a.r20_cod_tran, a.r20_num_tran, a.fecha, a.r35_num_ord_des, a.r20_bodega,
	a.r20_item, a.cant_pend, a.r19_codcli, a.r19_nomcli, a.cant_desp,
	NVL(SUM(c.r20_cant_ven), 0) * (-1) cant_tr
	FROM temp_pend a, OUTER rept019 b, rept020 c
	WHERE b.r19_compania   = vg_codcia
	  AND b.r19_localidad  = vg_codloc
	  AND b.r19_cod_tran   = 'TR'
	  AND b.r19_bodega_ori = a.r20_bodega
	  AND b.r19_tipo_dev   = a.r20_cod_tran
	  AND b.r19_num_dev    = a.r20_num_tran
	  AND c.r20_compania   = b.r19_compania
	  AND c.r20_localidad  = b.r19_localidad
	  AND c.r20_cod_tran   = b.r19_cod_tran
	  AND c.r20_num_tran   = b.r19_num_tran
	  AND c.r20_item       = a.r20_item
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
UNION
SELECT a.r20_cod_tran, a.r20_num_tran, a.fecha, a.r35_num_ord_des, a.r20_bodega,
	a.r20_item, a.cant_pend, a.r19_codcli, a.r19_nomcli, a.cant_desp,
	NVL(SUM(c.r20_cant_ven), 0) cant_tr
	FROM temp_pend a, OUTER rept019 b, rept020 c
	WHERE b.r19_compania    = vg_codcia
	  AND b.r19_localidad   = vg_codloc
	  AND b.r19_cod_tran    = 'TR'
	  AND b.r19_bodega_dest = a.r20_bodega
	  AND b.r19_tipo_dev    = a.r20_cod_tran
	  AND b.r19_num_dev     = a.r20_num_tran
	  AND c.r20_compania    = b.r19_compania
	  AND c.r20_localidad   = b.r19_localidad
	  AND c.r20_cod_tran    = b.r19_cod_tran
	  AND c.r20_num_tran    = b.r19_num_tran
	  AND c.r20_item        = a.r20_item
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
	INTO TEMP t4
DROP TABLE temp_pend
SELECT r20_cod_tran, r20_num_tran, fecha, r35_num_ord_des, r20_bodega,
	r20_item, cant_pend, r19_codcli, r19_nomcli, cant_desp,
	NVL(SUM(cant_tr), 0) cant_tr
	FROM t4
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
	INTO TEMP t5
DROP TABLE t4
SELECT r20_cod_tran, r20_num_tran, fecha, r35_num_ord_des, r20_bodega,
	r20_item, cant_pend - cant_tr cant_pend, r19_codcli, r19_nomcli,
	cant_desp - cant_tr cant_desp
	FROM t5
	INTO TEMP temp_pend
DROP TABLE t5
--
RETURN 1

END FUNCTION



FUNCTION muestra_descripciones(item, linea, sub_linea, cod_grupo, cod_clase)
DEFINE item		LIKE rept010.r10_codigo
DEFINE linea		LIKE rept010.r10_linea
DEFINE sub_linea	LIKE rept010.r10_sub_linea
DEFINE cod_grupo	LIKE rept010.r10_cod_grupo
DEFINE cod_clase	LIKE rept010.r10_cod_clase
DEFINE r_r03		RECORD LIKE rept003.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r70		RECORD LIKE rept070.*
DEFINE r_r71		RECORD LIKE rept071.*
DEFINE r_r72		RECORD LIKE rept072.*

CALL fl_lee_linea_rep(vg_codcia, linea) RETURNING r_r03.*
CALL fl_lee_sublinea_rep(vg_codcia, linea, sub_linea) RETURNING r_r70.*
CALL fl_lee_grupo_rep(vg_codcia, linea, sub_linea, cod_grupo)
	RETURNING r_r71.*
CALL fl_lee_clase_rep(vg_codcia, linea, sub_linea, cod_grupo, cod_clase)
	RETURNING r_r72.*
DISPLAY r_r72.r72_desc_clase TO descrip_4
CALL fl_lee_item(vg_codcia, item) RETURNING r_r10.*
DISPLAY r_r10.r10_nombre TO nom_item

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
DISPLAY '<F5>      Ver Factura'              AT a,2
DISPLAY  'F5' AT a,3 ATTRIBUTE(REVERSE)
LET a = a + 1
DISPLAY '<F6>      Imprimir'                 AT a,2
DISPLAY  'F6' AT a,3 ATTRIBUTE(REVERSE)
LET a = fgl_getkey()
CLOSE WINDOW w_tf

END FUNCTION
