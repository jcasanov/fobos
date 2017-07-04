SET ISOLATION TO DIRTY READ;


--------------------------------------------------------------------------------
--               TRANSMITIENDO FACTURAS DEL SUR A GUAYAQUIL                   --
--------------------------------------------------------------------------------

SELECT r19_compania cia, r19_localidad loc, r19_cod_tran cod, r19_num_tran num,
	r19_fecing fec, 1 loc_r
	--FROM acero_qs@idsuio02:rept019, acero_qs@idsuio02:rept021
	FROM acero_qs@acgyede:rept019, acero_qs@acgyede:rept021
	--FROM acero_qs@acuiopr:rept019, acero_qs@acuiopr:rept021
	WHERE r19_compania    = 1
	  AND r19_localidad   = 4
	  AND r19_cod_tran   IN ('FA', 'DF', 'AF')
	  AND r21_compania    = r19_compania
	  AND r21_localidad   = r19_localidad
	  AND r21_cod_tran    = r19_cod_tran
	  AND r21_num_tran    = r19_num_tran
	  AND r21_trans_fact  = 'S'
	  AND NOT EXISTS
		(SELECT 1
			--FROM acero_gm@idsgye01:rept090
			FROM aceros@acgyede:rept090
			--FROM acero_gm@acuiopr:rept090
			WHERE r90_compania  = r19_compania
			  AND r90_localidad = r19_localidad
			  AND r90_cod_tran  = r19_cod_tran
			  AND r90_num_tran  = r19_num_tran)
	INTO TEMP tmp_fact;

SELECT loc, cod, num, fec
	FROM tmp_fact
	ORDER BY 4, 1, 2, 3;

BEGIN WORK;

	--INSERT INTO acero_gm@idsgye01:rept090
	INSERT INTO aceros@acgyede:rept090
	--INSERT INTO acero_gm@acuiopr:rept090
		(r90_compania, r90_localidad, r90_cod_tran, r90_num_tran,
		 r90_fecing, r90_locali_fin)
		SELECT * FROM tmp_fact;

	--INSERT INTO acero_gm@idsgye01:rept091
	INSERT INTO aceros@acgyede:rept091
	--INSERT INTO acero_gm@acuiopr:rept091
		--SELECT * FROM acero_qs@idsuio02:rept019
		SELECT * FROM acero_qs@acgyede:rept019
		--SELECT * FROM acero_qs@acuiopr:rept019
			WHERE EXISTS
				(SELECT 1 FROM tmp_fact
					WHERE cia = r19_compania
					  AND loc = r19_localidad
					  AND cod = r19_cod_tran
					  AND num = r19_num_tran);

	--INSERT INTO acero_gm@idsgye01:rept092
	INSERT INTO aceros@acgyede:rept092
	--INSERT INTO acero_gm@acuiopr:rept092
		--SELECT * FROM acero_qs@idsuio02:rept020
		SELECT * FROM acero_qs@acgyede:rept020
		--SELECT * FROM acero_qs@acuiopr:rept020
			WHERE EXISTS
				(SELECT 1 FROM tmp_fact
					WHERE cia = r20_compania
					  AND loc = r20_localidad
					  AND cod = r20_cod_tran
					  AND num = r20_num_tran);

COMMIT WORK;

DROP TABLE tmp_fact;

--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--                 TRANSMITIENDO FACTURAS DEL SUR A QUITO                     --
--------------------------------------------------------------------------------

SELECT r19_compania cia, r19_localidad loc, r19_cod_tran cod, r19_num_tran num,
	r19_fecing fec, 3 loc_r
	--FROM acero_qs@idsuio02:rept019, acero_qs@idsuio02:rept021
	FROM acero_qs@acgyede:rept019, acero_qs@acgyede:rept021
	--FROM acero_qs@acuiopr:rept019, acero_qs@acuiopr:rept021
	WHERE r19_compania    = 1
	  AND r19_localidad   = 4
	  AND r19_cod_tran   IN ('FA', 'DF', 'AF')
	  AND r21_compania    = r19_compania
	  AND r21_localidad   = r19_localidad
	  AND r21_cod_tran    = r19_cod_tran
	  AND r21_num_tran    = r19_num_tran
	  AND r21_trans_fact  = 'S'
	  AND NOT EXISTS
		(SELECT 1
			--FROM acero_qm@idsuio01:rept090
			FROM acero_qm@acgyede:rept090
			--FROM acero_qm@acuiopr:rept090
			WHERE r90_compania  = r19_compania
			  AND r90_localidad = r19_localidad
			  AND r90_cod_tran  = r19_cod_tran
			  AND r90_num_tran  = r19_num_tran)
	INTO TEMP tmp_fact;

SELECT loc, cod, num, fec
	FROM tmp_fact
	ORDER BY 4, 1, 2, 3;

BEGIN WORK;

	--INSERT INTO acero_qm@idsuio01:rept090
	INSERT INTO acero_qm@acgyede:rept090
	--INSERT INTO acero_qm@acuiopr:rept090
		(r90_compania, r90_localidad, r90_cod_tran, r90_num_tran,
		 r90_fecing, r90_locali_fin)
		SELECT * FROM tmp_fact;

	--INSERT INTO acero_qm@idsuio01:rept091
	INSERT INTO acero_qm@acgyede:rept091
	--INSERT INTO acero_qm@acuiopr:rept091
		--SELECT * FROM acero_qs@idsuio02:rept019
		SELECT * FROM acero_qs@acgyede:rept019
		--SELECT * FROM acero_qs@acuiopr:rept019
			WHERE EXISTS
				(SELECT 1 FROM tmp_fact
					WHERE cia = r19_compania
					  AND loc = r19_localidad
					  AND cod = r19_cod_tran
					  AND num = r19_num_tran);

	--INSERT INTO acero_qm@idsuio01:rept092
	INSERT INTO acero_qm@acgyede:rept092
	--INSERT INTO acero_qm@acuiopr:rept092
		--SELECT * FROM acero_qs@idsuio02:rept020
		SELECT * FROM acero_qs@acgyede:rept020
		--SELECT * FROM acero_qs@acuiopr:rept020
			WHERE EXISTS
				(SELECT 1 FROM tmp_fact
					WHERE cia = r20_compania
					  AND loc = r20_localidad
					  AND cod = r20_cod_tran
					  AND num = r20_num_tran);

COMMIT WORK;

DROP TABLE tmp_fact;

--------------------------------------------------------------------------------
