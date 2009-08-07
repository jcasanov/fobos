DATABASE diteca
DEFINE vg_codcia		LIKE gent001.g01_compania
DEFINE vg_codloc1		LIKE gent002.g02_localidad
DEFINE base			CHAR(10)


DEFINE log_ult			RECORD LIKE log001.*
DEFINE log_nue			RECORD LIKE log001.*

MAIN

CALL startlog('errores')
LET vg_codcia  = 1
LET vg_codloc1 = 1      
IF num_args() <> 1 THEN
	DISPLAY 'Sintaxis: fglrun baja_stock base_datos'
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
CALL control_master()

END MAIN



FUNCTION control_master()
DEFINE r_g02		RECORD LIKE gent002.*
DEFINE i		SMALLINT
DEFINE file		CHAR(15)

DECLARE q_log CURSOR FOR SELECT * FROM log001 ORDER BY log_fecha DESC

OPEN  q_log
FETCH q_log INTO log_ult.*
CLOSE q_log
FREE  q_log

IF log_ult.log_fecha IS NULL THEN
	LET log_ult.log_fecha = CURRENT - 1 UNITS YEAR
END IF

SELECT * INTO r_g02.* FROM gent002 
	WHERE g02_compania = vg_codcia AND g02_matriz = 'S' 
IF status = NOTFOUND THEN
	DISPLAY 'No existe localidad matriz en compania: ', vg_codcia
	LET i = fgl_getkey()
	EXIT PROGRAM
END IF

{ Deberia hacer esto en base al stock desde la ultima transmision }
{ Think about it }

SELECT UNIQUE r11_item FROM rept011 INTO TEMP te

UNLOAD TO 'tr_a_quito_stock.txt'
	SELECT r11_bodega, r11_item, r11_stock_act FROM rept011
		WHERE r11_bodega IN 
			(SELECT r02_codigo FROM rept002 
				--WHERE r02_localidad = r_g02.g02_localidad AND 
				WHERE r02_localidad IN 
				     (vg_codloc1) AND 
				      r02_tipo = 'F') --AND r02_factura = 'S')
                  AND r11_stock_act <> 0
RUN 'bzip2 tr_a_quito_stock.txt'

UNLOAD TO 'tr_a_quito_items.txt'
	SELECT * FROM rept010
		WHERE r10_compania = vg_codcia 
	        AND r10_fecing BETWEEN log_ult.log_fecha AND CURRENT 
RUN 'bzip2 tr_a_quito_items.txt'

UNLOAD TO 'tr_a_quito_precios.txt'
        SELECT r10_compania, r10_codigo, 
	       r10_precio_mb, r10_fob  
	       FROM rept010
                WHERE r10_fec_camprec BETWEEN log_ult.log_fecha AND CURRENT
RUN 'bzip2 tr_a_quito_precios.txt'

END FUNCTION
