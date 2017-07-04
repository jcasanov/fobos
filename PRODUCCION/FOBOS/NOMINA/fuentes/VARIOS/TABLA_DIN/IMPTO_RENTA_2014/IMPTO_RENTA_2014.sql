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
	END AS discap,
	SUM(CASE WHEN a.n06_flag_ident IN ("VT", "VE", "VM", "VV", "OV", "SX",
					  "SY")
		 THEN n33_valor
		 ELSE 0.00
	    END) AS sueld,
	SUM(CASE WHEN a.n06_flag_ident = "V5"
		 THEN n33_valor
		 ELSE 0.00
	    END) AS sob50,
	SUM(CASE WHEN a.n06_flag_ident = "V1"
		 THEN n33_valor
		 ELSE 0.00
	    END) AS sob100,
	SUM(CASE WHEN a.n06_flag_ident IN ("CO", "C1", "C2", "C3", "C4")
		 THEN n33_valor
		 ELSE 0.00
	    END) AS comis,
	SUM(CASE WHEN a.n06_flag_ident = "BO"
		 THEN n33_valor
		 ELSE 0.00
	    END) AS bonif,
	SUM(CASE WHEN a.n06_flag_ident = "MO"
		 THEN n33_valor
		 ELSE 0.00
	    END) AS moviliz,
	CASE WHEN n32_mes_proceso >= 4 THEN
		(SELECT n42_val_trabaj + n42_val_cargas
			FROM acero_gm@idsgye01:rolt042
			WHERE n42_compania   = n32_compania
			  AND n42_proceso    = "UT"
			  AND n42_cod_trab   = n32_cod_trab
			  AND n42_fecha_ini >= MDY(01, 01, n32_ano_proceso - 1)
			  AND n42_fecha_fin <= MDY(12, 01, n32_ano_proceso - 1)
						+ 1 UNITS MONTH - 1 UNITS DAY)
		ELSE 0.00
	END AS val_ut,
	(SELECT NVL(SUM(n39_valor_vaca + n39_valor_adic), 0.00)
		FROM acero_gm@idsgye01:rolt039
		WHERE n39_compania     = n32_compania
		  AND n39_proceso      = "VP"
		  AND DATE(n39_fecing) BETWEEN MDY(01, 01, n32_ano_proceso)
					   AND MDY(n32_mes_proceso, 01,
						n32_ano_proceso)
						+ 1 UNITS MONTH - 1 UNITS DAY
		  AND n39_cod_trab     = n32_cod_trab) AS vac_pag,
	(SELECT NVL(SUM(n44_valor), 0.00)
		FROM acero_gm@idsgye01:rolt044, acero_gm@idsgye01:rolt043
		WHERE n44_compania     = n32_compania
		  AND n44_cod_trab     = n32_cod_trab
		  AND n43_compania     = n44_compania
		  AND n43_num_rol      = n44_num_rol
		  AND n43_estado       = "P"
		  AND n43_tributa      = "S"
		  AND DATE(n43_fecing) BETWEEN MDY(01, 01, n32_ano_proceso)
					   AND MDY(n32_mes_proceso, 01,
						n32_ano_proceso)
						+ 1 UNITS MONTH - 1 UNITS DAY)
	AS val_varios,
	SUM(CASE WHEN (a.n06_flag_ident = "AP" OR n33_cod_rubro = 80)
		 THEN n33_valor * (-1)
		 ELSE 0.00
	    END) AS ap_iess,
	SUM(CASE WHEN a.n06_flag_ident = "EC"
		 THEN n33_valor * (-1)
		 ELSE 0.00
	    END) AS ap_iess_ec
	FROM acero_gm@idsgye01:rolt032, acero_gm@idsgye01:rolt030,
		acero_gm@idsgye01:rolt033, acero_gm@idsgye01:rolt006 a
	WHERE  n32_compania     = 1
	  AND  n32_cod_liqrol  IN ("Q1", "Q2")
	  AND  n32_ano_proceso  = 2014
	  AND  n32_estado       = "C"
	  AND  n32_fecha_fin   <= (SELECT MAX(b.n32_fecha_fin)
					FROM acero_gm@idsgye01:rolt032 b
					WHERE b.n32_compania    = 1
					  AND b.n32_cod_liqrol  = "Q2"
					  AND b.n32_ano_proceso = 2014
					  AND b.n32_estado      = "C")
	  AND  n30_compania     = n32_compania
	  AND  n30_cod_trab     = n32_cod_trab
	  AND  n33_compania     = n32_compania
	  AND  n33_cod_liqrol   = n32_cod_liqrol
	  AND  n33_fecha_ini   >= MDY(01, 01, n32_ano_proceso)
	  AND  n33_fecha_fin   <= MDY(n32_mes_proceso, 01, n32_ano_proceso)
					+ 1 UNITS MONTH - 1 UNITS DAY
	  AND  n33_cod_trab     = n32_cod_trab
	  AND (n33_cod_rubro   IN
		(SELECT c.n08_rubro_base
			FROM acero_gm@idsgye01:rolt006 b,
				acero_gm@idsgye01:rolt008 c
			WHERE b.n06_flag_ident = "AP"
			  AND c.n08_cod_rubro  = b.n06_cod_rubro)
	   OR  n33_cod_rubro    = 80
	   OR  n33_cod_rubro   IN
		(SELECT b.n06_cod_rubro
			FROM acero_gm@idsgye01:rolt006 b
			WHERE b.n06_flag_ident IN ("BO", "MO", "AP", "EC")))
	  AND  a.n06_cod_rubro  = n33_cod_rubro
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 17, 18, 19
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
	END AS discap,
	0.00 AS sueld,
	0.00 AS sob50,
	0.00 AS sob100,
	0.00 AS comis,
	0.00 AS bonif,
	0.00 AS moviliz,
	(n42_val_trabaj + n42_val_cargas) AS val_ut,
	0.00 AS vac_pag,
	0.00 AS val_varios,
	0.00 AS ap_iess,
	0.00 AS ap_iess_ec
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
			  AND n32_fecha_ini >= MDY(04, 01, n42_ano + 1)
			  AND n32_fecha_fin <= MDY(12, 31, n42_ano + 1))
			  --AND n32_ano_proceso = n42_ano + 1)
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
	END AS discap,
	0.00 AS sueld,
	0.00 AS sob50,
	0.00 AS sob100,
	0.00 AS comis,
	0.00 AS bonif,
	0.00 AS moviliz,
	(n42_val_trabaj + n42_val_cargas) AS val_ut,
	0.00 AS vac_pag,
	0.00 AS val_varios,
	0.00 AS ap_iess,
	0.00 AS ap_iess_ec
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
			  AND n32_fecha_ini >= MDY(04, 01, n42_ano + 1)
			  AND n32_fecha_fin <= MDY(12, 31, n42_ano + 1))
			  --AND n32_ano_proceso = n42_ano + 1)
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
		FROM acero_qm@acgyede:gent034
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
	END AS discap,
	SUM(CASE WHEN a.n06_flag_ident IN ("VT", "VE", "VM", "VV", "OV", "SX",
					  "SY")
		 THEN n33_valor
		 ELSE 0.00
	    END) AS sueld,
	SUM(CASE WHEN a.n06_flag_ident = "V5"
		 THEN n33_valor
		 ELSE 0.00
	    END) AS sob50,
	SUM(CASE WHEN a.n06_flag_ident = "V1"
		 THEN n33_valor
		 ELSE 0.00
	    END) AS sob100,
	SUM(CASE WHEN a.n06_flag_ident IN ("CO", "C1", "C2", "C3", "C4")
		 THEN n33_valor
		 ELSE 0.00
	    END) AS comis,
	SUM(CASE WHEN a.n06_flag_ident = "BO"
		 THEN n33_valor
		 ELSE 0.00
	    END) AS bonif,
	SUM(CASE WHEN a.n06_flag_ident = "MO"
		 THEN n33_valor
		 ELSE 0.00
	    END) AS moviliz,
	CASE WHEN n32_mes_proceso >= 4 THEN
		(SELECT n42_val_trabaj + n42_val_cargas
			FROM acero_qm@acgyede:rolt042
			WHERE n42_compania   = n32_compania
			  AND n42_proceso    = "UT"
			  AND n42_cod_trab   = n32_cod_trab
			  AND n42_fecha_ini >= MDY(01, 01, n32_ano_proceso - 1)
			  AND n42_fecha_fin <= MDY(12, 01, n32_ano_proceso - 1)
						+ 1 UNITS MONTH - 1 UNITS DAY)
		ELSE 0.00
	END AS val_ut,
	(SELECT NVL(SUM(n39_valor_vaca + n39_valor_adic), 0.00)
		FROM acero_qm@acgyede:rolt039
		WHERE n39_compania     = n32_compania
		  AND n39_proceso      = "VP"
		  AND DATE(n39_fecing) BETWEEN MDY(01, 01, n32_ano_proceso)
					   AND MDY(n32_mes_proceso, 01,
						n32_ano_proceso)
						+ 1 UNITS MONTH - 1 UNITS DAY
		  AND n39_cod_trab     = n32_cod_trab) AS vac_pag,
	(SELECT NVL(SUM(n44_valor), 0.00)
		FROM acero_qm@acgyede:rolt044, acero_qm@acgyede:rolt043
		WHERE n44_compania     = n32_compania
		  AND n44_cod_trab     = n32_cod_trab
		  AND n43_compania     = n44_compania
		  AND n43_num_rol      = n44_num_rol
		  AND n43_estado       = "P"
		  AND n43_tributa      = "S"
		  AND DATE(n43_fecing) BETWEEN MDY(01, 01, n32_ano_proceso)
					   AND MDY(n32_mes_proceso, 01,
						n32_ano_proceso)
						+ 1 UNITS MONTH - 1 UNITS DAY)
	AS val_varios,
	SUM(CASE WHEN (a.n06_flag_ident = "AP" OR n33_cod_rubro = 125)
		 THEN n33_valor * (-1)
		 ELSE 0.00
	    END) AS ap_iess,
	SUM(CASE WHEN a.n06_flag_ident = "EC"
		 THEN n33_valor * (-1)
		 ELSE 0.00
	    END) AS ap_iess_ec
	FROM acero_qm@acgyede:rolt032, acero_qm@acgyede:rolt030,
		acero_qm@acgyede:rolt033, acero_qm@acgyede:rolt006 a
	WHERE  n32_compania     = 1
	  AND  n32_cod_liqrol  IN ("Q1", "Q2")
	  AND  n32_ano_proceso  = 2014
	  AND  n32_estado       = "C"
	  AND  n32_fecha_fin   <= (SELECT MAX(b.n32_fecha_fin)
					FROM acero_qm@acgyede:rolt032 b
					WHERE b.n32_compania    = 1
					  AND b.n32_cod_liqrol  = "Q2"
					  AND b.n32_ano_proceso = 2014
					  AND b.n32_estado      = "C")
	  AND  n30_compania     = n32_compania
	  AND  n30_cod_trab     = n32_cod_trab
	  AND  n33_compania     = n32_compania
	  AND  n33_cod_liqrol   = n32_cod_liqrol
	  AND  n33_fecha_ini   >= MDY(01, 01, n32_ano_proceso)
	  AND  n33_fecha_fin   <= MDY(n32_mes_proceso, 01, n32_ano_proceso)
					+ 1 UNITS MONTH - 1 UNITS DAY
	  AND  n33_cod_trab     = n32_cod_trab
	  AND (n33_cod_rubro   IN
		(SELECT c.n08_rubro_base
			FROM acero_qm@acgyede:rolt006 b,
				acero_qm@acgyede:rolt008 c
			WHERE b.n06_flag_ident = "AP"
			  AND c.n08_cod_rubro  = b.n06_cod_rubro)
	   OR  n33_cod_rubro    = 125
	   OR  n33_cod_rubro   IN
		(SELECT b.n06_cod_rubro
			FROM acero_qm@acgyede:rolt006 b
			WHERE b.n06_flag_ident IN ("BO", "MO", "AP", "EC")))
	  AND  a.n06_cod_rubro  = n33_cod_rubro
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 17, 18, 19
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
		FROM acero_qm@acgyede:gent034
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
	END AS discap,
	0.00 AS sueld,
	0.00 AS sob50,
	0.00 AS sob100,
	0.00 AS comis,
	0.00 AS bonif,
	0.00 AS moviliz,
	(n42_val_trabaj + n42_val_cargas) AS val_ut,
	0.00 AS vac_pag,
	0.00 AS val_varios,
	0.00 AS ap_iess,
	0.00 AS ap_iess_ec
	FROM acero_qm@acgyede:rolt041, acero_qm@acgyede:rolt042,
		acero_qm@acgyede:rolt030
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
		(SELECT 1 FROM acero_qm@acgyede:rolt032
			WHERE n32_compania   = n42_compania
			  AND n32_cod_trab   = n42_cod_trab
			  AND n32_fecha_ini >= MDY(04, 01, n42_ano + 1)
			  AND n32_fecha_fin <= MDY(12, 31, n42_ano + 1))
			  --AND n32_ano_proceso = n42_ano + 1)
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
		FROM acero_qm@acgyede:gent034
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
	END AS discap,
	0.00 AS sueld,
	0.00 AS sob50,
	0.00 AS sob100,
	0.00 AS comis,
	0.00 AS bonif,
	0.00 AS moviliz,
	(n42_val_trabaj + n42_val_cargas) AS val_ut,
	0.00 AS vac_pag,
	0.00 AS val_varios,
	0.00 AS ap_iess,
	0.00 AS ap_iess_ec
	FROM acero_qm@acgyede:rolt041, acero_qm@acgyede:rolt042,
		acero_qm@acgyede:rolt030
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
		(SELECT 1 FROM acero_qm@acgyede:rolt032
			WHERE n32_compania   = n42_compania
			  AND n32_cod_trab   = n42_cod_trab
			  AND n32_fecha_ini >= MDY(04, 01, n42_ano + 1)
			  AND n32_fecha_fin <= MDY(12, 31, n42_ano + 1))
			  --AND n32_ano_proceso = n42_ano + 1)
	ORDER BY 1 ASC, 2 ASC, 6 ASC;
