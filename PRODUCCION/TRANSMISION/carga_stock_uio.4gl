DATABASE diteca
DEFINE vg_codcia		LIKE gent001.g01_compania
DEFINE vg_codloc		LIKE gent002.g02_localidad
DEFINE vg_codadi		LIKE gent002.g02_localidad

MAIN
DEFINE base		CHAR(10)

CALL startlog('errores')
LET vg_codcia = 1
LET vg_codloc = 1
LET vg_codadi = 9
IF num_args() <> 1 THEN
	DISPLAY 'Sintaxis: fglgo carga_stock base_datos'
	SLEEP 2
	EXIT PROGRAM
END IF 
LET base = arg_val(1)
WHENEVER ERROR CONTINUE
DATABASE base
IF status < 0 THEN
	DISPLAY 'Error al abrir base...'
	SLEEP 2
	EXIT PROGRAM
END IF 
WHENEVER ERROR STOP
CALL control_carga_actualiza_stock()

END MAIN 



FUNCTION control_carga_actualiza_stock()
DEFINE r_r02		RECORD LIKE rept002.*
DEFINE bodega		LIKE rept002.r02_codigo
DEFINE rs		RECORD LIKE tr_stock_uio.*
DEFINE a		CHAR(1)
DEFINE hora		DATETIME YEAR TO SECOND
DEFINE num_items	INTEGER
DEFINE i, j		INTEGER
DEFINE porc, porc_acum	DECIMAL(10,2)

SELECT g02_localidad INTO vg_codloc FROM gent002
	WHERE g02_compania = vg_codcia 
          AND g02_localidad= vg_codloc
          AND g02_matriz = 'N'
DISPLAY 'Borrando de tabla temporal tr_stock_uio...'
DELETE FROM tr_stock_uio WHERE 1 = 1;

DISPLAY 'Cargando a tr_stock_uio...'
LOAD FROM 'tr_stock_a_gye.txt' INSERT INTO tr_stock_uio


DECLARE q_st CURSOR FOR SELECT UNIQUE te_bodega FROM tr_stock_uio
DISPLAY 'Chequeando consistencia de stock a cargar...'
FOREACH q_st INTO bodega
	DISPLAY 'Bodega: ', bodega
	SELECT * INTO r_r02.* FROM rept002 
		WHERE r02_compania = vg_codcia AND 
		      r02_codigo   = bodega
	IF status = NOTFOUND THEN
		CONTINUE FOREACH
	END IF
	IF r_r02.r02_localidad = vg_codloc OR
	   r_r02.r02_localidad = vg_codadi THEN
		DISPLAY 'ERROR: La tabla de stock (tr_stock_uio) tiene bodega: ', bodega, ' que es de esta localidad.'
		--LET a = fgl_getkey()
		DELETE FROM tr_stock_uio WHERE te_bodega = bodega
		--EXIT PROGRAM
	ELSE
		UPDATE rept011 SET r11_stock_act = 0
			WHERE r11_compania = vg_codcia    AND 
		              r11_bodega   = bodega
			
	END IF
END FOREACH
SELECT COUNT(*) INTO num_items FROM tr_stock_uio, rept002
	WHERE te_stock >= 0 AND te_bodega = r02_codigo AND
	      r02_localidad <> vg_codloc
DECLARE q_ex CURSOR FOR SELECT tr_stock_uio.* FROM tr_stock_uio, rept002
	WHERE te_stock >= 0 AND te_bodega = r02_codigo AND
	      r02_localidad <> vg_codloc
LET hora = CURRENT
DISPLAY hora
LET i = 0
LET j = 0
LET porc_acum = 0
WHENEVER ERROR STOP
FOREACH q_ex INTO rs.*
	LET i = i + 1
	LET j = j + 1
	LET porc = (j / num_items) * 100
	IF porc >= 5 OR i = num_items THEN
		LET porc_acum = porc_acum + porc
		IF i = num_items THEN
			LET porc_acum = 100
		END IF
		LET hora = CURRENT
		DISPLAY hora, '  ', 
			i USING '####&', 
			' de ', 
			num_items USING '####&', 
			' (', 
			porc_acum USING '##&', '%', ')' 
		LET j = 0
	END IF
	SELECT * FROM rept011 
		WHERE r11_compania = vg_codcia    AND 
		      r11_bodega   = rs.te_bodega AND 
		      r11_item     = rs.te_item
	IF status <> NOTFOUND THEN
	WHENEVER ERROR STOP
	UPDATE rept011 SET r11_stock_act = rs.te_stock
		WHERE r11_compania = vg_codcia    AND 
		      r11_bodega   = rs.te_bodega AND 
		      r11_item     = rs.te_item
	END IF
END FOREACH
END FUNCTION
