SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM gent002
		WHERE g02_compania  = r46_compania
		  AND g02_localidad = r46_localidad) AS local,
	r46_composicion AS recet,
	CAST(r46_item_comp AS INTEGER) AS item_c,
	r46_desc_clase_c AS clas,
	r46_desc_comp AS desc_ite_c,
	r46_marca_c AS marc,
	CAST(r47_item_part AS INTEGER) AS item_p,
	r47_desc_part AS desc_ite_p,
	r47_cantidad AS cant_p,
	CASE WHEN r46_estado = "C" THEN "CERRADA"
	     WHEN r46_estado = "P" THEN "EN PROCESO"
	END AS est
	FROM rept046, rept047
	WHERE r46_compania    = 1
	  AND r46_localidad   = 1
	  AND r47_compania    = r46_compania
	  AND r47_localidad   = r46_localidad
	  AND r47_composicion = r46_composicion
	  AND r47_item_comp   = r46_item_comp
	ORDER BY 7, 3;
