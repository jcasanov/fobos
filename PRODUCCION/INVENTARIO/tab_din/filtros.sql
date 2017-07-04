SELECT "GYE" AS loc, r10_filtro AS filtro, r10_marca AS marca,
	CASE WHEN r10_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM rept010
	WHERE r10_compania = 1
	  AND r10_estado   = 'A'
	GROUP BY 1, 2, 3, 4
	ORDER BY 2;
