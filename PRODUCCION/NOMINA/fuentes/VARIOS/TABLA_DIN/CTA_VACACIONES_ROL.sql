SELECT n50_compania AS cia,
	n50_cod_rubro AS rub,
	n06_nombre AS nom_rub,
	n50_cod_depto AS cod_depto,
	g34_nombre AS nom_depto,
	n50_aux_cont,
	(SELECT b10_descripcion
		FROM ctbt010
		WHERE b10_compania = n50_compania
		  AND b10_cuenta   = n50_aux_cont) AS nom_aux_cont
	FROM rolt050, rolt006, gent034
	WHERE n50_compania    = 1
	  AND n06_cod_rubro   = n50_cod_rubro
	  AND n06_flag_ident IN ("VV", "IV", "OV")
	  AND g34_compania    = n50_compania
	  AND g34_cod_depto   = n50_cod_depto
	ORDER BY 2, 5;
