SELECT "GYE J T M" AS loc,
	YEAR(a.b12_fec_proceso) AS anio,
	CASE WHEN MONTH(a.b12_fec_proceso) = 01 THEN "01_ENERO"
	     WHEN MONTH(a.b12_fec_proceso) = 02 THEN "02_FEBRERO"
	     WHEN MONTH(a.b12_fec_proceso) = 03 THEN "03_MARZO"
	     WHEN MONTH(a.b12_fec_proceso) = 04 THEN "04_ABRIL"
	     WHEN MONTH(a.b12_fec_proceso) = 05 THEN "05_MAYO"
	     WHEN MONTH(a.b12_fec_proceso) = 06 THEN "06_JUNIO"
	     WHEN MONTH(a.b12_fec_proceso) = 07 THEN "07_JULIO"
	     WHEN MONTH(a.b12_fec_proceso) = 08 THEN "08_AGOSTO"
	     WHEN MONTH(a.b12_fec_proceso) = 09 THEN "09_SEPTIEMBRE"
	     WHEN MONTH(a.b12_fec_proceso) = 10 THEN "10_OCTUBRE"
	     WHEN MONTH(a.b12_fec_proceso) = 11 THEN "11_NOVIEMBRE"
	     WHEN MONTH(a.b12_fec_proceso) = 12 THEN "12_DICIEMBRE"
	END AS nom_mes,
	b.b13_cuenta[1, 8] AS cta,
	b10_descripcion AS nom_cta,
	SUM(CASE WHEN b.b13_valor_base > 0
		THEN b.b13_valor_base
		ELSE 0.00
	END) AS val_db,
	SUM(CASE WHEN b.b13_valor_base < 0
		THEN b.b13_valor_base
		ELSE 0.00
	END) AS val_cr
	--SUM(b.b13_valor_base) AS sal_act
	FROM acero_gm@idsgye01:ctbt012 a, acero_gm@idsgye01:ctbt013 b,
		acero_gm@idsgye01:ctbt010
	WHERE a.b12_compania           = 1
	  AND a.b12_estado             = "M"
	  AND YEAR(a.b12_fec_proceso) >= 2009
	{--
	  AND NOT EXISTS
		(SELECT 1 FROM acero_gm@idsgye01:ctbt050
			WHERE b50_compania  = a.b12_compania
			  AND b50_tipo_comp = a.b12_tipo_comp
			  AND b50_num_comp  = a.b12_num_comp)
	--}
	  AND b.b13_compania           = a.b12_compania
	  AND b.b13_tipo_comp          = a.b12_tipo_comp
	  AND b.b13_num_comp           = a.b12_num_comp
	  AND b10_compania             = b.b13_compania
	  AND b10_cuenta               = b.b13_cuenta[1, 8]
	  AND b10_tipo_cta             = "R"
	GROUP BY 1, 2, 3, 4, 5
UNION
SELECT "GYE J T M" AS loc,
	2008 AS anio,
	"12_DICIEMBRE" AS nom_mes,
	b.b13_cuenta[1, 8] AS cta,
	b10_descripcion AS nom_cta,
	SUM(CASE WHEN b.b13_valor_base > 0
		THEN b.b13_valor_base
		ELSE 0.00
	END) AS val_db,
	SUM(CASE WHEN b.b13_valor_base < 0
		THEN b.b13_valor_base
		ELSE 0.00
	END) AS val_cr
	--SUM(b.b13_valor_base) AS sal_act
	FROM acero_gm@idsgye01:ctbt012 a, acero_gm@idsgye01:ctbt013 b,
		acero_gm@idsgye01:ctbt010
	WHERE a.b12_compania           = 1
	  AND a.b12_estado             = "M"
	  AND YEAR(a.b12_fec_proceso) <= 2008
	{--
	  AND NOT EXISTS
		(SELECT 1 FROM acero_gm@idsgye01:ctbt050
			WHERE b50_compania  = a.b12_compania
			  AND b50_tipo_comp = a.b12_tipo_comp
			  AND b50_num_comp  = a.b12_num_comp)
	--}
	  AND b.b13_compania           = a.b12_compania
	  AND b.b13_tipo_comp          = a.b12_tipo_comp
	  AND b.b13_num_comp           = a.b12_num_comp
	  AND b10_compania             = b.b13_compania
	  AND b10_cuenta               = b.b13_cuenta[1, 8]
	  AND b10_tipo_cta             = "R"
	GROUP BY 1, 2, 3, 4, 5
UNION
SELECT "MATRIZ U I O" AS loc,
	YEAR(a.b12_fec_proceso) AS anio,
	CASE WHEN MONTH(a.b12_fec_proceso) = 01 THEN "01_ENERO"
	     WHEN MONTH(a.b12_fec_proceso) = 02 THEN "02_FEBRERO"
	     WHEN MONTH(a.b12_fec_proceso) = 03 THEN "03_MARZO"
	     WHEN MONTH(a.b12_fec_proceso) = 04 THEN "04_ABRIL"
	     WHEN MONTH(a.b12_fec_proceso) = 05 THEN "05_MAYO"
	     WHEN MONTH(a.b12_fec_proceso) = 06 THEN "06_JUNIO"
	     WHEN MONTH(a.b12_fec_proceso) = 07 THEN "07_JULIO"
	     WHEN MONTH(a.b12_fec_proceso) = 08 THEN "08_AGOSTO"
	     WHEN MONTH(a.b12_fec_proceso) = 09 THEN "09_SEPTIEMBRE"
	     WHEN MONTH(a.b12_fec_proceso) = 10 THEN "10_OCTUBRE"
	     WHEN MONTH(a.b12_fec_proceso) = 11 THEN "11_NOVIEMBRE"
	     WHEN MONTH(a.b12_fec_proceso) = 12 THEN "12_DICIEMBRE"
	END AS nom_mes,
	b.b13_cuenta[1, 8] AS cta,
	b10_descripcion AS nom_cta,
	SUM(CASE WHEN b.b13_valor_base > 0
		THEN b.b13_valor_base
		ELSE 0.00
	END) AS val_db,
	SUM(CASE WHEN b.b13_valor_base < 0
		THEN b.b13_valor_base
		ELSE 0.00
	END) AS val_cr
	--SUM(b.b13_valor_base) AS sal_act
	FROM acero_qm@acgyede:ctbt012 a, acero_qm@acgyede:ctbt013 b,
		acero_qm@acgyede:ctbt010
	WHERE a.b12_compania           = 1
	  AND a.b12_estado             = "M"
	  AND YEAR(a.b12_fec_proceso) >= 2009
	{--
	  AND NOT EXISTS
		(SELECT 1 FROM acero_qm@acgyede:ctbt050
			WHERE b50_compania  = a.b12_compania
			  AND b50_tipo_comp = a.b12_tipo_comp
			  AND b50_num_comp  = a.b12_num_comp)
	--}
	  AND b.b13_compania           = a.b12_compania
	  AND b.b13_tipo_comp          = a.b12_tipo_comp
	  AND b.b13_num_comp           = a.b12_num_comp
	  AND b10_compania             = b.b13_compania
	  AND b10_cuenta               = b.b13_cuenta[1, 8]
	  AND b10_tipo_cta             = "R"
	GROUP BY 1, 2, 3, 4, 5
UNION
SELECT "MATRIZ U I O" AS loc,
	2008 AS anio,
	"12_DICIEMBRE" AS nom_mes,
	b.b13_cuenta[1, 8] AS cta,
	b10_descripcion AS nom_cta,
	SUM(CASE WHEN b.b13_valor_base > 0
		THEN b.b13_valor_base
		ELSE 0.00
	END) AS val_db,
	SUM(CASE WHEN b.b13_valor_base < 0
		THEN b.b13_valor_base
		ELSE 0.00
	END) AS val_cr
	--SUM(b.b13_valor_base) AS sal_act
	FROM acero_qm@acgyede:ctbt012 a, acero_qm@acgyede:ctbt013 b,
		acero_qm@acgyede:ctbt010
	WHERE a.b12_compania           = 1
	  AND a.b12_estado             = "M"
	  AND YEAR(a.b12_fec_proceso) <= 2008
	{--
	  AND NOT EXISTS
		(SELECT 1 FROM acero_qm@acgyede:ctbt050
			WHERE b50_compania  = a.b12_compania
			  AND b50_tipo_comp = a.b12_tipo_comp
			  AND b50_num_comp  = a.b12_num_comp)
	--}
	  AND b.b13_compania           = a.b12_compania
	  AND b.b13_tipo_comp          = a.b12_tipo_comp
	  AND b.b13_num_comp           = a.b12_num_comp
	  AND b10_compania             = b.b13_compania
	  AND b10_cuenta               = b.b13_cuenta[1, 8]
	  AND b10_tipo_cta             = "R"
	GROUP BY 1, 2, 3, 4, 5
	ORDER BY 1, 2, 3;
