SELECT a10_compania AS cia,
	a10_codigo_bien AS acti,
	a10_estado AS est,
	a10_fecha_baja AS fec_baj,
	a10_tot_dep_mb AS tot_dep_ori
	FROM actt010
	WHERE a10_compania = 999
	INTO TEMP tmp_act;

LOAD FROM "activos_gye_ori.unl"
	INSERT INTO tmp_act;

SELECT UNIQUE a12_codigo_tran AS codigo_tran
	FROM actt012
	WHERE a12_compania      = 1
	  AND DATE(a12_fecing)  = MDY(01, 13, 2013)
	  AND a12_codigo_bien  IN (SELECT acti FROM tmp_act)
	INTO TEMP t1;

BEGIN WORK;

	UPDATE ctbt012
		SET b12_subtipo = NULL
		WHERE b12_compania  = 1
		  AND b12_tipo_comp = "DC"
		  AND b12_num_comp  = "13011109";

	DELETE FROM actt012
		WHERE a12_compania      = 1
		  AND DATE(a12_fecing)  = MDY(01, 13, 2013)
		  AND a12_codigo_bien  IN (SELECT acti FROM tmp_act);

	UPDATE actt005
		SET a05_numero = NVL((SELECT MAX(a12_numero_tran)
				FROM actt012
				WHERE a12_compania    = a05_compania
				  AND a12_codigo_tran = a05_codigo_tran), 0)
		WHERE a05_compania     = 1
		  AND a05_codigo_tran IN (SELECT codigo_tran FROM t1);

	UPDATE actt010
		SET a10_estado     = (SELECT est
					FROM tmp_act
					WHERE cia  = a10_compania
					  AND acti = a10_codigo_bien),
		    a10_fecha_baja = (SELECT fec_baj
					FROM tmp_act
					WHERE cia  = a10_compania
					  AND acti = a10_codigo_bien),
		    a10_tot_dep_mb = (SELECT tot_dep_ori
					FROM tmp_act
					WHERE cia  = a10_compania
					  AND acti = a10_codigo_bien)
		WHERE a10_compania     = 1
		  AND a10_codigo_bien IN (SELECT acti FROM tmp_act);

--ROLLBACK WORK;
COMMIT WORK;

DROP TABLE tmp_act;
DROP TABLE t1;
