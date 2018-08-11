DATABASE sermaco_gm



MAIN

	SET ISOLATION TO DIRTY READ
	CALL ejecutar_proceso()

END MAIN



FUNCTION ejecutar_proceso()
DEFINE item		LIKE rept010.r10_codigo
DEFINE nombre		LIKE rept010.r10_nombre
DEFINE i		INTEGER

DECLARE q_r10 CURSOR FOR
	SELECT r10_codigo, TRIM(r10_nombre) FROM rept010 WHERE r10_compania = 1
DISPLAY 'Obteniendo Items para actualizar nombre... por favor espere'
LET i = 1
FOREACH q_r10 INTO item, nombre
	DISPLAY 'Actualizando el Item: ', item CLIPPED, ' en las 2 compa��as '
	UPDATE sermaco_gm@segye01:rept010
		SET r10_nombre = nombre
		WHERE r10_compania IN (1, 2)
		  AND r10_codigo   = item
	UPDATE sermaco_qm@seuio01:rept010
		SET r10_nombre = nombre
		WHERE r10_compania IN (1, 2)
		  AND r10_codigo   = item
	LET i = i + 1
END FOREACH
DISPLAY 'Se actualizaron ', i USING "<<<<<&", ' Items en Sermaco.'
DISPLAY 'Proceso Terminado OK.'

END FUNCTION
