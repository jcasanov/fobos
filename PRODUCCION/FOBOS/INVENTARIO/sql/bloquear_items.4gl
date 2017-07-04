DATABASE aceros


DEFINE vg_codcia	LIKE gent001.g01_compania
DEFINE vg_codloc	LIKE gent002.g02_localidad
DEFINE base_ori		CHAR(20)
DEFINE serv_ori		CHAR(20)



MAIN

	IF num_args() <> 4 THEN
		DISPLAY 'Parametros Incorrectos. SON: BASE SERVIDOR COMPANIA',
			' LOCALIDAD.'
		EXIT PROGRAM
	END IF
	LET base_ori   = arg_val(1)
	LET serv_ori   = arg_val(2)
	LET vg_codcia  = arg_val(3)
	LET vg_codloc  = arg_val(4)
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
DEFINE item		LIKE rept020.r20_item
DEFINE stock		LIKE rept011.r11_stock_act
DEFINE query		CHAR(600)
DEFINE i, j		SMALLINT

DISPLAY ' '
DISPLAY 'Obteniendo los Items. Por favor espere ...'
CALL activar_base(base_ori, serv_ori)
SET ISOLATION TO DIRTY READ
SELECT r10_codigo item
	FROM rept010
	WHERE r10_compania = 999
	INTO TEMP tmp_item
LOAD FROM "item_blo.unl" INSERT INTO tmp_item
SELECT r02_codigo
	FROM rept002
	WHERE r02_compania  = vg_codcia
	  AND r02_localidad = vg_codloc
	INTO TEMP tmp_bod
LET query = 'SELECT r11_item, ',
		'NVL(SUM(CASE WHEN r11_stock_act > 0 ',
				'THEN r11_stock_act ',
				'ELSE r11_stock_act * (-1) ',
			'END), 0) stock_loc ',
		' FROM rept011 ',
		' WHERE r11_compania = ', vg_codcia,
		'   AND r11_bodega   IN (SELECT r02_codigo FROM tmp_bod ',
					' WHERE r02_codigo = r11_bodega) ',
		'   AND r11_item     IN (SELECT item FROM tmp_item) ',
		' GROUP BY 1 ',
		' ORDER BY 1 '
BEGIN WORK
PREPARE cons FROM query
DECLARE q_items CURSOR FOR cons
DISPLAY ' '
DISPLAY 'Procesando los Items para bloquear. Por favor espere ...'
DISPLAY ' '
LET i = 0
LET j = 0
FOREACH q_items INTO item, stock
	IF stock <> 0 THEN
		DISPLAY ' '
		DISPLAY '   ITEM: ', item CLIPPED, ' CON STOCK ',
			stock USING "---,--&.##", '  EN LOC. ',
			vg_codloc USING "&&"
		DISPLAY ' '
		LET j = j + 1
		CONTINUE FOREACH
	END IF
	SELECT * FROM rept010
		WHERE r10_compania = vg_codcia
		  AND r10_codigo   = item
		  AND r10_estado   = 'A'
	IF STATUS = NOTFOUND THEN
		CONTINUE FOREACH
	END IF
	WHENEVER ERROR CONTINUE
	UPDATE rept010
		SET r10_estado = 'B',
		    r10_feceli = CURRENT
		WHERE r10_compania = vg_codcia
		  AND r10_codigo   = item
	IF STATUS <> 0 THEN
		ROLLBACK WORK
		DISPLAY '    ERROR AL BLOQUEAR EL ITEM: ', item CLIPPED,
			'. PROCESADO ABORTADO OK.'
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF
	WHENEVER ERROR STOP
	DISPLAY '  BLOQUEADO ITEM: ', item CLIPPED, '. OK'
	DISPLAY ' '
	LET i = i + 1
END FOREACH
DISPLAY ' '
DISPLAY 'Se bloquearon un total de ', i USING "<<<<&", ' ITEMS  OK.'
DISPLAY 'No se bloquearon un total de ', j USING "<<<<&", ' ITEMS CON STOCK.'
DISPLAY ' '
DROP TABLE tmp_bod
DROP TABLE tmp_item
COMMIT WORK

END FUNCTION
