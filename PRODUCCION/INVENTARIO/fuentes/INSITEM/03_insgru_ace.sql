SET ISOLATION TO DIRTY READ;


--------------------------------------------------------------------------------
--                    CREANDO GRUPOS DE QUITO EN GUAYAQUIL                    --
--------------------------------------------------------------------------------

SELECT a.*, b.r71_cod_grupo grupo
	FROM acero_qm@idsuio01:rept071 a, OUTER acero_gm@idsgye01:rept071 b
	WHERE a.r71_compania  = 1
	  AND b.r71_compania  = a.r71_compania
	  AND b.r71_linea     = a.r71_linea
	  AND b.r71_sub_linea = a.r71_sub_linea
	  AND b.r71_cod_grupo = a.r71_cod_grupo
	INTO TEMP t1;

DELETE FROM t1
	WHERE grupo IS NOT NULL;

SELECT COUNT(*) tot_gru_uio
	FROM t1;

SELECT r71_cod_grupo gru_uio, r71_fecing fec_uio
	FROM t1
	ORDER BY 2, 1;

BEGIN WORK;

	INSERT INTO acero_gm@idsgye01:rept071
		SELECT r71_compania, r71_linea, r71_sub_linea, r71_cod_grupo,
			r71_desc_grupo, 'FOBOS', CURRENT
			FROM t1;

COMMIT WORK;

DROP TABLE t1;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--                    CREANDO GRUPOS DE GUAYAQUIL EN QUITO                    --
--------------------------------------------------------------------------------

SELECT a.*, b.r71_cod_grupo grupo
	FROM acero_gm@idsgye01:rept071 a, OUTER acero_qm@idsuio01:rept071 b
	WHERE a.r71_compania = 1
	  AND b.r71_compania  = a.r71_compania
	  AND b.r71_linea     = a.r71_linea
	  AND b.r71_sub_linea = a.r71_sub_linea
	  AND b.r71_cod_grupo = a.r71_cod_grupo
	INTO TEMP t1;

DELETE FROM t1
	WHERE grupo IS NOT NULL;

SELECT COUNT(*) tot_gru_gye
	FROM t1;

SELECT r71_cod_grupo gru_gye, r71_fecing fec_gye
	FROM t1
	ORDER BY 2, 1;

BEGIN WORK;

	INSERT INTO acero_qm@idsuio01:rept071
		SELECT r71_compania, r71_linea, r71_sub_linea, r71_cod_grupo,
			r71_desc_grupo, 'FOBOS', CURRENT
			FROM t1;

COMMIT WORK;

DROP TABLE t1;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
