SET ISOLATION TO DIRTY READ;


--------------------------------------------------------------------------------
--                    CREANDO CLASES DE QUITO EN GUAYAQUIL                    --
--------------------------------------------------------------------------------

SELECT a.r72_cod_clase clase_uio
	FROM acero_qm@idsuio01:rept072 a
	WHERE a.r72_compania = 1
	INTO TEMP t1;

SELECT b.r72_cod_clase clase_gye
	FROM acero_gm@idsgye01:rept072 b
	WHERE b.r72_compania = 1
	INTO TEMP t2;

SELECT clase_uio, clase_gye
	FROM t1, OUTER t2
	WHERE clase_uio = clase_gye
	INTO TEMP t3;

DELETE FROM t3
	WHERE clase_gye IS NOT NULL;

SELECT COUNT(*) tot_cla_uio
	FROM t3;

SELECT a.* FROM acero_qm@idsuio01:rept072 a, t3
	WHERE a.r72_compania  = 1
	  AND a.r72_cod_clase = t3.clase_uio
	INTO TEMP t4;

DROP TABLE t3;

SELECT r72_cod_clase cla_uio, r72_fecing fec_uio
	FROM t4
	ORDER BY 2, 1;

BEGIN WORK;

	INSERT INTO acero_gm@idsgye01:rept072
		SELECT r72_compania, r72_linea, r72_sub_linea, r72_cod_grupo,
			r72_cod_clase, r72_desc_clase, 'FOBOS', CURRENT
			FROM t4;

COMMIT WORK;

DROP TABLE t4;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--                    CREANDO CLASES DE GUAYAQUIL EN QUITO                    --
--------------------------------------------------------------------------------

SELECT clase_uio, clase_gye
	FROM t2, OUTER t1
	WHERE clase_uio = clase_gye
	INTO TEMP t3;

DELETE FROM t3
	WHERE clase_uio IS NOT NULL;

SELECT COUNT(*) tot_cla_gye
	FROM t3;

SELECT a.* FROM acero_gm@idsgye01:rept072 a, t3
	WHERE a.r72_compania  = 1
	  AND a.r72_cod_clase = t3.clase_gye
	INTO TEMP t4;

DROP TABLE t3;

SELECT r72_cod_clase cla_gye, r72_fecing fec_gye
	FROM t4
	ORDER BY 2, 1;

BEGIN WORK;

	INSERT INTO acero_qm@idsuio01:rept072
		SELECT r72_compania, r72_linea, r72_sub_linea, r72_cod_grupo,
			r72_cod_clase, r72_desc_clase, 'FOBOS', CURRENT
			FROM t4;

COMMIT WORK;

DROP TABLE t1;
DROP TABLE t2;
DROP TABLE t4;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
