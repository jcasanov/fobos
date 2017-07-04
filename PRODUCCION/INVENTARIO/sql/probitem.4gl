DATABASE acero_qs



MAIN

	IF num_args() <> 1 THEN	
		DISPLAY 'Parametros Incorrectos. Falta el Item.'
		EXIT PROGRAM
	END IF
	CALL actualizar()

END MAIN



FUNCTION actualizar()
DEFINE item		LIKE rept010.r10_codigo
DEFINE r_r10		RECORD LIKE rept010.*

LET item = arg_val(1)
INITIALIZE r_r10.* TO NULL
BEGIN WORK
SELECT * FROM rept010 WHERE r10_compania = 10 INTO TEMP t1
LOAD FROM "caca.txt" INSERT INTO t1
SELECT * INTO r_r10.* FROM t1
	WHERE r10_compania = 1
	  AND r10_codigo   = item
WHENEVER ERROR STOP
UPDATE rept010 SET * = r_r10.*
	WHERE r10_compania = 1
	  AND r10_codigo   = item
DROP TABLE t1
COMMIT WORK

END FUNCTION
