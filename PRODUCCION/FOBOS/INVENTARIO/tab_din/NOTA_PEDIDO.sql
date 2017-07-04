SELECT r17_pedido AS pedido,
	NVL((SELECT r81_nom_prov
		FROM rept081
		WHERE r81_compania  = r16_compania
		  AND r81_localidad = r16_localidad
		  AND r81_pedido    = r16_pedido),
		(SELECT p01_nomprov
			FROM cxpt001
			WHERE p01_codprov = r16_proveedor)) AS proveedor,
	r10_cod_comerc AS codigo_prov,
	r17_item AS item,
	r72_desc_clase AS clase,
	r10_nombre AS descripcion,
	r16_referencia AS referencia,
	r17_cantped AS cant_pedida,
	r17_cantrec AS cant_recibida,
	CASE WHEN r17_estado = 'A' THEN "ACTIVO"
	     WHEN r17_estado = 'C' THEN "CONFIRMADO"
	     WHEN r17_estado = 'R' THEN "RECIBIDO"
	     WHEN r17_estado = 'L' THEN "LIQUIDADO"
	     WHEN r17_estado = 'P' THEN "PROCESADO"
	     WHEN r17_estado = 'E' THEN "ELIMINADO"
	END AS estado
	FROM rept016, rept017, rept010, rept072
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
