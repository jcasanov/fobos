SET ISOLATION TO DIRTY READ;


--------------------------------------------------------------------------------
--                   CREANDO BODEGAS DE QUITO EN GUAYAQUIL                    --
--------------------------------------------------------------------------------

SELECT a.*, b.r02_codigo bodega
	FROM acero_qm@idsuio01:rept002 a, OUTER acero_gm@idsgye01:rept002 b
	WHERE a.r02_compania = 1
	  AND b.r02_compania = a.r02_compania
	  AND b.r02_codigo   = a.r02_codigo
	INTO TEMP t1;

DELETE FROM t1
	WHERE bodega IS NOT NULL;

SELECT COUNT(*) tot_bod_uio
	FROM t1;

SELECT r02_codigo bod_uio, r02_fecing fec_uio
	FROM t1
	ORDER BY 2, 1;

BEGIN WORK;

	INSERT INTO acero_gm@idsgye01:rept002
		SELECT r02_compania, r02_codigo, r02_nombre, r02_estado,
			r02_tipo, r02_area, r02_factura, r02_localidad,
			r02_tipo_ident, 'FOBOS', CURRENT
			FROM t1;

COMMIT WORK;

DROP TABLE t1;
--------------------------------------------------------------------------------


--------------------------------------------------------------------------------
--                   CREANDO BODEGAS DE GUAYAQUIL EN QUITO                    --
--------------------------------------------------------------------------------

SELECT a.*, b.r02_codigo bodega
	FROM acero_gm@idsgye01:rept002 a, OUTER acero_qm@idsuio01:rept002 b
	WHERE a.r02_compania = 1
	  AND b.r02_compania = a.r02_compania
	  AND b.r02_codigo   = a.r02_codigo
	INTO TEMP t1;

DELETE FROM t1
	WHERE bodega IS NOT NULL;

SELECT COUNT(*) tot_bod_gye
	FROM t1;

SELECT r02_codigo bod_gye, r02_fecing fec_gye
	FROM t1
	ORDER BY 2, 1;

BEGIN WORK;

	INSERT INTO acero_qm@idsuio01:rept002
		SELECT r02_compania, r02_codigo, r02_nombre, r02_estado,
			r02_tipo, r02_area, r02_factura, r02_localidad,
			r02_tipo_ident, 'FOBOS', CURRENT
			FROM t1;

COMMIT WORK;

DROP TABLE t1;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
