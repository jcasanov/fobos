SET ISOLATION TO DIRTY READ;


--------------------------------------------------------------------------------
--                    CREANDO MARCAS DE QUITO EN GUAYAQUIL                    --
--------------------------------------------------------------------------------

SELECT a.*, b.r73_marca marca
	FROM acero_qm@idsuio01:rept073 a, OUTER acero_gm@idsgye01:rept073 b
	WHERE a.r73_compania = 1
	  AND b.r73_compania = a.r73_compania
	  AND b.r73_marca    = a.r73_marca
	INTO TEMP t1;

DELETE FROM t1
	WHERE marca IS NOT NULL;

SELECT COUNT(*) tot_mar_uio
	FROM t1;

SELECT r73_marca mar_uio, r73_fecing fec_uio
	FROM t1
	ORDER BY 2, 1;

BEGIN WORK;

	INSERT INTO acero_gm@idsgye01:rept073
		SELECT r73_compania, r73_marca, r73_desc_marca,'FOBOS', CURRENT
			FROM t1;

COMMIT WORK;

DROP TABLE t1;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--                    CREANDO MARCAS DE GUAYAQUIL EN QUITO                    --
--------------------------------------------------------------------------------

SELECT a.*, b.r73_marca marca
	FROM acero_gm@idsgye01:rept073 a, OUTER acero_qm@idsuio01:rept073 b
	WHERE a.r73_compania = 1
	  AND b.r73_compania = a.r73_compania
	  AND b.r73_marca   = a.r73_marca
	INTO TEMP t1;

DELETE FROM t1
	WHERE marca IS NOT NULL;

SELECT COUNT(*) tot_mar_gye
	FROM t1;

SELECT r73_marca mar_gye, r73_fecing fec_gye
	FROM t1
	ORDER BY 2, 1;

BEGIN WORK;

	INSERT INTO acero_qm@idsuio01:rept073
		SELECT r73_compania, r73_marca, r73_desc_marca,'FOBOS', CURRENT
			FROM t1;

COMMIT WORK;

DROP TABLE t1;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
