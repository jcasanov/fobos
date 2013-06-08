DATABASE aceros
GLOBALS

DEFINE vg_producto	VARCHAR(10)
DEFINE vg_proceso	LIKE gent054.g54_proceso
DEFINE vg_base		LIKE gent051.g51_basedatos
DEFINE vg_modulo	LIKE gent050.g50_modulo
DEFINE vg_codcia	LIKE gent001.g01_compania
DEFINE vg_codloc	LIKE gent002.g02_localidad
DEFINE vg_usuario	LIKE gent005.g05_usuario
DEFINE vg_separador	LIKE fobos.fb_separador
DEFINE vg_dir_fobos	LIKE fobos.fb_dir_fobos
DEFINE vg_gui		SMALLINT

DEFINE rg_gen		RECORD LIKE gent000.* 
DEFINE rg_cia		RECORD LIKE gent001.* 
DEFINE rg_loc		RECORD LIKE gent002.* 
DEFINE rg_mod		RECORD LIKE gent050.* 
DEFINE rg_pro		RECORD LIKE gent054.* 

DEFINE ag_one 		ARRAY[9] OF CHAR (6)
DEFINE ag_two 		ARRAY[9] OF CHAR (10)
DEFINE ag_three 	ARRAY[9] OF CHAR (9)
DEFINE ag_four 		ARRAY[9] OF CHAR (13)
DEFINE ag_five 		ARRAY[9] OF CHAR (13)

END GLOBALS


MAIN

IF num_args() <> 2 THEN
	DISPLAY 'ERROR: Numero de parametros incorrectos.'
	SLEEP 4
	EXIT PROGRAM
END IF
LET vg_base   = arg_val(1)
LET vg_codcia = arg_val(2)
IF vg_base <> 'acero_gm' AND vg_base <> 'acero_qm' AND vg_base <> 'aceros' THEN
	DISPLAY 'ERROR: Base de datos incorrecta.'
	SLEEP 4
	EXIT PROGRAM
END IF
CALL activa_base()
SELECT USER INTO vg_usuario FROM dual
LET vg_usuario = UPSHIFT(vg_usuario)
CALL verifica_descuadres_mayorizacion()

END MAIN



FUNCTION activa_base()
DEFINE query		CHAR(90)

CLOSE DATABASE
LET query = 'DATABASE ', vg_base
PREPARE bd FROM query
EXECUTE bd

END FUNCTION




FUNCTION verifica_descuadres_mayorizacion()
DEFINE r_b00		RECORD LIKE ctbt000.*
DEFINE query		CHAR(700)
DEFINE campo_db		CHAR(15)
DEFINE campo_cr		CHAR(15)
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE valor_db_cr 	DECIMAL(12,2)
DEFINE valor_tran	DECIMAL(12,2)
DEFINE mayorizar 	SMALLINT
DEFINE ano, mes		SMALLINT
DEFINE fecha		DATE

SET ISOLATION TO DIRTY READ;
SELECT * INTO r_b00.* FROM ctbt000 WHERE b00_compania = vg_codcia
DECLARE q1 CURSOR WITH HOLD FOR 
	SELECT UNIQUE MDY(MONTH(b12_fec_proceso), 1, YEAR(b12_fec_proceso))
		FROM ctbt012
		WHERE b12_compania         = vg_codcia AND 
		      b12_moneda           = r_b00.b00_moneda_base --AND
		     --(DATE(b12_fec_modifi) = TODAY OR 
		      --DATE(b12_fecing)     = TODAY)
		ORDER BY 1
FOREACH q1 INTO fecha
	SELECT b12_moneda, ctbt013.* FROM ctbt012, ctbt013
		WHERE b12_compania           = vg_codcia
	  	  AND YEAR(b12_fec_proceso)  = YEAR(fecha)
	  	  AND MONTH(b12_fec_proceso) = MONTH(fecha)
	  	  AND b12_estado             <> 'E'
	  	  AND b12_compania           = b13_compania
          	  AND b12_tipo_comp          = b13_tipo_comp
          	  AND b12_num_comp           = b13_num_comp
		  INTO TEMP te
	LET campo_db = 'b11_db_mes_', MONTH(fecha)USING '&&'
	LET campo_cr = 'b11_cr_mes_', MONTH(fecha)USING '&&'
	LET query = 'SELECT b11_cuenta, ', campo_db, ', SUM(b13_valor_base) ',
			'FROM ctbt011, te ',
			'WHERE b11_compania   = b13_compania ',
          		 ' AND b11_ano        = YEAR(b13_fec_proceso) ',
	  	         ' AND b11_cuenta     = b13_cuenta ',
	  	         ' AND b11_moneda     = b12_moneda ',
	                 ' AND b13_valor_base > 0 ',
		         ' AND b13_cuenta <> "', r_b00.b00_cuenta_uti, '" ',
	                 'GROUP BY 1,2 ',
			 'HAVING ', campo_db, ' <> SUM(b13_valor_base) ',
		    'UNION ALL ',
	            'SELECT b11_cuenta, ', campo_cr, ', SUM(b13_valor_base) ',
			'FROM ctbt011, te ',
			'WHERE b11_compania   = b13_compania ',
          		 ' AND b11_ano        = YEAR(b13_fec_proceso) ',
	  	         ' AND b11_cuenta     = b13_cuenta ',
	  	         ' AND b11_moneda     = b12_moneda ',
	                 ' AND b13_valor_base < 0 ',
		         ' AND b13_cuenta <> "', r_b00.b00_cuenta_uti, '" ',
	                 'GROUP BY 1,2 ',
			 'HAVING ', campo_cr, ' * -1 <> SUM(b13_valor_base) ',
			'ORDER BY 1'
	PREPARE vdb FROM query
	LET ano = YEAR(fecha)
	LET mes = MONTH(fecha)
	LET mayorizar = 0
	DECLARE q_vdb CURSOR WITH HOLD FOR vdb
	FOREACH q_vdb INTO cuenta, valor_db_cr, valor_tran
		LET mayorizar = 1
		INSERT INTO ctbt666 VALUES (ano, mes, cuenta, valor_db_cr, 
					    valor_tran, CURRENT)
	END FOREACH
	IF mayorizar THEN
		CALL fl_mayorizacion_mes(vg_codcia, r_b00.b00_moneda_base,
				         ano, mes)
			RETURNING int_flag
	END IF
	DROP TABLE te
END FOREACH

END FUNCTION



FUNCTION fl_mayorizacion_mes(codcia, moneda, ano, mes)
DEFINE codcia		LIKE ctbt012.b12_compania
DEFINE moneda		LIKE ctbt012.b12_moneda
DEFINE ano		SMALLINT
DEFINE mes		SMALLINT
DEFINE r_cia		RECORD LIKE ctbt000.*
DEFINE rd		RECORD LIKE ctbt013.*
DEFINE r_sal		RECORD LIKE ctbt011.*
DEFINE tipo_cta		CHAR(1)
DEFINE existe		SMALLINT
DEFINE campo_db		CHAR(15)
DEFINE campo_cr		CHAR(15)
DEFINE expr_up		VARCHAR(200)
DEFINE debito		LIKE ctbt013.b13_valor_base
DEFINE credito		LIKE ctbt013.b13_valor_base
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE num_ctas		INTEGER
DEFINE num_act		INTEGER
DEFINE tot_db		DECIMAL(15,2)
DEFINE tot_cr		DECIMAL(15,2)
DEFINE num_row		INTEGER
DEFINE hora		DATETIME YEAR TO SECOND

CALL fl_lee_compania_contabilidad(codcia) RETURNING r_cia.*
IF r_cia.b00_compania IS NULL THEN
	--CALL fl_mostrar_mensaje('Compañía no está configurada en Contabilidad', 'exclamation')
	RETURN 0
END IF
IF ano < r_cia.b00_anopro THEN 
	--CALL fl_mostrar_mensaje('El ano ya está cerrado', 'exclamation')
	RETURN 0
END IF
IF mes < 1 OR mes > 12 THEN 
	--CALL fl_mostrar_mensaje('Mes no está en el rango de 1 a 12', 'exclamation')
	RETURN 0
END IF
IF moneda IS NULL OR (moneda <> r_cia.b00_moneda_base AND 
	moneda <> r_cia.b00_moneda_aux) THEN
	--CALL fl_mostrar_mensaje('Moneda no está configurada en Contabilidad', 'exclamation')
	RETURN 0
END IF
IF r_cia.b00_cuenta_uti IS NULL THEN
	--CALL fl_mostrar_mensaje('No está configurada la cuenta utilidad presente ejercicio.', 'exclamation')
	RETURN 0
END IF
BEGIN WORK
WHENEVER ERROR STOP
SELECT * FROM ctbt006 
	WHERE b06_compania = codcia AND 
	      b06_ano      = ano    AND
	      b06_mes      = mes
LET num_row = 0
IF status = NOTFOUND THEN
	INSERT INTO ctbt006 VALUES (codcia, ano, mes, vg_usuario, CURRENT)
	LET num_row = SQLCA.SQLERRD[6]
END IF
LET hora = CURRENT
DISPLAY hora, ' Remayorizando: ', ano, ' ', mes
LOCK TABLE ctbt011 IN EXCLUSIVE MODE
IF status < 0 THEN
	--CALL fl_mostrar_mensaje('No se pudo bloquear en modo exclusivo maestro de saldos. Asegúrese que nadie esté ingresando/modificando comprobantes en el sistema', 'exclamtion')
	WHENEVER ERROR STOP
	ROLLBACK WORK
	RETURN 0
END IF
WHENEVER ERROR STOP
LET campo_db = 'b11_db_mes_', mes USING '&&'
LET campo_cr = 'b11_cr_mes_', mes USING '&&'
LET expr_up = 'UPDATE ctbt011 SET ', campo_db, ' = 0, ', 
	                             campo_cr, ' = 0 ' ,
			' WHERE b11_compania = ? AND ',
			'       b11_moneda   = ? AND ',
			'       b11_ano      = ? '
PREPARE up_mesc FROM expr_up
--DISPLAY 'Encerando maestro de saldos'
EXECUTE up_mesc USING codcia, moneda, ano	
DECLARE q_tcomp CURSOR FOR
	SELECT ctbt013.* FROM ctbt012, ctbt013
		WHERE b12_compania           = codcia AND 
		      YEAR(b12_fec_proceso)  = ano    AND
		      MONTH(b12_fec_proceso) = mes    AND
		      b12_estado <> 'E' AND
		      b12_compania           = b13_compania  AND 
		      b12_tipo_comp          = b13_tipo_comp AND 
		      b12_num_comp           = b13_num_comp 
CREATE TEMP table temp_may (	
		te_cuenta 	CHAR(12),
		te_debito	DECIMAL(14,2),
		te_credito	DECIMAL(14,2))
CREATE INDEX i1_temp_may ON temp_may (te_cuenta)
LET num_ctas = 0
LET tot_db = 0
LET tot_cr = 0
FOREACH q_tcomp INTO rd.*
	--DISPLAY 'Procesando cuenta: ', rd.b13_cuenta, '   ', num_ctas
	SELECT b10_tipo_cta INTO tipo_cta FROM ctbt010
		WHERE b10_compania = rd.b13_compania AND 
		      b10_cuenta   = rd.b13_cuenta
	LET num_ctas = num_ctas + 1
	LET debito  = 0
	LET credito = 0
	IF rd.b13_valor_base < 0 THEN
		LET credito = rd.b13_valor_base * -1
	ELSE
		LET debito  = rd.b13_valor_base
	END IF
	IF tipo_cta = 'R' THEN
		CALL fl_genera_niveles_mayorizacion(r_cia.b00_cuenta_uti, debito, credito)
	END IF
	CALL fl_genera_niveles_mayorizacion(rd.b13_cuenta, debito, credito)
END FOREACH
DECLARE q_tmm CURSOR FOR SELECT * FROM temp_may
	ORDER BY te_cuenta DESC
WHENEVER ERROR CONTINUE
SET LOCK MODE TO WAIT 1
LET num_act = 1
FOREACH q_tmm INTO cuenta, debito, credito
	--DISPLAY 'Mayorizando cuenta: ', cuenta, '  ', num_act, '   ',
		--debito, ' ', credito
	LET num_act = num_act + 1
	LET existe = 0
	WHILE NOT existe
		DECLARE q_mayc CURSOR FOR
			SELECT * FROM ctbt011
				WHERE b11_compania = codcia AND 
		                      b11_moneda   = moneda AND
		                      b11_ano      = ano    AND
		                      b11_cuenta   = cuenta
			        FOR UPDATE
	        OPEN q_mayc 
		FETCH q_mayc INTO r_sal.*
		IF status = NOTFOUND THEN
			CLOSE q_mayc
			INSERT INTO ctbt011 VALUES (codcia, cuenta,
				moneda, ano,
				0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
				0,0,0,0,0)
			IF status < 0 THEN
				ROLLBACK WORK
				WHENEVER ERROR STOP
				--CALL fl_mostrar_mensaje('Error al crear registro de saldos', 'exclamation')
				RETURN 0
			END IF
		ELSE
			IF status < 0 THEN
				ROLLBACK WORK
				WHENEVER ERROR STOP
				--CALL fl_mostrar_mensaje('Cuenta ' || cuenta || ' está bloqueada por otro usuario', 'exclamation')
				RETURN 0
			END IF
			LET existe = 1
		END IF
	END WHILE
	LET campo_db = 'b11_db_mes_', mes USING '&&'
	LET campo_cr = 'b11_cr_mes_', mes USING '&&'
	LET expr_up = 'UPDATE ctbt011 SET ', campo_db, ' = ', 
					     campo_db, ' + ?, ',
	                                     campo_cr, ' = ', 
					     campo_cr, ' + ? ',
				' WHERE CURRENT OF q_mayc' 
	PREPARE up_may FROM expr_up
	EXECUTE	up_may USING debito, credito
	IF status < 0 THEN
		ROLLBACK WORK
		WHENEVER ERROR STOP
		--CALL fl_mostrar_mensaje('Error al actualizar maestro de saldos de cuenta ' || cuenta, 'exclamation')
		RETURN 0
	END IF
END FOREACH
DROP TABLE temp_may
WHENEVER ERROR CONTINUE
--ERROR 'Actualizando estado de comprobantes mayorizados'
UPDATE ctbt012 SET b12_estado = 'M' 
	WHERE b12_compania           = codcia AND 
	      YEAR(b12_fec_proceso)  = ano    AND
	      MONTH(b12_fec_proceso) = mes    AND
	      b12_estado <> 'E'
IF status < 0 THEN
	ROLLBACK WORK
	WHENEVER ERROR STOP
	--CALL fl_mostrar_mensaje('Error al actualizar estado de los comprobantes mayorizados ', 'exclamation')
	RETURN 0
END IF
WHENEVER ERROR STOP
DELETE FROM ctbt006 WHERE ROWID = num_row
COMMIT WORK
--CALL fl_mostrar_mensaje('Mayorización terminó correctamente', 'exclamation')
LET hora = CURRENT
DISPLAY hora, ' Remayorizacion Ok: ', ano, ' ', mes
RETURN 1

END FUNCTION



FUNCTION fl_genera_niveles_mayorizacion(cuenta, debito, credito)
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE debito		LIKE ctbt013.b13_valor_base
DEFINE credito		LIKE ctbt013.b13_valor_base
DEFINE i, j, aux	SMALLINT
DEFINE ini, fin 	SMALLINT
DEFINE ceros		CHAR(10)
DEFINE rn		RECORD LIKE ctbt001.*

DECLARE q_niv CURSOR FOR SELECT * FROM ctbt001
	ORDER BY b01_nivel DESC
LET i = 0
FOREACH q_niv INTO rn.*
	LET i = i + 1
	IF i = 1 THEN
		LET aux = rn.b01_posicion_i - 1
		CALL fl_inserta_temporal_mayorizacion(cuenta, debito, credito)
		LET cuenta = cuenta[1, aux]
	ELSE
		CALL fl_inserta_temporal_mayorizacion(cuenta, debito, credito)
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



FUNCTION fl_inserta_temporal_mayorizacion(cuenta, debito, credito)
DEFINE cuenta		LIKE ctbt010.b10_cuenta
DEFINE debito		DECIMAL(14,2)
DEFINE credito		DECIMAL(14,2)

SELECT * FROM temp_may WHERE te_cuenta = cuenta
IF status = NOTFOUND THEN
	INSERT INTO temp_may VALUES(cuenta, debito, credito)	
ELSE
	UPDATE temp_may SET te_debito  = te_debito  + debito,
	                    te_credito = te_credito + credito
		WHERE te_cuenta = cuenta
END IF
			
END FUNCTION



FUNCTION fl_lee_compania_contabilidad(cod_cia)
DEFINE cod_cia		LIKE ctbt000.b00_compania
DEFINE r		RECORD LIKE ctbt000.*

INITIALIZE r.* TO NULL
SELECT * INTO r.* FROM ctbt000 WHERE b00_compania = cod_cia
RETURN r.*

END FUNCTION
