SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS GYE"
	END AS loc,
	CASE WHEN (n30_estado = "A" AND TODAY <= MDY(12, 31, 2014))
		THEN (SELECT MAX(n32_mes_proceso)
			FROM acero_gm@idsgye01:rolt032
			WHERE n32_compania     = 1
			  AND n32_cod_liqrol  IN ("Q1", "Q2")
			  AND n32_ano_proceso  = 2014)
	     WHEN (n30_estado = "I" AND YEAR(n30_fecha_sal) = 2013)
		THEN 12
	     WHEN (n30_estado = "I" AND YEAR(n30_fecha_sal) = 2014)
		THEN MONTH(n30_fecha_sal)
		ELSE 12
	END AS mes,
	n30_num_doc_id AS num_d,
	n30_cod_trab AS codi,
	n30_nombres AS empl,
	(SELECT g34_nombre
		FROM acero_gm@idsgye01:gent034
		WHERE g34_compania  = n30_compania
		  AND g34_cod_depto = n30_cod_depto) AS depto,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est,
	CASE WHEN ROUND((TODAY - n30_fecha_nacim) / 365, 0) >= 65
		THEN "SI"
		ELSE "NO"
	END AS ter_edad,
	CASE WHEN n30_cod_trab IN (138, 215)
		THEN "SI"
		ELSE "NO"
	END AS discap
	FROM acero_gm@idsgye01:rolt030
	WHERE  n30_compania        = 1
	  AND (n30_estado          = "A"
	   OR (n30_estado          = "I"
	  AND  YEAR(n30_fecha_sal) > 2012))
	  AND  n30_fec_jub         IS NULL
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS UIO"
	END AS loc,
	CASE WHEN (n30_estado = "A" AND TODAY <= MDY(12, 31, 2014))
		THEN (SELECT MAX(n32_mes_proceso)
			FROM acero_qm@idsuio01:rolt032
			WHERE n32_compania     = 1
			  AND n32_cod_liqrol  IN ("Q1", "Q2")
			  AND n32_ano_proceso  = 2014)
	     WHEN (n30_estado = "I" AND YEAR(n30_fecha_sal) = 2013)
		THEN 12
	     WHEN (n30_estado = "I" AND YEAR(n30_fecha_sal) = 2014)
		THEN MONTH(n30_fecha_sal)
		ELSE 12
	END AS mes,
	n30_num_doc_id AS num_d,
	n30_cod_trab AS codi,
	n30_nombres AS empl,
	(SELECT g34_nombre
		FROM acero_qm@idsuio01:gent034
		WHERE g34_compania  = n30_compania
		  AND g34_cod_depto = n30_cod_depto) AS depto,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est,
	CASE WHEN ROUND((TODAY - n30_fecha_nacim) / 365, 0) >= 65
		THEN "SI"
		ELSE "NO"
	END AS ter_edad,
	"NO" AS discap
	FROM acero_qm@idsuio01:rolt030
	WHERE  n30_compania         = 1
	  AND  n30_cod_trab        <> 477
	  AND (n30_estado           = "A"
	   OR (n30_estado           = "I"
	  AND  YEAR(n30_fecha_sal)  > 2012))
	  AND  n30_fec_jub         IS NULL
	ORDER BY 1 ASC, 5 ASC;
