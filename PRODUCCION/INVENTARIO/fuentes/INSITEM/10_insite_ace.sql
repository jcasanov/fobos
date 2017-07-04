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

SELECT COUNT(*) tot_ite_uio
	FROM t3;

SELECT qm.* FROM acero_qm@idsuio01:rept010 qm, t3
	WHERE qm.r10_compania  = 1
	  AND qm.r10_codigo    = t3.item_uio
	INTO TEMP t4;

DROP TABLE t3;

SELECT r10_codigo ite_uio, r10_fecing fec_uio
	FROM t4
	ORDER BY 2, 1;

SELECT r02_codigo bodega
	FROM acero_qm@idsuio01:rept002
	WHERE r02_compania   = 1
	  AND r02_localidad IN (3, 5)
	INTO TEMP tmp_bod;

SELECT qm.* FROM acero_qm@idsuio01:rept011 qm, t4
	WHERE qm.r11_compania  = 1
	  AND qm.r11_bodega   IN (SELECT bodega FROM tmp_bod)
	  AND qm.r11_item     = t4.r10_codigo
	  AND qm.r11_compania = t4.r10_compania
	INTO TEMP t5;

DROP TABLE tmp_bod;

SELECT COUNT(*) tot_ite_bod_uio
	FROM t5;

SELECT r11_bodega bod_uio, r11_item ite_uio
	FROM t5
	ORDER BY 1, 2;

BEGIN WORK;

	INSERT INTO acero_gm@idsgye01:rept010
		SELECT r10_compania, r10_codigo, r10_nombre, r10_estado,
			r10_tipo, r10_peso, r10_uni_med, r10_cantpaq,
			r10_cantveh, r10_partida, r10_modelo, r10_cod_pedido,
			r10_cod_comerc,
			CASE WHEN r10_cod_util = 
				(SELECT r77_codigo_util
				FROM acero_gm@idsgye01:rept077
				WHERE r77_compania    = r10_compania
				  AND r77_codigo_util = r10_cod_util)
				THEN r10_cod_util
				ELSE "RE000"
			END cod_util,
			r10_linea, r10_sub_linea,
			r10_cod_grupo, r10_cod_clase, r10_marca, r10_rotacion,
			r10_paga_impto, r10_fob, r10_monfob, r10_precio_mb,
			r10_precio_ma, r10_costo_mb, r10_costo_ma,
			r10_costult_mb, r10_costult_ma, r10_costrepo_mb,
			r10_usu_cosrepo, r10_fec_cosrepo, r10_cantped,
			r10_cantback, r10_comentarios, r10_precio_ant,
			r10_fec_camprec, r10_proveedor, r10_filtro,
			r10_electrico, r10_color, r10_serie_lote,
			r10_stock_max, r10_stock_min, r10_vol_cuft,
			r10_dias_mant,r10_dias_inv, r10_sec_item, 'FOBOS',
			CURRENT, r10_feceli
			FROM t4;
			{
			WHERE NOT EXISTS
				(SELECT 1 FROM t4 b
					WHERE b.r10_compania = r10_compania
					  AND b.r10_codigo   = r10_codigo);
			}

	INSERT INTO acero_gm@idsgye01:rept011
		SELECT * FROM t5;
			{
			WHERE NOT EXISTS
				(SELECT 1 FROM t5 b
					WHERE b.r11_compania = r11_compania
					  AND b.r11_bodega   = r11_bodega
					  AND b.r11_item     = r11_item);
			}

COMMIT WORK;

DROP TABLE t4;
DROP TABLE t5;
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

SELECT COUNT(*) tot_ite_gye
	FROM t3;

SELECT gm.* FROM acero_gm@idsgye01:rept010 gm, t3
	WHERE gm.r10_compania  = 1
	  AND gm.r10_codigo    = t3.item_gye
	INTO TEMP t4;

DROP TABLE t3;

SELECT r10_codigo ite_gye, r10_fecing fec_gye
	FROM t4
	ORDER BY 2, 1;

SELECT r02_codigo bodega
	FROM acero_gm@idsgye01:rept002
	WHERE r02_compania  = 1
	  AND r02_localidad = 1
	INTO TEMP tmp_bod;

SELECT gm.* FROM acero_gm@idsgye01:rept011 gm, t4
	WHERE gm.r11_compania  = 1
	  AND gm.r11_bodega   IN (SELECT bodega FROM tmp_bod)
	  AND gm.r11_item     = t4.r10_codigo
	  AND gm.r11_compania = t4.r10_compania
	INTO TEMP t5;

DROP TABLE tmp_bod;

SELECT COUNT(*) tot_ite_bod_gye
	FROM t5;

SELECT r11_bodega bod_gye, r11_item ite_gye
	FROM t5
	ORDER BY 1, 2;

BEGIN WORK;

	INSERT INTO acero_qm@idsuio01:rept010
		SELECT r10_compania, r10_codigo, r10_nombre, r10_estado,
			r10_tipo, r10_peso, r10_uni_med, r10_cantpaq,
			r10_cantveh, r10_partida, r10_modelo, r10_cod_pedido,
			r10_cod_comerc,
			CASE WHEN r10_cod_util = 
				(SELECT r77_codigo_util
				FROM acero_qm@idsuio01:rept077
				WHERE r77_compania    = r10_compania
				  AND r77_codigo_util = r10_cod_util)
				THEN r10_cod_util
				ELSE "RE000"
			END cod_util,
			r10_linea, r10_sub_linea,
			r10_cod_grupo, r10_cod_clase, r10_marca, r10_rotacion,
			r10_paga_impto, r10_fob, r10_monfob, r10_precio_mb,
			r10_precio_ma, r10_costo_mb, r10_costo_ma,
			r10_costult_mb, r10_costult_ma, r10_costrepo_mb,
			r10_usu_cosrepo, r10_fec_cosrepo, r10_cantped,
			r10_cantback, r10_comentarios, r10_precio_ant,
			r10_fec_camprec, r10_proveedor, r10_filtro,
			r10_electrico, r10_color, r10_serie_lote,
			r10_stock_max, r10_stock_min, r10_vol_cuft,
			r10_dias_mant,r10_dias_inv, r10_sec_item, 'FOBOS',
			CURRENT, r10_feceli
			FROM t4;
			{
			WHERE NOT EXISTS
				(SELECT 1 FROM t4 b
					WHERE b.r10_compania = r10_compania
					  AND b.r10_codigo   = r10_codigo);
			}

	INSERT INTO acero_qm@idsuio01:rept011
		SELECT * FROM t5;
			{
			WHERE NOT EXISTS
				(SELECT 1 FROM t5 b
					WHERE b.r11_compania = r11_compania
					  AND b.r11_bodega   = r11_bodega
					  AND b.r11_item     = r11_item);
			}

COMMIT WORK;

DROP TABLE t1;
DROP TABLE t2;
DROP TABLE t4;
DROP TABLE t5;
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
