SET ISOLATION TO DIRTY READ;


--------------------------------------------------------------------------------
--                    CREANDO LINEAS DE QUITO EN GUAYAQUIL                    --
--------------------------------------------------------------------------------

SELECT a.*, b.r70_sub_linea linea
	FROM acero_qm@idsuio01:rept070 a, OUTER acero_gm@idsgye01:rept070 b
	WHERE a.r70_compania  = 1
	  AND b.r70_compania  = a.r70_compania
	  AND b.r70_linea     = a.r70_linea
	  AND b.r70_sub_linea = a.r70_sub_linea
	INTO TEMP t1;

DELETE FROM t1
	WHERE linea IS NOT NULL;

SELECT COUNT(*) tot_lin_uio
	FROM t1;

SELECT r70_sub_linea lin_uio, r70_fecing fec_uio
	FROM t1
	ORDER BY 2, 1;

BEGIN WORK;

	INSERT INTO acero_gm@idsgye01:rept070
		SELECT r70_compania, r70_linea, r70_sub_linea, r70_desc_sub,
			'FOBOS', CURRENT
			FROM t1;

COMMIT WORK;

DROP TABLE t1;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--                    CREANDO LINEAS DE GUAYAQUIL EN QUITO                    --
--------------------------------------------------------------------------------

SELECT a.*, b.r70_sub_linea linea
	FROM acero_gm@idsgye01:rept070 a, OUTER acero_qm@idsuio01:rept070 b
	WHERE a.r70_compania = 1
	  AND b.r70_compania  = a.r70_compania
	  AND b.r70_linea     = a.r70_linea
	  AND b.r70_sub_linea = a.r70_sub_linea
	INTO TEMP t1;

DELETE FROM t1
	WHERE linea IS NOT NULL;

SELECT COUNT(*) tot_lin_gye
	FROM t1;

SELECT r70_sub_linea lin_gye, r70_fecing fec_gye
	FROM t1
	ORDER BY 2, 1;

BEGIN WORK;

	INSERT INTO acero_qm@idsuio01:rept070
		SELECT r70_compania, r70_linea, r70_sub_linea, r70_desc_sub,
			'FOBOS', CURRENT
			FROM t1;

COMMIT WORK;

DROP TABLE t1;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
