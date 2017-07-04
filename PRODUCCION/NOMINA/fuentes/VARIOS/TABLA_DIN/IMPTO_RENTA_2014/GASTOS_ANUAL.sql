SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS GYE"
	END AS loc,
	n30_cod_trab AS codi,
	n30_nombres AS empl,
	MIN(n32_fecha_ini) AS fec_proc,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est
	FROM acero_gm@idsgye01:rolt032, acero_gm@idsgye01:rolt030
	WHERE n32_compania     = 1
	  AND n32_cod_liqrol  IN ("Q1", "Q2")
	  AND n32_ano_proceso  = 2014
	  AND n30_compania     = n32_compania
	  AND n30_cod_trab     = n32_cod_trab
	GROUP BY 1, 2, 3, 5
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS UIO"
	END AS loc,
	n30_cod_trab AS codi,
	n30_nombres AS empl,
	MIN(n32_fecha_ini) AS fec_proc,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est
	FROM acero_qm@idsuio01:rolt032, acero_qm@idsuio01:rolt030
	WHERE n32_compania     = 1
	  AND n32_cod_liqrol  IN ("Q1", "Q2")
	  AND n32_ano_proceso  = 2014
	  AND n30_compania     = n32_compania
	  AND n30_cod_trab     = n32_cod_trab
	GROUP BY 1, 2, 3, 5
	ORDER BY 1 ASC, 4 ASC, 3 ASC;
