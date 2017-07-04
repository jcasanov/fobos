DATABASE acero_qs



MAIN

	CALL ejecuta_proceso()
	DISPLAY 'Proceso Terminado OK.'

END MAIN



FUNCTION ejecuta_proceso()
DEFINE r_r10		RECORD LIKE rept010.*
DEFINE i, j		INTEGER

DISPLAY 'Cargando maesto de items de MATRIZ ... por favor espere.'
SELECT * FROM rept010 WHERE r10_compania = 999 INTO TEMP tmp_r10
LOAD FROM "rept010_qm.unl" INSERT INTO tmp_r10
DECLARE q_tmp CURSOR WITH HOLD FOR SELECT * FROM tmp_r10
LET i = 0
LET j = 0
DISPLAY ' '
DISPLAY 'Actualizando el maestro de items del SUR ...'
FOREACH q_tmp INTO r_r10.*
	BEGIN WORK
	WHENEVER ERROR CONTINUE
	UPDATE rept010 SET * = r_r10.*
		WHERE r10_compania = r_r10.r10_compania
		  AND r10_codigo   = r_r10.r10_codigo
	IF STATUS = NOTFOUND THEN
		DISPLAY '  INSERTANDO el item: ', r_r10.r10_codigo CLIPPED
		INSERT INTO rept010 VALUES(r_r10.*)
		IF STATUS < 0 THEN
			DISPLAY 'ERROR: No se pudo insertar item ',
				r_r10.r10_codigo CLIPPED,
				'. Llame al ADMINISTRADOR.'
			WHENEVER ERROR STOP
			ROLLBACK WORK
			EXIT PROGRAM
		END IF
		WHENEVER ERROR STOP
		COMMIT WORK
		LET j = j + 1
		CONTINUE FOREACH
	END IF
	IF STATUS < 0 THEN
		DISPLAY 'ERROR: No se pudo actualizar item ',
			r_r10.r10_codigo CLIPPED, '. Llame al ADMINISTRADOR.'
		WHENEVER ERROR STOP
		ROLLBACK WORK
		EXIT PROGRAM
	END IF
	WHENEVER ERROR STOP
	COMMIT WORK
	LET i = i + 1
	DISPLAY 'Actualizando el item: ', r_r10.r10_codigo CLIPPED
END FOREACH
DISPLAY ' '
DISPLAY 'Se actualizaron un total de ', i USING "<<<<<<&", ' ITEMS. OK '
DISPLAY ' '
DISPLAY 'Se insertaron un total de ', j USING "<<<<<<&", ' ITEMS. OK '
DISPLAY ' '

END FUNCTION
