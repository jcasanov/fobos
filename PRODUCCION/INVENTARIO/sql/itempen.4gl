DATABASE aceros


DEFINE vg_codcia	LIKE gent001.g01_compania
DEFINE vg_codloc	LIKE gent002.g02_localidad
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE base		CHAR(20)
DEFINE serv		CHAR(20)
DEFINE expr_sql		CHAR(500)
DEFINE vm_expr_loc	VARCHAR(50)
DEFINE vm_stock_pend	SMALLINT



MAIN

	IF num_args() <> 6 THEN
		DISPLAY 'PARAMETROS INCORRECTOS. SON: BASE SERV CIA LOC CL/ITEM FLAG.'
		EXIT PROGRAM
	END IF
	LET base      = arg_val(1)
	LET serv      = arg_val(2)
	LET vg_codcia = arg_val(3)
	LET vg_codloc = arg_val(4)
	CALL activar_base(base, serv)
	LET vm_expr_loc = NULL
	CASE vg_codloc
		WHEN 1 LET codloc = 2
		WHEN 2 LET codloc = 1
		WHEN 3 LET codloc = 4
		WHEN 4 LET codloc = 3
	END CASE
	LET vm_expr_loc = ' r02_localidad IN (', vg_codloc, ', ', codloc, ')'
	CASE arg_val(6)
		WHEN 'C' CALL obtener_items_desde_cl()
		WHEN 'I' LET expr_sql = 'r10_codigo = "', arg_val(5) CLIPPED,'"'
	END CASE
	LET int_flag = 0
	RUN 'date'
	CALL ejecutar_carga_datos_temp()
	RUN 'date'
	IF arg_val(6) = 'C' THEN
		DROP TABLE tmp_ite_cl
	END IF
	IF int_flag THEN
		EXIT PROGRAM
	END IF
	CALL mostrar_detalle_item()
	DROP TABLE t_r11
	DROP TABLE t_bod
	DROP TABLE temp_item
	IF vm_stock_pend THEN
		DROP TABLE temp_pend
	END IF

END MAIN



FUNCTION activar_base(b, s)
DEFINE b, s		CHAR(20)
DEFINE base, base1	CHAR(20)
DEFINE r_g51		RECORD LIKE gent051.*

LET base  = b
LET base1 = base CLIPPED, '@', s
CLOSE DATABASE
WHENEVER ERROR CONTINUE
DATABASE base1
IF STATUS < 0 THEN
	DISPLAY 'No se pudo abrir base de datos: ', base1
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
INITIALIZE r_g51.* TO NULL
SELECT * INTO r_g51.* FROM gent051 WHERE g51_basedatos = base
IF r_g51.g51_basedatos IS NULL THEN
	DISPLAY 'No existe base de datos: ', base
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION obtener_items_desde_cl()
DEFINE num_tran		LIKE rept020.r20_num_tran

LET num_tran = arg_val(5)
SELECT r20_item item_p
	FROM rept020
	WHERE r20_compania  = vg_codcia
	  AND r20_localidad = vg_codloc
	  AND r20_cod_tran  = 'CL'
	  --AND r20_num_tran  >= num_tran
	  AND r20_num_tran  = num_tran
	INTO TEMP tmp_ite_cl
LET expr_sql = 'r10_codigo IN (SELECT * FROM tmp_ite_cl) '

END FUNCTION



FUNCTION ejecutar_carga_datos_temp()
DEFINE cuantos		INTEGER
DEFINE query		CHAR(1200)

DISPLAY 'Generando consulta . . . espere por favor'
SELECT r10_sec_item r10_codigo, r10_nombre, r11_stock_act stock_pend,
	r11_stock_act stock_tot, r11_stock_act stock_loc, r10_stock_max,
	r10_stock_min
	FROM rept010, rept011
	WHERE r10_compania  = 17
	  AND r11_compania  = r10_compania
	  AND r11_item      = r10_codigo
	INTO TEMP t_item
SELECT r10_codigo item, stock_loc stock_l
	FROM t_item
	INTO TEMP t_item_loc
SELECT r02_compania, r02_codigo, r02_nombre, r02_localidad
	FROM rept002
	WHERE r02_compania  = vg_codcia
	  AND r02_tipo     <> "S"
	INTO TEMP t_bod
LET query = ' SELECT r10_codigo, r10_nombre, 0 stock_p1, 0 stock_t1, ',
			' 0 stock_l1, r10_stock_max, r10_stock_min ',
		' FROM rept010 ',
		' WHERE r10_compania   = ', vg_codcia,
		'   AND ', expr_sql CLIPPED,
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
	DISPLAY 'No se encontraron registros.'
	DROP TABLE t_r11
	DROP TABLE t_bod
	DROP TABLE t_item
	LET int_flag = 1
	RETURN
END IF
LET vm_stock_pend = obtener_stock_pendiente()
IF NOT vm_stock_pend THEN
	DISPLAY 'No se encontraron registros pendientes.'
	DROP TABLE t_r11
	DROP TABLE t_bod
	DROP TABLE t_item
	LET vm_stock_pend = 0
	LET int_flag = 1
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

END FUNCTION



FUNCTION mostrar_detalle_item()
DEFINE r_ite		RECORD
				codigo		LIKE rept010.r10_codigo,
				nombre		LIKE rept010.r10_nombre,
				stock_pend	DECIMAL(10,2),
				stock_tot	DECIMAL(10,2),
				stock_loc	DECIMAL(10,2),
				sto_max		LIKE rept010.r10_stock_max,
				sto_min		LIKE rept010.r10_stock_min
			END RECORD
DEFINE i		SMALLINT

DECLARE q_item CURSOR FOR SELECT * FROM temp_item
DISPLAY ' '
LET i = 1
FOREACH q_item INTO r_ite.*
	DISPLAY 'ITEM: ', r_ite.codigo CLIPPED, ' ', r_ite.nombre CLIPPED
	DISPLAY '  Sto. Pend. ', r_ite.stock_pend USING "---,--&.##"
	DISPLAY '  Sto. Tot.  ', r_ite.stock_tot  USING "---,--&.##"
	DISPLAY '  Sto. Loc.  ', r_ite.stock_loc  USING "---,--&.##"
	DISPLAY ' '
	LET i = i + 1
END FOREACH
LET i = i - 1
IF i > 0 THEN
	DISPLAY 'Se encontraron un total de ', i USING "<<<<&", ' ITEMS. OK'
END IF

END FUNCTION



FUNCTION obtener_stock_pendiente()
DEFINE cuantos		INTEGER
DEFINE query		CHAR(800)

LET query = 'SELECT r02_codigo FROM rept002 ',
		' WHERE r02_compania  = ', vg_codcia,
		'   AND r02_localidad = ', vg_codloc,
		'   AND r02_factura   = "S" ',
		'   AND r02_tipo      = "S" ',
		' INTO TEMP t_bd1 '
PREPARE cons_bod FROM query
EXECUTE cons_bod
SELECT r20_cod_tran, r20_num_tran, DATE(r20_fecing) fecha, r20_bodega, r20_item,
		r20_cant_ven
	FROM rept020
	WHERE r20_compania   = vg_codcia
	  AND r20_localidad  = vg_codloc
	  AND r20_cod_tran   = "FA"
	  AND r20_bodega    IN (SELECT r02_codigo FROM t_bd1)
	  AND r20_item      IN (SELECT r10_codigo FROM t_item)
	INTO TEMP t_r20
SELECT r19_cod_tran, r19_num_tran, r19_nomcli
	FROM rept019
	WHERE r19_compania  = vg_codcia
	  AND r19_localidad = vg_codloc
	  AND r19_cod_tran  = "FA"
	  AND (r19_tipo_dev = "DF" OR r19_tipo_dev IS NULL)
	INTO TEMP t_r19
SELECT t_r20.*, r19_nomcli FROM t_r20, t_r19
	WHERE r19_cod_tran = r20_cod_tran
	  AND r19_num_tran = r20_num_tran
	INTO TEMP t1
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
		r34_num_ord_des, r19_nomcli
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
	r20_item, cantidad cant_pend, r19_nomcli
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
RETURN 1

END FUNCTION
