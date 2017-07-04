SELECT CASE WHEN r19_localidad = 01 THEN "01 GYE J T M"
	    WHEN r19_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r19_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r19_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r19_localidad = 05 THEN "05 ACERO KHOLER"
	END AS localidad,
	YEAR(a.r19_fecing) AS anio,
	fp_numero_semana(DATE(a.r19_fecing)) AS num_sem,
	YEAR(TODAY) AS anio_h,
	fp_numero_semana(TODAY) AS num_sem_h,
	r01_nombres AS vend,
	a.r19_codcli AS codcli,
	a.r19_nomcli AS nomcli,
	SUM(CASE WHEN a.r19_cod_tran = "FA"
		THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
		ELSE ((r20_cant_ven * r20_precio) - r20_val_descto) * (-1)
	END) AS vta
	FROM aceros@acgyede:rept019 a, aceros@acgyede:rept001,
		aceros@acgyede:rept020
	WHERE a.r19_compania      = 1
	  AND a.r19_localidad     = 1
	  AND a.r19_cod_tran     IN ("FA", "DF", "AF")
	  AND YEAR(a.r19_fecing) >= 2012
	  AND r01_compania        = a.r19_compania
	  AND r01_codigo          = a.r19_vendedor
	  AND r20_compania        = a.r19_compania
	  AND r20_localidad       = a.r19_localidad
	  AND r20_cod_tran        = a.r19_cod_tran
	  AND r20_num_tran        = a.r19_num_tran
	  AND DATE(a.r19_fecing)  = (TODAY - 90 UNITS DAY)
	  AND NOT EXISTS
		(SELECT 1 FROM aceros@acgyede:rept019 b
			WHERE b.r19_compania      = a.r19_compania
			  AND b.r19_localidad     = a.r19_localidad
			  AND b.r19_cod_tran     IN ("FA", "DF", "AF")
			  AND b.r19_vendedor      = a.r19_vendedor
			  AND b.r19_codcli        = a.r19_codcli
			  AND DATE(b.r19_fecing)  > (TODAY - 90 UNITS DAY))
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
	HAVING SUM(CASE WHEN a.r19_cod_tran = "FA"
		THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
		ELSE ((r20_cant_ven * r20_precio) - r20_val_descto) * (-1)
	END) > 500
UNION
SELECT CASE WHEN r19_localidad = 01 THEN "01 GYE J T M"
	    WHEN r19_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r19_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r19_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r19_localidad = 05 THEN "05 ACERO KHOLER"
	END AS localidad,
	YEAR(a.r19_fecing) AS anio,
	fp_numero_semana(DATE(a.r19_fecing)) AS num_sem,
	YEAR(TODAY) AS anio_h,
	fp_numero_semana(TODAY) AS num_sem_h,
	r01_nombres AS vend,
	a.r19_codcli AS codcli,
	a.r19_nomcli AS nomcli,
	SUM(CASE WHEN a.r19_cod_tran = "FA"
		THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
		ELSE ((r20_cant_ven * r20_precio) - r20_val_descto) * (-1)
	END) AS vta
	FROM acero_qm@acgyede:rept019 a, acero_qm@acgyede:rept001,
		acero_qm@acgyede:rept020
	WHERE a.r19_compania      = 1
	  AND a.r19_localidad    IN (3, 5)
	  AND a.r19_cod_tran     IN ("FA", "DF", "AF")
	  AND YEAR(a.r19_fecing) >= 2012
	  AND r01_compania        = a.r19_compania
	  AND r01_codigo          = a.r19_vendedor
	  AND r20_compania        = a.r19_compania
	  AND r20_localidad       = a.r19_localidad
	  AND r20_cod_tran        = a.r19_cod_tran
	  AND r20_num_tran        = a.r19_num_tran
	  AND DATE(a.r19_fecing)  = (TODAY - 90 UNITS DAY)
	  AND NOT EXISTS
		(SELECT 1 FROM acero_qm@acgyede:rept019 b
			WHERE b.r19_compania      = a.r19_compania
			  AND b.r19_localidad     = a.r19_localidad
			  AND b.r19_cod_tran     IN ("FA", "DF", "AF")
			  AND b.r19_vendedor      = a.r19_vendedor
			  AND b.r19_codcli        = a.r19_codcli
			  AND DATE(b.r19_fecing)  > (TODAY - 90 UNITS DAY))
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
	HAVING SUM(CASE WHEN a.r19_cod_tran = "FA"
		THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
		ELSE ((r20_cant_ven * r20_precio) - r20_val_descto) * (-1)
	END) > 500
UNION
SELECT CASE WHEN r19_localidad = 01 THEN "01 GYE J T M"
	    WHEN r19_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r19_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r19_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r19_localidad = 05 THEN "05 ACERO KHOLER"
	END AS localidad,
	YEAR(a.r19_fecing) AS anio,
	fp_numero_semana(DATE(a.r19_fecing)) AS num_sem,
	YEAR(TODAY) AS anio_h,
	fp_numero_semana(TODAY) AS num_sem_h,
	r01_nombres AS vend,
	a.r19_codcli AS codcli,
	a.r19_nomcli AS nomcli,
	SUM(CASE WHEN a.r19_cod_tran = "FA"
		THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
		ELSE ((r20_cant_ven * r20_precio) - r20_val_descto) * (-1)
	END) AS vta
	FROM acero_qs@acgyede:rept019 a, acero_qs@acgyede:rept001,
		acero_qs@acgyede:rept020
	WHERE a.r19_compania      = 1
	  AND a.r19_localidad     = 4
	  AND a.r19_cod_tran     IN ("FA", "DF", "AF")
	  AND YEAR(a.r19_fecing) >= 2012
	  AND r01_compania        = a.r19_compania
	  AND r01_codigo          = a.r19_vendedor
	  AND r20_compania        = a.r19_compania
	  AND r20_localidad       = a.r19_localidad
	  AND r20_cod_tran        = a.r19_cod_tran
	  AND r20_num_tran        = a.r19_num_tran
	  AND DATE(a.r19_fecing)  = (TODAY - 90 UNITS DAY)
	  AND NOT EXISTS
		(SELECT 1 FROM acero_qs@acgyede:rept019 b
			WHERE b.r19_compania      = a.r19_compania
			  AND b.r19_localidad     = a.r19_localidad
			  AND b.r19_cod_tran     IN ("FA", "DF", "AF")
			  AND b.r19_vendedor      = a.r19_vendedor
			  AND b.r19_codcli        = a.r19_codcli
			  AND DATE(b.r19_fecing)  > (TODAY - 90 UNITS DAY))
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
	HAVING SUM(CASE WHEN a.r19_cod_tran = "FA"
		THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
		ELSE ((r20_cant_ven * r20_precio) - r20_val_descto) * (-1)
	END) > 500;
