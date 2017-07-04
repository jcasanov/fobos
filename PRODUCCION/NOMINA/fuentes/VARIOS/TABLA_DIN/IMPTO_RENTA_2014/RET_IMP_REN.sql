SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS GYE"
	END AS loc,
	LPAD(n32_mes_proceso, 2, 0) || "-" ||
	CASE WHEN n32_mes_proceso = 01 THEN "ENERO"
	     WHEN n32_mes_proceso = 02 THEN "FEBRERO"
	     WHEN n32_mes_proceso = 03 THEN "MARZO"
	     WHEN n32_mes_proceso = 04 THEN "ABRIL"
	     WHEN n32_mes_proceso = 05 THEN "MAYO"
	     WHEN n32_mes_proceso = 06 THEN "JUNIO"
	     WHEN n32_mes_proceso = 07 THEN "JULIO"
	     WHEN n32_mes_proceso = 08 THEN "AGOSTO"
	     WHEN n32_mes_proceso = 09 THEN "SEPTIEMBRE"
	     WHEN n32_mes_proceso = 10 THEN "OCTUBRE"
	     WHEN n32_mes_proceso = 11 THEN "NOVIEMBRE"
	     WHEN n32_mes_proceso = 12 THEN "DICIEMBRE"
	END || "-" || n32_ano_proceso AS period,
	n32_mes_proceso AS mes,
	n30_cod_trab AS codi,
	n30_nombres AS empl,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est,
	SUM(NVL(CASE WHEN a.n06_flag_ident = "IR"
			THEN n33_valor
			ELSE n33_valor * (-1)
		END, 0.00)) AS val_ir
	FROM acero_gm@idsgye01:rolt032, acero_gm@idsgye01:rolt030,
		acero_gm@idsgye01:rolt033, acero_gm@idsgye01:rolt006 a
	WHERE   n32_compania     = 1
	  AND   n32_cod_liqrol  IN ("Q1", "Q2")
	  AND   n32_ano_proceso  = 2014
	  AND   n32_estado       = "C"
	  AND   n32_fecha_fin   <= (SELECT MAX(b.n32_fecha_fin)
					FROM acero_gm@idsgye01:rolt032 b
					WHERE b.n32_compania    = 1
					  AND b.n32_cod_liqrol  = "Q2"
					  AND b.n32_ano_proceso = 2014
					  AND b.n32_estado      = "C")
	  AND   n30_compania     = n32_compania
	  AND   n30_cod_trab     = n32_cod_trab
	  AND   n33_compania     = n32_compania
	  AND   n33_cod_liqrol   = n32_cod_liqrol
	  AND   n33_fecha_ini   >= MDY(01, 01, n32_ano_proceso)
	  AND   n33_fecha_fin   <= MDY(n32_mes_proceso, 01, n32_ano_proceso)
					+ 1 UNITS MONTH - 1 UNITS DAY
	  AND   n33_cod_trab     = n32_cod_trab
	  AND   n33_valor        > 0
	  AND   a.n06_cod_rubro  = n33_cod_rubro
	  AND ((a.n06_cod_rubro  = n33_cod_rubro
	  AND   a.n06_flag_ident = "IR")
	   OR  (a.n06_cod_rubro  = n33_cod_rubro
	  AND   a.n06_flag_ident = "DI"))
	GROUP BY 1, 2, 3, 4, 5, 6
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS UIO"
	END AS loc,
	LPAD(n32_mes_proceso, 2, 0) || "-" ||
	CASE WHEN n32_mes_proceso = 01 THEN "ENERO"
	     WHEN n32_mes_proceso = 02 THEN "FEBRERO"
	     WHEN n32_mes_proceso = 03 THEN "MARZO"
	     WHEN n32_mes_proceso = 04 THEN "ABRIL"
	     WHEN n32_mes_proceso = 05 THEN "MAYO"
	     WHEN n32_mes_proceso = 06 THEN "JUNIO"
	     WHEN n32_mes_proceso = 07 THEN "JULIO"
	     WHEN n32_mes_proceso = 08 THEN "AGOSTO"
	     WHEN n32_mes_proceso = 09 THEN "SEPTIEMBRE"
	     WHEN n32_mes_proceso = 10 THEN "OCTUBRE"
	     WHEN n32_mes_proceso = 11 THEN "NOVIEMBRE"
	     WHEN n32_mes_proceso = 12 THEN "DICIEMBRE"
	END || "-" || n32_ano_proceso AS period,
	n32_mes_proceso AS mes,
	n30_cod_trab AS codi,
	n30_nombres AS empl,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est,
	SUM(NVL(CASE WHEN a.n06_flag_ident = "IR"
			THEN n33_valor
			ELSE n33_valor * (-1)
		END, 0.00)) AS val_ir
	FROM acero_qm@idsuio01:rolt032, acero_qm@idsuio01:rolt030,
		acero_qm@idsuio01:rolt033, acero_qm@idsuio01:rolt006 a
	WHERE   n32_compania     = 1
	  AND   n32_cod_liqrol  IN ("Q1", "Q2")
	  AND   n32_ano_proceso  = 2014
	  AND   n32_estado       = "C"
	  AND   n32_fecha_fin   <= (SELECT MAX(b.n32_fecha_fin)
					FROM acero_qm@idsuio01:rolt032 b
					WHERE b.n32_compania    = 1
					  AND b.n32_cod_liqrol  = "Q2"
					  AND b.n32_ano_proceso = 2014
					  AND b.n32_estado      = "C")
	  AND   n30_compania     = n32_compania
	  AND   n30_cod_trab     = n32_cod_trab
	  AND   n33_compania     = n32_compania
	  AND   n33_cod_liqrol   = n32_cod_liqrol
	  AND   n33_fecha_ini   >= MDY(01, 01, n32_ano_proceso)
	  AND   n33_fecha_fin   <= MDY(n32_mes_proceso, 01, n32_ano_proceso)
					+ 1 UNITS MONTH - 1 UNITS DAY
	  AND   n33_cod_trab     = n32_cod_trab
	  AND   n33_valor        > 0
	  AND ((a.n06_cod_rubro  = n33_cod_rubro
	  AND   a.n06_flag_ident = "IR")
	   OR  (a.n06_cod_rubro  = n33_cod_rubro
	  AND   a.n06_flag_ident = "DI"))
	GROUP BY 1, 2, 3, 4, 5, 6
	ORDER BY 1 ASC, 2 ASC, 5 ASC;
