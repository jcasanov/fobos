DATABASE aceros



MAIN

	CALL ej_proceso()

END MAIN



FUNCTION ej_proceso()
DEFINE r_emp		ARRAY[120] OF RECORD LIKE rolt030.*
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n30_p		RECORD LIKE rolt030.*
DEFINE i, max		SMALLINT

LET max = 120
FOR i = 1 TO max
	LET r_emp[i].* = NULL
END FOR
DECLARE q_dif CURSOR FOR
	SELECT * FROM rolt030
		WHERE n30_compania = 1
		  AND n30_estado   = 'A'
		ORDER BY n30_nombres
FOREACH q_dif INTO r_n30.*
	SELECT * INTO r_n30_p.*
		FROM acero_gm:rolt030
		WHERE n30_compania = r_n30.n30_compania
		  AND n30_cod_trab = r_n30.n30_cod_trab
	IF r_n30.* = r_n30_p.* THEN
		CONTINUE FOREACH
	END IF
	LET r_emp[r_n30.n30_cod_trab].* = r_n30_p.*
END FOREACH
FOR i = 1 TO max
	IF r_emp[i].n30_compania IS NULL THEN
		CONTINUE FOR
	END IF
	DISPLAY 'Diferente Empleado: ', r_emp[i].n30_cod_trab USING "&&&",
		'  ', r_emp[i].n30_nombres
END FOR

END FUNCTION
