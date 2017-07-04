SET ISOLATION TO DIRTY READ;


--------------------------------------------------------------------------------
--                   CREANDO UNIDADES DE QUITO EN GUAYAQUIL                   --
--------------------------------------------------------------------------------

SELECT a.*, b.r05_codigo unidad
	FROM acero_qm@idsuio01:rept005 a, OUTER acero_gm@idsgye01:rept005 b
	WHERE b.r05_codigo = a.r05_codigo
	INTO TEMP t1;

DELETE FROM t1
	WHERE unidad IS NOT NULL;

SELECT COUNT(*) tot_uni_uio
	FROM t1;

SELECT r05_codigo uni_uio, r05_fecing fec_uio
	FROM t1
	ORDER BY 2, 1;

BEGIN WORK;

	INSERT INTO acero_gm@idsgye01:rept005
		SELECT r05_codigo, r05_siglas, r05_decimales, 'FOBOS', CURRENT
			FROM t1;

COMMIT WORK;

DROP TABLE t1;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--                   CREANDO UNIDADES DE GUAYAQUIL EN QUITO                   --
--------------------------------------------------------------------------------

SELECT a.*, b.r05_codigo unidad
	FROM acero_gm@idsgye01:rept005 a, OUTER acero_qm@idsuio01:rept005 b
	WHERE b.r05_codigo = a.r05_codigo
	INTO TEMP t1;

DELETE FROM t1
	WHERE unidad IS NOT NULL;

SELECT COUNT(*) tot_uni_gye
	FROM t1;

SELECT r05_codigo uni_gye, r05_fecing fec_gye
	FROM t1
	ORDER BY 2, 1;

BEGIN WORK;

	INSERT INTO acero_qm@idsuio01:rept005
		SELECT r05_codigo, r05_siglas, r05_decimales, 'FOBOS', CURRENT
			FROM t1;

COMMIT WORK;

DROP TABLE t1;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
