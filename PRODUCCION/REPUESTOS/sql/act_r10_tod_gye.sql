SET ISOLATION TO DIRTY READ;

SELECT r10_compania AS cia,
	r10_codigo AS item,
	r10_nombre AS nom,
	r10_estado AS est,
	r10_tipo AS tipo,
	r10_peso AS peso,
	r10_uni_med AS uni_m,
	r10_cantpaq AS cantp,
	r10_cantveh AS cantv,
	r10_partida AS part,
	r10_modelo AS model,
	r10_cod_pedido AS cod_p,
	r10_cod_comerc AS cod_c,
	r10_cod_util AS cod_uti,
	r10_linea AS linea,
	r10_sub_linea AS sub_lin,
	r10_cod_grupo AS cod_gru,
	r10_cod_clase AS cod_cla,
	r10_marca AS marca,
	r10_rotacion AS rotac,
	r10_paga_impto AS paga_i,
	r10_fob AS fob,
	r10_monfob AS mon_f,
	r10_precio_mb AS prec,
	r10_precio_ma AS prec_ma,
	r10_cantped AS cantpe,
	r10_cantback AS cantba,
	r10_comentarios AS comenta,
	r10_precio_ant AS prec_ant,
	r10_fec_camprec AS fec_cam,
	r10_filtro AS filtro,
	r10_electrico AS elect,
	r10_color AS color,
	r10_serie_lote AS ser_lot,
	r10_stock_max AS stock_max,
	r10_stock_min AS stock_min,
	r10_vol_cuft AS vol_cuft,
	r10_dias_mant AS dias_mant,
	r10_dias_inv AS dias_inv,
	r10_sec_item AS sec_item,
	r10_feceli AS feceli
	FROM rept010
	WHERE r10_compania = 999
	INTO TEMP tmp_ite;

SELECT item AS ite
	FROM tmp_ite
	INTO TEMP t1;

LOAD FROM "items_uio_en_gye.csv" DELIMITER ","
	INSERT INTO t1;

INSERT INTO tmp_ite
	SELECT r10_compania AS cia,
		r10_codigo AS item,
		r10_nombre AS nom,
		r10_estado AS est,
		r10_tipo AS tipo,
		r10_peso AS peso,
		r10_uni_med AS uni_m,
		r10_cantpaq AS cantp,
		r10_cantveh AS cantv,
		r10_partida AS part,
		r10_modelo AS model,
		r10_cod_pedido AS cod_p,
		r10_cod_comerc AS cod_c,
		r10_cod_util AS cod_uti,
		r10_linea AS linea,
		r10_sub_linea AS sub_lin,
		r10_cod_grupo AS cod_gru,
		r10_cod_clase AS cod_cla,
		r10_marca AS marca,
		r10_rotacion AS rotac,
		r10_paga_impto AS paga_i,
		r10_fob AS fob,
		r10_monfob AS mon_f,
		r10_precio_mb AS prec,
		r10_precio_ma AS prec_ma,
		r10_cantped AS cantpe,
		r10_cantback AS cantba,
		r10_comentarios AS comenta,
		r10_precio_ant AS prec_ant,
		r10_fec_camprec AS fec_cam,
		r10_filtro AS filtro,
		r10_electrico AS elect,
		r10_color AS color,
		r10_serie_lote AS ser_lot,
		r10_stock_max AS stock_max,
		r10_stock_min AS stock_min,
		r10_vol_cuft AS vol_cuft,
		r10_dias_mant AS dias_mant,
		r10_dias_inv AS dias_inv,
		r10_sec_item AS sec_item,
		r10_feceli AS feceli
		FROM acero_qm@idsuio01:rept010, t1
		WHERE r10_compania = 1
		  AND ite          = r10_codigo;

DROP TABLE t1;

BEGIN WORK;

	UPDATE rept010
		SET r10_nombre  = (SELECT nom
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_estado  = (SELECT est
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_tipo    = (SELECT tipo
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_peso    = (SELECT peso
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_uni_med = (SELECT uni_m
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_cantpaq = (SELECT cantp
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_cantveh = (SELECT cantv
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_partida = (SELECT part
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_modelo = (SELECT model
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_cod_pedido = (SELECT cod_p
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_cod_comerc = (SELECT cod_c
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_cod_util = (SELECT cod_uti
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_linea = (SELECT linea
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_sub_linea = (SELECT sub_lin
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_cod_grupo = (SELECT cod_gru
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_cod_clase = (SELECT cod_cla
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_marca = (SELECT marca
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_rotacion = (SELECT rotac
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_paga_impto = (SELECT paga_i
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_fob = (SELECT fob
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_monfob = (SELECT mon_f
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_precio_mb = (SELECT prec
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_precio_ma = (SELECT prec_ma
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_cantped = (SELECT cantpe
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_cantback = (SELECT cantba
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_comentarios = (SELECT comenta
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_precio_ant = (SELECT prec_ant
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_fec_camprec = (SELECT fec_cam
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_filtro = (SELECT filtro
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_electrico = (SELECT elect
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_color = (SELECT color
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_serie_lote = (SELECT ser_lot
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_stock_max = (SELECT stock_max
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_stock_min = (SELECT stock_min
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_vol_cuft = (SELECT vol_cuft
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_dias_mant = (SELECT dias_mant
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_dias_inv = (SELECT dias_inv
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_sec_item = (SELECT sec_item
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo),
		    r10_feceli = (SELECT feceli
					FROM tmp_ite
					WHERE cia  = r10_compania
					  AND item = r10_codigo)
		WHERE r10_compania  = 1
		  AND r10_codigo   IN
			(SELECT item
				FROM tmp_ite
				WHERE cia = r10_compania);

--ROLLBACK WORK;
COMMIT WORK;

DROP TABLE tmp_ite;
