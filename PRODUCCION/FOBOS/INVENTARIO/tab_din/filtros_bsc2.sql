SELECT r10_codigo AS item, r72_desc_clase AS clase, r10_nombre AS descripcion,
	r10_marca AS marca, r10_filtro AS filtro,
	CASE WHEN r10_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM rept010, rept072
	WHERE r10_compania = 1
	  AND r72_linea    = '7'
	{--
	  AND r10_marca IN ("ECERAM", "INSINK", "RIALTO", "SIDEC", "FVGRIF",
				"FVSANI", "FVCERA", "EDESA", "TEKVEN", "TEKA",
				"CALORE", "KOHGRI", "KOHSAN", "CERREC",
				"AVALON", "BRIGGS", "CREIN", "ALPHAJ", "ARISTO",
				"CATA", "CASTEL", "CONACA", "EREJIL", "FECSA",
				"FIBRAS", "HACEB", "INSINK", "INCAME", "INTACO",
				"KERAMI", "KWIKSE", "MATEX", "PERMAC")
	--}
	  AND r72_compania  = r10_compania
	  AND r72_linea     = r10_linea
	  AND r72_sub_linea = r10_sub_linea
	  AND r72_cod_grupo = r10_cod_grupo
	  AND r72_cod_clase = r10_cod_clase
	ORDER BY 1;
