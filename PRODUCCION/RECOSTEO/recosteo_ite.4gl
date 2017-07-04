DATABASE aceros


DEFINE db1		CHAR(20)
DEFINE serv1		CHAR(20)
DEFINE codcia1		LIKE gent001.g01_compania
DEFINE codloc1		LIKE gent002.g02_localidad
DEFINE visualizar	SMALLINT



MAIN

	IF num_args() <> 4 AND num_args() <> 5 THEN
		DISPLAY 'PARAMETROS INCORRECTOS. '
		DISPLAY 'SON: BASE1 SERVIDOR_BASE1 COMPAÑIA LOCALIDAD'
		EXIT PROGRAM
	END IF
	LET db1     = arg_val(1)
	LET serv1   = arg_val(2)
	LET codcia1 = arg_val(3)
	LET codloc1 = arg_val(4)
	LET visualizar = 0
	IF num_args() = 5 THEN
		LET visualizar = arg_val(5)
	END IF
	CALL activar_base(db1, serv1)
	CALL validar_parametros(codcia1, codloc1)
	CALL proceso_costeo()
	DISPLAY ' '
	DISPLAY 'Reproceso de Costo Terminado OK.'

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
	DISPLAY 'No existe base de datos: ', base, ' en la tabla gent051.'
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION validar_parametros(codcia, codloc)
DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE r_g01		RECORD LIKE gent001.*
DEFINE r_g02		RECORD LIKE gent002.*

INITIALIZE r_g01.*, r_g02.* TO NULL
SELECT * INTO r_g01.*
	FROM gent001
	WHERE g01_compania = codcia
IF r_g01.g01_compania IS NULL THEN
	DISPLAY 'No existe la compania ', codcia USING "<<<&", ' en la base.'
	EXIT PROGRAM
END IF
SELECT * INTO r_g02.*
	FROM gent002
	WHERE g02_compania  = codcia
	  AND g02_localidad = codloc
IF r_g02.g02_compania IS NULL THEN
	DISPLAY 'No existe la localidad ', codloc USING "<<<&", ' en la base.'
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION proceso_costeo()
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE ite_orl		LIKE rept010.r10_codigo
DEFINE posicion		INTEGER
DEFINE base1		CHAR(40)
DEFINE primero, unavez	SMALLINT
DEFINE i, j, l, k	SMALLINT

SET ISOLATION TO DIRTY READ
SELECT * FROM rept020 WHERE r20_compania = 999 INTO TEMP t1
CREATE TEMP TABLE t2
	(
		item		INTEGER
	)
SELECT item, t1.*
	FROM t1, t2
	WHERE r20_item = item
	INTO TEMP tmp_r20
DROP TABLE t1
DROP TABLE t2
INSERT INTO tmp_r20
	SELECT UNIQUE item, rept020.*
		FROM ite_cos_rea, rept020
		WHERE compania         = codcia1
		  AND r20_compania     = compania
		  AND r20_localidad    = codloc1
		  AND r20_item         = item
		  AND DATE(r20_fecing) BETWEEN MDY(01, 01, 2009)
					   AND MDY(12, 31, 2009)
DECLARE q_r20 CURSOR WITH HOLD FOR
	SELECT * FROM tmp_r20
		ORDER BY item, r20_fecing, r20_num_tran
LET primero = 1
LET base1   = db1 CLIPPED, '@', serv1 CLIPPED
DISPLAY ' '
DISPLAY ' Iniciando proceso principal de costeo en base: ', base1 CLIPPED
DISPLAY ' '
LET i = 0
LET j = 0
LET l = 0
LET k = 0
FOREACH q_r20 INTO ite_orl, r_r20.*
	INITIALIZE r_r19.* TO NULL
	SELECT * INTO r_r19.*
		FROM rept019
		WHERE r19_compania  = r_r20.r20_compania
		  AND r19_localidad = r_r20.r20_localidad
		  AND r19_cod_tran  = r_r20.r20_cod_tran
		  AND r19_num_tran  = r_r20.r20_num_tran
	IF NOT procesar_transf_ent(base1, r_r19.*, r_r20.r20_item) THEN
		LET l = l + 1
		CONTINUE FOREACH
	END IF
	IF r_r19.r19_cod_tran = 'TR' THEN
		CALL lee_bodega(base1, r_r19.r19_compania, r_r19.r19_bodega_ori)
			RETURNING r_r02.*
		IF r_r19.r19_localidad <> r_r02.r02_localidad THEN
			CALL actualizar_costo_ventas_ajustes_transf(base1,
								r_r19.*, 0,
								r_r20.r20_item)
			CALL registrar_transferencia_llegada(r_r19.*,
								r_r20.r20_item)
			LET unavez = 1
			WHILE TRUE
				IF NOT procesar_transf_sal(base1,
						r_r02.r02_localidad, r_r19.*,
						unavez, r_r20.r20_item)
				THEN
					LET unavez = 0
					CONTINUE WHILE
				END IF
				EXIT WHILE
			END WHILE
			LET k       = k + 1
			LET primero = 0
			CONTINUE FOREACH
		END IF
		CALL lee_bodega(base1, r_r19.r19_compania,r_r19.r19_bodega_dest)
			RETURNING r_r02.*
		IF r_r19.r19_localidad <> r_r02.r02_localidad THEN
			CALL actualizar_costo_ventas_ajustes_transf(base1,
								r_r19.*, 0,
								r_r20.r20_item)
			CALL registrar_transferencia_salida(r_r02.r02_localidad,
								r_r19.*,
								r_r20.r20_item)
			LET i = i + 1
			CONTINUE FOREACH
		END IF
	END IF
	CALL procesar_costo_transacciones(base1, r_r19.*, r_r20.r20_item)
	LET j = j + 1
END FOREACH
DROP TABLE tmp_r20
DISPLAY ' '
DISPLAY ' Terminado reproceso principal de costo en base: ', base1 CLIPPED
DISPLAY '  Total de ', j USING "<<<<&", '  Transacciones OK.'
DISPLAY '  Total de ', i USING "<<<<&", '   TRANSFERENCIAS ENTRADA OK.'
DISPLAY '  Total de ', k USING "<<<<&", '   TRANSFERENCIAS SALIDA OK.'
DISPLAY '  Total de ', l USING "<<<<&", '   Transacciones descartadas OK.'

END FUNCTION



FUNCTION procesar_transf_ent(base, r_r19, item_tr)
DEFINE base		CHAR(40)
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE item_tr		LIKE rept010.r10_codigo
DEFINE r_tr_e		RECORD LIKE trans_ent.*
DEFINE query		CHAR(400)

INITIALIZE r_tr_e.* TO NULL
LET query = 'SELECT * FROM ', base CLIPPED, ':trans_ent ',
		' WHERE compania   = ', r_r19.r19_compania,
		'   AND localidad  = ', r_r19.r19_localidad,
		'   AND cod_tran   = "', r_r19.r19_cod_tran, '"',
		'   AND num_tran   = ', r_r19.r19_num_tran,
		'   AND item_ent   = "', item_tr CLIPPED, '"'
PREPARE cons_r19_ent FROM query
DECLARE q_cons_r19_ent CURSOR FOR cons_r19_ent
OPEN q_cons_r19_ent
FETCH q_cons_r19_ent INTO r_tr_e.*
CLOSE q_cons_r19_ent
FREE q_cons_r19_ent
IF r_tr_e.compania IS NOT NULL THEN
	{--
	DISPLAY '  Transaccion ', r_r19.r19_localidad USING "&&", ' ',
		r_r19.r19_cod_tran, '-', r_r19.r19_num_tran USING "<<<<<<<&",
		' reprocesada en base: ', base CLIPPED, '.'
	DISPLAY ' '
	--}
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION procesar_transf_sal(base, loc_bod, r_r19, unavez, item_tr)
DEFINE base		CHAR(40)
DEFINE loc_bod		LIKE rept002.r02_localidad
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE unavez		SMALLINT
DEFINE item_tr		LIKE rept010.r10_codigo
DEFINE r_tr_s		RECORD LIKE trans_salida.*
DEFINE r_r90		RECORD LIKE rept090.*
DEFINE query		CHAR(1000)
DEFINE base2		CHAR(40)

INITIALIZE r_r90.*, r_tr_s.* TO NULL
CASE loc_bod
	WHEN 1 LET base2 = 'aceros@', serv1 CLIPPED, ':'
	WHEN 2 LET base2 = 'acero_gc@', serv1 CLIPPED, ':'
	WHEN 3 LET base2 = 'acero_qm@', serv1 CLIPPED, ':'
	WHEN 4 LET base2 = 'acero_qs@', serv1 CLIPPED, ':'
	WHEN 5 LET base2 = 'acero_qm@', serv1 CLIPPED, ':'
	OTHERWISE LET base2 = NULL
END CASE
LET query = 'SELECT * FROM rept090 ',
		' WHERE r90_compania   = ', r_r19.r19_compania,
		'   AND r90_locali_fin = ', r_r19.r19_localidad,
		'   AND r90_codtra_fin = "', r_r19.r19_cod_tran, '"',
		'   AND r90_numtra_fin = ', r_r19.r19_num_tran,
		' INTO TEMP t1 '
PREPARE exe_tra_rem2 FROM query
EXECUTE exe_tra_rem2
SELECT * INTO r_r90.* FROM t1
DROP TABLE t1
IF unavez THEN
	DISPLAY '  TR-Ent LOC: ', r_r19.r19_localidad USING "&&",
		' ITEM: ', item_tr CLIPPED,
		' TRAN: (', r_r19.r19_cod_tran, ')-',
		r_r19.r19_num_tran USING "<<<<<<&", '. Espera: ',
		r_r90.r90_localidad USING "&&", ' ',
		r_r90.r90_cod_tran, '-',
		r_r90.r90_num_tran USING "<<<<<<&"
	DISPLAY ' '
END IF
IF r_r90.r90_compania IS NULL THEN
	RETURN 0
END IF
LET query = 'SELECT * FROM ', base2 CLIPPED, 'trans_salida ',
		' WHERE compania    = ', r_r90.r90_compania,
		'   AND local_sal   = ', r_r90.r90_localidad,
		'   AND codtran_sal = "', r_r90.r90_cod_tran, '"',
		'   AND numtran_sal = ', r_r90.r90_num_tran,
		'   AND item_sal    = "', item_tr CLIPPED, '"'
PREPARE cons_r19_sal FROM query
DECLARE q_cons_r19_sal CURSOR FOR cons_r19_sal
OPEN q_cons_r19_sal
FETCH q_cons_r19_sal INTO r_tr_s.*
CLOSE q_cons_r19_sal
FREE q_cons_r19_sal
IF r_tr_s.compania IS NULL THEN
	RETURN 0
END IF
RETURN 1

END FUNCTION



FUNCTION lee_bodega(base, cod_cia, bodega)
DEFINE base		CHAR(40)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE bodega		LIKE rept002.r02_codigo
DEFINE query		CHAR(800)
DEFINE r_r02		RECORD LIKE rept002.*

INITIALIZE r_r02.* TO NULL
LET query = 'SELECT * FROM ', base CLIPPED, ':rept002 ',
		' WHERE r02_compania = ', cod_cia,
		'   AND r02_codigo   = "', bodega, '"',
		' INTO TEMP t1 '
PREPARE exe_bodega FROM query
EXECUTE exe_bodega
SELECT * INTO r_r02.* FROM t1
DROP TABLE t1
RETURN r_r02.*

END FUNCTION



FUNCTION registrar_transferencia_salida(loc_bod, r_r19, item_tr)
DEFINE loc_bod		LIKE rept002.r02_localidad
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE item_tr		LIKE rept010.r10_codigo
DEFINE r_r90		RECORD LIKE rept090.*
DEFINE query		CHAR(1000)
DEFINE base2		CHAR(40)

CASE loc_bod
	WHEN 1 LET base2 = 'aceros@', serv1 CLIPPED, ':'
	WHEN 2 LET base2 = 'acero_gc@', serv1 CLIPPED, ':'
	WHEN 3 LET base2 = 'acero_qm@', serv1 CLIPPED, ':'
	WHEN 4 LET base2 = 'acero_qs@', serv1 CLIPPED, ':'
	WHEN 5 LET base2 = 'acero_qm@', serv1 CLIPPED, ':'
	OTHERWISE LET base2 = NULL
END CASE
INITIALIZE r_r90.* TO NULL
LET query = 'SELECT * FROM ', base2 CLIPPED, 'rept090 ',
		' WHERE r90_compania  = ', r_r19.r19_compania,
		'   AND r90_localidad = ', r_r19.r19_localidad,
		'   AND r90_cod_tran  = "', r_r19.r19_cod_tran, '"',
		'   AND r90_num_tran  = ', r_r19.r19_num_tran,
		' INTO TEMP t1 '
PREPARE exe_tra_rem FROM query
EXECUTE exe_tra_rem
SELECT * INTO r_r90.* FROM t1
DROP TABLE t1
DISPLAY '  TR-Sal LOC: ', r_r19.r19_localidad USING "&&",
		' ITEM: ', item_tr CLIPPED,
		' TRAN: (', r_r19.r19_cod_tran, ')-',
		r_r19.r19_num_tran USING "<<<<<<&", '. Proce.: ',
		r_r90.r90_locali_fin USING "&&", ' ',
		r_r90.r90_codtra_fin, '-',
		r_r90.r90_numtra_fin USING "<<<<<<&"
	DISPLAY ' '
IF r_r90.r90_compania IS NULL THEN
	RETURN
END IF
LET query = 'INSERT INTO trans_salida ',
		'SELECT r90_compania, r90_locali_fin, r90_codtra_fin, ',
			'r90_numtra_fin, "', item_tr CLIPPED,
			'", r90_localidad, r90_cod_tran, r90_num_tran, "',
			item_tr CLIPPED, '", "FOBOS", ',
			'CURRENT ',
			' FROM ', base2 CLIPPED, 'rept090 ',
			' WHERE r90_compania  = ', r_r19.r19_compania,
			'   AND r90_localidad = ', r_r19.r19_localidad,
			'   AND r90_cod_tran  = "', r_r19.r19_cod_tran, '"',
			'   AND r90_num_tran  = ', r_r19.r19_num_tran
PREPARE exec_ins_te FROM query
EXECUTE exec_ins_te

END FUNCTION



FUNCTION registrar_transferencia_llegada(r_r19, item_tr)
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE item_tr		LIKE rept010.r10_codigo
DEFINE r_r90		RECORD LIKE rept090.*
DEFINE query		CHAR(1000)
DEFINE base2		CHAR(40)

INITIALIZE r_r90.* TO NULL
SELECT * INTO r_r90.*
	FROM rept090
	WHERE r90_compania   = r_r19.r19_compania
	  AND r90_locali_fin = r_r19.r19_localidad
	  AND r90_codtra_fin = r_r19.r19_cod_tran
	  AND r90_numtra_fin = r_r19.r19_num_tran
CASE r_r90.r90_localidad
	WHEN 1 LET base2 = 'aceros@', serv1 CLIPPED, ':'
	WHEN 2 LET base2 = 'acero_gc@', serv1 CLIPPED, ':'
	WHEN 3 LET base2 = 'acero_qm@', serv1 CLIPPED, ':'
	WHEN 4 LET base2 = 'acero_qs@', serv1 CLIPPED, ':'
	WHEN 5 LET base2 = 'acero_qm@', serv1 CLIPPED, ':'
	OTHERWISE LET base2 = NULL
END CASE
IF r_r90.r90_compania IS NULL THEN
	RETURN
END IF
LET query = 'INSERT INTO trans_salida ',
		'SELECT r90_compania, r90_locali_fin, r90_codtra_fin, ',
			'r90_numtra_fin, "', item_tr CLIPPED,
			'", r90_localidad, r90_cod_tran, r90_num_tran, "',
			item_tr CLIPPED, '", "FOBOS", ',
			'CURRENT ',
			' FROM ', base2 CLIPPED, 'rept090 ',
			' WHERE r90_compania   = ', r_r19.r19_compania,
			'   AND r90_locali_fin = ', r_r19.r19_localidad,
			'   AND r90_codtra_fin = "', r_r19.r19_cod_tran, '"',
			'   AND r90_numtra_fin = ', r_r19.r19_num_tran
PREPARE exec_ins_ts FROM query
EXECUTE exec_ins_ts
INSERT INTO trans_ent
	VALUES (r_r19.r19_compania, r_r19.r19_localidad, r_r19.r19_cod_tran,
		r_r19.r19_num_tran, item_tr, 'FOBOS', CURRENT)

END FUNCTION



FUNCTION obtener_item_trans_ant(base, posi, r_r20)
DEFINE base		CHAR(40)
DEFINE posi		INTEGER
DEFINE r_r20, r_r20_ant	RECORD LIKE rept020.*
DEFINE query		CHAR(800)

LET query = 'SELECT b.* ',
		' FROM ', base CLIPPED, ':rept019 a, ',
			base CLIPPED, ':rept020 b',
		' WHERE a.ROWID         <= ', posi,
		'   AND b.r20_compania   = a.r19_compania ',
		'   AND b.r20_localidad  = a.r19_localidad ',
		'   AND b.r20_cod_tran   = a.r19_cod_tran ',
		'   AND b.r20_num_tran   = a.r19_num_tran ',
		'   AND b.r20_bodega     = "', r_r20.r20_bodega, '"',
		'   AND b.r20_item       = "', r_r20.r20_item, '"',
		'   AND b.r20_orden      = ', r_r20.r20_orden,
		' ORDER BY r20_fecing DESC '
PREPARE tr_ant FROM query
DECLARE q_tr_ant CURSOR FOR tr_ant
INITIALIZE r_r20_ant.* TO NULL
OPEN q_tr_ant
FETCH q_tr_ant INTO r_r20_ant.*
CLOSE q_tr_ant
FREE q_tr_ant
RETURN r_r20_ant.*

END FUNCTION



FUNCTION obtener_item_trans_costo_ori(base, r_r19, r_r20)
DEFINE base		CHAR(40)
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE costo_ori	LIKE rept020.r20_costo
DEFINE query		CHAR(800)

LET query = 'SELECT NVL(r20_costo, 0) ',
		' FROM ', base CLIPPED, ':rept019, ',
			base CLIPPED, ':rept020 ',
		' WHERE r19_compania   = ', r_r19.r19_compania,
		'   AND r19_localidad  = ', r_r19.r19_localidad,
		'   AND r19_cod_tran   = "', r_r19.r19_cod_tran, '"',
		'   AND r19_num_tran   = ', r_r19.r19_num_tran,
		'   AND r20_compania   = r19_compania ',
		'   AND r20_localidad  = r19_localidad ',
		'   AND r20_cod_tran   = r19_cod_tran ',
		'   AND r20_num_tran   = r19_num_tran ',
		'   AND r20_bodega     = "', r_r20.r20_bodega, '"',
		'   AND r20_item       = "', r_r20.r20_item, '"',
		'   AND r20_orden      = ', r_r20.r20_orden
PREPARE tr_item_cos FROM query
DECLARE q_tr_item_cos CURSOR FOR tr_item_cos
OPEN q_tr_item_cos
FETCH q_tr_item_cos INTO costo_ori
CLOSE q_tr_item_cos
FREE q_tr_item_cos
RETURN costo_ori

END FUNCTION



FUNCTION obtiene_costo_item(base, cod_cia, cod_loc, moneda, item, cant_ing,
				costo_ing)
DEFINE base		CHAR(40)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE cod_loc		LIKE gent002.g02_localidad
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE item		LIKE rept010.r10_codigo
DEFINE cant_ing		LIKE rept011.r11_stock_act
DEFINE costo_ing	DECIMAL(12,2)
DEFINE stock		LIKE rept011.r11_stock_act
DEFINE tot_stock	LIKE rept011.r11_stock_act
DEFINE costo_act	DECIMAL(12,2)
DEFINE costo_nue	DECIMAL(12,2)
DEFINE r_rep		RECORD LIKE rept000.*
DEFINE r_art		RECORD LIKE rept010.*
DEFINE r_g00		RECORD LIKE gent000.*
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE ciudad		LIKE gent002.g02_ciudad
DEFINE codloc		LIKE gent002.g02_localidad
DEFINE query		CHAR(800)

INITIALIZE r_rep.*, r_g02.*, r_art.* TO NULL
LET query = 'SELECT * FROM ', base CLIPPED, ':rept000 ',
		' WHERE r00_compania = ', cod_cia,
		' INTO TEMP t1 '
PREPARE exe_r00 FROM query
EXECUTE exe_r00
SELECT * INTO r_rep.* FROM t1
DROP TABLE t1
IF r_rep.r00_tipo_costo <> 'P' THEN
	RETURN costo_ing
END IF
CALL obtener_localidad(base, cod_cia, cod_loc) RETURNING r_g02.*
LET ciudad = r_g02.g02_ciudad
LET query  = 'SELECT r02_localidad, r11_stock_act ',
			' FROM ', base CLIPPED, ':rept011, ',
				base CLIPPED, ':rept002 ',
			' WHERE r11_compania   = ', cod_cia,
		  	'   AND r11_item       = "', item, '"',
		  	'   AND r11_compania   = r02_compania ',
		  	'   AND r11_bodega     = r02_codigo ',
		  	'   AND r02_tipo      <> "S" ',
		  	'   AND r11_stock_act  > 0 '
PREPARE exe_gy_gy FROM query
DECLARE qy_gy CURSOR FOR exe_gy_gy
LET tot_stock = 0
FOREACH qy_gy INTO codloc, stock
	CALL obtener_localidad(base, cod_cia, cod_loc) RETURNING r_g02.*
	IF r_g02.g02_ciudad <> ciudad THEN
		CONTINUE FOREACH
	END IF
	LET tot_stock = tot_stock + stock
END FOREACH	
CALL obtener_configuracion(base) RETURNING r_g00.*
CALL obtener_item(base, cod_cia, item) RETURNING r_art.*
IF moneda = r_g00.g00_moneda_base THEN
	LET costo_act = r_art.r10_costo_mb
ELSE
	LET costo_act = r_art.r10_costo_ma
END IF
LET costo_nue = ((costo_act * tot_stock) + (costo_ing * cant_ing)) / 
		 (tot_stock + cant_ing)
CALL retorna_precision_valor(base, moneda, costo_nue) RETURNING costo_nue
RETURN costo_nue

END FUNCTION



FUNCTION retorna_precision_valor(base, moneda, valor)
DEFINE base		CHAR(40)
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE valor, val_aux	DECIMAL(16,4)
DEFINE query		CHAR(800)
DEFINE r		RECORD LIKE gent013.*

CALL obtener_moneda(base, moneda) RETURNING r.*
IF r.g13_moneda IS NULL THEN
	DISPLAY 'No existe moneda: ', moneda CLIPPED, '.'
	EXIT PROGRAM
END IF
LET val_aux = NULL
LET query   = 'SELECT ROUND(', valor, ', ', r.g13_decimales, ') valor_prec',
			' FROM ', base CLIPPED, ':dual ',
			' INTO TEMP t1 '
PREPARE exe_preci FROM query
EXECUTE exe_preci
SELECT * INTO val_aux FROM t1
DROP TABLE t1
RETURN val_aux

END FUNCTION



FUNCTION obtener_configuracion(base)
DEFINE base		CHAR(40)
DEFINE query		CHAR(800)
DEFINE r_g00		RECORD LIKE gent000.*

INITIALIZE r_g00.* TO NULL
LET query = 'SELECT * FROM ', base CLIPPED, ':gent000 ',
		' INTO TEMP t1 '
PREPARE exe_conf FROM query
EXECUTE exe_conf
SELECT * INTO r_g00.* FROM t1
DROP TABLE t1
RETURN r_g00.*

END FUNCTION



FUNCTION obtener_localidad(base, cod_cia, cod_loc)
DEFINE base		CHAR(40)
DEFINE cod_cia		LIKE gent001.g01_compania
DEFINE cod_loc		LIKE gent002.g02_localidad
DEFINE query		CHAR(800)
DEFINE r_g02		RECORD LIKE gent002.*

INITIALIZE r_g02.* TO NULL
LET query = 'SELECT * FROM ', base CLIPPED, ':gent002 ',
		' WHERE g02_compania  = ', cod_cia,
		'   AND g02_localidad = ', cod_loc,
		' INTO TEMP t1 '
PREPARE exe_loc FROM query
EXECUTE exe_loc
SELECT * INTO r_g02.* FROM t1
DROP TABLE t1
RETURN r_g02.*

END FUNCTION



FUNCTION obtener_item(base, cod_cia, item)
DEFINE base		CHAR(40)
DEFINE cod_cia		LIKE rept010.r10_compania
DEFINE item		LIKE rept010.r10_codigo
DEFINE query		CHAR(800)
DEFINE r_r10		RECORD LIKE rept010.*

INITIALIZE r_r10.* TO NULL
LET query = 'SELECT * FROM ', base CLIPPED, ':rept010 ',
		' WHERE r10_compania = ', cod_cia,
		'   AND r10_codigo   = "', item, '"',
		' INTO TEMP t1 '
PREPARE exe_item FROM query
EXECUTE exe_item
SELECT * INTO r_r10.* FROM t1
DROP TABLE t1
RETURN r_r10.*

END FUNCTION



FUNCTION obtener_moneda(base, moneda)
DEFINE base		CHAR(40)
DEFINE moneda		LIKE gent013.g13_moneda
DEFINE query		CHAR(800)
DEFINE r_g13		RECORD LIKE gent013.*

INITIALIZE r_g13.* TO NULL
LET query = 'SELECT * FROM ', base CLIPPED, ':gent013 ',
		' WHERE g13_moneda = "', moneda, '"',
		' INTO TEMP t1 '
PREPARE exe_mone FROM query
EXECUTE exe_mone
SELECT * INTO r_g13.* FROM t1
DROP TABLE t1
RETURN r_g13.*

END FUNCTION



FUNCTION comito_item(base, cod_cia, item)
DEFINE base		CHAR(40)
DEFINE cod_cia		LIKE rept010.r10_compania
DEFINE item		LIKE rept010.r10_codigo
DEFINE query		CHAR(800)

LET query = 'UPDATE ', base CLIPPED, ':rept010_res ',
		' SET r10_comito = "S" ',
		' WHERE r10_compania = ', cod_cia,
		'   AND r10_codigo   = "', item, '"'
PREPARE up_r10_res FROM query
EXECUTE up_r10_res
IF STATUS < 0 THEN
	DISPLAY '  Ha ocurrido un error al actualizar el registro: ',
		base CLIPPED, ' item: ', item CLIPPED, ' en rept010_res.'
	DISPLAY ' '
	WHENEVER ERROR STOP
	ROLLBACK WORK
	EXIT PROGRAM
END IF
IF STATUS = NOTFOUND THEN
	DISPLAY '  No se ha podido encontrar el registro: ',
		base CLIPPED, ' item: ', item CLIPPED, ' en rept010_res.'
	DISPLAY ' '
	WHENEVER ERROR STOP
	ROLLBACK WORK
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION comito_r20(base, r_r20)
DEFINE base		CHAR(40)
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE query		CHAR(800)

LET query = 'UPDATE ', base CLIPPED, ':rept020_res ',
		' SET r20_comito = "S" ',
		' WHERE r20_compania  = ', r_r20.r20_compania,
	  	'   AND r20_localidad = ', r_r20.r20_localidad,
	  	'   AND r20_cod_tran  = "', r_r20.r20_cod_tran, '"',
	  	'   AND r20_num_tran  = ', r_r20.r20_num_tran,
	  	'   AND r20_bodega    = "', r_r20.r20_bodega, '"',
	  	'   AND r20_item      = "', r_r20.r20_item, '"',
	  	'   AND r20_orden     = ', r_r20.r20_orden
PREPARE up_r20_res FROM query
EXECUTE up_r20_res
IF STATUS < 0 THEN
	DISPLAY '  Ha ocurrido un error al actualizar el registro: ',
		base CLIPPED, ' ', r_r20.r20_localidad USING "<<&", ' ',
		r_r20.r20_cod_tran, '-', r_r20.r20_num_tran USING "<<<<<<<&"
	DISPLAY '    item: ', r_r20.r20_item CLIPPED, ' en rept020_res.'
	DISPLAY ' '
	WHENEVER ERROR STOP
	ROLLBACK WORK
	EXIT PROGRAM
END IF
IF STATUS = NOTFOUND THEN
	DISPLAY '  No se ha podido encontrar el registro: ',
		base CLIPPED, ' ', r_r20.r20_localidad USING "<<&", ' ',
		r_r20.r20_cod_tran, '-', r_r20.r20_num_tran USING "<<<<<<<&"
	DISPLAY '    item: ', r_r20.r20_item CLIPPED, ' en rept020_res.'
	DISPLAY ' '
	WHENEVER ERROR STOP
	ROLLBACK WORK
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION comito_r19(base, r_r19)
DEFINE base		CHAR(40)
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE query		CHAR(800)

LET query = 'UPDATE ', base CLIPPED, ':rept019_res ',
		' SET r19_comito = "S" ',
		' WHERE r19_compania  = ', r_r19.r19_compania,
	  	'   AND r19_localidad = ', r_r19.r19_localidad,
	  	'   AND r19_cod_tran  = "', r_r19.r19_cod_tran, '"',
	  	'   AND r19_num_tran  = ', r_r19.r19_num_tran
PREPARE up_r19_res FROM query
EXECUTE up_r19_res
IF STATUS < 0 THEN
	DISPLAY '  Ha ocurrido un error al actualizar el registro: ',
		base CLIPPED, ' ', r_r19.r19_localidad USING "<<&", ' ',
		r_r19.r19_cod_tran, '-', r_r19.r19_num_tran USING "<<<<<<<&",
		' en rept019_res.'
	DISPLAY ' '
	WHENEVER ERROR STOP
	ROLLBACK WORK
	EXIT PROGRAM
END IF
IF STATUS = NOTFOUND THEN
	DISPLAY '  No se ha podido encontrar el registro: ',
		base CLIPPED, ' ', r_r19.r19_localidad USING "<<&", ' ',
		r_r19.r19_cod_tran, '-', r_r19.r19_num_tran USING "<<<<<<<&",
		' en rept019_res.'
	DISPLAY ' '
	WHENEVER ERROR STOP
	ROLLBACK WORK
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION sicomito_r19(base1, r_r19)
DEFINE base1		CHAR(40)
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE sicomito		LIKE rept019_res.r19_comito
DEFINE query		CHAR(300)

LET query = 'SELECT r19_comito ',
		' FROM ', base1 CLIPPED, ':rept019_res ',
		' WHERE r19_compania  = ', r_r19.r19_compania,
	  	'   AND r19_localidad = ', r_r19.r19_localidad,
	  	'   AND r19_cod_tran  = "', r_r19.r19_cod_tran, '"',
	  	'   AND r19_num_tran  = ', r_r19.r19_num_tran,
		' INTO TEMP t1 '
PREPARE sel_r19_res FROM query
EXECUTE sel_r19_res
SELECT * INTO sicomito FROM t1
DROP TABLE t1
IF sicomito = 'S' THEN
	{--
	DISPLAY '     No se pudo reprocesar esta trans., esta comitada.'
	DISPLAY '       Llegada: ', r_r19.r19_cod_tran, '-',
		r_r19.r19_num_tran USING "<<<<<<<&"
	--}
	RETURN 1
END IF
RETURN 0

END FUNCTION



FUNCTION sicomito_r10(base1, codcia, item)
DEFINE base1		CHAR(40)
DEFINE codcia		LIKE rept010.r10_compania
DEFINE item		LIKE rept010.r10_codigo
DEFINE sicomito		LIKE rept019_res.r19_comito
DEFINE query		CHAR(300)

LET query = 'SELECT r10_comito ',
		' FROM ', base1 CLIPPED, ':rept010_res ',
		' WHERE r10_compania = ', codcia,
	  	'   AND r10_codigo   = "', item, '"',
		' INTO TEMP t1 '
PREPARE sel_r10_res FROM query
EXECUTE sel_r10_res
SELECT * INTO sicomito FROM t1
DROP TABLE t1
IF sicomito = 'S' THEN
	RETURN 1
ELSE
	RETURN 0
END IF

END FUNCTION



FUNCTION procesar_costo_transacciones(base, r_r19, item)
DEFINE base		CHAR(40)
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE item		LIKE rept010.r10_codigo

CASE r_r19.r19_cod_tran
	WHEN 'A+'
		CALL actualizar_costo_ventas_ajustes_transf(base, r_r19.*, 0, item)
	WHEN 'A-'
		CALL actualizar_costo_ventas_ajustes_transf(base, r_r19.*, 0, item)
	WHEN 'AC'
		CALL actualizar_costo_compras_ajucos_imp(base, r_r19.*, item)
	WHEN 'AF'
		CALL actualizar_costo_dev_ventas(base, r_r19.*, item)
	WHEN 'CL'
		CALL actualizar_costo_compras_ajucos_imp(base, r_r19.*, item)
	WHEN 'DC'
		CALL actualizar_costo_dev_compras(base, r_r19.*, item)
	WHEN 'DF'
		CALL actualizar_costo_dev_ventas(base, r_r19.*, item)
	WHEN 'FA'
		CALL actualizar_costo_ventas_ajustes_transf(base, r_r19.*, 0, item)
	WHEN 'IM'
		CALL actualizar_costo_compras_ajucos_imp(base, r_r19.*, item)
	WHEN 'TR'
		CALL actualizar_costo_ventas_ajustes_transf(base, r_r19.*, 0, item)
END CASE

END FUNCTION



FUNCTION actualizar_costo_ventas_ajustes_transf(base, r_tr_ori, flag, item)
DEFINE base		CHAR(40)
DEFINE r_tr_ori		RECORD LIKE rept019.*
DEFINE flag		SMALLINT
DEFINE item		LIKE rept010.r10_codigo
DEFINE r_g21		RECORD LIKE gent021.*
DEFINE r_r02_o, r_r02_d	RECORD LIKE rept002.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20, r_r20_ant	RECORD LIKE rept020.*
DEFINE query		CHAR(1200)
DEFINE posi, unavez	INTEGER

CALL obtener_transaccion(base, r_tr_ori.r19_cod_tran) RETURNING r_g21.*
IF visualizar THEN
	DISPLAY '    Conectando base: ', base CLIPPED
	DISPLAY '    Obteniendo ', r_g21.g21_nombre CLIPPED, ' de origen ...'
END IF
INITIALIZE r_r19.*, r_r20.* TO NULL
SET LOCK MODE TO WAIT 5
BEGIN WORK
WHENEVER ERROR CONTINUE
CALL query_detalle_trans(base, r_tr_ori.*, 0, item) RETURNING query
PREPARE tr_vta FROM query
DECLARE q_tr_vta CURSOR WITH HOLD FOR tr_vta
OPEN q_tr_vta
FETCH q_tr_vta INTO r_r19.*, r_r20.*, posi
CLOSE q_tr_vta
IF flag AND sicomito_r19(base, r_r19.*) THEN
	WHENEVER ERROR STOP
	ROLLBACK WORK
	RETURN
END IF
LET unavez = 1
FOREACH q_tr_vta INTO r_r19.*, r_r20.*, posi
	CALL lee_bodega(base, r_tr_ori.r19_compania, r_tr_ori.r19_bodega_ori)
		RETURNING r_r02_o.*
	CALL lee_bodega(base, r_tr_ori.r19_compania, r_tr_ori.r19_bodega_dest)
		RETURNING r_r02_d.*
	IF (r_r19.r19_localidad = r_r02_o.r02_localidad) AND
	   (r_r19.r19_localidad = r_r02_d.r02_localidad)
	THEN
		DISPLAY '         LOC: ', r_r20.r20_localidad USING "&&",
			' ITEM: ', r_r20.r20_item CLIPPED,
			' TRAN: (', r_r20.r20_cod_tran, ')-',
			r_r20.r20_num_tran USING "<<<<<<&"
	END IF
	IF unavez THEN
		LET unavez              = 0
		LET r_r19.r19_tot_costo = 0
	END IF
	CALL obtener_item(base, r_r20.r20_compania, r_r20.r20_item)
		RETURNING r_r10.*
	CALL obtener_item_trans_ant(base, posi, r_r20.*) RETURNING r_r20_ant.*
	LET r_r20.r20_costant_mb = r_r20_ant.r20_costo
	IF sicomito_r10(base, r_r20.r20_compania, r_r20.r20_item) THEN
		LET r_r20.r20_costnue_mb = r_r10.r10_costo_mb
		LET r_r20.r20_costo      = r_r10.r10_costo_mb
	END IF
	CALL actualizar_rept020(base, r_r20.*)
	LET r_r19.r19_tot_costo = r_r19.r19_tot_costo + (r_r20.r20_cant_ven *
				  r_r20.r20_costo)
END FOREACH
IF visualizar THEN
	--DISPLAY '    El nuevo costo para esta trans. es: ', r_r19.r19_tot_costo USING "---,---,--&.##"
END IF
CALL validar_costo_r19(base, r_r19.*)
IF r_r19.r19_cod_tran <> 'FA' AND r_r19.r19_tot_costo > 0 THEN
	LET r_r19.r19_tot_neto = r_r19.r19_tot_costo
END IF
CALL actualizar_rept019(base, r_r19.*, 1)
WHENEVER ERROR STOP
COMMIT WORK
IF r_r19.r19_cod_tran = 'FA' OR r_r19.r19_cod_tran = 'TR' THEN
	--CALL actualizar_diario_contable_trans(base, r_r19.*)
END IF

END FUNCTION



FUNCTION actualizar_costo_dev_ventas(base, r_tr_ori, item)
DEFINE base		CHAR(40)
DEFINE r_tr_ori		RECORD LIKE rept019.*
DEFINE item		LIKE rept010.r10_codigo
DEFINE r_g21		RECORD LIKE gent021.*
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20 		RECORD LIKE rept020.*
DEFINE r_r20_fact	RECORD LIKE rept020.*
DEFINE costo_nue	DECIMAL(12,2)
DEFINE query		CHAR(1200)
DEFINE posi, unavez	INTEGER

CALL obtener_transaccion(base, r_tr_ori.r19_cod_tran) RETURNING r_g21.*
IF visualizar THEN
	DISPLAY '    Conectando base: ', base CLIPPED
	DISPLAY '    Obteniendo ', r_g21.g21_nombre CLIPPED, ' de origen ...'
END IF
INITIALIZE r_r19.*, r_r20.* TO NULL
SET LOCK MODE TO WAIT 5
BEGIN WORK
WHENEVER ERROR CONTINUE
CALL query_detalle_trans(base, r_tr_ori.*, 0, item) RETURNING query
PREPARE tr_dev_vta FROM query
DECLARE q_tr_dev_vta CURSOR WITH HOLD FOR tr_dev_vta
LET unavez = 1
FOREACH q_tr_dev_vta INTO r_r19.*, r_r20.*, posi
	DISPLAY '         LOC: ', r_r20.r20_localidad USING "&&",
		' ITEM: ', r_r20.r20_item CLIPPED,
		' TRAN: (', r_r20.r20_cod_tran, ')-',
		r_r20.r20_num_tran USING "<<<<<<&"
	IF unavez THEN
		LET unavez              = 0
		LET r_r19.r19_tot_costo = 0
	END IF
	CALL obtener_item_fact(base, r_r19.*, r_r20.*) RETURNING r_r20_fact.*
	LET r_r20.r20_costo      = r_r20_fact.r20_costo
	LET r_r20.r20_costant_mb = r_r20_fact.r20_costant_mb
	LET r_r20.r20_costant_ma = r_r20_fact.r20_costant_ma
	LET r_r20.r20_costnue_mb = r_r20_fact.r20_costnue_mb
	LET r_r20.r20_costnue_ma = r_r20_fact.r20_costnue_ma
	CALL obtiene_costo_item(base, r_r20.r20_compania, r_r20.r20_localidad,
				r_r19.r19_moneda, r_r20.r20_item,
				r_r20.r20_cant_ven, r_r20.r20_costo)
		RETURNING costo_nue
	IF costo_nue = 0 THEN
		DISPLAY '  Error al actualizar el nuevo costo en: ',
			base CLIPPED, ' ', r_r20.r20_localidad USING "<<&", ' ',
			r_r20.r20_cod_tran, '-',
			r_r20.r20_num_tran USING "<<<<<<<&"
		DISPLAY '   item: ', r_r20.r20_item CLIPPED, ' en rept020',
			' tiene costo CERO.'
		DISPLAY ' '
		WHENEVER ERROR STOP
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	CALL obtener_item(base, r_r20.r20_compania, r_r20.r20_item)
		RETURNING r_r10.*
	IF r_r10.r10_costo_mb <> costo_nue THEN
		LET r_r10.r10_costo_mb   = costo_nue
		LET r_r10.r10_costult_mb = r_r20.r20_costo
		CALL actualizar_rept010(base, r_r10.*, r_r20.*)
	ELSE
		CALL comito_item(base, r_r20.r20_compania, r_r20.r20_item)
	END IF
	CALL actualizar_rept020(base, r_r20.*)
	LET r_r19.r19_tot_costo = r_r19.r19_tot_costo + (r_r20.r20_cant_ven *
				  r_r20.r20_costo)
END FOREACH
IF visualizar THEN
	--DISPLAY '    El nuevo costo para esta trans. es: ',r_r19.r19_tot_costo USING "---,---,--&.##"
END IF
CALL validar_costo_r19(base, r_r19.*)
CALL actualizar_rept019(base, r_r19.*, 1)
WHENEVER ERROR STOP
COMMIT WORK
IF r_r19.r19_cod_tran = 'DF' THEN
	--CALL actualizar_diario_contable_trans(base, r_r19.*)
END IF

END FUNCTION



FUNCTION actualizar_costo_compras_ajucos_imp(base, r_tr_ori, item)
DEFINE base		CHAR(40)
DEFINE r_tr_ori		RECORD LIKE rept019.*
DEFINE item		LIKE rept010.r10_codigo
DEFINE r_g21		RECORD LIKE gent021.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20 		RECORD LIKE rept020.*
DEFINE r_r10 		RECORD LIKE rept010.*
DEFINE query		CHAR(1200)
DEFINE posi, unavez	INTEGER

CALL obtener_transaccion(base, r_tr_ori.r19_cod_tran) RETURNING r_g21.*
IF visualizar THEN
	DISPLAY '    Conectando base: ', base CLIPPED
	DISPLAY '    Obteniendo ', r_g21.g21_nombre CLIPPED, ' de origen ...'
END IF
INITIALIZE r_r19.*, r_r20.* TO NULL
SET LOCK MODE TO WAIT 5
BEGIN WORK
WHENEVER ERROR CONTINUE
CALL query_detalle_trans(base, r_tr_ori.*, 0, item) RETURNING query
PREPARE tr_comp FROM query
DECLARE q_tr_comp CURSOR WITH HOLD FOR tr_comp
LET unavez = 1
FOREACH q_tr_comp INTO r_r19.*, r_r20.*, posi
	DISPLAY '         LOC: ', r_r20.r20_localidad USING "&&",
		' ITEM: ', r_r20.r20_item CLIPPED,
		' TRAN: (', r_r20.r20_cod_tran, ')-',
		r_r20.r20_num_tran USING "<<<<<<&"
	IF unavez THEN
		LET unavez              = 0
		LET r_r19.r19_tot_costo = 0
	END IF
	CALL obtener_item_trans_costo_ori(base, r_tr_ori.*, r_r20.*)
		RETURNING r_r20.r20_costant_mb
	CALL actualizar_rept020(base, r_r20.*)
	IF r_r20.r20_costo = 0 THEN
		IF r_r20.r20_cod_tran <> 'AC' THEN
			LET r_r20.r20_costo = r_r20.r20_costnue_mb
		ELSE
			LET r_r20.r20_costo = r_r20.r20_costant_mb
		END IF
	ELSE
		CALL obtener_item(base, r_r20.r20_compania, r_r20.r20_item)
			RETURNING r_r10.*
		IF sicomito_r10(base, r_r20.r20_compania, r_r20.r20_item) THEN
			IF r_r20.r20_cod_tran <> 'AC' THEN
				LET r_r20.r20_costo      = r_r10.r10_costo_mb
			ELSE
				LET r_r20.r20_costnue_mb = r_r10.r10_costo_mb
			END IF
		END IF
	END IF
	IF r_r20.r20_cod_tran <> 'AC' THEN
		LET r_r19.r19_tot_costo = r_r19.r19_tot_costo +
				(r_r20.r20_cant_ven * r_r20.r20_costo)
	ELSE
		LET r_r19.r19_tot_costo = r_r19.r19_tot_costo +
				(r_r20.r20_cant_ven * r_r20.r20_costnue_mb)
	END IF
END FOREACH
IF visualizar THEN
	--DISPLAY '    El nuevo costo para esta trans. es: ', r_r19.r19_tot_costo USING "---,---,--&.##"
END IF
CALL validar_costo_r19(base, r_r19.*)
IF r_r19.r19_cod_tran = 'AC' AND r_r19.r19_tot_costo > 0 THEN
	LET r_r19.r19_tot_neto = r_r19.r19_tot_costo
END IF
CALL actualizar_rept019(base, r_r19.*, 1)
WHENEVER ERROR STOP
COMMIT WORK

END FUNCTION



FUNCTION actualizar_costo_dev_compras(base, r_tr_ori, item)
DEFINE base		CHAR(40)
DEFINE r_tr_ori		RECORD LIKE rept019.*
DEFINE item		LIKE rept010.r10_codigo
DEFINE r_g21		RECORD LIKE gent021.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20 		RECORD LIKE rept020.*
DEFINE r_r20_fact	RECORD LIKE rept020.*
DEFINE query		CHAR(1200)
DEFINE posi, unavez	INTEGER

CALL obtener_transaccion(base, r_tr_ori.r19_cod_tran) RETURNING r_g21.*
IF visualizar THEN
	DISPLAY '    Conectando base: ', base CLIPPED
	DISPLAY '    Obteniendo ', r_g21.g21_nombre CLIPPED, ' de origen ...'
END IF
INITIALIZE r_r19.*, r_r20.* TO NULL
SET LOCK MODE TO WAIT 5
BEGIN WORK
WHENEVER ERROR CONTINUE
CALL query_detalle_trans(base, r_tr_ori.*, 0, item) RETURNING query
PREPARE tr_dev_comp FROM query
DECLARE q_tr_dev_comp CURSOR WITH HOLD FOR tr_dev_comp
LET unavez = 1
FOREACH q_tr_dev_comp INTO r_r19.*, r_r20.*, posi
	DISPLAY '         LOC: ', r_r20.r20_localidad USING "&&",
		' ITEM: ', r_r20.r20_item CLIPPED,
		' TRAN: (', r_r20.r20_cod_tran, ')-',
		r_r20.r20_num_tran USING "<<<<<<&"
	IF unavez THEN
		LET unavez              = 0
		LET r_r19.r19_tot_costo = 0
	END IF
	CALL obtener_item_fact(base, r_r19.*, r_r20.*) RETURNING r_r20_fact.*
	LET r_r20.r20_costo      = r_r20_fact.r20_costo
	LET r_r20.r20_costnue_mb = r_r20_fact.r20_costnue_mb
	LET r_r20.r20_costnue_ma = r_r20_fact.r20_costnue_ma
	CALL obtener_item_trans_costo_ori(base, r_tr_ori.*, r_r20.*)
		RETURNING r_r20.r20_costant_mb
	CALL actualizar_rept020(base, r_r20.*)
	LET r_r19.r19_tot_costo = r_r19.r19_tot_costo + (r_r20.r20_cant_ven *
				  r_r20.r20_costo)
END FOREACH
IF visualizar THEN
	--DISPLAY '    El nuevo costo para esta trans. es: ', r_r19.r19_tot_costo USING "---,---,--&.##"
END IF
CALL validar_costo_r19(base, r_r19.*)
IF r_r19.r19_tot_costo > 0 THEN
	LET r_r19.r19_tot_neto = r_r19.r19_tot_costo
END IF
CALL actualizar_rept019(base, r_r19.*, 1)
WHENEVER ERROR STOP
COMMIT WORK

END FUNCTION



FUNCTION validar_costo_r19(base, r_r19)
DEFINE base		CHAR(40)
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE query		CHAR(300)
DEFINE t_costo		LIKE rept019.r19_tot_costo

IF r_r19.r19_tot_costo > 0 THEN
	RETURN
END IF
LET query = 'SELECT NVL(r19_tot_costo, 0) tot_costo ',
		' FROM ', base CLIPPED, ':rept019_res ',
		' WHERE r19_compania  = ', r_r19.r19_compania,
		'   AND r19_localidad = ', r_r19.r19_localidad,
		'   AND r19_cod_tran  = "', r_r19.r19_cod_tran, '"',
		'   AND r19_num_tran  = ', r_r19.r19_num_tran,
		' INTO TEMP t1 '
PREPARE exe_r19_res FROM query
EXECUTE exe_r19_res
SELECT * INTO t_costo FROM t1
DROP TABLE t1
IF t_costo = 0 THEN
	IF visualizar THEN
		DISPLAY '    El costo total en rept019 no puede ser CERO.',
			r_r19.r19_cod_tran, '-',
			r_r19.r19_num_tran USING "<<<<<<&",
			' costo ', t_costo USING "###,##&.##"
		DISPLAY ' '
	END IF
	RETURN
END IF
WHENEVER ERROR STOP
ROLLBACK WORK
EXIT PROGRAM

END FUNCTION



FUNCTION obtener_transaccion(base, cod_tran)
DEFINE base		CHAR(40)
DEFINE cod_tran		LIKE gent021.g21_cod_tran
DEFINE query		CHAR(800)
DEFINE r_g21		RECORD LIKE gent021.*

INITIALIZE r_g21.* TO NULL
LET query = 'SELECT * FROM ', base CLIPPED, ':gent021 ',
		' WHERE g21_cod_tran = "', cod_tran, '"',
		' INTO TEMP t1 '
PREPARE exe_trans FROM query
EXECUTE exe_trans
SELECT * INTO r_g21.* FROM t1
DROP TABLE t1
RETURN r_g21.*

END FUNCTION



FUNCTION query_detalle_trans(base, r_tr_ori, flag, item)
DEFINE base		CHAR(40)
DEFINE r_tr_ori		RECORD LIKE rept019.*
DEFINE flag		SMALLINT
DEFINE item		LIKE rept010.r10_codigo
DEFINE expr_fro		CHAR(50)
DEFINE expr_sql		CHAR(500)
DEFINE query		CHAR(1500)

LET expr_fro = NULL
LET expr_sql = ' WHERE a.r19_compania  = ', r_tr_ori.r19_compania,
		'   AND a.r19_localidad = ', r_tr_ori.r19_localidad,
		'   AND a.r19_cod_tran  = "', r_tr_ori.r19_cod_tran, '"',
		'   AND a.r19_num_tran  = ', r_tr_ori.r19_num_tran
IF flag THEN
	LET expr_fro = base CLIPPED, ':rept090,'
	LET expr_sql = ' WHERE r90_compania    = ', r_tr_ori.r19_compania,
			'   AND r90_localidad   = ', r_tr_ori.r19_localidad,
			'   AND r90_cod_tran    = "',r_tr_ori.r19_cod_tran, '"',
			'   AND r90_num_tran    = ', r_tr_ori.r19_num_tran,
			'   AND a.r19_compania  = r90_compania ',
			'   AND a.r19_localidad = r90_locali_fin ',
			'   AND a.r19_cod_tran  = r90_codtra_fin ',
			'   AND a.r19_num_tran  = r90_numtra_fin '
END IF
LET query = 'SELECT a.*, b.*, a.ROWID ',
		' FROM ', expr_fro CLIPPED, ' ', base CLIPPED, ':rept019 a, ',
			base CLIPPED, ':rept020 b ',
		expr_sql CLIPPED,
		'   AND b.r20_compania  = a.r19_compania ',
		'   AND b.r20_localidad = a.r19_localidad ',
		'   AND b.r20_cod_tran  = a.r19_cod_tran ',
		'   AND b.r20_num_tran  = a.r19_num_tran ',
		'   AND b.r20_item      = "', item CLIPPED, '"'
RETURN query CLIPPED

END FUNCTION



FUNCTION actualizar_rept010(base, r_r10, r_r20)
DEFINE base		CHAR(40)
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE query		CHAR(800)

LET query = 'UPDATE ', base CLIPPED, ':rept010 ',
		' SET r10_costo_mb   = ', r_r10.r10_costo_mb, ', ',
		'     r10_costult_mb = ', r_r10.r10_costult_mb,
		' WHERE r10_compania = ', r_r20.r20_compania,
		'   AND r10_codigo   = "', r_r20.r20_item, '"'
PREPARE up_r10 FROM query
EXECUTE up_r10
IF STATUS < 0 THEN
	DISPLAY '  Ha ocurrido un error al actualizar el registro: ',
		base CLIPPED, ' item: ', r_r20.r20_item CLIPPED,
		' en rept010.'
	DISPLAY ' '
	WHENEVER ERROR STOP
	ROLLBACK WORK
	EXIT PROGRAM
END IF
IF STATUS = NOTFOUND THEN
	DISPLAY '  No se ha podido encontrar el registro: ',
		base CLIPPED, ' item: ', r_r20.r20_item CLIPPED,
		' en rept010.'
	DISPLAY ' '
	WHENEVER ERROR STOP
	ROLLBACK WORK
	EXIT PROGRAM
END IF
CALL comito_item(base, r_r20.r20_compania, r_r20.r20_item)

END FUNCTION



FUNCTION actualizar_rept020(base, r_r20)
DEFINE base		CHAR(40)
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE query		CHAR(800)

LET query = 'UPDATE ', base CLIPPED, ':rept020 ',
		' SET r20_costo      = ', r_r20.r20_costo, ', ',
		'     r20_costant_mb = ', r_r20.r20_costant_mb, ', ',
		'     r20_costant_ma = ', r_r20.r20_costant_ma, ', ',
		'     r20_costnue_mb = ', r_r20.r20_costnue_mb, ', ',
		'     r20_costnue_ma = ', r_r20.r20_costnue_ma,
		' WHERE r20_compania  = ', r_r20.r20_compania,
	  	'   AND r20_localidad = ', r_r20.r20_localidad,
	  	'   AND r20_cod_tran  = "', r_r20.r20_cod_tran, '"',
	  	'   AND r20_num_tran  = ', r_r20.r20_num_tran,
	  	'   AND r20_bodega    = "', r_r20.r20_bodega, '"',
	  	'   AND r20_item      = "', r_r20.r20_item, '"',
	  	'   AND r20_orden     = ', r_r20.r20_orden
PREPARE up_r20 FROM query
EXECUTE up_r20
IF STATUS < 0 THEN
	DISPLAY '  Ha ocurrido un error al actualizar el registro: ',
		base CLIPPED, ' ', r_r20.r20_localidad USING "<<&", ' ',
		r_r20.r20_cod_tran, '-',
		r_r20.r20_num_tran USING "<<<<<<<&"
	DISPLAY '    item: ', r_r20.r20_item CLIPPED, ' en rept020.'
	DISPLAY ' '
	WHENEVER ERROR STOP
	ROLLBACK WORK
	EXIT PROGRAM
END IF
IF STATUS = NOTFOUND THEN
	DISPLAY '  No se ha podido encontrar el registro: ',
		base CLIPPED, ' ', r_r20.r20_localidad USING "<<&", ' ',
		r_r20.r20_cod_tran, '-',
		r_r20.r20_num_tran USING "<<<<<<<&"
	DISPLAY '    item: ', r_r20.r20_item CLIPPED, ' en rept020.'
	DISPLAY ' '
	WHENEVER ERROR STOP
	ROLLBACK WORK
	EXIT PROGRAM
END IF
CALL comito_r20(base, r_r20.*)

END FUNCTION



FUNCTION actualizar_rept019(base, r_r19, comitado)
DEFINE base		CHAR(40)
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE comitado		SMALLINT
DEFINE query		CHAR(800)

LET query = 'UPDATE ', base CLIPPED, ':rept019 ',
		' SET r19_tot_costo = ', r_r19.r19_tot_costo, ', ',
		'     r19_tot_neto  = ', r_r19.r19_tot_neto,
		' WHERE r19_compania  = ', r_r19.r19_compania,
	  	'   AND r19_localidad = ', r_r19.r19_localidad,
	  	'   AND r19_cod_tran  = "', r_r19.r19_cod_tran, '"',
	  	'   AND r19_num_tran  = ', r_r19.r19_num_tran
PREPARE up_r19 FROM query
EXECUTE up_r19
IF STATUS < 0 THEN
	DISPLAY '  Ha ocurrido un error al actualizar el registro: ',
		base CLIPPED, ' ', r_r19.r19_localidad USING "<<&", ' ',
		r_r19.r19_cod_tran, '-', r_r19.r19_num_tran USING "<<<<<<<&",
		' en rept019.'
	DISPLAY ' '
	WHENEVER ERROR STOP
	ROLLBACK WORK
	EXIT PROGRAM
END IF
IF STATUS = NOTFOUND THEN
	DISPLAY '  No se ha podido encontrar el registro: ',
		base CLIPPED, ' ', r_r19.r19_localidad USING "<<&", ' ',
		r_r19.r19_cod_tran, '-', r_r19.r19_num_tran USING "<<<<<<<&",
		' en rept019.'
	DISPLAY ' '
	WHENEVER ERROR STOP
	ROLLBACK WORK
	EXIT PROGRAM
END IF
IF comitado THEN
	CALL comito_r19(base, r_r19.*)
END IF

END FUNCTION



FUNCTION obtener_item_fact(base, r_r19, r_r20)
DEFINE base		CHAR(40)
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20 		RECORD LIKE rept020.*
DEFINE r_r20_fact	RECORD LIKE rept020.*
DEFINE query		CHAR(800)

INITIALIZE r_r20_fact.* TO NULL
LET query = 'SELECT b.* FROM ', base CLIPPED, ':rept019, ',
			base CLIPPED, ':rept020 b ',
		' WHERE r19_compania    = ', r_r19.r19_compania,
	  	'   AND r19_localidad   = ', r_r19.r19_localidad,
	  	'   AND r19_cod_tran    = "', r_r19.r19_tipo_dev, '"',
	  	'   AND r19_num_tran    = ', r_r19.r19_num_dev,
		'   AND b.r20_compania  = r19_compania ',
		'   AND b.r20_localidad = r19_localidad ',
		'   AND b.r20_cod_tran  = r19_cod_tran ',
		'   AND b.r20_num_tran  = r19_num_tran ',
		'   AND b.r20_bodega    = "', r_r20.r20_bodega, '"',
		'   AND b.r20_item      = "', r_r20.r20_item, '"'
PREPARE obt_fact FROM query
DECLARE q_obt_fact CURSOR FOR obt_fact
OPEN q_obt_fact
FETCH q_obt_fact INTO r_r20_fact.*
CLOSE q_obt_fact
FREE q_obt_fact
RETURN r_r20_fact.*

END FUNCTION



FUNCTION actualizar_diario_contable_trans(base, r_r19, item)
DEFINE base		CHAR(40)
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE item		LIKE rept010.r10_codigo
DEFINE r_b13		RECORD LIKE ctbt013.*
DEFINE r_b13_res	RECORD LIKE ctbt013_res.*
DEFINE query		CHAR(1200)
DEFINE tot_costo	DECIMAL(14,2)
DEFINE valor		LIKE ctbt013.b13_valor_base

IF visualizar THEN
	--DISPLAY '    Actualizando Diario Contable. Por favor espere ...'
END IF
SET LOCK MODE TO WAIT 5
BEGIN WORK
WHENEVER ERROR CONTINUE
CALL obtener_costo_total(base, r_r19.*, item) RETURNING tot_costo
LET query = 'SELECT a.* ',
		' FROM ', base CLIPPED, ':rept040, ',
			base CLIPPED, ':ctbt013_res a ',
		' WHERE r40_compania    = ', r_r19.r19_compania,
		'   AND r40_localidad   = ', r_r19.r19_localidad,
		'   AND r40_cod_tran    = "', r_r19.r19_cod_tran, '"',
		'   AND r40_num_tran    = ', r_r19.r19_num_tran,
		'   AND a.b13_compania  = r40_compania ',
		'   AND a.b13_tipo_comp = r40_tipo_comp ',
		'   AND a.b13_num_comp  = r40_num_comp '
PREPARE cons_b13 FROM query
DECLARE q_b13 CURSOR WITH HOLD FOR cons_b13
OPEN q_b13
FETCH q_b13 INTO r_b13_res.*
IF STATUS = NOTFOUND THEN
	DISPLAY '    Transacción no tiene diario en: ',
		base CLIPPED, ' ', r_r19.r19_cod_tran, '-',
		r_r19.r19_num_tran USING "<<<<<<<<&", '.'
	DISPLAY ' '
	WHENEVER ERROR STOP
	ROLLBACK WORK
	RETURN
END IF
CLOSE q_b13
FOREACH q_b13 INTO r_b13_res.*
	CALL actualizar_ctbt013(base, r_b13_res.*, tot_costo)
END FOREACH
LET query = 'SELECT NVL(SUM(b13_valor_base), 0) valor_base ',
		' FROM ', base CLIPPED, ':ctbt013 ',
		' WHERE b13_compania  = ', r_b13_res.b13_compania,
		'   AND b13_tipo_comp = "', r_b13_res.b13_tipo_comp, '"',
		'   AND b13_num_comp  = "', r_b13_res.b13_num_comp, '"',
		' INTO TEMP t1 '
PREPARE exe_b13_res FROM query
EXECUTE exe_b13_res
SELECT * INTO valor FROM t1
DROP TABLE t1
IF valor <> 0 THEN
	DISPLAY '    Error al actualizar el diario en ',
		base CLIPPED, ' ', r_b13_res.b13_tipo_comp, '-',
		r_b13_res.b13_num_comp CLIPPED, ' en ctbt013. Descuadre ',
		valor USING "---,---,--&.##"
	DISPLAY ' '
	WHENEVER ERROR STOP
	ROLLBACK WORK
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
COMMIT WORK
{--
IF visualizar THEN
	DISPLAY '    Diario: ', r_b13_res.b13_tipo_comp, '-',
	r_b13_res.b13_num_comp CLIPPED, ' actualizado en base: ', base CLIPPED,
	'. OK'
END IF
--}
CALL mayoriza_comprobante(base, r_b13_res.b13_compania, r_b13_res.b13_tipo_comp,
			  r_b13_res.b13_num_comp, 'M')
{--
IF visualizar THEN
	DISPLAY '    Diario: ', r_b13_res.b13_tipo_comp, '-',
	r_b13_res.b13_num_comp CLIPPED, ' mayorizado en base: ', base CLIPPED,
	'. OK'
END IF
--}

END FUNCTION



FUNCTION obtener_costo_total(base, r_r19, item)
DEFINE base		CHAR(40)
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE item		LIKE rept010.r10_codigo
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE posi		INTEGER
DEFINE tot_costo	DECIMAL(14,2)
DEFINE query		CHAR(1200)

IF visualizar THEN
	--DISPLAY '      Obteniendo costo total de ', r_r19.r19_cod_tran, '-', r_r19.r19_num_tran USING "<<<<<<<&"
END IF
CALL query_detalle_trans(base, r_r19.*, 0, item) RETURNING query
PREPARE tr_ctb FROM query
DECLARE q_tr_ctb CURSOR WITH HOLD FOR tr_ctb
LET tot_costo = 0
FOREACH q_tr_ctb INTO r_r19.*, r_r20.*, posi
	LET tot_costo = tot_costo + (r_r20.r20_cant_ven * r_r20.r20_costo)
END FOREACH
RETURN retorna_precision_valor(base, r_r19.r19_moneda, tot_costo)

END FUNCTION



FUNCTION actualizar_ctbt013(base, r_b13_res, tot_costo)
DEFINE base		CHAR(40)
DEFINE r_b13_res	RECORD LIKE ctbt013_res.*
DEFINE tot_costo	DECIMAL(14,2)
DEFINE expr_up		CHAR(100)
DEFINE query		CHAR(800)

LET expr_up = ' SET b13_valor_base = ', tot_costo
IF r_b13_res.b13_valor_base < 0 THEN
	LET expr_up = ' SET b13_valor_base = ', tot_costo * (-1)
END IF
LET query = 'UPDATE ', base CLIPPED, ':ctbt013 ',
		expr_up CLIPPED,
		' WHERE b13_compania  = ', r_b13_res.b13_compania,
		'   AND b13_tipo_comp = "', r_b13_res.b13_tipo_comp, '"',
		'   AND b13_num_comp  = "', r_b13_res.b13_num_comp, '"',
		'   AND b13_secuencia = ', r_b13_res.b13_secuencia,
		'   AND b13_cuenta    = "', r_b13_res.b13_cuenta CLIPPED, '"'
PREPARE up_b13 FROM query
EXECUTE up_b13
IF STATUS < 0 THEN
	DISPLAY '  Ha ocurrido un error al actualizar el registro: ',
		base CLIPPED, ' diario: ', r_b13_res.b13_tipo_comp, '-',
		r_b13_res.b13_num_comp CLIPPED, ' en ctbt013.'
	DISPLAY ' '
	WHENEVER ERROR STOP
	ROLLBACK WORK
	EXIT PROGRAM
END IF
IF STATUS = NOTFOUND THEN
	DISPLAY '  No se ha podido encontrar el registro: ',
		base CLIPPED, ' diario: ', r_b13_res.b13_tipo_comp, '-',
		r_b13_res.b13_num_comp CLIPPED, ' en ctbt013.'
	DISPLAY ' '
	WHENEVER ERROR STOP
	ROLLBACK WORK
	EXIT PROGRAM
END IF
CALL comito_diario(base, r_b13_res.*)

END FUNCTION



FUNCTION comito_diario(base, r_b13_res)
DEFINE base		CHAR(40)
DEFINE r_b13_res	RECORD LIKE ctbt013_res.*
DEFINE query		CHAR(800)

LET query = 'UPDATE ', base CLIPPED, ':ctbt013_res ',
		' SET b13_comito = "S" ',
		' WHERE b13_compania  = ', r_b13_res.b13_compania,
		'   AND b13_tipo_comp = "', r_b13_res.b13_tipo_comp, '"',
		'   AND b13_num_comp  = "', r_b13_res.b13_num_comp, '"',
		'   AND b13_secuencia = ', r_b13_res.b13_secuencia
PREPARE up_b13_res FROM query
EXECUTE up_b13_res
IF STATUS < 0 THEN
	DISPLAY '  Ha ocurrido un error al actualizar el registro: ',
		base CLIPPED, ' diario: ', r_b13_res.b13_tipo_comp, '-',
		r_b13_res.b13_num_comp CLIPPED, ' en ctbt013_res.'
	DISPLAY ' '
	WHENEVER ERROR STOP
	ROLLBACK WORK
	EXIT PROGRAM
END IF
IF STATUS = NOTFOUND THEN
	DISPLAY '  No se ha podido encontrar el registro: ',
		base CLIPPED, ' diario: ', r_b13_res.b13_tipo_comp, '-',
		r_b13_res.b13_num_comp CLIPPED, ' en ctbt013_res.'
	DISPLAY ' '
	WHENEVER ERROR STOP
	ROLLBACK WORK
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION mayoriza_comprobante(base, codcia, tipo, numero, flag_may)
DEFINE base		CHAR(40)
DEFINE codcia		LIKE ctbt012.b12_compania
DEFINE tipo		LIKE ctbt012.b12_tipo_comp
DEFINE numero		LIKE ctbt012.b12_num_comp
DEFINE flag_may		CHAR(1)
DEFINE r_cia		RECORD LIKE ctbt000.*
DEFINE r		RECORD LIKE ctbt012.*
DEFINE rd		RECORD LIKE ctbt013.*
DEFINE r_sal		RECORD LIKE ctbt011.*
DEFINE tipo_cta		CHAR(1)
DEFINE estado		CHAR(1)
DEFINE existe		SMALLINT
DEFINE ano_aux		SMALLINT
DEFINE campo_db		CHAR(15)
DEFINE campo_cr		CHAR(15)
DEFINE query		CHAR(1500)
DEFINE expr_up		VARCHAR(200)
DEFINE debito		LIKE ctbt013.b13_valor_base
DEFINE credito		LIKE ctbt013.b13_valor_base
DEFINE cuenta		LIKE ctbt010.b10_cuenta

IF flag_may <> 'M' AND flag_may <> 'D' THEN
	DISPLAY 'Flag mayorización incorrecto, debe ser M ó D.'
	RETURN
END IF
INITIALIZE r_cia.* TO NULL
LET query = 'SELECT * FROM ', base CLIPPED, ':ctbt000 ',
		' WHERE b00_compania = ', codcia,
		' INTO TEMP t1 '
PREPARE exe_b00 FROM query
EXECUTE exe_b00
SELECT * INTO r_cia.* FROM t1
DROP TABLE t1
IF r_cia.b00_cuenta_uti IS NULL THEN
	DISPLAY 'No esta configurada la cuenta utilidad presente ejercicio.'
	RETURN
END IF
BEGIN WORK
WHENEVER ERROR CONTINUE
LET query = 'SELECT * FROM ', base CLIPPED, ':ctbt012 ',
		' WHERE b12_compania  = ', codcia,
		'   AND b12_tipo_comp = "', tipo, '"',
		'   AND b12_num_comp  = "', numero, '"',
		' FOR UPDATE '
PREPARE cons_mcomp FROM query
DECLARE q_mcomp CURSOR FOR cons_mcomp 
OPEN q_mcomp
FETCH q_mcomp INTO r.*
IF STATUS = NOTFOUND THEN
	DISPLAY '     Comprobante a mayorizar no existe en base: ',base CLIPPED,
		' ', tipo, '-', numero, '.'
	ROLLBACK WORK
	WHENEVER ERROR STOP
	RETURN
END IF
IF STATUS < 0 THEN
	DISPLAY '     Error al intentar bloquear comprobante para mayorizar en'
	DISPLAY '      base: ', base CLIPPED, ' ', tipo, '-', numero, '.'
	ROLLBACK WORK
	WHENEVER ERROR STOP
	RETURN
END IF
IF YEAR(r.b12_fec_proceso) < r_cia.b00_anopro THEN 
	DISPLAY '     El comprobante pertenece a un año que ya fue cerrado.'
	DISPLAY '      Base: ', base CLIPPED, ' ', tipo, '-', numero, '.'
	ROLLBACK WORK
	WHENEVER ERROR STOP
	RETURN
END IF
WHENEVER ERROR STOP
LET query = 'SELECT b13_cuenta te_cuenta, b13_valor_base te_debito, ',
		' b13_valor_base te_credito ',
		' FROM ', base CLIPPED, ':ctbt013 ',
		' WHERE b13_compania = 99 ',
		' INTO TEMP temp_may '
PREPARE exe_may FROM query
EXECUTE exe_may
LET query = 'SELECT a.*, b10_tipo_cta ',
		' FROM ', base CLIPPED, ':ctbt013 a, ',
			base CLIPPED, ':ctbt010 ',
		' WHERE a.b13_compania  = ', codcia,
		'   AND a.b13_tipo_comp = "', tipo, '"',
		'   AND a.b13_num_comp  = "', numero, '"',
		'   AND a.b13_compania  = b10_compania ',
		'   AND a.b13_cuenta    = b10_cuenta '
PREPARE cons_mdcomp FROM query
DECLARE q_mdcomp CURSOR FOR cons_mdcomp
FOREACH q_mdcomp INTO rd.*, tipo_cta
	LET debito  = 0
	LET credito = 0
	IF rd.b13_valor_base < 0 THEN
		LET credito = rd.b13_valor_base * -1
	ELSE
		LET debito  = rd.b13_valor_base
	END IF
	IF tipo_cta = 'R' THEN
		CALL genera_niveles_mayorizacion(base, r_cia.b00_cuenta_uti,
						 debito, credito)
	END IF
	CALL genera_niveles_mayorizacion(base, rd.b13_cuenta, debito, credito)
END FOREACH
DECLARE q_tmay CURSOR FOR SELECT * FROM temp_may ORDER BY te_cuenta DESC
WHENEVER ERROR CONTINUE
SET LOCK MODE TO WAIT 5
FOREACH q_tmay INTO cuenta, debito, credito
	LET existe = 0
	WHILE NOT existe
		LET query = 'SELECT * FROM ', base CLIPPED, ':ctbt011 ',
				' WHERE b11_compania = ', codcia,
				'   AND b11_moneda   = "',r_cia.b00_moneda_base,
				'"  AND b11_ano      =',YEAR(r.b12_fec_proceso),
				'   AND b11_cuenta   = "', cuenta, '"',
				' FOR UPDATE '
		PREPARE cons_msal FROM query
		DECLARE q_msal CURSOR FOR cons_msal
	        OPEN q_msal 
		FETCH q_msal INTO r_sal.*
		IF STATUS = NOTFOUND THEN
			CLOSE q_msal
			LET ano_aux = YEAR(r.b12_fec_proceso)
			LET query   = 'INSERT INTO ', base CLIPPED, ':ctbt011 ',
					' VALUES (', codcia, ', "', cuenta, '"',
					', "', r_cia.b00_moneda_base, '", ',
					ano_aux, ',0,0,0,0,0,0,0,0,0,0,0,0,0,',
					'0,0,0,0,0,0,0,0,0,0,0,0,0)'
			PREPARE ins_b11 FROM query
			EXECUTE ins_b11
			IF STATUS < 0 THEN
				DROP TABLE temp_may
				ROLLBACK WORK
				WHENEVER ERROR STOP
				DISPLAY 'Error al crear registro de saldos.'
				RETURN
			END IF
		ELSE
			IF STATUS < 0 THEN
				DROP TABLE temp_may
				ROLLBACK WORK
				WHENEVER ERROR STOP
				DISPLAY 'Cuenta ', cuenta CLIPPED,
					' esta bloqueada por otro usuario.'
				RETURN
			END IF
			LET existe = 1
		END IF
	END WHILE
	LET campo_db = 'b11_db_mes_', MONTH(r.b12_fec_proceso) USING '&&'
	LET campo_cr = 'b11_cr_mes_', MONTH(r.b12_fec_proceso) USING '&&'
	IF flag_may = 'D' THEN
		LET debito  = debito  * -1
		LET credito = credito * -1
	END IF
	LET expr_up = 'UPDATE ', base CLIPPED, ':ctbt011',
			' SET ', campo_db, ' = ',
				 campo_db, ' + ?, ',
				 campo_cr, ' = ',
				 campo_cr, ' + ? ',
			' WHERE CURRENT OF q_msal' 
	PREPARE up_sal FROM expr_up
	EXECUTE	up_sal USING debito, credito
	IF STATUS < 0 THEN
		DROP TABLE temp_may
		ROLLBACK WORK
		WHENEVER ERROR STOP
		DISPLAY 'Error al actualizar maestro de saldos de cuenta ',
			cuenta CLIPPED, '.'
		RETURN
	END IF
END FOREACH
DROP TABLE temp_may
LET estado = 'M'
IF flag_may = 'D' THEN
	LET estado = 'A'
END IF
WHENEVER ERROR CONTINUE
LET query = 'UPDATE ', base CLIPPED, ':ctbt012',
		' SET b12_estado = "', estado, '"',
		' WHERE CURRENT OF q_mcomp '
PREPARE up_b12 FROM query
EXECUTE up_b12
IF STATUS < 0 THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	DISPLAY 'Error al actualizar estado del comprobante ', tipo, '-',numero,
		'.'
	RETURN
END IF
WHENEVER ERROR STOP
COMMIT WORK

END FUNCTION



FUNCTION genera_niveles_mayorizacion(base, cuenta, debito, credito)
DEFINE base		CHAR(40)
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE debito		LIKE ctbt013.b13_valor_base
DEFINE credito		LIKE ctbt013.b13_valor_base
DEFINE i, j, aux	SMALLINT
DEFINE ini, fin 	SMALLINT
DEFINE ceros		CHAR(10)
DEFINE query		CHAR(300)
DEFINE rn		RECORD LIKE ctbt001.*

LET query = 'SELECT * FROM ', base CLIPPED, ':ctbt001 ORDER BY b01_nivel DESC'
PREPARE cons_niv FROM query
DECLARE q_niv CURSOR FOR cons_niv
LET i = 0
FOREACH q_niv INTO rn.*
	LET i = i + 1
	IF i = 1 THEN
		LET aux = rn.b01_posicion_i - 1
		CALL inserta_temporal_mayorizacion(cuenta, debito, credito)
		LET cuenta = cuenta[1, aux]
	ELSE
		CALL inserta_temporal_mayorizacion(cuenta, debito, credito)
		LET ceros = NULL
		FOR j = rn.b01_posicion_i TO rn.b01_posicion_f
			LET ceros = ceros CLIPPED, '0'
		END FOR
		LET ini = rn.b01_posicion_i
		LET fin = rn.b01_posicion_f
		LET cuenta[ini, fin] = ceros CLIPPED
	END IF
END FOREACH

END FUNCTION



FUNCTION inserta_temporal_mayorizacion(cuenta, debito, credito)
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE debito		DECIMAL(14,2)
DEFINE credito		DECIMAL(14,2)

SELECT * FROM temp_may WHERE te_cuenta = cuenta
IF STATUS = NOTFOUND THEN
	INSERT INTO temp_may VALUES(cuenta, debito, credito)
ELSE
	UPDATE temp_may
		SET te_debito  = te_debito  + debito,
		    te_credito = te_credito + credito
		WHERE te_cuenta = cuenta
END IF

END FUNCTION
