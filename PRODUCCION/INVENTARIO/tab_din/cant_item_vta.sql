SELECT r20_item AS item,
	r19_nomcli AS cliente,
	r20_cod_tran AS tipo,
	r20_num_tran AS numero,
	DATE(r20_fecing) AS fecha,
	CASE WHEN r20_cod_tran = "FA"
		THEN r20_cant_ven
		ELSE r20_cant_ven * (-1)
	END AS cantidad
	FROM rept019, rept020
	WHERE r19_compania      = 1
	  AND r19_localidad     = 1
	  AND r19_cod_tran     IN ("FA", "DF", "AF")
	  AND DATE(r19_fecing) >= MDY(07, 01, 2012)
	  AND r20_compania      = r19_compania
	  AND r20_localidad     = r19_localidad
	  AND r20_cod_tran      = r19_cod_tran
	  AND r20_num_tran      = r19_num_tran
	ORDER BY 1, 2;
