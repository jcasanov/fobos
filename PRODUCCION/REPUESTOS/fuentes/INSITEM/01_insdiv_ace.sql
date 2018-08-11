SET ISOLATION TO DIRTY READ;


--------------------------------------------------------------------------------
--                  CREANDO DIVISIONES DE QUITO EN GUAYAQUIL                  --
--------------------------------------------------------------------------------

SELECT a.*, b.r03_codigo division
	FROM acero_qm@idsuio01:rept003 a, OUTER acero_gm@idsgye01:rept003 b
	WHERE a.r03_compania = 1
	  AND b.r03_compania = a.r03_compania
	  AND b.r03_codigo   = a.r03_codigo
	INTO TEMP t1;

DELETE FROM t1
	WHERE division IS NOT NULL;

SELECT COUNT(*) tot_div_uio
	FROM t1;

SELECT r03_codigo div_uio, r03_fecing fec_uio
	FROM t1
	ORDER BY 2, 1;

BEGIN WORK;

	INSERT INTO acero_gm@idsgye01:rept003
		SELECT r03_compania, r03_codigo, r03_nombre, r03_estado,
			r03_area, r03_porc_uti, r03_tipo, r03_dcto_tal,
			r03_dcto_cont, r03_dcto_cred, r03_grupo_linea,
			'FOBOS', CURRENT
			FROM t1;

COMMIT WORK;

DROP TABLE t1;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--                  CREANDO DIVISIONES DE GUAYAQUIL EN QUITO                  --
--------------------------------------------------------------------------------

SELECT a.*, b.r03_codigo division
	FROM acero_gm@idsgye01:rept003 a, OUTER acero_qm@idsuio01:rept003 b
	WHERE a.r03_compania = 1
	  AND b.r03_compania = a.r03_compania
	  AND b.r03_codigo   = a.r03_codigo
	INTO TEMP t1;

DELETE FROM t1
	WHERE division IS NOT NULL;

SELECT COUNT(*) tot_div_gye
	FROM t1;

SELECT r03_codigo div_gye, r03_fecing fec_gye
	FROM t1
	ORDER BY 2, 1;

BEGIN WORK;

	INSERT INTO acero_qm@idsuio01:rept003
		SELECT r03_compania, r03_codigo, r03_nombre, r03_estado,
			r03_area, r03_porc_uti, r03_tipo, r03_dcto_tal,
			r03_dcto_cont, r03_dcto_cred, r03_grupo_linea,
			'FOBOS', CURRENT
			FROM t1;

COMMIT WORK;

DROP TABLE t1;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
