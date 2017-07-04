SET ISOLATION TO DIRTY READ;


--------------------------------------------------------------------------------
--               COMPARANDO FACTURAS DE GUAYAQUIL EN QUITO                    --
--------------------------------------------------------------------------------

SELECT r19_compania cia, r19_localidad loc, r19_cod_tran cod, r19_num_tran num,
	r19_fecing fec, 3 loc_r
	--FROM acero_gm@idsgye01:rept019, acero_gm@idsgye01:rept021
	FROM aceros@acgyede:rept019, aceros@acgyede:rept021
	--FROM acero_gm@acuiopr:rept019, acero_gm@acuiopr:rept021
	WHERE r19_compania    = 1
	  AND r19_localidad   = 1
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

SELECT "NUEVOS_GM_QM:" || TRUNC(COUNT(*)) tot_fa_gm_qm
	FROM tmp_fact;

SELECT loc, cod, num, fec
	FROM tmp_fact
	ORDER BY 4, 1, 2, 3;

DROP TABLE tmp_fact;

--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--               COMPARANDO FACTURAS DE GUAYAQUIL EN EL SUR                   --
--------------------------------------------------------------------------------

SELECT r19_compania cia, r19_localidad loc, r19_cod_tran cod, r19_num_tran num,
	r19_fecing fec, 4 loc_r
	--FROM acero_gm@idsgye01:rept019, acero_gm@idsgye01:rept021
	FROM aceros@acgyede:rept019, aceros@acgyede:rept021
	--FROM acero_gm@acuiopr:rept019, acero_gm@acuiopr:rept021
	WHERE r19_compania    = 1
	  AND r19_localidad   = 1
	  AND r19_cod_tran   IN ('FA', 'DF', 'AF')
	  AND r21_compania    = r19_compania
	  AND r21_localidad   = r19_localidad
	  AND r21_cod_tran    = r19_cod_tran
	  AND r21_num_tran    = r19_num_tran
	  AND r21_trans_fact  = 'S'
	  AND NOT EXISTS
		(SELECT 1
			--FROM acero_qs@idsuio02:rept090
			FROM acero_qs@acgyede:rept090
			--FROM acero_qs@acuiopr:rept090
			WHERE r90_compania  = r19_compania
			  AND r90_localidad = r19_localidad
			  AND r90_cod_tran  = r19_cod_tran
			  AND r90_num_tran  = r19_num_tran)
	INTO TEMP tmp_fact;

SELECT "NUEVOS_GM_QS:" || TRUNC(COUNT(*)) tot_fa_gm_qs
	FROM tmp_fact;

SELECT loc, cod, num, fec
	FROM tmp_fact
	ORDER BY 4, 1, 2, 3;

DROP TABLE tmp_fact;

--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--                COMPARANDO FACTURAS DE QUITO EN GUAYAQUIL                   --
--------------------------------------------------------------------------------

SELECT r19_compania cia, r19_localidad loc, r19_cod_tran cod, r19_num_tran num,
	r19_fecing fec, 1 loc_r
	--FROM acero_qm@idsuio01:rept019, acero_qm@idsuio01:rept021
	FROM acero_qm@acgyede:rept019, acero_qm@acgyede:rept021
	--FROM acero_qm@acuiopr:rept019, acero_qm@acuiopr:rept021
	WHERE r19_compania    = 1
	  AND r19_localidad   = 3
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

SELECT "NUEVOS_QM_GM:" || TRUNC(COUNT(*)) tot_fa_qm_gm
	FROM tmp_fact;

SELECT loc, cod, num, fec
	FROM tmp_fact
	ORDER BY 4, 1, 2, 3;

DROP TABLE tmp_fact;

--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--                 COMPARANDO FACTURAS DE QUITO EN EL SUR                     --
--------------------------------------------------------------------------------

SELECT r19_compania cia, r19_localidad loc, r19_cod_tran cod, r19_num_tran num,
	r19_fecing fec, 4 loc_r
	--FROM acero_qm@idsuio01:rept019, acero_qm@idsuio01:rept021
	FROM acero_qm@acgyede:rept019, acero_qm@acgyede:rept021
	--FROM acero_qm@acuiopr:rept019, acero_qm@acuiopr:rept021
	WHERE r19_compania    = 1
	  AND r19_localidad   = 3
	  AND r19_cod_tran   IN ('FA', 'DF', 'AF')
	  AND r21_compania    = r19_compania
	  AND r21_localidad   = r19_localidad
	  AND r21_cod_tran    = r19_cod_tran
	  AND r21_num_tran    = r19_num_tran
	  AND r21_trans_fact  = 'S'
	  AND NOT EXISTS
		(SELECT 1
			--FROM acero_qs@idsuio02:rept090
			FROM acero_qs@acgyede:rept090
			--FROM acero_qs@acuiopr:rept090
			WHERE r90_compania  = r19_compania
			  AND r90_localidad = r19_localidad
			  AND r90_cod_tran  = r19_cod_tran
			  AND r90_num_tran  = r19_num_tran)
	INTO TEMP tmp_fact;

SELECT "NUEVOS_QM_QS:" || TRUNC(COUNT(*)) tot_fa_qm_qs
	FROM tmp_fact;

SELECT loc, cod, num, fec
	FROM tmp_fact
	ORDER BY 4, 1, 2, 3;

DROP TABLE tmp_fact;

--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--                COMPARANDO FACTURAS DEL SUR EN GUAYAQUIL                    --
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

SELECT "NUEVOS_QS_GM:" || TRUNC(COUNT(*)) tot_fa_qs_gm
	FROM tmp_fact;

SELECT loc, cod, num, fec
	FROM tmp_fact
	ORDER BY 4, 1, 2, 3;

DROP TABLE tmp_fact;

--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--                  COMPARANDO FACTURAS DEL SUR EN QUITO                      --
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

SELECT "NUEVOS_QS_QM:" || TRUNC(COUNT(*)) tot_fa_qs_qm
	FROM tmp_fact;

SELECT loc, cod, num, fec
	FROM tmp_fact
	ORDER BY 4, 1, 2, 3;

DROP TABLE tmp_fact;

--------------------------------------------------------------------------------
