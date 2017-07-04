SET ISOLATION TO DIRTY READ;


--------------------------------------------------------------------------------
--                    CREANDO ITEMS DE QUITO EN GUAYAQUIL                     --
--------------------------------------------------------------------------------

SELECT a.r10_codigo item_uio, a.r10_estado est_uio
	FROM acero_qm@idsuio01:rept010 a
	WHERE a.r10_compania = 1
	INTO TEMP t1;

SELECT b.r10_codigo item_gye, b.r10_estado est_gye
	FROM acero_gm@idsgye01:rept010 b
	WHERE b.r10_compania = 1
	INTO TEMP t2;

SELECT item_uio, item_gye
	FROM t1, OUTER t2
	WHERE item_uio = item_gye
	  AND est_uio  = 'A'
	INTO TEMP t3;

DELETE FROM t3
	WHERE item_gye IS NOT NULL;

SELECT "NUEVOS_UIO:" || TRUNC(COUNT(*)) tot_ite_uio
	FROM t3;

SELECT qm.* FROM acero_qm@idsuio01:rept010 qm, t3
	WHERE qm.r10_compania  = 1
	  AND qm.r10_codigo    = t3.item_uio
	INTO TEMP t4;

DROP TABLE t3;

SELECT r10_codigo ite_uio, r10_fecing fec_uio
	FROM t4
	ORDER BY 2, 1;


DROP TABLE t4;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--                    CREANDO ITEMS DE GUAYAQUIL EN QUITO                     --
--------------------------------------------------------------------------------

SELECT item_uio, item_gye
	FROM t2, OUTER t1
	WHERE item_gye = item_uio
	  AND est_gye  = 'A'
	INTO TEMP t3;

DELETE FROM t3
	WHERE item_uio IS NOT NULL;

SELECT "NUEVOS_GYE:" || TRUNC(COUNT(*)) tot_ite_gye
	FROM t3;

SELECT gm.* FROM acero_gm@idsgye01:rept010 gm, t3
	WHERE gm.r10_compania  = 1
	  AND gm.r10_codigo    = t3.item_gye
	INTO TEMP t4;

DROP TABLE t3;

SELECT r10_codigo ite_gye, r10_fecing fec_gye
	FROM t4
	ORDER BY 2, 1;

DROP TABLE t1;
DROP TABLE t2;
DROP TABLE t4;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
