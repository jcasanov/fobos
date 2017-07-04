SELECT a.n32_ano_proceso AS anio,
	CASE WHEN (a.n32_mes_proceso >= 01 AND a.n32_mes_proceso <= 03)
		THEN "TRI_01"
	     WHEN (a.n32_mes_proceso >= 04 AND a.n32_mes_proceso <= 06)
		THEN "TRI_02"
	     WHEN (a.n32_mes_proceso >= 07 AND a.n32_mes_proceso <= 09)
		THEN "TRI_03"
	     WHEN (a.n32_mes_proceso >= 10 AND a.n32_mes_proceso <= 12)
		THEN "TRI_04"
	END AS trimes,
	a.n32_cod_trab AS codi,
	n30_nombres AS empl,
	g34_nombre AS depto,
	ROUND(SUM(b.n33_valor +
		NVL((SELECT SUM(n47_dias_real)
			FROM rolt047
			WHERE n47_compania         = a.n32_compania
			  AND n47_cod_trab         = a.n32_cod_trab
			  AND YEAR(n47_fecha_fin)  = a.n32_ano_proceso
			  AND MONTH(n47_fecha_fin) = a.n32_mes_proceso
			  AND n47_estado           = "A"), 0.00)), 2) AS dias_v,
	NVL(CASE WHEN (a.n32_mes_proceso >= 01 AND a.n32_mes_proceso <= 03) THEN
		(SELECT SUM(c.n33_valor)
			FROM rolt033 c
			WHERE c.n33_compania          = n30_compania
			  AND c.n33_cod_liqrol       IN ("Q1", "Q2")
			  AND YEAR(c.n33_fecha_fin)   = a.n32_ano_proceso
			  AND MONTH(c.n33_fecha_fin) BETWEEN 1 AND 3
			  AND c.n33_cod_trab          = n30_cod_trab
			  AND c.n33_cod_rubro         =
					(SELECT n06_cod_rubro
						FROM rolt006
						WHERE n06_flag_ident = "MO")
			  AND c.n33_valor      > 0)
	     WHEN (a.n32_mes_proceso >= 04 AND a.n32_mes_proceso <= 06) THEN
		(SELECT SUM(c.n33_valor)
			FROM rolt033 c
			WHERE c.n33_compania          = n30_compania
			  AND c.n33_cod_liqrol       IN ("Q1", "Q2")
			  AND YEAR(c.n33_fecha_fin)   = a.n32_ano_proceso
			  AND MONTH(c.n33_fecha_fin) BETWEEN 4 AND 6
			  AND c.n33_cod_trab          = n30_cod_trab
			  AND c.n33_cod_rubro         =
					(SELECT n06_cod_rubro
						FROM rolt006
						WHERE n06_flag_ident = "MO")
			  AND c.n33_valor      > 0)
	     WHEN (a.n32_mes_proceso >= 07 AND a.n32_mes_proceso <= 09) THEN
		(SELECT SUM(c.n33_valor)
			FROM rolt033 c
			WHERE c.n33_compania          = n30_compania
			  AND c.n33_cod_liqrol       IN ("Q1", "Q2")
			  AND YEAR(c.n33_fecha_fin)   = a.n32_ano_proceso
			  AND MONTH(c.n33_fecha_fin) BETWEEN 7 AND 9
			  AND c.n33_cod_trab          = n30_cod_trab
			  AND c.n33_cod_rubro         =
					(SELECT n06_cod_rubro
						FROM rolt006
						WHERE n06_flag_ident = "MO")
			  AND c.n33_valor      > 0)
	     WHEN (a.n32_mes_proceso >= 10 AND a.n32_mes_proceso <= 12) THEN
		(SELECT SUM(c.n33_valor)
			FROM rolt033 c
			WHERE c.n33_compania          = n30_compania
			  AND c.n33_cod_liqrol       IN ("Q1", "Q2")
			  AND YEAR(c.n33_fecha_fin)   = a.n32_ano_proceso
			  AND MONTH(c.n33_fecha_fin) BETWEEN 10 AND 12
			  AND c.n33_cod_trab          = n30_cod_trab
			  AND c.n33_cod_rubro         =
					(SELECT n06_cod_rubro
						FROM rolt006
						WHERE n06_flag_ident = "MO")
			  AND c.n33_valor      > 0)
	END, 0.00) AS tot_mov,
	NVL(CASE WHEN MONTH(TODAY) IN (3, 6, 9, 12) THEN
		CASE WHEN (SELECT COUNT(*)
				FROM rolt032 c
				WHERE c.n32_compania    = a.n32_compania
				  AND c.n32_cod_trab    = a.n32_cod_trab
				  AND c.n32_ano_proceso = a.n32_ano_proceso
				  AND c.n32_mes_proceso = MONTH(TODAY)) = 1
		THEN (SELECT n10_valor
			FROM rolt010
			WHERE n10_compania  = n30_compania
			  AND n10_cod_trab  = n30_cod_trab
			  AND n10_cod_rubro = (SELECT n06_cod_rubro
						FROM rolt006
						WHERE n06_flag_ident = "MO")
			  AND n10_valor     > 0)
		END
	END, 0.00) AS mov_mes
	FROM rolt032 a, rolt033 b, rolt030, gent034
	WHERE a.n32_compania     = 1
	  AND a.n32_cod_liqrol  IN ("Q1", "Q2")
	  AND a.n32_ano_proceso >= 2012
	  AND a.n32_estado       = "C"
	  AND b.n33_compania     = a.n32_compania
	  AND b.n33_cod_liqrol   = a.n32_cod_liqrol
	  AND b.n33_fecha_ini    = a.n32_fecha_ini
	  AND b.n33_fecha_fin    = a.n32_fecha_fin
	  AND b.n33_cod_trab     = a.n32_cod_trab
	  AND b.n33_cod_rubro    = (SELECT n06_cod_rubro
					FROM rolt006
					WHERE n06_flag_ident = "DV")
	  AND b.n33_valor        > 0
	  AND n30_compania       = b.n33_compania
	  AND n30_cod_trab       = b.n33_cod_trab
	  AND g34_compania       = a.n32_compania
	  AND g34_cod_depto      = a.n32_cod_depto
	  AND EXISTS
		(SELECT 1 FROM rolt010
			WHERE n10_compania  = n30_compania
			  AND n10_cod_trab  = n30_cod_trab
			  AND n10_cod_rubro = (SELECT n06_cod_rubro
						FROM rolt006
						WHERE n06_flag_ident = "MO")
			  AND n10_valor     > 0)
	GROUP BY 1, 2, 3, 4, 5, 7, 8
	ORDER BY 1, 2, 4;
