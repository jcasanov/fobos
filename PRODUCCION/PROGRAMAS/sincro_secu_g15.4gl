DATABASE jadesa



DEFINE fecha		DATE



MAIN

	IF num_args() <> 3 THEN
		DISPLAY 'PARAMENTROS INCORRECTOS. DEBEN SER: BASE FECHA (mm/dd/aaaa) FLAG (E/C)'
		DISPLAY ' '
		DISPLAY '  EJEMPLO: '
		DISPLAY ' '
		DISPLAY '     fglgo sincro_secu_g15 jadesa 10/24/2017 C'
		DISPLAY '        Donde C = Consulta y E = Ejecutar '
		DISPLAY ' '
		EXIT PROGRAM
	END IF
	CALL activar_base_datos(arg_val(1))
	LET fecha = arg_val(2)
	CALL obtener_secuencias_activas()
	IF comparar_secuencias_en_gent015() > 0 AND arg_val(3) = 'E' THEN
		CALL actualizar_gent015()
	END IF
	DROP TABLE tmp_sec_faltan
	IF arg_val(3) = 'E' THEN
		DISPLAY 'Proceso Terminado OK.'
	ELSE
		DISPLAY 'Verificación Terminada OK.'
	END IF
	DISPLAY ' '

END MAIN



FUNCTION activar_base_datos(base)
DEFINE base			CHAR(20)
DEFINE r_cia		RECORD LIKE gent001.*
DEFINE r_loc		RECORD LIKE gent002.*

CLOSE DATABASE 
WHENEVER ERROR CONTINUE
DATABASE base
IF STATUS < 0 THEN
	DISPLAY 'No se pudo abrir base de datos: ', base CLIPPED
	EXIT PROGRAM
END IF
WHENEVER ERROR STOP
SELECT * FROM gent051 WHERE g51_basedatos = base
IF STATUS = NOTFOUND THEN
	DISPLAY 'No se pudo abrir base de datos: ', base CLIPPED
	EXIT PROGRAM
END IF

END FUNCTION



FUNCTION actualizar_gent015()
DEFINE cuantos		INTEGER

BEGIN WORK
WHENEVER ERROR CONTINUE
	UPDATE gent015
		SET g15_numero = (SELECT a.numero
							FROM tmp_sec_faltan a
							WHERE a.g15_compania   = gent015.g15_compania
							  AND a.g15_localidad  = gent015.g15_localidad
							  AND a.g15_modulo     = gent015.g15_modulo
							  AND a.g15_bodega     = gent015.g15_bodega
							  AND a.g15_tipo       = gent015.g15_tipo)
		WHERE EXISTS
			(SELECT 1 FROM tmp_sec_faltan a
				WHERE a.g15_compania   = gent015.g15_compania
				  AND a.g15_localidad  = gent015.g15_localidad
				  AND a.g15_modulo     = gent015.g15_modulo
				  AND a.g15_bodega     = gent015.g15_bodega
				  AND a.g15_tipo       = gent015.g15_tipo
				  AND a.actua          = "U")

	IF STATUS <> 0 THEN
		DISPLAY '  ERROR (', STATUS USING "<<<------#",
				'): No se pudo actualizar la tabla gent015.'
		ROLLBACK WORK
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF

	INSERT INTO gent015
		(g15_compania, g15_localidad, g15_modulo, g15_bodega, g15_tipo,
		 g15_nombre, g15_numero, g15_usuario, g15_fecing)
		SELECT g15_compania, g15_localidad, g15_modulo, g15_bodega, g15_tipo,
				g15_nombre, g15_numero, g15_usuario, g15_fecing
			FROM tmp_sec_faltan
			WHERE actua = "I"

	IF STATUS <> 0 THEN
		DISPLAY '  ERROR (', STATUS USING "<<<------#",
				'): No se pudo insertar la tabla gent015.'
		ROLLBACK WORK
		WHENEVER ERROR STOP
		EXIT PROGRAM
	END IF

WHENEVER ERROR STOP
COMMIT WORK
DISPLAY ' '
SELECT COUNT(*) INTO cuantos FROM tmp_sec_faltan WHERE actua = "U"
DISPLAY ' Se actualizaron ', cuantos USING "<<<<&", ' registros en gent015.'
DISPLAY ' '
SELECT COUNT(*) INTO cuantos FROM tmp_sec_faltan WHERE actua = "I"
DISPLAY ' Se insertaron ', cuantos USING "<<<<&", ' registros en gent015.'
DISPLAY ' '

END FUNCTION



FUNCTION comparar_secuencias_en_gent015()
DEFINE fec_cur		VARCHAR(19)
DEFINE fecha_cur	DATETIME YEAR TO SECOND
DEFINE query		CHAR(400)
DEFINE modu, bod	CHAR(2)
DEFINE tip			CHAR(2)
DEFINE num, num2	INTEGER
DEFINE act			CHAR(1)
DEFINE cuantos		SMALLINT

DISPLAY ' Comparando secuencias que no están en la gent015 ...'
SELECT gent015.*, numero, "U" AS actua
	FROM gent015, tmp_sec
	WHERE g15_compania   = cia
	  AND g15_localidad  = loc
	  AND g15_modulo     = modulo
	  AND g15_bodega     = bode
	  AND g15_tipo       = tipo
	  AND g15_numero    <> numero
	INTO TEMP tmp_sec_faltan

LET fec_cur   = fecha USING "yyyy-mm-dd", " ", EXTEND(CURRENT, HOUR TO SECOND)
LET fecha_cur = fec_cur

LET query = 'INSERT INTO tmp_sec_faltan ',
				'SELECT cia, loc, modulo, bode, tipo, tipo, numero, ',
						'"FOBOS", "', fecha_cur, '", numero, "I" AS actua ',
					'FROM tmp_sec ',
				'WHERE NOT EXISTS ',
				'(SELECT 1 FROM gent015 ',
					'WHERE g15_compania   = cia ',
					'  AND g15_localidad  = loc ',
					'  AND g15_modulo     = modulo ',
					'  AND g15_bodega     = bode ',
					'  AND g15_tipo       = tipo) '
PREPARE exec_query FROM query
EXECUTE exec_query

DROP TABLE tmp_sec

DECLARE q1 CURSOR FOR
	SELECT g15_modulo, g15_bodega, g15_tipo, g15_numero, numero, actua
		FROM tmp_sec_faltan
		ORDER BY 1, 3
DISPLAY ' '
DISPLAY '  Secuencias encontradas: '
FOREACH q1 INTO modu, bod, tip, num, num2, act
	DISPLAY '  Modulo: ', modu, ' Bodega: ', bod, ' Tipo: ', tip,
			' Num. en g15.: ', num USING "<<<<&",
			'  Num. Act: ', num2 USING "<<<<&", ' ', act
END FOREACH
DISPLAY ' '
SELECT COUNT(*) INTO cuantos FROM tmp_sec_faltan
DISPLAY ' Total de secuencias: ', cuantos USING "<<<<&"
DISPLAY ' '
RETURN cuantos

END FUNCTION



FUNCTION obtener_secuencias_activas()
DEFINE cuantos		SMALLINT

SELECT r19_compania AS cia, r19_localidad AS loc, "RE" AS modulo, "AA" AS bode,
		r19_cod_tran AS tipo, MAX(r19_num_tran) AS numero
	FROM rept019
	WHERE DATE(r19_fecing) <= fecha
	GROUP BY 1, 2, 3, 4, 5
	INTO TEMP tmp_sec

SELECT COUNT(*) INTO cuantos FROM tmp_sec
DISPLAY ' Total de transacciones (rept019): ', cuantos USING "<<<<&"
DISPLAY ' '

INSERT INTO tmp_sec
	SELECT r34_compania AS cia, r34_localidad AS loc, "RE" AS modulo,
			r34_bodega AS bode, 'OD' AS tipo, MAX(r34_num_ord_des) AS numero
		FROM rept034
		WHERE DATE(r34_fecing) <= fecha
		GROUP BY 1, 2, 3, 4, 5

SELECT COUNT(*) INTO cuantos FROM tmp_sec WHERE tipo = 'OD'
DISPLAY ' Total de transacciones (rept034): ', cuantos USING "<<<<&"
DISPLAY ' '

INSERT INTO tmp_sec
	SELECT r36_compania AS cia, r36_localidad AS loc, "RE" AS modulo,
			r36_bodega AS bode, 'ND' AS tipo, MAX(r36_num_ord_des) AS numero
		FROM rept036
		WHERE DATE(r36_fecing) <= fecha
		GROUP BY 1, 2, 3, 4, 5

SELECT COUNT(*) INTO cuantos FROM tmp_sec WHERE tipo = 'ND'
DISPLAY ' Total de transacciones (rept036): ', cuantos USING "<<<<&"
DISPLAY ' '

INSERT INTO tmp_sec
	SELECT r21_compania AS cia, r21_localidad AS loc, "RE" AS modulo,
			"AA" AS bode, 'PF' AS tipo, MAX(r21_numprof) AS numero
		FROM rept021
		WHERE DATE(r21_fecing) <= fecha
		GROUP BY 1, 2, 3, 4, 5

SELECT COUNT(*) INTO cuantos FROM tmp_sec WHERE tipo = 'PF'
DISPLAY ' Total de transacciones (rept021): ', cuantos USING "<<<<&"
DISPLAY ' '

INSERT INTO tmp_sec
	SELECT r23_compania AS cia, r23_localidad AS loc, "RE" AS modulo,
			"AA" AS bode, 'PV' AS tipo, MAX(r23_numprof) AS numero
		FROM rept023
		WHERE DATE(r23_fecing) <= fecha
		GROUP BY 1, 2, 3, 4, 5

SELECT COUNT(*) INTO cuantos FROM tmp_sec WHERE tipo = 'PV'
DISPLAY ' Total de transacciones (rept023): ', cuantos USING "<<<<&"
DISPLAY ' '

INSERT INTO tmp_sec
	SELECT z22_compania AS cia, z22_localidad AS loc, "CO" AS modulo,
			"AA" AS bode, z22_tipo_trn AS tipo, MAX(z22_num_trn) AS numero
		FROM cxct022
		WHERE DATE(z22_fecing) <= fecha
		GROUP BY 1, 2, 3, 4, 5

INSERT INTO tmp_sec
	SELECT z21_compania AS cia, z21_localidad AS loc, "CO" AS modulo,
			"AA" AS bode, z21_tipo_doc AS tipo, MAX(z21_num_doc) AS numero
		FROM cxct021
		WHERE DATE(z21_fecing) <= fecha
		GROUP BY 1, 2, 3, 4, 5

INSERT INTO tmp_sec
	SELECT z24_compania AS cia, z24_localidad AS loc, "CO" AS modulo,
			"AA" AS bode, "SC" AS tipo, MAX(z24_numero_sol) AS numero
		FROM cxct024
		WHERE DATE(z24_fecing) <= fecha
		GROUP BY 1, 2, 3, 4, 5

SELECT COUNT(*) INTO cuantos FROM tmp_sec WHERE modulo = 'CO'
DISPLAY ' Total de transacciones (cxct021, cxct022, cxct024): ',
	cuantos USING "<<<<&"
DISPLAY ' '

INSERT INTO tmp_sec
	SELECT p22_compania AS cia, p22_localidad AS loc, "TE" AS modulo,
			"AA" AS bode, p22_tipo_trn AS tipo, MAX(p22_num_trn) AS numero
		FROM cxpt022
		WHERE DATE(p22_fecing) <= fecha
		GROUP BY 1, 2, 3, 4, 5

INSERT INTO tmp_sec
	SELECT p21_compania AS cia, p21_localidad AS loc, "TE" AS modulo,
			"AA" AS bode, p21_tipo_doc AS tipo, MAX(p21_num_doc) AS numero
		FROM cxpt021
		WHERE DATE(p21_fecing) <= fecha
		GROUP BY 1, 2, 3, 4, 5

INSERT INTO tmp_sec
	SELECT p27_compania AS cia, p27_localidad AS loc, "TE" AS modulo,
			"AA" AS bode, "RT" AS tipo, MAX(p27_num_ret) AS numero
		FROM cxpt027
		WHERE DATE(p27_fecing) <= fecha
		GROUP BY 1, 2, 3, 4, 5

SELECT COUNT(*) INTO cuantos FROM tmp_sec WHERE modulo = 'TE'
DISPLAY ' Total de transacciones (cxpt021, cxpt022, cxpt027): ',
	cuantos USING "<<<<&"
DISPLAY ' '

INSERT INTO tmp_sec
	SELECT c10_compania AS cia, c10_localidad AS loc, "OC" AS modulo,
			"AA" AS bode, "OC" AS tipo, MAX(c10_numero_oc) AS numero
		FROM ordt010
		WHERE DATE(c10_fecing) <= fecha
		GROUP BY 1, 2, 3, 4, 5

SELECT COUNT(*) INTO cuantos FROM tmp_sec WHERE modulo = 'OC'
DISPLAY ' Total de transacciones (ordt010): ', cuantos USING "<<<<&"
DISPLAY ' '

SELECT COUNT(*) INTO cuantos FROM tmp_sec
DISPLAY ' Total Trans. con generación de secuencia: ', cuantos USING "<<<<&",
	'  Al ', fecha USING "dd-mm-yyyy"
DISPLAY ' '
DISPLAY ' '

END FUNCTION
