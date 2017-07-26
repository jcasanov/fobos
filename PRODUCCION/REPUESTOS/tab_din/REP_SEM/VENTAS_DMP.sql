SELECT YEAR(r19_fecing) AS anio,
	r19_codcli AS cod_cli,
	r19_nomcli AS nom_cli,
	NVL(SUM(CASE WHEN r19_cod_tran = "FA"
			THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
			ELSE ((r20_cant_ven * r20_precio) - r20_val_descto)
				* (-1)
		END), 0) AS vta
	FROM rept019, rept020
	WHERE r19_compania      = 1
	  AND r19_localidad     = 1
	  AND r19_cod_tran     IN ("FA", "DF", "AF")
	  AND r19_vendedor      = 37
	  AND r19_codcli       <> 101
	  AND YEAR(r19_fecing) >= 2010
	  AND r20_compania      = r19_compania
	  AND r20_localidad     = r19_localidad
	  AND r20_cod_tran      = r19_cod_tran
	  AND r20_num_tran      = r19_num_tran
	GROUP BY 1, 2, 3
	ORDER BY 3;
