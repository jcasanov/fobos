SELECT "GYE" AS loc, r10_filtro AS filtro, r10_marca AS marca,
	CASE WHEN r10_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM rept010
	WHERE r10_compania = 1
	  AND r10_estado   = 'A'
	  AND r10_marca IN ("ECERAM", "INSINK", "RIALTO", "SIDEC", "FVGRIF",
				"FVSANI", "FVCERA", "EDESA", "TEKVEN", "TEKA",
				"CALORE", "KOHGRI", "KOHSAN", "CERREC",
				"AVALON", "BRIGGS", "CREIN", "ALPHAJ", "ARISTO",
				"CATA", "CASTEL", "CONACA", "EREJIL", "FECSA",
				"FIBRAS", "HACEB", "INSINK", "INCAME", "INTACO",
				"KERAMI", "KWIKSE", "MATEX", "PERMAC")
	GROUP BY 1, 2, 3, 4
	ORDER BY 2;
