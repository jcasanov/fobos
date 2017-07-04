SELECT n15_ano, 12 AS mes, n15_secuencia, n15_base_imp_ini, n15_base_imp_fin,
	n15_fracc_base, (n15_porc_ir / 100) AS porc
	FROM rolt015
	WHERE n15_ano = 2014
	ORDER BY 3 ASC;
