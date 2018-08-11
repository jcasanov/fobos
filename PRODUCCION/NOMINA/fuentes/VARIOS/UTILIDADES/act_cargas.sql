SELECT n31_compania cia, n31_cod_trab cod, n31_secuencia secu,
	n31_tipo_carga tipo, n31_cod_trab_e cod_e, n31_nombres nombres,
	n31_fecha_nacim fec_nac, n31_usuario usua
	FROM rolt031
	WHERE n31_compania = 999
	INTO TEMP t1;

LOAD FROM "cargas_gm.unl" INSERT INTO t1;

SELECT * FROM t1
	WHERE NOT EXISTS
		(SELECT 1 FROM rolt031
			WHERE n31_compania  = cia
			  AND n31_cod_trab  = cod
			  AND n31_secuencia = secu)
	INTO TEMP tmp_car_ins;

SELECT * FROM t1
	WHERE EXISTS
		(SELECT 1 FROM rolt031
			WHERE n31_compania  = cia
			  AND n31_cod_trab  = cod
			  AND n31_secuencia = secu)
	INTO TEMP tmp_car_up;

DROP TABLE t1;

SELECT COUNT(*) reg_ins FROM tmp_car_ins;
SELECT COUNT(*) reg_up FROM tmp_car_up;

BEGIN WORK;

	INSERT INTO rolt031
		(n31_compania, n31_cod_trab, n31_secuencia, n31_tipo_carga,
		 n31_cod_trab_e, n31_nombres, n31_fecha_nacim, n31_usuario,
		 n31_fecing)
		SELECT tmp_car_ins.*, CURRENT
			FROM tmp_car_ins;

	UPDATE rolt031
		SET n31_tipo_carga  = (SELECT tipo
					FROM tmp_car_up
					WHERE cia  = n31_compania
					  AND cod  = n31_cod_trab
					  AND secu = n31_secuencia),
		    n31_cod_trab_e  = (SELECT cod_e
					FROM tmp_car_up
					WHERE cia  = n31_compania
					  AND cod  = n31_cod_trab
					  AND secu = n31_secuencia),
		    n31_nombres     = (SELECT nombres
					FROM tmp_car_up
					WHERE cia  = n31_compania
					  AND cod  = n31_cod_trab
					  AND secu = n31_secuencia),
		    n31_fecha_nacim = (SELECT fec_nac
					FROM tmp_car_up
					WHERE cia  = n31_compania
					  AND cod  = n31_cod_trab
					  AND secu = n31_secuencia)
		WHERE n31_compania = 1
		  AND n31_cod_trab =
			(SELECT cod
				FROM tmp_car_up
				WHERE cia  = n31_compania
				  AND cod  = n31_cod_trab
				  AND secu = n31_secuencia);

COMMIT WORK;

DROP TABLE tmp_car_ins;
DROP TABLE tmp_car_up;
