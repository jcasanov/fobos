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

LOAD FROM "egr_che_uio.unl" INSERT INTO tmp_j11;

BEGIN WORK;

{--
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
				  AND loc     = 3
				  AND num_egr BETWEEN 938 AND 939);

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
				  AND loc     = 3
				  AND num_egr = 940);

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
				  AND loc     = 3
				  AND num_egr = 941);

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
				  AND loc     = 3
				  AND num_egr BETWEEN 942 AND 943);

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
				  AND loc     = 3
				  AND num_egr = 944);

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
				  AND loc     = 3
				  AND num_egr BETWEEN 945 AND 947);

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
				  AND loc     = 3
				  AND num_egr = 948);

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
				  AND loc     = 3
				  AND num_egr = 949);

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
				  AND loc     = 3
				  AND num_egr = 950);

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
				  AND loc     = 3
				  AND num_egr = 951);
--}

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
				  AND loc     = 4
				  AND num_egr = 10);

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
				  AND loc     = 4
				  AND num_egr BETWEEN 11 AND 16);

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
				  AND loc     = 4
				  AND num_egr = 17);

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
				  AND loc     = 4
				  AND num_egr BETWEEN 18 AND 19);

{--
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
				  AND loc     = 5);
--}

COMMIT WORK;

DROP TABLE tmp_j11;
