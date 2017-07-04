SELECT r19_codcli AS codcli,
	r19_nomcli AS nomcli,
	r19_telcli AS telcli,
	r10_marca AS marca,
	DATE(max(r19_fecing)) AS ultfec
	FROM rept019, rept020, rept010
	WHERE r19_compania      = 1
	  AND r19_localidad     = 1
	  AND r19_cod_tran     IN ("FA", "DF")
	  AND YEAR(r19_fecing)  > 2011
	  AND r20_compania      = r19_compania
	  AND r20_localidad     = r19_localidad
	  AND r20_cod_tran      = r19_cod_tran
	  AND r20_num_tran      = r19_num_tran
	  AND r10_compania      = r20_compania
	  AND r10_codigo        = r20_item
	  AND r10_marca        IN ("MILWAU", "RIDGID")
	GROUP BY 1, 2, 3, 4;
