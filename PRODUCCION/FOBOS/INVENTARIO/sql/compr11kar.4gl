DATABASE aceros


DEFINE vg_codcia	LIKE gent001.g01_compania
DEFINE vg_codloc	LIKE gent002.g02_localidad
DEFINE base_ori		CHAR(20)
DEFINE serv_ori		CHAR(20)
DEFINE vm_stock_inicial	LIKE rept011.r11_stock_act
DEFINE r_detalle	ARRAY[30000] OF RECORD
				cant_ing	LIKE rept011.r11_stock_act,
				cant_egr	LIKE rept011.r11_stock_act,
				saldo		LIKE rept011.r11_stock_act
			END RECORD
DEFINE vm_max_det       SMALLINT
DEFINE vm_num_det       SMALLINT



MAIN

	IF num_args() <> 4 AND num_args() <> 6 THEN
		DISPLAY 'Parametros Incorrectos. SON: BASE SERVIDOR COMPANIA',
			' LOCALIDAD y/o ITEM/BODEGA/LOCALIDAD I/B/T.'
		EXIT PROGRAM
	END IF
	LET base_ori   = arg_val(1)
	LET serv_ori   = arg_val(2)
	LET vg_codcia  = arg_val(3)
	LET vg_codloc  = arg_val(4)
	LET vm_max_det = 30000
	CALL ejecuta_proceso()
	DISPLAY 'Proceso Terminado Ok.'

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



FUNCTION ejecuta_proceso()
DEFINE bodega		LIKE rept020.r20_bodega
DEFINE item		LIKE rept020.r20_item
DEFINE stock		LIKE rept011.r11_stock_act
DEFINE bd		LIKE rept020.r20_bodega
DEFINE saldo		DECIMAL (8,2)
DEFINE query		CHAR(600)
DEFINE expr_sql		VARCHAR(100)
DEFINE i, j, l		SMALLINT

DISPLAY ' '
DISPLAY 'Obteniendo los Items. Por favor espere ...'
CALL activar_base(base_ori, serv_ori)
SET ISOLATION TO DIRTY READ
SELECT r02_codigo, r02_localidad
	FROM rept002
	WHERE r02_compania  = vg_codcia
	  AND r02_localidad = vg_codloc
	INTO TEMP tmp_bod
LET expr_sql = NULL
IF num_args() > 4 THEN
	CASE arg_val(6)
		WHEN 'I'
			LET expr_sql = '   AND r11_item     = "',
					arg_val(5) CLIPPED, '"'
		WHEN 'B'
			LET query = 'SELECT * FROM tmp_bod ',
					' WHERE r02_codigo = "', arg_val(5),'"',
					' INTO TEMP t1 '
		WHEN 'T'
			LET query = 'SELECT * FROM tmp_bod ',
					' WHERE r02_localidad = ', arg_val(5),
					' INTO TEMP t1 '
	END CASE
	IF arg_val(6) <> 'I' THEN
		PREPARE exec_t1 FROM query
		EXECUTE exec_t1
		DROP TABLE tmp_bod
		SELECT * FROM t1 INTO TEMP tmp_bod
		DROP TABLE t1
	END IF
END IF
LET query = 'SELECT r11_bodega, r11_item, r11_stock_act ',
		' FROM rept011 ',
		' WHERE r11_compania = ', vg_codcia,
		'   AND r11_bodega   IN (SELECT r02_codigo FROM tmp_bod ',
					' WHERE r02_codigo = r11_bodega) ',
		expr_sql CLIPPED,
		' ORDER BY 1, 2 '
PREPARE cons FROM query
DECLARE q_items CURSOR FOR cons
DISPLAY ' '
DISPLAY 'Procesando los movimientos de los Items. Por favor espere ...'
DISPLAY ' '
LET i  = 0
LET j  = 0
LET l  = 0
LET bd = 'XX'
FOREACH q_items INTO bodega, item, stock
	--DISPLAY ' Procesando Item ', item CLIPPED, ' de bodega ', bodega USING "&&", '.'
	IF arg_val(6) = 'T' THEN
		IF bd <> bodega THEN
			IF bd <> 'XX' AND j > 0 THEN
				DISPLAY '  Existen ', j USING "<<<<&",
					' ITEMS diferentes, stock con Kardex ',
					'en BODEGA ', bd CLIPPED
				DISPLAY ' '
				LET j = 0
			END IF
			DISPLAY ' Verificando Bodega: ', bodega CLIPPED
			LET l  = l + 1
			LET bd = bodega
		END IF
	END IF
	LET vm_stock_inicial = 0
	LET vm_num_det       = 0
	CALL control_consulta_detalle(bodega, item) RETURNING saldo
	IF vm_num_det = 0 THEN
		CONTINUE FOREACH
	END IF
	IF saldo = stock THEN
		CONTINUE FOREACH
	END IF
	DISPLAY ' '
	{--
	DISPLAY '  ERROR ITEM: ', item CLIPPED, ' Bod. ', bodega USING "&&",
		' Stock: ', stock USING "---,--&.##", ' Kardex: ',
		saldo USING "---,--&.##", '. Son distintos.'
	--}
	DISPLAY '   ERROR ITEM: ', item CLIPPED, ' ', bodega USING "&&",
		' ', stock USING "---,--&.##", ' ',
		saldo USING "---,--&.##", '  No. T ', vm_num_det USING "<<<<&"
	DISPLAY ' '
	LET i = i + 1
	LET j = j + 1
END FOREACH
IF i = 0 OR arg_val(6) = 'T' THEN
	DISPLAY ' '
END IF
DISPLAY 'Existen un total de ', i USING "<<<<&", ' de ITEMS diferentes, stock',
	' con el Kardex.'
IF arg_val(6) = 'T' THEN
	DISPLAY 'Se verificaron ', l USING "<<<<&", ' Bodegas.'
END IF
DISPLAY ' '
DROP TABLE tmp_bod

END FUNCTION



FUNCTION control_consulta_detalle(bod_pri, item)
DEFINE bod_pri		LIKE rept020.r20_bodega
DEFINE item		LIKE rept020.r20_item
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_g21		RECORD LIKE gent021.*
DEFINE bodega		LIKE rept019.r19_bodega_ori
DEFINE codloc		LIKE rept019.r19_localidad
DEFINE fec_ini		LIKE rept020.r20_fecing
DEFINE fec_fin		LIKE rept020.r20_fecing
DEFINE query         	CHAR(2000)
DEFINE expr_sql        	CHAR(400)
DEFINE saldo		DECIMAL (8,2)
DEFINE i		SMALLINT

LET fec_ini = EXTEND(MDY(01, 01, 2003), YEAR TO SECOND)
LET fec_fin = EXTEND(TODAY, YEAR TO SECOND) + 23 UNITS HOUR +
	      59 UNITS MINUTE + 59 UNITS SECOND  
LET codloc = 0
IF vg_codloc = 3 THEN
	--LET codloc = 5
	LET codloc = 3
END IF
LET expr_sql = NULL
IF bod_pri <> '17' AND vg_codloc = 3 THEN
	LET expr_sql = '   AND NOT EXISTS ',
			'(SELECT 1 FROM rept094 ',
				'WHERE r94_compania   = r19_compania ',
				'  AND r94_localidad  = r19_localidad ',
				'  AND r94_cod_tran   = r19_cod_tran ',
				'  AND r94_num_tran   = r19_num_tran ',
				'  AND r94_codtra_fin IS NULL ',
				'  AND r94_traspasada = "N") '
END IF
LET query = 'SELECT rept020.*, rept019.*, gent021.*, rept020.ROWID ' ,
		' FROM rept020, rept019, gent021 ',
		' WHERE r20_compania  = ', vg_codcia,
		'   AND r20_localidad IN (', vg_codloc, ', ', codloc, ')',
		'   AND r20_item      = "', item CLIPPED, '"',
		'   AND r20_fecing    BETWEEN "', fec_ini, '"',
					' AND "', fec_fin, '"',
		'   AND r20_compania  = r19_compania ',
		'   AND r20_localidad = r19_localidad ',
		'   AND r20_cod_tran  = r19_cod_tran ',
		'   AND r20_num_tran  = r19_num_tran ',
		'   AND r20_cod_tran  = g21_cod_tran ',
			expr_sql CLIPPED,
		' ORDER BY r20_fecing, rept020.ROWID '
PREPARE consulta FROM query
DECLARE q_consulta CURSOR FOR consulta
LET i          = 1
LET saldo      = 0
FOREACH q_consulta INTO r_r20.*, r_r19.*, r_g21.*
	LET bodega = "**"
	IF r_g21.g21_tipo = 'T' THEN
		IF bod_pri = r_r19.r19_bodega_ori THEN
			LET bodega = r_r19.r19_bodega_ori
		END IF
		IF bod_pri = r_r19.r19_bodega_dest THEN
			LET bodega = r_r19.r19_bodega_dest
		END IF
	ELSE
		IF r_g21.g21_tipo <> 'C' THEN
			LET bodega = r_r20.r20_bodega
		END IF
	END IF
	IF bod_pri <> bodega THEN
		CONTINUE FOREACH
	END IF
	IF i = 1 THEN
		IF r_g21.g21_tipo <> 'T' THEN
			LET vm_stock_inicial = r_r20.r20_stock_ant
		ELSE
			IF bodega = r_r19.r19_bodega_ori THEN
				LET vm_stock_inicial = r_r20.r20_stock_ant
			END IF
			IF bodega = r_r19.r19_bodega_dest THEN
				LET vm_stock_inicial = r_r20.r20_stock_bd
			END IF
		END IF
		LET saldo = vm_stock_inicial
	END IF
	CASE
		WHEN(r_g21.g21_tipo = 'I')
			LET r_detalle[i].cant_egr = 0
			LET r_detalle[i].cant_ing = r_r20.r20_cant_ven
			LET r_detalle[i].saldo    = r_r20.r20_cant_ven + saldo
		WHEN(r_g21.g21_tipo = 'E')
			LET r_detalle[i].cant_egr = r_r20.r20_cant_ven
			LET r_detalle[i].cant_ing = 0
			LET r_detalle[i].saldo    = saldo - r_r20.r20_cant_ven
		WHEN(r_g21.g21_tipo = 'C')
			LET r_detalle[i].cant_egr = 0
			LET r_detalle[i].cant_ing = 0
			LET r_detalle[i].saldo    = saldo
		WHEN(r_g21.g21_tipo = 'T')
			IF bod_pri = r_r19.r19_bodega_ori THEN
				LET r_detalle[i].cant_egr = r_r20.r20_cant_ven
				LET r_detalle[i].cant_ing = 0
				LET r_detalle[i].saldo    = saldo - 
							    r_r20.r20_cant_ven 
			END IF
			IF bod_pri = r_r19.r19_bodega_dest THEN
				LET r_detalle[i].cant_egr = 0
				LET r_detalle[i].cant_ing = r_r20.r20_cant_ven
				LET r_detalle[i].saldo    = r_r20.r20_cant_ven +
							    saldo
			END IF
	END CASE
	LET saldo = r_detalle[i].saldo
	LET i = i + 1
	IF i > vm_max_det THEN
		EXIT FOREACH
	END IF
END FOREACH
LET vm_num_det = i - 1
RETURN saldo

END FUNCTION
