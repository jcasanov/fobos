SELECT n15_ano, n15_base_imp_ini, n15_base_imp_fin, n15_fracc_base,
	(n15_porc_ir / 100) porc_ir
	FROM rolt015
	WHERE n15_compania = 1
	ORDER BY 1 DESC, 2 ASC;