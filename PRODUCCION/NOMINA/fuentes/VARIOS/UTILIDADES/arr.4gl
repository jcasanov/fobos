DATABASE acero_qm


MAIN

	CALL ejecuta_proceso()
	DISPLAY 'Datos empleados actualizados. OK'

END MAIN



FUNCTION ejecuta_proceso()
DEFINE r_n30		RECORD LIKE rolt030.*
DEFINE r_n31		RECORD LIKE rolt031.*

SELECT * FROM rolt030 WHERE n30_compania = 999 INTO TEMP tmp_n30
SELECT * FROM rolt031 WHERE n31_compania = 999 INTO TEMP tmp_n31
LOAD FROM "rolt030.unl" INSERT INTO tmp_n30
LOAD FROM "rolt031.unl" INSERT INTO tmp_n31
DECLARE q_n30 CURSOR FOR SELECT * FROM tmp_n30
FOREACH q_n30 INTO r_n30.*
	SELECT * FROM rolt030
		WHERE n30_compania = r_n30.n30_compania
		  AND n30_cod_trab = r_n30.n30_cod_trab
	IF STATUS <> NOTFOUND THEN
		UPDATE rolt030
			SET * = r_n30.*
			WHERE n30_compania = r_n30.n30_compania
			  AND n30_cod_trab = r_n30.n30_cod_trab
	ELSE
		INSERT INTO rolt030 VALUES (r_n30.*)
	END IF
	INITIALIZE r_n31.* TO NULL
	DECLARE q_n31 CURSOR FOR
		SELECT * FROM tmp_n31
			WHERE n31_compania = r_n30.n30_compania
			  AND n31_cod_trab = r_n30.n30_cod_trab
	OPEN q_n31
	FETCH q_n31 INTO r_n31.*
	CLOSE q_n31
	FREE q_n31
	IF r_n31.n31_compania IS NOT NULL THEN
		UPDATE rolt031
			SET n31_tipo_carga =
				(SELECT a.n31_tipo_carga
					FROM tmp_n31 a
					WHERE a.n31_compania  = n31_compania
					  AND a.n31_cod_trab  = n31_cod_trab
					  AND a.n31_secuencia = n31_secuencia),
			    n31_nombres    =
				(SELECT a.n31_nombres
					FROM tmp_n31 a
					WHERE a.n31_compania  = n31_compania
					  AND a.n31_cod_trab  = n31_cod_trab
					  AND a.n31_secuencia = n31_secuencia),
			    n31_fecha_nacim =
				(SELECT a.n31_fecha_nacim
					FROM tmp_n31 a
					WHERE a.n31_compania  = n31_compania
					  AND a.n31_cod_trab  = n31_cod_trab
					  AND a.n31_secuencia = n31_secuencia)
			WHERE EXISTS
				(SELECT * FROM rolt031
					WHERE n31_compania = r_n30.n30_compania
					  AND n31_cod_trab = r_n30.n30_cod_trab)
	ELSE
		INSERT INTO rolt031
			SELECT * FROM tmp_n31
				WHERE n31_compania = r_n30.n30_compania
				  AND n31_cod_trab = r_n30.n30_cod_trab
	END IF
END FOREACH

END FUNCTION
