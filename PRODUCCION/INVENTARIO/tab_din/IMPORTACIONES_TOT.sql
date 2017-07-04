SELECT r17_pedido AS pedido,
	NVL((SELECT r81_nom_prov
		FROM acero_qm:rept081
		WHERE r81_compania  = r16_compania
		  AND r81_localidad = r16_localidad
		  AND r81_pedido    = r16_pedido),
		(SELECT p01_nomprov
			FROM cxpt001
			WHERE p01_codprov = r16_proveedor)) AS proveedor,
	DATE(r16_fecing) AS fec_ped,
	(SELECT r19_num_tran
		FROM acero_qm:rept029, acero_qm:rept019
		WHERE r29_compania   = r16_compania
		  AND r29_localidad  = r16_localidad
		  AND r29_pedido     = r16_pedido
		  AND r19_compania   = r29_compania
		  AND r19_localidad  = r29_localidad
		  AND r19_cod_tran  IN ('IM', 'AI')
		  AND r19_numliq     = r29_numliq) AS num_tran,
	(SELECT DATE(r19_fecing)
		FROM acero_qm:rept029, acero_qm:rept019
		WHERE r29_compania   = r16_compania
		  AND r29_localidad  = r16_localidad
		  AND r29_pedido     = r16_pedido
		  AND r19_compania   = r29_compania
		  AND r19_localidad  = r29_localidad
		  AND r19_cod_tran  IN ('IM', 'AI')
		  AND r19_numliq     = r29_numliq) AS fec_imp,
	r16_referencia AS referencia,
	SUM(r17_fob) AS fob_imp,
	SUM(r17_tot_fob_mb) AS fob_tot,
	SUM(r17_peso) AS peso,
	NVL((SELECT r81_tipo_trans
		FROM acero_qm:rept081
		WHERE r81_compania  = r16_compania
		  AND r81_localidad = r16_localidad
		  AND r81_pedido    = r16_pedido), "SIN TRANSPORTE") AS med_tra,
	SUM(NVL((SELECT r20_costnue_mb
		FROM acero_qm:rept029, acero_qm:rept019, acero_qm:rept020
		WHERE r29_compania   = r16_compania
		  AND r29_localidad  = r16_localidad
		  AND r29_pedido     = r16_pedido
		  AND r19_compania   = r29_compania
		  AND r19_localidad  = r29_localidad
		  AND r19_cod_tran  IN ('IM', 'AI')
		  AND r19_numliq     = r29_numliq
		  AND r20_compania   = r19_compania
		  AND r20_localidad  = r19_localidad
		  AND r20_cod_tran   = r19_cod_tran
		  AND r20_num_tran   = r19_num_tran
		  AND r20_item       = r17_item), 0)) AS cost_imp,
	SUM(r17_cantped) AS cant_pedida,
	SUM(r17_cantrec) AS cant_recibida,
	NVL((SELECT SUM(r28_tot_cargos)
		FROM acero_qm:rept029, acero_qm:rept028
		WHERE r29_compania  = r16_compania
		  AND r29_localidad = r16_localidad
		  AND r29_pedido    = r16_pedido
		  AND r28_compania  = r29_compania
		  AND r28_localidad = r29_localidad
		  AND r28_numliq    = r29_numliq), 0) AS tot_car,
	CASE WHEN r16_estado = 'A' THEN "ACTIVO"
	     WHEN r16_estado = 'C' THEN "CONFIRMADO"
	     WHEN r16_estado = 'R' THEN "RECIBIDO"
	     WHEN r16_estado = 'L' THEN "LIQUIDADO"
	     WHEN r16_estado = 'P' THEN "PROCESADO"
	     WHEN r16_estado = 'E' THEN "ELIMINADO"
	END AS estado
	FROM acero_qm:rept016, acero_qm:rept017
	WHERE r16_compania  = 1
	  AND r16_localidad = 3
	  AND r17_compania  = r16_compania
	  AND r17_localidad = r16_localidad
	  AND r17_pedido    = r16_pedido
	GROUP BY 1, 2, 3, 4, 5, 6, 10, 14, 15;
