SELECT CASE WHEN r19_localidad = 01 THEN "01 GYE J T M"
	    WHEN r19_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r19_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r19_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r19_localidad = 05 THEN "05 ACERO KHOLER"
	END AS localidad,
	YEAR(a.r19_fecing) AS anio,
	CASE WHEN a.r19_cont_cred = "C"
		THEN "CONTADO"
		ELSE "CREDITO"
	END AS tip_vta,
	r01_nombres AS vend,
	a.r19_codcli AS codcli,
	a.r19_nomcli AS nomcli,
	CASE WHEN z01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est_cli,
	"MAS 90 DIAS" AS sin_v,
	(SELECT (TODAY - MAX(DATE(b.r19_fecing)))
		FROM acero_gm@idsgye01:rept019 b
		WHERE b.r19_compania  = a.r19_compania
		  AND b.r19_localidad = a.r19_localidad
		  AND b.r19_cod_tran  = "FA"
		  AND b.r19_codcli    = a.r19_codcli) AS n_dias,
	LPAD(ROUND((DATE(a.r19_fecing) - MDY(1, 3, YEAR(DATE(a.r19_fecing)
		- WEEKDAY(DATE(a.r19_fecing) - 1 UNITS DAY) + 4 UNITS DAY))
		+ WEEKDAY(MDY(1, 3, YEAR(DATE(a.r19_fecing)
		- WEEKDAY(DATE(a.r19_fecing) - 1 UNITS DAY) + 4 UNITS DAY)))
		+ 5) / 7, 0), 2, 0) AS num_sem,
	CASE WHEN a.r19_cod_tran = "FA" THEN "FACTURAS"
	     WHEN a.r19_cod_tran = "DF" THEN "DEVOLUCIONES"
	     WHEN a.r19_cod_tran = "AF" THEN "ANULACIONES"
	END AS tipo_t,
	SUM(CASE WHEN a.r19_cod_tran = "FA"
		THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
		ELSE ((r20_cant_ven * r20_precio) - r20_val_descto) * (-1)
	END) AS vta
	FROM acero_gm@idsgye01:rept019 a, acero_gm@idsgye01:rept001,
		acero_gm@idsgye01:rept020, acero_gm@idsgye01:cxct001
	WHERE a.r19_compania      = 1
	  AND a.r19_localidad     = 1
	  AND a.r19_cod_tran     IN ("FA", "DF", "AF")
	  AND YEAR(a.r19_fecing) >= 2011
	  AND r01_compania        = a.r19_compania
	  AND r01_codigo          = a.r19_vendedor
	  AND r20_compania        = a.r19_compania
	  AND r20_localidad       = a.r19_localidad
	  AND r20_cod_tran        = a.r19_cod_tran
	  AND r20_num_tran        = a.r19_num_tran
	  AND z01_codcli          = a.r19_codcli
	  AND (SELECT (TODAY - MAX(DATE(b.r19_fecing)))
			FROM acero_gm@idsgye01:rept019 b
			WHERE b.r19_compania  = a.r19_compania
			  AND b.r19_localidad = a.r19_localidad
			  AND b.r19_cod_tran  = "FA"
			  AND b.r19_codcli    = a.r19_codcli) BETWEEN 90 AND 180
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
UNION
SELECT CASE WHEN r19_localidad = 01 THEN "01 GYE J T M"
	    WHEN r19_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r19_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r19_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r19_localidad = 05 THEN "05 ACERO KHOLER"
	END AS localidad,
	YEAR(a.r19_fecing) AS anio,
	CASE WHEN a.r19_cont_cred = "C"
		THEN "CONTADO"
		ELSE "CREDITO"
	END AS tip_vta,
	r01_nombres AS vend,
	a.r19_codcli AS codcli,
	a.r19_nomcli AS nomcli,
	CASE WHEN z01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est_cli,
	"MAS 180 DIAS" AS sin_v,
	(SELECT (TODAY - MAX(DATE(b.r19_fecing)))
		FROM acero_gm@idsgye01:rept019 b
		WHERE b.r19_compania  = a.r19_compania
		  AND b.r19_localidad = a.r19_localidad
		  AND b.r19_cod_tran  = "FA"
		  AND b.r19_codcli    = a.r19_codcli) AS n_dias,
	LPAD(ROUND((DATE(a.r19_fecing) - MDY(1, 3, YEAR(DATE(a.r19_fecing)
		- WEEKDAY(DATE(a.r19_fecing) - 1 UNITS DAY) + 4 UNITS DAY))
		+ WEEKDAY(MDY(1, 3, YEAR(DATE(a.r19_fecing)
		- WEEKDAY(DATE(a.r19_fecing) - 1 UNITS DAY) + 4 UNITS DAY)))
		+ 5) / 7, 0), 2, 0) AS num_sem,
	CASE WHEN a.r19_cod_tran = "FA" THEN "FACTURAS"
	     WHEN a.r19_cod_tran = "DF" THEN "DEVOLUCIONES"
	     WHEN a.r19_cod_tran = "AF" THEN "ANULACIONES"
	END AS tipo_t,
	SUM(CASE WHEN a.r19_cod_tran = "FA"
		THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
		ELSE ((r20_cant_ven * r20_precio) - r20_val_descto) * (-1)
	END) AS vta
	FROM acero_gm@idsgye01:rept019 a, acero_gm@idsgye01:rept001,
		acero_gm@idsgye01:rept020, acero_gm@idsgye01:cxct001
	WHERE a.r19_compania      = 1
	  AND a.r19_localidad     = 1
	  AND a.r19_cod_tran     IN ("FA", "DF", "AF")
	  AND YEAR(a.r19_fecing) >= 2011
	  AND r01_compania        = a.r19_compania
	  AND r01_codigo          = a.r19_vendedor
	  AND r20_compania        = a.r19_compania
	  AND r20_localidad       = a.r19_localidad
	  AND r20_cod_tran        = a.r19_cod_tran
	  AND r20_num_tran        = a.r19_num_tran
	  AND z01_codcli          = a.r19_codcli
	  AND (SELECT (TODAY - MAX(DATE(b.r19_fecing)))
			FROM acero_gm@idsgye01:rept019 b
			WHERE b.r19_compania  = a.r19_compania
			  AND b.r19_localidad = a.r19_localidad
			  AND b.r19_cod_tran  = "FA"
			  AND b.r19_codcli    = a.r19_codcli) > 180
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
UNION
SELECT CASE WHEN r19_localidad = 01 THEN "01 GYE J T M"
	    WHEN r19_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r19_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r19_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r19_localidad = 05 THEN "05 ACERO KHOLER"
	END AS localidad,
	YEAR(a.r19_fecing) AS anio,
	CASE WHEN a.r19_cont_cred = "C"
		THEN "CONTADO"
		ELSE "CREDITO"
	END AS tip_vta,
	r01_nombres AS vend,
	a.r19_codcli AS codcli,
	a.r19_nomcli AS nomcli,
	CASE WHEN z01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est_cli,
	"MAS 90 DIAS" AS sin_v,
	(SELECT (TODAY - MAX(DATE(b.r19_fecing)))
		FROM acero_qm@acgyede:rept019 b
		WHERE b.r19_compania  = a.r19_compania
		  AND b.r19_localidad = a.r19_localidad
		  AND b.r19_cod_tran  = "FA"
		  AND b.r19_codcli    = a.r19_codcli) AS n_dias,
	LPAD(ROUND((DATE(a.r19_fecing) - MDY(1, 3, YEAR(DATE(a.r19_fecing)
		- WEEKDAY(DATE(a.r19_fecing) - 1 UNITS DAY) + 4 UNITS DAY))
		+ WEEKDAY(MDY(1, 3, YEAR(DATE(a.r19_fecing)
		- WEEKDAY(DATE(a.r19_fecing) - 1 UNITS DAY) + 4 UNITS DAY)))
		+ 5) / 7, 0), 2, 0) AS num_sem,
	CASE WHEN a.r19_cod_tran = "FA" THEN "FACTURAS"
	     WHEN a.r19_cod_tran = "DF" THEN "DEVOLUCIONES"
	     WHEN a.r19_cod_tran = "AF" THEN "ANULACIONES"
	END AS tipo_t,
	SUM(CASE WHEN a.r19_cod_tran = "FA"
		THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
		ELSE ((r20_cant_ven * r20_precio) - r20_val_descto) * (-1)
	END) AS vta
	FROM acero_qm@acgyede:rept019 a, acero_qm@acgyede:rept001,
		acero_qm@acgyede:rept020, acero_qm@acgyede:cxct001
	WHERE a.r19_compania      = 1
	  AND a.r19_localidad    IN (3, 5)
	  AND a.r19_cod_tran     IN ("FA", "DF", "AF")
	  AND YEAR(a.r19_fecing) >= 2011
	  AND r01_compania        = a.r19_compania
	  AND r01_codigo          = a.r19_vendedor
	  AND r20_compania        = a.r19_compania
	  AND r20_localidad       = a.r19_localidad
	  AND r20_cod_tran        = a.r19_cod_tran
	  AND r20_num_tran        = a.r19_num_tran
	  AND z01_codcli          = a.r19_codcli
	  AND (SELECT (TODAY - MAX(DATE(b.r19_fecing)))
			FROM acero_qm@acgyede:rept019 b
			WHERE b.r19_compania  = a.r19_compania
			  AND b.r19_localidad = a.r19_localidad
			  AND b.r19_cod_tran  = "FA"
			  AND b.r19_codcli    = a.r19_codcli) BETWEEN 90 AND 180
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
UNION
SELECT CASE WHEN r19_localidad = 01 THEN "01 GYE J T M"
	    WHEN r19_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r19_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r19_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r19_localidad = 05 THEN "05 ACERO KHOLER"
	END AS localidad,
	YEAR(a.r19_fecing) AS anio,
	CASE WHEN a.r19_cont_cred = "C"
		THEN "CONTADO"
		ELSE "CREDITO"
	END AS tip_vta,
	r01_nombres AS vend,
	a.r19_codcli AS codcli,
	a.r19_nomcli AS nomcli,
	CASE WHEN z01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est_cli,
	"MAS 180 DIAS" AS sin_v,
	(SELECT (TODAY - MAX(DATE(b.r19_fecing)))
		FROM acero_qm@acgyede:rept019 b
		WHERE b.r19_compania  = a.r19_compania
		  AND b.r19_localidad = a.r19_localidad
		  AND b.r19_cod_tran  = "FA"
		  AND b.r19_codcli    = a.r19_codcli) AS n_dias,
	LPAD(ROUND((DATE(a.r19_fecing) - MDY(1, 3, YEAR(DATE(a.r19_fecing)
		- WEEKDAY(DATE(a.r19_fecing) - 1 UNITS DAY) + 4 UNITS DAY))
		+ WEEKDAY(MDY(1, 3, YEAR(DATE(a.r19_fecing)
		- WEEKDAY(DATE(a.r19_fecing) - 1 UNITS DAY) + 4 UNITS DAY)))
		+ 5) / 7, 0), 2, 0) AS num_sem,
	CASE WHEN a.r19_cod_tran = "FA" THEN "FACTURAS"
	     WHEN a.r19_cod_tran = "DF" THEN "DEVOLUCIONES"
	     WHEN a.r19_cod_tran = "AF" THEN "ANULACIONES"
	END AS tipo_t,
	SUM(CASE WHEN a.r19_cod_tran = "FA"
		THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
		ELSE ((r20_cant_ven * r20_precio) - r20_val_descto) * (-1)
	END) AS vta
	FROM acero_qm@acgyede:rept019 a, acero_qm@acgyede:rept001,
		acero_qm@acgyede:rept020, acero_qm@acgyede:cxct001
	WHERE a.r19_compania      = 1
	  AND a.r19_localidad    IN (3, 5)
	  AND a.r19_cod_tran     IN ("FA", "DF", "AF")
	  AND YEAR(a.r19_fecing) >= 2011
	  AND r01_compania        = a.r19_compania
	  AND r01_codigo          = a.r19_vendedor
	  AND r20_compania        = a.r19_compania
	  AND r20_localidad       = a.r19_localidad
	  AND r20_cod_tran        = a.r19_cod_tran
	  AND r20_num_tran        = a.r19_num_tran
	  AND z01_codcli          = a.r19_codcli
	  AND (SELECT (TODAY - MAX(DATE(b.r19_fecing)))
			FROM acero_qm@acgyede:rept019 b
			WHERE b.r19_compania  = a.r19_compania
			  AND b.r19_localidad = a.r19_localidad
			  AND b.r19_cod_tran  = "FA"
			  AND b.r19_codcli    = a.r19_codcli) > 180
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
UNION
SELECT CASE WHEN r19_localidad = 01 THEN "01 GYE J T M"
	    WHEN r19_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r19_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r19_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r19_localidad = 05 THEN "05 ACERO KHOLER"
	END AS localidad,
	YEAR(a.r19_fecing) AS anio,
	CASE WHEN a.r19_cont_cred = "C"
		THEN "CONTADO"
		ELSE "CREDITO"
	END AS tip_vta,
	r01_nombres AS vend,
	a.r19_codcli AS codcli,
	a.r19_nomcli AS nomcli,
	CASE WHEN z01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est_cli,
	"MAS 90 DIAS" AS sin_v,
	(SELECT (TODAY - MAX(DATE(b.r19_fecing)))
		FROM acero_qs@acgyede:rept019 b
		WHERE b.r19_compania  = a.r19_compania
		  AND b.r19_localidad = a.r19_localidad
		  AND b.r19_cod_tran  = "FA"
		  AND b.r19_codcli    = a.r19_codcli) AS n_dias,
	LPAD(ROUND((DATE(a.r19_fecing) - MDY(1, 3, YEAR(DATE(a.r19_fecing)
		- WEEKDAY(DATE(a.r19_fecing) - 1 UNITS DAY) + 4 UNITS DAY))
		+ WEEKDAY(MDY(1, 3, YEAR(DATE(a.r19_fecing)
		- WEEKDAY(DATE(a.r19_fecing) - 1 UNITS DAY) + 4 UNITS DAY)))
		+ 5) / 7, 0), 2, 0) AS num_sem,
	CASE WHEN a.r19_cod_tran = "FA" THEN "FACTURAS"
	     WHEN a.r19_cod_tran = "DF" THEN "DEVOLUCIONES"
	     WHEN a.r19_cod_tran = "AF" THEN "ANULACIONES"
	END AS tipo_t,
	SUM(CASE WHEN a.r19_cod_tran = "FA"
		THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
		ELSE ((r20_cant_ven * r20_precio) - r20_val_descto) * (-1)
	END) AS vta
	FROM acero_qs@acgyede:rept019 a, acero_qs@acgyede:rept001,
		acero_qs@acgyede:rept020, acero_qs@acgyede:cxct001
	WHERE a.r19_compania      = 1
	  AND a.r19_localidad     = 4
	  AND a.r19_cod_tran     IN ("FA", "DF", "AF")
	  AND YEAR(a.r19_fecing) >= 2011
	  AND r01_compania        = a.r19_compania
	  AND r01_codigo          = a.r19_vendedor
	  AND r20_compania        = a.r19_compania
	  AND r20_localidad       = a.r19_localidad
	  AND r20_cod_tran        = a.r19_cod_tran
	  AND r20_num_tran        = a.r19_num_tran
	  AND z01_codcli          = a.r19_codcli
	  AND (SELECT (TODAY - MAX(DATE(b.r19_fecing)))
			FROM acero_qs@acgyede:rept019 b
			WHERE b.r19_compania  = a.r19_compania
			  AND b.r19_localidad = a.r19_localidad
			  AND b.r19_cod_tran  = "FA"
			  AND b.r19_codcli    = a.r19_codcli) BETWEEN 90 AND 180
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11
UNION
SELECT CASE WHEN r19_localidad = 01 THEN "01 GYE J T M"
	    WHEN r19_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r19_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r19_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r19_localidad = 05 THEN "05 ACERO KHOLER"
	END AS localidad,
	YEAR(a.r19_fecing) AS anio,
	CASE WHEN a.r19_cont_cred = "C"
		THEN "CONTADO"
		ELSE "CREDITO"
	END AS tip_vta,
	r01_nombres AS vend,
	a.r19_codcli AS codcli,
	a.r19_nomcli AS nomcli,
	CASE WHEN z01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est_cli,
	"MAS 180 DIAS" AS sin_v,
	(SELECT (TODAY - MAX(DATE(b.r19_fecing)))
		FROM acero_qs@acgyede:rept019 b
		WHERE b.r19_compania  = a.r19_compania
		  AND b.r19_localidad = a.r19_localidad
		  AND b.r19_cod_tran  = "FA"
		  AND b.r19_codcli    = a.r19_codcli) AS n_dias,
	LPAD(ROUND((DATE(a.r19_fecing) - MDY(1, 3, YEAR(DATE(a.r19_fecing)
		- WEEKDAY(DATE(a.r19_fecing) - 1 UNITS DAY) + 4 UNITS DAY))
		+ WEEKDAY(MDY(1, 3, YEAR(DATE(a.r19_fecing)
		- WEEKDAY(DATE(a.r19_fecing) - 1 UNITS DAY) + 4 UNITS DAY)))
		+ 5) / 7, 0), 2, 0) AS num_sem,
	CASE WHEN a.r19_cod_tran = "FA" THEN "FACTURAS"
	     WHEN a.r19_cod_tran = "DF" THEN "DEVOLUCIONES"
	     WHEN a.r19_cod_tran = "AF" THEN "ANULACIONES"
	END AS tipo_t,
	SUM(CASE WHEN a.r19_cod_tran = "FA"
		THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
		ELSE ((r20_cant_ven * r20_precio) - r20_val_descto) * (-1)
	END) AS vta
	FROM acero_qs@acgyede:rept019 a, acero_qs@acgyede:rept001,
		acero_qs@acgyede:rept020, acero_qs@acgyede:cxct001
	WHERE a.r19_compania      = 1
	  AND a.r19_localidad     = 4
	  AND a.r19_cod_tran     IN ("FA", "DF", "AF")
	  AND YEAR(a.r19_fecing) >= 2011
	  AND r01_compania        = a.r19_compania
	  AND r01_codigo          = a.r19_vendedor
	  AND r20_compania        = a.r19_compania
	  AND r20_localidad       = a.r19_localidad
	  AND r20_cod_tran        = a.r19_cod_tran
	  AND r20_num_tran        = a.r19_num_tran
	  AND z01_codcli          = a.r19_codcli
	  AND (SELECT (TODAY - MAX(DATE(b.r19_fecing)))
			FROM acero_qs@acgyede:rept019 b
			WHERE b.r19_compania  = a.r19_compania
			  AND b.r19_localidad = a.r19_localidad
			  AND b.r19_cod_tran  = "FA"
			  AND b.r19_codcli    = a.r19_codcli) > 180
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11;
