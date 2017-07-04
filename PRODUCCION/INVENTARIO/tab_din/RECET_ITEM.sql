SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM gent002
		WHERE g02_compania  = r46_compania
		  AND g02_localidad = r46_localidad) AS local,
	r46_composicion AS recet,
	CAST(r46_item_comp AS INTEGER) AS item_c,
	(SELECT COUNT(*)
		FROM rept047
		WHERE r47_compania    = r46_compania
		  AND r47_localidad   = r46_localidad
		  AND r47_composicion = r46_composicion
		  AND r47_item_comp   = r46_item_comp) AS num_ite,
	1 AS cant,
	r10_costo_mb AS cost_act,
	r10_precio_mb AS pvp_act,
	CASE WHEN r46_estado = "C" THEN "CERRADA"
	     WHEN r46_estado = "P" THEN "EN PROCESO"
	END AS est
	FROM rept046, rept010
	WHERE r46_compania  = 1
	  AND r46_localidad = 1
	  AND r10_compania  = r46_compania
	  AND r10_codigo    = r46_item_comp;
