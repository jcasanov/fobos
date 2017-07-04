SELECT "ACERO COMERCIAL" AS cia,
	(SELECT g02_abreviacion
		FROM acero_gm@idsgye01:gent002
		WHERE g02_compania  = n30_compania
		  AND g02_localidad = 1) AS lc,
	n30_cod_trab AS cod_trab,
	n30_num_doc_id AS cedula,
	n30_nombres AS empleados,
	NVL((CASE WHEN (n30_est_civil = 'C' OR n30_est_civil = 'U')
			THEN (SELECT COUNT(n31_secuencia)
				FROM acero_gm@idsgye01:rolt031
				WHERE n31_compania           = n30_compania
				  AND n31_cod_trab           = n30_cod_trab
				  AND n31_tipo_carga        <> 'H'
				  AND YEAR(n31_fecha_nacim) <= 2014)
			ELSE 0
		END +
		(SELECT COUNT(n31_secuencia)
			FROM acero_gm@idsgye01:rolt031
			WHERE n31_compania     = n30_compania 
			  AND n31_cod_trab     = n30_cod_trab
			  AND n31_tipo_carga   = 'H'
			  AND n31_fecha_nacim >= MDY(12, 31, 2014)
						- 19 UNITS YEAR + 1 UNITS DAY
			  AND n31_fecha_nacim <= MDY(12, 31, 2014))), 0)
	AS cargas,
	NVL(n30_fecha_reing, n30_fecha_ing) AS fecha_ing,
	n30_fecha_sal AS fecha_sal,
	CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) < MDY(01, 01, 2014)
		THEN MDY(01, 01, 2014)
		ELSE NVL(n30_fecha_reing, n30_fecha_ing)
	END AS fecha_ini,
	CASE WHEN n30_estado = "A"
		THEN MDY(12, 31, 2014)
		ELSE
			CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2014)
			END
	END AS fecha_fin,
	fp_dias360(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
				MDY(01, 01, 2014)
				THEN MDY(01, 01, 2014)
				ELSE NVL(n30_fecha_reing, n30_fecha_ing)
			END,
			CASE WHEN n30_estado = "A"
				THEN MDY(12, 31, 2014)
				ELSE
				CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2014)
				END
			END, 1) AS dias,
	NVL((CASE WHEN (n30_est_civil = 'C' OR n30_est_civil = 'U')
			THEN (SELECT COUNT(n31_secuencia)
				FROM acero_gm@idsgye01:rolt031
				WHERE n31_compania           = n30_compania
				  AND n31_cod_trab           = n30_cod_trab
				  AND n31_tipo_carga        <> 'H'
				  AND YEAR(n31_fecha_nacim) <= 2014)
			ELSE 0
		END +
		(SELECT COUNT(n31_secuencia)
			FROM acero_gm@idsgye01:rolt031
			WHERE n31_compania     = n30_compania 
			  AND n31_cod_trab     = n30_cod_trab
			  AND n31_tipo_carga   = 'H'
			  AND n31_fecha_nacim >= MDY(12, 31, 2014)
						- 19 UNITS YEAR + 1 UNITS DAY
			  AND n31_fecha_nacim <= MDY(12, 31, 2014))), 0) *
		fp_dias360(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
				MDY(01, 01, 2014)
				THEN MDY(01, 01, 2014)
				ELSE NVL(n30_fecha_reing, n30_fecha_ing)
			END,
			CASE WHEN n30_estado = "A"
				THEN MDY(12, 31, 2014)
				ELSE
				CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2014)
				END
			END, 1) AS dias_carg,
	ROUND(NVL((SELECT SUM(n46_saldo * (-1))
			FROM acero_gm@idsgye01:rolt045,
				acero_gm@idsgye01:rolt046
			WHERE n45_compania         = n30_compania
			  AND n45_cod_trab         = n30_cod_trab
			  AND n45_estado          IN ("A", "R")
			  AND n46_compania         = n45_compania
			  AND n46_num_prest        = n45_num_prest
			  AND n46_cod_liqrol       = "UT"
			  AND YEAR(n46_fecha_ini)  = 2014
			  AND YEAR(n46_fecha_fin)  = 2014
			  AND n46_saldo            > 0), 0) +
		NVL((SELECT SUM(n10_valor)
			FROM acero_gm@idsgye01:rolt010
			WHERE n10_compania   = n30_compania
			  AND n10_cod_liqrol = "UT"
			  AND n10_cod_trab   = n30_cod_trab), 0), 2) AS dscto,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM acero_gm@idsgye01:rolt030
	WHERE   n30_compania                               = 1
	  AND ((n30_estado                                 = "A"
	  AND   YEAR(NVL(n30_fecha_reing, n30_fecha_ing)) <= 2014)
	   OR  (n30_estado                                 = "I"
	  AND   YEAR(NVL(n30_fecha_reing, n30_fecha_ing)) <= 2014
	  AND   YEAR(n30_fecha_sal)                       >= 2014
	  AND   YEAR(n30_fecha_sal)                       <= YEAR(TODAY)))
	  AND   n30_tipo_contr                             = "F"
	  AND   n30_tipo_trab                              = "N"
	  AND   n30_fec_jub                               IS NULL
UNION
SELECT "ACERO COMERCIAL" AS cia,
	(SELECT g02_abreviacion
		FROM acero_qm@idsuio01:gent002
		WHERE g02_compania  = n30_compania
		  AND g02_localidad = 3) AS lc,
	n30_cod_trab AS cod_trab,
	n30_num_doc_id AS cedula,
	n30_nombres AS empleados,
	NVL((CASE WHEN (n30_est_civil = 'C' OR n30_est_civil = 'U')
			THEN (SELECT COUNT(n31_secuencia)
				FROM acero_qm@idsuio01:rolt031
				WHERE n31_compania           = n30_compania
				  AND n31_cod_trab           = n30_cod_trab
				  AND n31_tipo_carga        <> 'H'
				  AND YEAR(n31_fecha_nacim) <= 2014)
			ELSE 0
		END +
		(SELECT COUNT(n31_secuencia)
			FROM acero_qm@idsuio01:rolt031
			WHERE n31_compania     = n30_compania 
			  AND n31_cod_trab     = n30_cod_trab
			  AND n31_tipo_carga   = 'H'
			  AND n31_fecha_nacim >= MDY(12, 31, 2014)
						- 19 UNITS YEAR + 1 UNITS DAY
			  AND n31_fecha_nacim <= MDY(12, 31, 2014))), 0)
	AS cargas,
	NVL(n30_fecha_reing, n30_fecha_ing) AS fecha_ing,
	n30_fecha_sal AS fecha_sal,
	CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) < MDY(01, 01, 2014)
		THEN MDY(01, 01, 2014)
		ELSE NVL(n30_fecha_reing, n30_fecha_ing)
	END AS fecha_ini,
	CASE WHEN n30_estado = "A"
		THEN MDY(12, 31, 2014)
		ELSE
			CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2014)
			END
	END AS fecha_fin,
	fp_dias360(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
				MDY(01, 01, 2014)
				THEN MDY(01, 01, 2014)
				ELSE NVL(n30_fecha_reing, n30_fecha_ing)
			END,
			CASE WHEN n30_estado = "A"
				THEN MDY(12, 31, 2014)
				ELSE
				CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2014)
				END
			END, 1) AS dias,
	NVL((CASE WHEN (n30_est_civil = 'C' OR n30_est_civil = 'U')
			THEN (SELECT COUNT(n31_secuencia)
				FROM acero_qm@idsuio01:rolt031
				WHERE n31_compania           = n30_compania
				  AND n31_cod_trab           = n30_cod_trab
				  AND n31_tipo_carga        <> 'H'
				  AND YEAR(n31_fecha_nacim) <= 2014)
			ELSE 0
		END +
		(SELECT COUNT(n31_secuencia)
			FROM acero_qm@idsuio01:rolt031
			WHERE n31_compania     = n30_compania 
			  AND n31_cod_trab     = n30_cod_trab
			  AND n31_tipo_carga   = 'H'
			  AND n31_fecha_nacim >= MDY(12, 31, 2014)
						- 19 UNITS YEAR + 1 UNITS DAY
			  AND n31_fecha_nacim <= MDY(12, 31, 2014))), 0) *
		fp_dias360(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
				MDY(01, 01, 2014)
				THEN MDY(01, 01, 2014)
				ELSE NVL(n30_fecha_reing, n30_fecha_ing)
			END,
			CASE WHEN n30_estado = "A"
				THEN MDY(12, 31, 2014)
				ELSE
				CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2014)
				END
			END, 1) AS dias_carg,
	ROUND(NVL((SELECT SUM(n46_saldo * (-1))
			FROM acero_qm@idsuio01:rolt045,
				acero_qm@idsuio01:rolt046
			WHERE n45_compania         = n30_compania
			  AND n45_cod_trab         = n30_cod_trab
			  AND n45_estado          IN ("A", "R", "P")
			  AND n46_compania         = n45_compania
			  AND n46_num_prest        = n45_num_prest
			  AND n46_cod_liqrol       = "UT"
			  AND YEAR(n46_fecha_ini)  = 2014
			  AND YEAR(n46_fecha_fin)  = 2014
			  AND n46_saldo            > 0), 0) +
		NVL((SELECT SUM(n10_valor)
			FROM acero_qm@idsuio01:rolt010
			WHERE n10_compania   = n30_compania
			  AND n10_cod_liqrol = "UT"
			  AND n10_cod_trab   = n30_cod_trab), 0), 2) AS dscto,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM acero_qm@idsuio01:rolt030
	WHERE   n30_compania                               = 1
	  AND ((n30_estado                                 = "A"
	  AND   YEAR(NVL(n30_fecha_reing, n30_fecha_ing)) <= 2014)
	   OR  (n30_estado                                 = "I"
	  AND   YEAR(NVL(n30_fecha_reing, n30_fecha_ing)) <= 2014
	  AND   YEAR(n30_fecha_sal)                       >= 2014
	  AND   YEAR(n30_fecha_sal)                       <= YEAR(TODAY)))
	  AND   n30_tipo_contr                             = "F"
	  AND   n30_tipo_trab                              = "N"
	  AND   n30_fec_jub                               IS NULL
	ORDER BY 2 ASC, 5 ASC;
