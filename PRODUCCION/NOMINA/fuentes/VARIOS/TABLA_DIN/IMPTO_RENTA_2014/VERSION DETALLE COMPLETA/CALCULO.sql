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
	n30_num_doc_id AS num_d,
	n30_cod_trab AS codi,
	n30_nombres AS empl,
	(SELECT g34_nombre
		FROM acero_gm@idsgye01:gent034
		WHERE g34_compania  = n32_compania
		  AND g34_cod_depto = n32_cod_depto) AS depto,
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
	FROM acero_gm@idsgye01:rolt032, acero_gm@idsgye01:rolt030
	WHERE n32_compania     = 1
	  AND n32_cod_liqrol  IN ("Q1", "Q2")
	  AND n32_ano_proceso  = 2014
	  --AND n32_estado       = "C"
	  AND n30_compania     = n32_compania
	  AND n30_cod_trab     = n32_cod_trab
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS GYE"
	END AS loc,
	LPAD(MONTH(n41_fecing), 2, 0) || "-" ||
	CASE WHEN MONTH(n41_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(n41_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(n41_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(n41_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(n41_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(n41_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(n41_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(n41_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(n41_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(n41_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(n41_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(n41_fecing) = 12 THEN "DICIEMBRE"
	END || "-" || YEAR(n41_fecing) AS period,
	MONTH(n41_fecing) AS mes,
	n30_num_doc_id AS num_d,
	n30_cod_trab AS codi,
	n30_nombres AS empl,
	(SELECT g34_nombre
		FROM acero_gm@idsgye01:gent034
		WHERE g34_compania  = n42_compania
		  AND g34_cod_depto = n42_cod_depto) AS depto,
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
	FROM acero_gm@idsgye01:rolt041, acero_gm@idsgye01:rolt042,
		acero_gm@idsgye01:rolt030
	WHERE n41_compania        = 1
	  AND n41_proceso         = "UT"
	  AND n41_ano             = 2013
	  AND n41_estado          = "P"
	  AND n42_compania        = n41_compania
	  AND n42_proceso         = n41_proceso
	  AND n42_ano             = n41_ano
	  AND n30_compania        = n42_compania
	  AND n30_cod_trab        = n42_cod_trab
	  AND n30_estado          = 'I'
	  AND YEAR(n30_fecha_sal) BETWEEN n42_ano AND n42_ano + 1
	  AND NOT EXISTS
		(SELECT 1 FROM acero_gm@idsgye01:rolt032
			WHERE n32_compania   = n42_compania
			  AND n32_cod_trab   = n42_cod_trab
			  AND n32_fecha_ini >= MDY(MONTH(n41_fecing), 01,
							YEAR(n41_fecing))
			  AND n32_fecha_fin <= MDY(12, 31, YEAR(n41_fecing)))
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS GYE"
	END AS loc,
	LPAD(MONTH(n41_fecha_fin), 2, 0) || "-" ||
	CASE WHEN MONTH(n41_fecha_fin) = 01 THEN "ENERO"
	     WHEN MONTH(n41_fecha_fin) = 02 THEN "FEBRERO"
	     WHEN MONTH(n41_fecha_fin) = 03 THEN "MARZO"
	     WHEN MONTH(n41_fecha_fin) = 04 THEN "ABRIL"
	     WHEN MONTH(n41_fecha_fin) = 05 THEN "MAYO"
	     WHEN MONTH(n41_fecha_fin) = 06 THEN "JUNIO"
	     WHEN MONTH(n41_fecha_fin) = 07 THEN "JULIO"
	     WHEN MONTH(n41_fecha_fin) = 08 THEN "AGOSTO"
	     WHEN MONTH(n41_fecha_fin) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(n41_fecha_fin) = 10 THEN "OCTUBRE"
	     WHEN MONTH(n41_fecha_fin) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(n41_fecha_fin) = 12 THEN "DICIEMBRE"
	END || "-" || YEAR(n41_fecha_fin) + 1 AS period,
	MONTH(n41_fecha_fin) AS mes,
	n30_num_doc_id AS num_d,
	n30_cod_trab AS codi,
	n30_nombres AS empl,
	(SELECT g34_nombre
		FROM acero_gm@idsgye01:gent034
		WHERE g34_compania  = n42_compania
		  AND g34_cod_depto = n42_cod_depto) AS depto,
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
	FROM acero_gm@idsgye01:rolt041, acero_gm@idsgye01:rolt042,
		acero_gm@idsgye01:rolt030
	WHERE n41_compania        = 1
	  AND n41_proceso         = "UT"
	  AND n41_ano             = 2013
	  AND n41_estado          = "P"
	  AND n42_compania        = n41_compania
	  AND n42_proceso         = n41_proceso
	  AND n42_ano             = n41_ano
	  AND n30_compania        = n42_compania
	  AND n30_cod_trab        = n42_cod_trab
	  AND n30_estado          = 'I'
	  AND YEAR(n30_fecha_sal) BETWEEN n42_ano AND n42_ano + 1
	  AND NOT EXISTS
		(SELECT 1 FROM acero_gm@idsgye01:rolt032
			WHERE n32_compania   = n42_compania
			  AND n32_cod_trab   = n42_cod_trab
			  AND n32_fecha_ini >= MDY(MONTH(n41_fecing), 01,
							YEAR(n41_fecing))
			  AND n32_fecha_fin <= MDY(12, 31, YEAR(n41_fecing)))
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
	n30_num_doc_id AS num_d,
	n30_cod_trab AS codi,
	n30_nombres AS empl,
	(SELECT g34_nombre
		FROM acero_qm@idsuio01:gent034
		WHERE g34_compania  = n32_compania
		  AND g34_cod_depto = n32_cod_depto) AS depto,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est,
	CASE WHEN ROUND((TODAY - n30_fecha_nacim) / 365, 0) >= 65
		THEN "SI"
		ELSE "NO"
	END AS ter_edad,
	"NO" AS discap
	FROM acero_qm@idsuio01:rolt032, acero_qm@idsuio01:rolt030
	WHERE n32_compania     = 1
	  AND n32_cod_liqrol  IN ("Q1", "Q2")
	  AND n32_ano_proceso  = 2014
	  --AND n32_estado       = "C"
	  AND n30_compania     = n32_compania
	  AND n30_cod_trab     = n32_cod_trab
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS UIO"
	END AS loc,
	LPAD(MONTH(n41_fecing), 2, 0) || "-" ||
	CASE WHEN MONTH(n41_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(n41_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(n41_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(n41_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(n41_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(n41_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(n41_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(n41_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(n41_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(n41_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(n41_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(n41_fecing) = 12 THEN "DICIEMBRE"
	END || "-" || YEAR(n41_fecing) AS period,
	MONTH(n41_fecing) AS mes,
	n30_num_doc_id AS num_d,
	n30_cod_trab AS codi,
	n30_nombres AS empl,
	(SELECT g34_nombre
		FROM acero_qm@idsuio01:gent034
		WHERE g34_compania  = n42_compania
		  AND g34_cod_depto = n42_cod_depto) AS depto,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est,
	CASE WHEN ROUND((TODAY - n30_fecha_nacim) / 365, 0) >= 65
		THEN "SI"
		ELSE "NO"
	END AS ter_edad,
	"NO" AS discap
	FROM acero_qm@idsuio01:rolt041, acero_qm@idsuio01:rolt042,
		acero_qm@idsuio01:rolt030
	WHERE n41_compania        = 1
	  AND n41_proceso         = "UT"
	  AND n41_ano             = 2013
	  AND n41_estado          = "P"
	  AND n42_compania        = n41_compania
	  AND n42_proceso         = n41_proceso
	  AND n42_ano             = n41_ano
	  AND n30_compania        = n42_compania
	  AND n30_cod_trab        = n42_cod_trab
	  AND n30_estado          = 'I'
	  AND YEAR(n30_fecha_sal) BETWEEN n42_ano AND n42_ano + 1
	  AND NOT EXISTS
		(SELECT 1 FROM acero_qm@idsuio01:rolt032
			WHERE n32_compania   = n42_compania
			  AND n32_cod_trab   = n42_cod_trab
			  AND n32_fecha_ini >= MDY(MONTH(n41_fecing), 01,
							YEAR(n41_fecing))
			  AND n32_fecha_fin <= MDY(12, 31, YEAR(n41_fecing)))
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS UIO"
	END AS loc,
	LPAD(MONTH(n41_fecha_fin), 2, 0) || "-" ||
	CASE WHEN MONTH(n41_fecha_fin) = 01 THEN "ENERO"
	     WHEN MONTH(n41_fecha_fin) = 02 THEN "FEBRERO"
	     WHEN MONTH(n41_fecha_fin) = 03 THEN "MARZO"
	     WHEN MONTH(n41_fecha_fin) = 04 THEN "ABRIL"
	     WHEN MONTH(n41_fecha_fin) = 05 THEN "MAYO"
	     WHEN MONTH(n41_fecha_fin) = 06 THEN "JUNIO"
	     WHEN MONTH(n41_fecha_fin) = 07 THEN "JULIO"
	     WHEN MONTH(n41_fecha_fin) = 08 THEN "AGOSTO"
	     WHEN MONTH(n41_fecha_fin) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(n41_fecha_fin) = 10 THEN "OCTUBRE"
	     WHEN MONTH(n41_fecha_fin) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(n41_fecha_fin) = 12 THEN "DICIEMBRE"
	END || "-" || YEAR(n41_fecha_fin) + 1 AS period,
	MONTH(n41_fecha_fin) AS mes,
	n30_num_doc_id AS num_d,
	n30_cod_trab AS codi,
	n30_nombres AS empl,
	(SELECT g34_nombre
		FROM acero_qm@idsuio01:gent034
		WHERE g34_compania  = n42_compania
		  AND g34_cod_depto = n42_cod_depto) AS depto,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est,
	CASE WHEN ROUND((TODAY - n30_fecha_nacim) / 365, 0) >= 65
		THEN "SI"
		ELSE "NO"
	END AS ter_edad,
	"NO" AS discap
	FROM acero_qm@idsuio01:rolt041, acero_qm@idsuio01:rolt042,
		acero_qm@idsuio01:rolt030
	WHERE n41_compania        = 1
	  AND n41_proceso         = "UT"
	  AND n41_ano             = 2013
	  AND n41_estado          = "P"
	  AND n42_compania        = n41_compania
	  AND n42_proceso         = n41_proceso
	  AND n42_ano             = n41_ano
	  AND n30_compania        = n42_compania
	  AND n30_cod_trab        = n42_cod_trab
	  AND n30_estado          = 'I'
	  AND YEAR(n30_fecha_sal) BETWEEN n42_ano AND n42_ano + 1
	  AND NOT EXISTS
		(SELECT 1 FROM acero_qm@idsuio01:rolt032
			WHERE n32_compania   = n42_compania
			  AND n32_cod_trab   = n42_cod_trab
			  AND n32_fecha_ini >= MDY(MONTH(n41_fecing), 01,
							YEAR(n41_fecing))
			  AND n32_fecha_fin <= MDY(12, 31, YEAR(n41_fecing)))
	ORDER BY 1 ASC, 2 ASC, 6 ASC;
