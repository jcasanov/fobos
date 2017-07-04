SET ISOLATION TO DIRTY READ;


--------------------------------------------------------------------------------
--                   CREANDO CAPITULOS DE QUITO EN GUAYAQUIL                  --
--------------------------------------------------------------------------------

SELECT a.*, b.g38_capitulo capitulo
	FROM acero_qm@idsuio01:gent038 a, OUTER acero_gm@idsgye01:gent038 b
	WHERE b.g38_capitulo = a.g38_capitulo
	INTO TEMP t1;

DELETE FROM t1
	WHERE capitulo IS NOT NULL;

SELECT COUNT(*) tot_cap_uio
	FROM t1;

SELECT g38_capitulo cap_uio, g38_fecing fec_uio
	FROM t1
	ORDER BY 2, 1;

BEGIN WORK;

	INSERT INTO acero_gm@idsgye01:gent038
		SELECT g38_capitulo, g38_desc_cap, 'FOBOS', CURRENT
			FROM t1;

COMMIT WORK;

DROP TABLE t1;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--                   CREANDO CAPITULOS DE GUAYAQUIL EN QUITO                  --
--------------------------------------------------------------------------------

SELECT a.*, b.g38_capitulo capitulo
	FROM acero_gm@idsgye01:gent038 a, OUTER acero_qm@idsuio01:gent038 b
	WHERE b.g38_capitulo = a.g38_capitulo
	INTO TEMP t1;

DELETE FROM t1
	WHERE capitulo IS NOT NULL;

SELECT COUNT(*) tot_cap_gye
	FROM t1;

SELECT g38_capitulo cap_gye, g38_fecing fec_gye
	FROM t1
	ORDER BY 2, 1;

BEGIN WORK;

	INSERT INTO acero_qm@idsuio01:gent038
		SELECT g38_capitulo, g38_desc_cap, 'FOBOS', CURRENT
			FROM t1;

COMMIT WORK;

DROP TABLE t1;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
