DATABASE aceros



DEFINE codcia		INTEGER
DEFINE codloc		SMALLINT



MAIN

	IF num_args() <> 5 THEN
		DISPLAY 'Parametros Incorrectos. '
		DISPLAY 'Faltan BASE_1 SERVER_1 LOCALIDAD_1 BASE_2 SERVER_2.'
		EXIT PROGRAM
	END IF
	LET codcia = 1
	LET codloc = arg_val(3)
	CALL ejecutar_proceso()

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



FUNCTION ejecutar_proceso()

CALL activar_base(arg_val(1), arg_val(2))
CALL carga_temporal('t1')
UNLOAD TO "dato_sto.unl" SELECT * FROM t1
DROP TABLE t1
CALL activar_base(arg_val(4), arg_val(5))
CALL carga_temporal('t1')
CALL carga_temporal('t2')
CALL ejecuta_tabla_veri()
RUN " rm -rf dato_sto.unl"

END FUNCTION



FUNCTION carga_temporal(tabla)
DEFINE tabla		CHAR(10)
DEFINE query		CHAR(800)

SET ISOLATION TO DIRTY READ
LET query = 'SELECT r11_bodega, r11_item, r11_stock_act, r11_stock_ant ',
		' FROM rept011 ',
		' WHERE r11_compania = 71 ',
		' INTO TEMP ', tabla CLIPPED
PREPARE crea_tmp FROM query
EXECUTE crea_tmp
LET query = 'INSERT INTO ', tabla CLIPPED,
		' SELECT r11_bodega, r11_item, r11_stock_act, r11_stock_ant ',
		' FROM rept011 ',
		' WHERE r11_compania = ', codcia,
		'   AND r11_bodega IN ',
			' (SELECT r02_codigo from rept002 ',
				' WHERE r02_estado    = "A" ',
				'   AND r02_tipo     <> "S" ',
				'   AND r02_area      = "R" ',
				'   AND r02_localidad = ', codloc, ')'
PREPARE ins_tmp FROM query
EXECUTE ins_tmp

END FUNCTION



FUNCTION ejecuta_tabla_veri()
DEFINE hay, pausa	INTEGER
DEFINE tot_sto_a1	DECIMAL(10,2)
DEFINE tot_sto_a2	DECIMAL(10,2)
DEFINE fila		SMALLINT
DEFINE base, base1	CHAR(20)
DEFINE bod1, bod2	LIKE rept011.r11_bodega
DEFINE ite1, ite2	LIKE rept011.r11_item
DEFINE sto_a1, sto_a2	LIKE rept011.r11_stock_act
DEFINE sto_n1, sto_n2	LIKE rept011.r11_stock_ant

LOAD FROM "dato_sto.unl" INSERT INTO t1
LET base  = arg_val(1)
LET base1 = arg_val(4)
SELECT t1.r11_bodega, t1.r11_item, t1.r11_stock_act, t1.r11_stock_ant,
	t2.r11_bodega bodega, t2.r11_item item, t2.r11_stock_act sto_act,
	t2.r11_stock_ant sto_ant
	FROM t1, t2
	WHERE t1.r11_bodega     = t2.r11_bodega
	  AND t1.r11_item       = t2.r11_item
	  AND t1.r11_stock_act <> t2.r11_stock_act
	INTO TEMP t3
DROP TABLE t1
DROP TABLE t2
SELECT COUNT(*) INTO hay FROM t3
DISPLAY ' '
DISPLAY 'Existen ', hay USING "<<<<<&", ' Items con diferente STOCK entre ',
	'las bases ', base CLIPPED, ' y ', base1 CLIPPED, '.'
DISPLAY ' '
DISPLAY ' '
DISPLAY 'LAS DIFERENCIAS'
DISPLAY '==============='
DISPLAY ' '
DECLARE q_veri CURSOR FOR SELECT * FROM t3 ORDER BY r11_bodega, r11_item
LET fila       = 1
LET tot_sto_a1 = 0
LET tot_sto_a2 = 0
DISPLAY 'BD', '  ', ' ITEM  ', '  ', 'STO.ACT.', '  ', 'STO.ANT.', '  ', 'BD',
	'  ', ' ITEM  ', '  ', 'STO.ACT.', '  ', 'STO.ANT.'
DISPLAY '----------------------------------------------------------------'
FOREACH q_veri INTO bod1, ite1, sto_a1, sto_n1, bod2, ite2, sto_a2, sto_n2
	DISPLAY bod1, '  ', ite1 USING "######&", '  ', sto_a1 USING "####&.##",
		'  ', sto_n1 USING "####&.##", '  ', bod2, '  ',
		ite2 USING "######&", '  ', sto_a2 USING "####&.##", '  ',
		sto_n2 USING "####&.##"
	LET tot_sto_a1 = tot_sto_a1 + sto_a1
	LET tot_sto_a2 = tot_sto_a2 + sto_a2
	LET fila       = fila + 1
	IF fila > 21 THEN
		LET fila  = 1
		--LET pausa = fgl_getkey()
		DISPLAY ' '
		DISPLAY 'BD', '  ', ' ITEM  ', '  ', 'STO.ACT.', '  ',
			'STO.ANT.', '  ', 'BD', '  ', ' ITEM  ', '  ',
			'STO.ACT.', '  ', 'STO.ANT.'
		DISPLAY '----------------------------------------------------',
			'------------'
	END IF
END FOREACH
DISPLAY ' '
DISPLAY 'El Stock Actual en base ', base CLIPPED, ' es: ',
	tot_sto_a1 USING "###,##&.##"
DISPLAY 'El Stock Actual en base ', base1 CLIPPED, ' es: ',
	tot_sto_a2 USING "###,##&.##"
DISPLAY ' '
DISPLAY 'Existen ', hay USING "<<<<<&", ' Items con diferente STOCK entre ',
	'las bases ', base CLIPPED, ' y ', base1 CLIPPED, '.'
DROP TABLE t3

END FUNCTION
