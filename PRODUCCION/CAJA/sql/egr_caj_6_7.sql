SET ISOLATION TO DIRTY READ;

SELECT j11_compania AS cia,
	j11_localidad AS loc,
	j11_tipo_fuente AS tip_f,
	j11_num_fuente AS num_f,
	j11_secuencia AS secuen,
	j11_num_egreso AS num_egr
	FROM cajt011
	WHERE j11_compania = 999
	INTO TEMP tmp_j11;

LOAD FROM "egr_che_sur.unl" INSERT INTO tmp_j11;

DELETE FROM tmp_j11 WHERE num_egr < 6;

BEGIN WORK;

	UPDATE cajt011
		SET j11_num_egreso = (SELECT num_egr
					FROM tmp_j11
					WHERE cia    = j11_compania
					  AND loc    = j11_localidad
					  AND tip_f  = j11_tipo_fuente
					  AND num_f  = j11_num_fuente
					  AND secuen = j11_secuencia)
		WHERE EXISTS
			(SELECT 1 FROM tmp_j11
				WHERE cia     = j11_compania
				  AND loc     = j11_localidad
				  AND tip_f   = j11_tipo_fuente
				  AND num_f   = j11_num_fuente
				  AND secuen  = j11_secuencia
				  AND num_egr BETWEEN 6 AND 7);

COMMIT WORK;

DROP TABLE tmp_j11;
