DATABASE aceros


DEFINE db1		CHAR(20)
DEFINE serv1		CHAR(20)
DEFINE serv2		CHAR(20)
DEFINE serv3		CHAR(20)
DEFINE serv4		CHAR(20)
DEFINE serv_trab	CHAR(20)
DEFINE base_gye		CHAR(20)
DEFINE codcia1		LIKE gent001.g01_compania
DEFINE codloc1		LIKE gent002.g02_localidad
DEFINE rm_b00		RECORD LIKE ctbt000.*
DEFINE vm_anopro_ini	INTEGER
DEFINE vm_anopro_fin	INTEGER
DEFINE vm_mespro_ini	SMALLINT
DEFINE vm_mespro_fin	SMALLINT
DEFINE tit_mes_ini	CHAR(11)
DEFINE tit_mes_fin	CHAR(11)



MAIN

	IF num_args() <> 9 THEN
		DISPLAY 'PARAMETROS INCORRECTOS. '
		DISPLAY 'SON: BASE1 SERVIDOR_BASE1 COMPAÑIA LOCALIDAD LG/LQ'
		DISPLAY 'ANIO_INI ANIO_FIN MES_INI MES_FIN '
		EXIT PROGRAM
	END IF
	LET db1     = arg_val(1)
	LET serv1   = arg_val(2)
	IF serv1 = 'acgyede' OR serv1 = 'ACUIORE' OR serv1 = 'acuiopr' THEN
		LET serv2   = 'acgyede'
		LET serv3   = 'acuiopr'
		LET serv4   = 'acuiopr'
	ELSE
		LET serv2   = 'idsgye01'
		LET serv3   = 'idsuio01'
		LET serv4   = 'idsuio02'
	END IF
	LET codcia1 = arg_val(3)
	LET codloc1 = arg_val(4)
	CASE arg_val(5)
		WHEN 'LG'
			LET serv2   = 'acgyede'
			LET serv3   = serv2
			LET serv4   = serv2
		WHEN 'LQ'
			LET serv2   = 'acuiopr'
			LET serv3   = serv2
			LET serv4   = serv2
	END CASE
	CALL activar_base(db1, serv1)
	CALL validar_parametros(codcia1, codloc1)
	--LET base_gye = 'acero_gm'
	LET serv_trab = FGL_GETENV('INFORMIXSERVER')
	IF serv_trab = 'acgyede' OR serv_trab = 'ACUIORE' OR
	   serv_trab = 'acuiopr'
	THEN
		LET base_gye = 'aceros'
	ELSE
		LET base_gye = 'acero_gm'
	END IF
	CASE arg_val(5)
		WHEN 'LG'
			LET base_gye = 'aceros'
		WHEN 'LQ'
			LET base_gye = 'acero_gm'
	END CASE
	CALL funcion_master()

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



FUNCTION funcion_master()
DEFINE fecha		DATE
DEFINE query		CHAR(600)
DEFINE base2		CHAR(40)

INITIALIZE rm_b00.* TO NULL
LET vm_anopro_ini = arg_val(6)
LET vm_mespro_ini = arg_val(7)
LET vm_anopro_fin = arg_val(8)
LET vm_mespro_fin = arg_val(9)
CASE codloc1
	WHEN 1 LET base2 = base_gye CLIPPED, '@', serv2 CLIPPED
	WHEN 3 LET base2 = 'acero_qm@', serv3 CLIPPED
END CASE
LET query = 'SELECT * FROM ', base2 CLIPPED, ':ctbt000 ',
		' WHERE b00_compania = ', codcia1,
		' INTO TEMP t1 '
PREPARE exe_b00_1 FROM query
EXECUTE exe_b00_1
SELECT * INTO rm_b00.* FROM t1
DROP TABLE t1
IF vm_anopro_ini > YEAR(TODAY) OR vm_anopro_ini < rm_b00.b00_anopro THEN
	DISPLAY 'Año Inicial de proceso contable está incorrecto.'
	EXIT PROGRAM
END IF
IF vm_anopro_fin > YEAR(TODAY) OR vm_anopro_fin < rm_b00.b00_anopro THEN
	DISPLAY 'Año Final de proceso contable está incorrecto.'
	EXIT PROGRAM
END IF
LET fecha = MDY(vm_mespro_ini, 1, vm_anopro_ini)
IF fecha > TODAY OR fecha < rm_b00.b00_fecha_cm THEN
	DISPLAY 'Mes Inicial para la remayorización está incorrecto.'
	EXIT PROGRAM
END IF
LET fecha = MDY(vm_mespro_fin, 1, vm_anopro_fin)
IF fecha > TODAY OR fecha < rm_b00.b00_fecha_cm THEN
	DISPLAY 'Mes Inicial para la remayorización está incorrecto.'
	EXIT PROGRAM
END IF
IF vm_anopro_ini > vm_anopro_fin THEN
	DISPLAY 'El Año Final debe ser mayor o igual al Año Inicial.'
	EXIT PROGRAM
END IF
IF vm_anopro_ini = vm_anopro_fin THEN
	IF vm_mespro_ini > vm_mespro_fin THEN
		DISPLAY 'El Mes Final debe ser mayor o igual al Mes Inicial.'
		EXIT PROGRAM
	END IF
END IF
CALL proceso_mayorizacion(base2)
DISPLAY ' '
DISPLAY 'Mayorización Terminó Correctamente.'

END FUNCTION



FUNCTION proceso_mayorizacion(base)
DEFINE base		CHAR(40)
DEFINE mayorizado	SMALLINT
DEFINE primera, ultimo	SMALLINT
DEFINE mes		SMALLINT
DEFINE mes_ini, mes_fin	SMALLINT
DEFINE anio		INTEGER
DEFINE mensaje		VARCHAR(150)

LET mes_ini = vm_mespro_ini
LET mes_fin = vm_mespro_fin
IF vm_anopro_ini < vm_anopro_fin THEN
	LET mes_fin = 12
END IF
LET primera = 1
LET ultimo  = 0
FOR anio = vm_anopro_ini TO vm_anopro_fin
	LET ultimo = ultimo + 1
	IF NOT primera AND anio < vm_anopro_fin THEN
		LET mes_ini = 1
		LET mes_fin = 12
	END IF
	IF NOT primera THEN
		IF ultimo > 1 AND anio = vm_anopro_fin THEN
			LET mes_ini = 1
			LET mes_fin = vm_mespro_fin
		END IF
	END IF
	LET primera = 0
	FOR mes = mes_ini TO mes_fin
		CALL mayorizacion_mes(base, codcia1, rm_b00.b00_moneda_base,
					anio, mes, 0)
			RETURNING mayorizado
		IF NOT mayorizado THEN
			LET mensaje = 'No se pudo mayorizar el MES ',
				mes USING "&&", ' ANIO ', anio USING "&&&&",
				'. Ultimo periodo mayorizado ',
				(MDY(mes, 01, anio) - 1 UNITS DAY)
				USING "yyyy-mm", '.'
			DISPLAY mensaje
			EXIT PROGRAM
		END IF
		LET mensaje = 'MES ', mes USING "&&", ' ANIO ',
				anio USING "&&&&", '  MAYORIZADO CORRECTAMENTE.'
		DISPLAY mensaje CLIPPED
		DISPLAY ' '
	END FOR
END FOR

END FUNCTION



FUNCTION mayorizacion_mes(base, codcia, moneda, ano, mes, flag)
DEFINE base		CHAR(40)
DEFINE codcia		LIKE ctbt012.b12_compania
DEFINE moneda		LIKE ctbt012.b12_moneda
DEFINE ano		SMALLINT
DEFINE mes, flag	SMALLINT
DEFINE r_cia		RECORD LIKE ctbt000.*
DEFINE r_b06		RECORD LIKE ctbt006.*
DEFINE rd		RECORD LIKE ctbt013.*
DEFINE r_sal		RECORD LIKE ctbt011.*
DEFINE tipo_cta		CHAR(1)
DEFINE existe		SMALLINT
DEFINE campo_db		CHAR(15)
DEFINE campo_cr		CHAR(15)
DEFINE expr_up		CHAR(400)
DEFINE debito		LIKE ctbt013.b13_valor_base
DEFINE credito		LIKE ctbt013.b13_valor_base
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE num_ctas		INTEGER
DEFINE num_act		INTEGER
DEFINE tot_db		DECIMAL(15,2)
DEFINE tot_cr		DECIMAL(15,2)
DEFINE num_row		INTEGER
DEFINE query		CHAR(1500)

INITIALIZE r_cia.* TO NULL
LET query = 'SELECT * FROM ', base CLIPPED, ':ctbt000 ',
		' WHERE b00_compania = ', codcia,
		' INTO TEMP t1 '
PREPARE exe_b00 FROM query
EXECUTE exe_b00
SELECT * INTO r_cia.* FROM t1
DROP TABLE t1
IF ano < r_cia.b00_anopro THEN 
	DISPLAY 'ERROR: El ano ya esta cerrado'
	RETURN 0
END IF
IF mes < 1 OR mes > 12 THEN 
	DISPLAY 'ERROR: Mes no esta el rango de 1 a 12'
	RETURN 0
END IF
IF moneda IS NULL OR (moneda <> r_cia.b00_moneda_base AND
   moneda <> r_cia.b00_moneda_aux)
THEN
	DISPLAY 'ERROR: Moneda no esta configurada en Contabilidad'
	RETURN 0
END IF
IF r_cia.b00_cuenta_uti IS NULL THEN
	DISPLAY 'ERROR: No esta configurada la cuenta utilidad presente ejercicio.'
	RETURN 0
END IF
BEGIN WORK
WHENEVER ERROR STOP
LET query = 'SELECT * FROM ', base CLIPPED, ':ctbt006 ',
		'WHERE b06_compania = ', codcia,
		'  AND b06_ano      = ', ano,
		'  AND b06_mes      = ', mes
PREPARE cons_b06 FROM query
DECLARE q_b06 CURSOR WITH HOLD FOR cons_b06
LET num_row = 0
OPEN q_b06
FETCH q_b06 INTO r_b06.*
IF STATUS = NOTFOUND THEN
	LET query = 'INSERT INTO ', base CLIPPED, ':ctbt006 ',
			'VALUES (', codcia, ', ', ano, ', ', mes, ', "FOBOS", ',
				' CURRENT) '
	PREPARE exec_b06 FROM query
	EXECUTE exec_b06
	LET num_row = SQLCA.SQLERRD[6]
END IF
CLOSE q_b06
FREE q_b06
DISPLAY 'Bloqueando maestro de saldos'
LOCK TABLE ctbt011 IN EXCLUSIVE MODE
IF STATUS < 0 THEN
	DISPLAY 'ERROR: No se pudo bloquear en modo exclusivo maestro de ',
		'saldos.'
	WHENEVER ERROR STOP
	ROLLBACK WORK
	RETURN 0
END IF
WHENEVER ERROR STOP
LET campo_db = 'b11_db_mes_', mes USING '&&'
LET campo_cr = 'b11_cr_mes_', mes USING '&&'
LET expr_up  = 'UPDATE ', base CLIPPED, ':ctbt011 ',
			'SET ', campo_db, ' = 0, ',
				campo_cr, ' = 0 ' ,
			' WHERE  b11_compania = ? ',
			'   AND  b11_moneda   = ? ',
			'   AND  b11_ano      = ? ',
			'   AND (b11_cuenta   MATCHES ("114*") ',
			'    OR  b11_cuenta   MATCHES ("6*")) '
PREPARE up_mesc FROM expr_up
EXECUTE up_mesc USING codcia, moneda, ano
LET query = 'SELECT b.* ',
		'FROM ', base CLIPPED, ':ctbt012 a, ',
			base CLIPPED, ':ctbt013 b ',
		'WHERE  a.b12_compania            = ', codcia,
		'  AND  YEAR(a.b12_fec_proceso)   = ', ano,
		'  AND  MONTH(a.b12_fec_proceso)  = ', mes,
		'  AND  a.b12_estado             <> "E" ',
		'  AND  b.b13_compania            = a.b12_compania ',
		'  AND  b.b13_tipo_comp           = a.b12_tipo_comp ',
		'  AND  b.b13_num_comp            = a.b12_num_comp ',
		'  AND (b.b13_cuenta             MATCHES ("114*") ',
		'   OR  b.b13_cuenta             MATCHES ("6*")) '
PREPARE cons_b13 FROM query
DECLARE q_tcomp CURSOR WITH HOLD FOR cons_b13
CREATE TEMP table temp_may (	
		te_cuenta 	CHAR(12),
		te_debito	DECIMAL(14,2),
		te_credito	DECIMAL(14,2))
CREATE INDEX i1_temp_may ON temp_may (te_cuenta)
LET num_ctas = 0
LET tot_db = 0
LET tot_cr = 0
DISPLAY 'Encerando maestro de saldos. Por favor espere ...'
FOREACH q_tcomp INTO rd.*
	DISPLAY 'Procesando cuenta: ', rd.b13_cuenta, '   ', num_ctas
	LET query = 'SELECT b10_tipo_cta ',
			'FROM ', base CLIPPED, ':ctbt010 ',
			'WHERE b10_compania = ', rd.b13_compania,
			'  AND b10_cuenta   = "', rd.b13_cuenta, '"'
	PREPARE cons_b10 FROM query
	DECLARE q_b10 CURSOR WITH HOLD FOR cons_b10
	OPEN q_b10
	FETCH q_b10 INTO tipo_cta
	IF STATUS = NOTFOUND THEN
		ROLLBACK WORK
		WHENEVER ERROR STOP
		DISPLAY 'ERROR no existe cuenta: ', rd.b13_cuenta
		RETURN 0
	END IF
	CLOSE q_b10
	FREE q_b10
	LET num_ctas = num_ctas + 1
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
DECLARE q_tmm CURSOR FOR
	SELECT * FROM temp_may
		ORDER BY te_cuenta DESC
WHENEVER ERROR CONTINUE
SET LOCK MODE TO WAIT 1
LET num_act = 1
FOREACH q_tmm INTO cuenta, debito, credito
	DISPLAY 'Mayorizando cuenta: ', cuenta, '  ', num_act, '   ',
		debito, ' ', credito
	LET num_act = num_act + 1
	LET existe = 0
	WHILE NOT existe
		LET query = 'SELECT * FROM ', base CLIPPED, ':ctbt011 ',
				'WHERE b11_compania = ', codcia,
				'  AND b11_moneda   = "', moneda, '"',
				'  AND b11_ano      = ', ano,
				'  AND b11_cuenta   = "', cuenta, '"',
				' FOR UPDATE '
		PREPARE cons_b11 FROM query
		DECLARE q_mayc CURSOR FOR cons_b11
	        OPEN q_mayc 
		FETCH q_mayc INTO r_sal.*
		IF STATUS = NOTFOUND THEN
			LET query = 'INSERT INTO ', base CLIPPED, ':ctbt011 ',
					'VALUES (', codcia, ', "',
						cuenta CLIPPED, '", "', moneda,
						'", ', ano, ',0,0,0,0,0,0,0,0,',
						'0,0,0,0,0,0,0,0,0,0,0,0,0,0,',
						'0,0,0,0) '
			PREPARE ins_b11 FROM query
			EXECUTE ins_b11
			IF STATUS < 0 THEN
				ROLLBACK WORK
				WHENEVER ERROR STOP
				DISPLAY 'ERROR al crear registro de saldos.',
					cuenta CLIPPED
				RETURN 0
			END IF
		ELSE
			IF STATUS < 0 THEN
				ROLLBACK WORK
				WHENEVER ERROR STOP
				DISPLAY 'ERROR: Cuenta ', cuenta CLIPPED,
					' esta bloqueada por otro usuario'
				RETURN 0
			END IF
			LET existe = 1
		END IF
	END WHILE
	LET campo_db = 'b11_db_mes_', mes USING '&&'
	LET campo_cr = 'b11_cr_mes_', mes USING '&&'
	LET expr_up = 'UPDATE ', base CLIPPED, ':ctbt011',
				' SET ', campo_db, ' = ', 
					     campo_db, ' + ?, ',
	                                     campo_cr, ' = ', 
					     campo_cr, ' + ? ',
				' WHERE CURRENT OF q_mayc' 
	PREPARE up_may FROM expr_up
	EXECUTE	up_may USING debito, credito
	IF STATUS < 0 THEN
		ROLLBACK WORK
		WHENEVER ERROR STOP
		DISPLAY 'ERROR al actualizar maestro de saldos de cuenta ',
			cuenta CLIPPED
		RETURN 0
	END IF
	CLOSE q_mayc
	FREE q_mayc
END FOREACH
DROP TABLE temp_may
WHENEVER ERROR CONTINUE
--DISPLAY 'Actualizando estado de comprobantes mayorizados'
LET query = 'UPDATE ', base CLIPPED, ':ctbt012 ',
		'SET b12_estado = "M" ',
		'WHERE b12_compania            = ', codcia,
		'  AND YEAR(b12_fec_proceso)   = ', ano,
		'  AND MONTH(b12_fec_proceso)  = ', mes,
		'  AND b12_estado             <> "E" ',
		'  AND EXISTS ',
			'(SELECT 1 FROM ', base CLIPPED, ':ctbt013 ',
			'WHERE  b13_compania   = b12_compania ',
			'  AND  b13_tipo_comp  = b12_tipo_comp ',
			'  AND  b13_num_comp   = b12_num_comp ',
			'  AND (b13_cuenta    MATCHES ("114*") ',
			'   OR  b13_cuenta    MATCHES ("6*"))) '
PREPARE up_b12 FROM query
EXECUTE up_b12
IF STATUS < 0 THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	DISPLAY 'ERROR al actualizar estado de los comprobantes mayorizados '
	RETURN 0
END IF
WHENEVER ERROR STOP
LET query = 'DELETE FROM ', base CLIPPED, ':ctbt006 WHERE ROWID = ', num_row
PREPARE bor_b12 FROM query
EXECUTE bor_b12
COMMIT WORK
IF flag THEN
	DISPLAY 'Mayorizacion Terminada Correctamente. OK'
END IF
RETURN 1

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
