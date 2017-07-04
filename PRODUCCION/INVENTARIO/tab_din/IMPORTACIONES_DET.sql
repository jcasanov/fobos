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
	r10_cod_comerc AS codigo_prov,
	r17_item AS item,
	r72_desc_clase AS clase,
	r10_nombre AS descripcion,
	r16_referencia AS referencia,
	r17_fob AS fob_imp,
	r17_tot_fob_mb AS fob_tot,
	r17_partida AS partida,
	r17_peso AS peso,
	NVL((SELECT r81_tipo_trans
		FROM acero_qm:rept081
		WHERE r81_compania  = r16_compania
		  AND r81_localidad = r16_localidad
		  AND r81_pedido    = r16_pedido), "SIN TRANSPORTE") AS med_tra,
	NVL((SELECT r20_costnue_mb
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
		  AND r20_item       = r17_item), 0) AS cost_imp,
	r17_cantped AS cant_pedida,
	r17_cantrec AS cant_recibida,
	CASE WHEN r17_estado = 'A' THEN "ACTIVO"
	     WHEN r17_estado = 'C' THEN "CONFIRMADO"
	     WHEN r17_estado = 'R' THEN "RECIBIDO"
	     WHEN r17_estado = 'L' THEN "LIQUIDADO"
	     WHEN r17_estado = 'P' THEN "PROCESADO"
	     WHEN r17_estado = 'E' THEN "ELIMINADO"
	END AS estado
	FROM acero_qm:rept016, acero_qm:rept017, acero_qm:rept010,
		acero_qm:rept072
	WHERE r16_compania  = 1
	  AND r16_localidad = 3
	  AND r17_compania  = r16_compania
	  AND r17_localidad = r16_localidad
	  AND r17_pedido    = r16_pedido
	  AND r10_compania  = r17_compania
	  AND r10_codigo    = r17_item
	  AND r72_compania  = r10_compania
	  AND r72_linea     = r10_linea
	  AND r72_sub_linea = r10_sub_linea
	  AND r72_cod_grupo = r10_cod_grupo
	  AND r72_cod_clase = r10_cod_clase;
