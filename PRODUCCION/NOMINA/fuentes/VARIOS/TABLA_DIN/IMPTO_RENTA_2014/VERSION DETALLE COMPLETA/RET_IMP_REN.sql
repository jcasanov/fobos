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
	  AND   n30_compania     = n32_compania
	  AND   n30_cod_trab     = n32_cod_trab
	  AND   n33_compania     = n32_compania
	  AND   n33_cod_liqrol   = n32_cod_liqrol
	  AND   n33_fecha_ini    = n32_fecha_ini
	  AND   n33_fecha_fin    = n32_fecha_fin
	  AND   n33_cod_trab     = n32_cod_trab
	  AND   n33_valor        > 0
	  AND   a.n06_cod_rubro  = n33_cod_rubro
	  AND ((a.n06_cod_rubro  = n33_cod_rubro
	  AND   a.n06_flag_ident = "IR")
	   OR  (a.n06_cod_rubro  = n33_cod_rubro
	  AND   a.n06_flag_ident = "DI"))
	GROUP BY 1, 2, 3, 4, 5, 6
UNION ALL
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
	  AND   n30_compania     = n32_compania
	  AND   n30_cod_trab     = n32_cod_trab
	  AND   n33_compania     = n32_compania
	  AND   n33_cod_liqrol   = n32_cod_liqrol
	  AND   n33_fecha_ini    = n32_fecha_ini
	  AND   n33_fecha_fin    = n32_fecha_fin
	  AND   n33_cod_trab     = n32_cod_trab
	  AND   n33_valor        > 0
	  AND ((a.n06_cod_rubro  = n33_cod_rubro
	  AND   a.n06_flag_ident = "IR")
	   OR  (a.n06_cod_rubro  = n33_cod_rubro
	  AND   a.n06_flag_ident = "DI"))
	GROUP BY 1, 2, 3, 4, 5, 6
UNION ALL
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS GYE"
	END AS loc,
	LPAD(MONTH(n30_fecha_sal), 2, 0) || "-" ||
	CASE WHEN MONTH(n30_fecha_sal) = 01 THEN "ENERO"
	     WHEN MONTH(n30_fecha_sal) = 02 THEN "FEBRERO"
	     WHEN MONTH(n30_fecha_sal) = 03 THEN "MARZO"
	     WHEN MONTH(n30_fecha_sal) = 04 THEN "ABRIL"
	     WHEN MONTH(n30_fecha_sal) = 05 THEN "MAYO"
	     WHEN MONTH(n30_fecha_sal) = 06 THEN "JUNIO"
	     WHEN MONTH(n30_fecha_sal) = 07 THEN "JULIO"
	     WHEN MONTH(n30_fecha_sal) = 08 THEN "AGOSTO"
	     WHEN MONTH(n30_fecha_sal) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(n30_fecha_sal) = 10 THEN "OCTUBRE"
	     WHEN MONTH(n30_fecha_sal) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(n30_fecha_sal) = 12 THEN "DICIEMBRE"
	END || "-" || YEAR(n30_fecha_sal) AS period,
	MONTH(n30_fecha_sal) AS mes,
	n30_cod_trab AS codi,
	n30_nombres AS empl,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est,
	SUM(NVL(b13_valor_base * (-1), 0.00)) AS val_ir
	FROM acero_gm@idsgye01:rolt030, acero_gm@idsgye01:rolt056,
		acero_gm@idsgye01:ctbt013, acero_gm@idsgye01:ctbt012
	WHERE n30_compania         = 1
	  AND n30_estado           = "I"
	  AND YEAR(n30_fecha_sal)  = 2014
	  AND n30_fec_jub         IS NULL
	  AND n56_compania         = n30_compania
	  AND n56_proceso          = "IR"
	  AND n56_cod_depto        = n30_cod_depto
	  AND n56_cod_trab         = n30_cod_trab
	  AND b13_compania         = n56_compania
	  AND b13_cuenta           = n56_aux_val_vac
	  AND b13_fec_proceso     BETWEEN n30_fecha_sal
				      AND MDY(12, 31, 2014)
	  AND b13_tipo_comp       <> "DN"
	  AND b13_valor_base       < 0
	  AND b12_compania         = b13_compania
	  AND b12_tipo_comp        = b13_tipo_comp
	  AND b12_num_comp         = b13_num_comp
	  AND b12_estado           = "M"
	GROUP BY 1, 2, 3, 4, 5, 6
	ORDER BY 1 ASC, 2 ASC, 5 ASC;
