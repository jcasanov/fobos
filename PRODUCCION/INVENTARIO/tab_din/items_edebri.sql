SELECT r10_codigo AS item,
	r10_nombre AS descripcion,
	r10_cod_pedido AS referencia,
	r10_marca AS marca,
	r10_precio_mb AS precio,
	CASE WHEN r10_estado = 'A'
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS estado
	FROM rept010
	WHERE r10_compania  = 1
	  AND r10_marca    IN ("EDESA", "BRIGGS");
