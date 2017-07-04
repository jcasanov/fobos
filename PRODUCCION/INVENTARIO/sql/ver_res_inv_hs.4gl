DATABASE aceros


DEFINE codcia		LIKE gent001.g01_compania
DEFINE codloc1, codloc2	LIKE gent002.g02_localidad
DEFINE codloc3		LIKE gent002.g02_localidad
DEFINE ciudad		SMALLINT



MAIN

	IF num_args() <> 5 THEN
		DISPLAY 'Parametros Incorectos. '
		DISPLAY '  Son: COMPAÑÍA BASE SERVIDOR_BASE CIUDAD FECHA_INI.'
		EXIT PROGRAM
	END IF
	LET codcia = arg_val(1)
	CALL activar_base(arg_val(2), arg_val(3))
	LET ciudad = arg_val(4)
	CASE ciudad
		WHEN 1
			LET codloc1 = 1
			LET codloc2 = 2
			LET codloc3 = 0
		WHEN 2
			LET codloc1 = 3
			LET codloc2 = 4
			LET codloc3 = 5
	END CASE
	CALL ejecutar_proceso()
	DISPLAY ' '
	DISPLAY 'Descarga Terminada OK. '

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



FUNCTION ejecutar_proceso()
DEFINE r_r11		RECORD LIKE rept011.*
DEFINE stock		LIKE rept011.r11_stock_act
DEFINE query		CHAR(600)
DEFINE i		SMALLINT

DISPLAY 'Obteniendo Items de las clases: 410.C050 y 410.C060. ',
	'Por favor espere ...'
SELECT r10_compania cia, r10_codigo item
	FROM rept010
	WHERE r10_compania  = codcia
	  AND r10_estado    = 'A'
	  AND r10_cod_clase IN ('410.C050', '410.C060')
	INTO TEMP tmp_item
SELECT r02_compania cia_bod, r02_codigo bodega
	FROM rept002
	WHERE r02_compania  = codcia
	  AND r02_localidad IN (codloc1, codloc2, codloc3)
	  AND r02_estado    = 'A'
	  AND r02_area      = 'R'
	  AND r02_tipo      IN ('F', 'L')
	INTO TEMP tmp_bod
DISPLAY ' '
DISPLAY 'Obteniendo Stock Actual de los Items ...'
LET query = 'SELECT r11_bodega bode, item, r11_stock_act stock_ini, ',
			'r11_stock_act stock_act ',
		' FROM tmp_item, rept011 ',
		' WHERE r11_compania  = cia ',
		'   AND r11_item      = item ',
		'   AND r11_bodega    IN (SELECT bodega FROM tmp_bod ',
					' WHERE bodega = r11_bodega) ',
		' INTO TEMP tmp_sto '
PREPARE exec_tmp FROM query
EXECUTE exec_tmp
DROP TABLE tmp_item
DROP TABLE tmp_bod
DISPLAY ' '
DISPLAY 'Obteniendo Stock Inicial de los Items. Por favor espere ...'
DECLARE q_ite CURSOR FOR SELECT bode, item FROM tmp_sto
LET i = 0
FOREACH q_ite INTO r_r11.r11_bodega, r_r11.r11_item
	DISPLAY '  Obteniendo stock inicial del ítem: ', r_r11.r11_item CLIPPED,
		' en bodega ', r_r11.r11_bodega CLIPPED
	CALL obtener_stock_inicial_bodega(r_r11.r11_bodega, r_r11.r11_item)
		RETURNING stock
	UPDATE tmp_sto
		SET stock_ini = stock
		WHERE bode = r_r11.r11_bodega
		  AND item = r_r11.r11_item
	LET i = i + 1
END FOREACH
DISPLAY 'Se obtuvieron stock inicial de ', i USING "<<<<<<&", ' ítems.'
DISPLAY ' '
SELECT item, NVL(SUM(stock_ini), 0) stock_ini, NVL(SUM(stock_act), 0) stock_act
	FROM tmp_sto
	GROUP BY 1
	INTO TEMP tmp_saldo
DROP TABLE tmp_sto
DISPLAY 'Obteniendo Saldo de Ventas de los Items. Por favor espere ...'
LET query = 'SELECT item, stock_ini, stock_act, r20_cod_tran, ',
		' CASE WHEN r20_cod_tran = "FA" ',
			' THEN NVL(SUM(r20_cant_ven), 0) ',
			' ELSE NVL(SUM(r20_cant_ven), 0) * (-1) ',
		' END saldo_vta ',
		' FROM tmp_saldo, rept020 ',
		' WHERE r20_compania = ', codcia,
		'   AND r20_cod_tran IN ("FA", "DF") ',
		'   AND r20_item     = item ',
		' GROUP BY 1, 2, 3, 4 ',
		' INTO TEMP t1 '
PREPARE exec_t1 FROM query
EXECUTE exec_t1
DISPLAY ' '
DISPLAY 'Descargando archivo del resumen de stock y saldo ventas ...'
UNLOAD TO "resumen_hs.txt"
	SELECT item, stock_ini, stock_act, NVL(SUM(saldo_vta), 0) saldo_vta
		FROM t1
		GROUP BY 1, 2, 3
		ORDER BY 1
DROP TABLE t1

END FUNCTION



FUNCTION obtener_stock_inicial_bodega(bod_par, item)
DEFINE bod_par		LIKE rept019.r19_bodega_ori
DEFINE item		LIKE rept020.r20_item
DEFINE bodega		LIKE rept019.r19_bodega_ori
DEFINE fec_ini		LIKE rept020.r20_fecing
DEFINE stock_inicial	LIKE rept011.r11_stock_act
DEFINE r_r19		RECORD LIKE rept019.*
DEFINE r_r20		RECORD LIKE rept020.*
DEFINE r_g21		RECORD LIKE gent021.*
DEFINE query         	CHAR(800)
DEFINE fecha		DATE

LET fecha   = arg_val(5)
LET fec_ini = EXTEND(fecha, YEAR TO SECOND)
LET query = 'SELECT rept020.*, rept019.*, gent021.* ' ,
		' FROM rept020, rept019, gent021 ',
		' WHERE r20_compania   = ', codcia,
		'   AND r20_localidad IN (', codloc1, ', ', codloc2, ', ',
						codloc3, ')',
		'   AND r20_item       = "', item, '"',
		'   AND r20_fecing    <= "', fec_ini, '"',
		'   AND r20_compania   = r19_compania ',
		'   AND r20_localidad  = r19_localidad ',
		'   AND r20_cod_tran   = r19_cod_tran ',
		'   AND r20_num_tran   = r19_num_tran ',
		'   AND r20_cod_tran   = g21_cod_tran ',
		' ORDER BY r20_fecing DESC'
PREPARE cons_stock FROM query
DECLARE q_sto CURSOR FOR cons_stock
LET stock_inicial = 0
OPEN q_sto
FETCH q_sto INTO r_r20.*, r_r19.*, r_g21.*
IF STATUS <> NOTFOUND THEN
	LET bodega = bod_par
	IF r_g21.g21_tipo = 'T' THEN
		IF bod_par = r_r19.r19_bodega_ori THEN
			LET bodega = r_r19.r19_bodega_ori
		END IF
		IF bod_par = r_r19.r19_bodega_dest THEN
			LET bodega = r_r19.r19_bodega_dest
		END IF
	ELSE
		IF r_g21.g21_tipo <> 'C' THEN
			LET bodega = r_r20.r20_bodega
		END IF
	END IF
	IF r_g21.g21_tipo <> 'T' THEN
		IF r_g21.g21_tipo = 'E' THEN
			LET r_r20.r20_cant_ven =
				r_r20.r20_cant_ven * (-1)
		END IF
		LET stock_inicial = r_r20.r20_stock_ant + r_r20.r20_cant_ven
	ELSE
		IF bodega = r_r19.r19_bodega_ori THEN
			LET stock_inicial = r_r20.r20_stock_ant
						- r_r20.r20_cant_ven
		END IF
		IF bodega = r_r19.r19_bodega_dest THEN
			LET stock_inicial = r_r20.r20_stock_bd
						+ r_r20.r20_cant_ven
		END IF
	END IF
END IF
CLOSE q_sto
FREE q_sto
RETURN stock_inicial

END FUNCTION
