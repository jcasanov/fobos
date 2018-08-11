SELECT "GYE" AS loc,
	r72_cod_clase AS clase,
	r72_desc_clase AS descripcion
	FROM rept072
	WHERE r72_compania = 1
	ORDER BY 2 ASC;
