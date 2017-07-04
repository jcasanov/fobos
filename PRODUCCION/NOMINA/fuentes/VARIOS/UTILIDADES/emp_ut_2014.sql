SELECT (SELECT g02_abreviacion
		FROM acero_gm@idsgye01:gent002
		WHERE g02_compania  = n30_compania
		  AND g02_localidad = 1) AS lc,
	"ACERO COMERCIAL" AS cia,
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
	((12 - MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2014)
			THEN MDY(01, 01, 2014)
			ELSE MDY(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)),
				DAY(NVL(n30_fecha_reing, n30_fecha_ing)),
				2014)
		    END)) * (SELECT n00_dias_mes
				FROM acero_gm@idsgye01:rolt000
				WHERE n00_serial = n30_compania)) +
	((SELECT n00_dias_mes
		FROM acero_gm@idsgye01:rolt000
		WHERE n00_serial = n30_compania) -
	DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) < MDY(01, 01, 2014)
		THEN MDY(01, 01, 2014)
		ELSE MDY(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)),
			CASE WHEN DAY(NVL(n30_fecha_reing, n30_fecha_ing)) = 31
				THEN (SELECT n00_dias_mes
					FROM acero_gm@idsgye01:rolt000
					WHERE n00_serial = n30_compania)
				ELSE DAY(NVL(n30_fecha_reing, n30_fecha_ing))
			END,
			2014)
	    END) + 1) AS dias,
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
	(((12 - MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2014)
			THEN MDY(01, 01, 2014)
			ELSE MDY(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)),
				DAY(NVL(n30_fecha_reing, n30_fecha_ing)),
				2014)
		    END)) * (SELECT n00_dias_mes
				FROM acero_gm@idsgye01:rolt000
				WHERE n00_serial = n30_compania)) +
	((SELECT n00_dias_mes
		FROM acero_gm@idsgye01:rolt000
		WHERE n00_serial = n30_compania) -
	DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) < MDY(01, 01, 2014)
		THEN MDY(01, 01, 2014)
		ELSE MDY(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)),
			CASE WHEN DAY(NVL(n30_fecha_reing, n30_fecha_ing)) = 31
				THEN (SELECT n00_dias_mes
					FROM acero_gm@idsgye01:rolt000
					WHERE n00_serial = n30_compania)
				ELSE DAY(NVL(n30_fecha_reing, n30_fecha_ing))
			END,
			2014)
	    END) + 1)) AS dias_carg,
	ROUND(NVL((SELECT SUM(n46_saldo)
			FROM acero_gm@idsgye01:rolt045,
				acero_gm@idsgye01:rolt046
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
			FROM acero_gm@idsgye01:rolt010
			WHERE n10_compania   = n30_compania
			  AND n10_cod_liqrol = "UT"
			  AND n10_cod_trab   = n30_cod_trab), 0), 2) AS dscto,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM acero_gm@idsgye01:rolt030
	WHERE n30_compania             = 1
	  AND n30_estado               = 'A'
	  AND ((YEAR(n30_fecha_ing)   <= 2014
	  AND   n30_fecha_sal         IS NULL)
	   OR  (YEAR(n30_fecha_reing) <= 2014
	  AND   n30_fecha_sal         IS NOT NULL))
	  AND n30_tipo_contr           = 'F'
	  AND n30_tipo_trab            = 'N'
	  AND n30_fec_jub             IS NULL
UNION
SELECT (SELECT g02_abreviacion
		FROM acero_gm@idsgye01:gent002
		WHERE g02_compania  = n30_compania
		  AND g02_localidad = 1) AS lc,
	"ACERO COMERCIAL" AS cia,
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
	CASE WHEN (MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2014)
			 END) - CASE WHEN MONTH(n30_fecha_sal) =
				MONTH(NVL(n30_fecha_reing, n30_fecha_ing))
					THEN 0 ELSE 1 END) >=
			MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2014)
					THEN MDY(01, 01, 2014)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						2014)
				END)
		THEN (((MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2014)
				END) - 1) -
			MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2014)
					THEN MDY(01, 01, 2014)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
								n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
								n30_fecha_ing)),
						2014)
				END)) * (SELECT n00_dias_mes
					FROM acero_gm@idsgye01:rolt000
					WHERE n00_serial = n30_compania)) +
			((SELECT n00_dias_mes
				FROM acero_gm@idsgye01:rolt000
				WHERE n00_serial = n30_compania) -
			DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2014)
				THEN MDY(01, 01, 2014)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					CASE WHEN DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)) = 31
						THEN (SELECT n00_dias_mes
						FROM acero_gm@idsgye01:rolt000
							WHERE n00_serial =
								n30_compania)
						ELSE DAY(NVL(n30_fecha_reing,
								n30_fecha_ing))
					END,
					2014)
			    END) + 1)
		ELSE 0
	END + CASE WHEN DAY(CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2014)
			    END) = 31
			THEN (SELECT n00_dias_mes
				FROM acero_gm@idsgye01:rolt000
				WHERE n00_serial = n30_compania)
			ELSE DAY(CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2014)
				 END) -
				CASE WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2014)
						THEN MDY(01, 01, 2014)
						ELSE MDY(MONTH(NVL(
							n30_fecha_reing,
							n30_fecha_ing)),
							DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
							2014)
						END) = 
					MONTH(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2014)
						THEN n30_fecha_sal
						ELSE MDY(12, 31, 2014)
						END)
					THEN DAY(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2014)
						THEN MDY(01, 01, 2014)
						ELSE MDY(MONTH(NVL(
							n30_fecha_reing,
							n30_fecha_ing)),
							DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
							2014)
						END) - 1
					ELSE 0
				END
		END +
	CASE WHEN (MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2014)
			END) = 02 AND
			EXTEND(CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2014)
			END, MONTH TO DAY) =
			EXTEND(MDY(MONTH(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2014)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2014)
				  END), 01,
				YEAR(CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2014)
				     END)) + 1 UNITS MONTH - 1 UNITS DAY,
				MONTH TO DAY))
		THEN CASE WHEN MOD(2014, 4) = 0 THEN 1 ELSE 2 END
		ELSE 0
	END AS dias,
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
	(CASE WHEN (MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2014)
			 END) - CASE WHEN MONTH(n30_fecha_sal) =
				MONTH(NVL(n30_fecha_reing, n30_fecha_ing))
					THEN 0 ELSE 1 END) >=
			MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2014)
					THEN MDY(01, 01, 2014)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						2014)
				END)
		THEN (((MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2014)
				END) - 1) -
			MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2014)
					THEN MDY(01, 01, 2014)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
								n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
								n30_fecha_ing)),
						2014)
				END)) * (SELECT n00_dias_mes
					FROM acero_gm@idsgye01:rolt000
					WHERE n00_serial = n30_compania)) +
			((SELECT n00_dias_mes
				FROM acero_gm@idsgye01:rolt000
				WHERE n00_serial = n30_compania) -
			DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2014)
				THEN MDY(01, 01, 2014)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					CASE WHEN DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)) = 31
						THEN (SELECT n00_dias_mes
						FROM acero_gm@idsgye01:rolt000
							WHERE n00_serial =
								n30_compania)
						ELSE DAY(NVL(n30_fecha_reing,
								n30_fecha_ing))
					END,
					2014)
			    END) + 1)
		ELSE 0
	END + CASE WHEN DAY(CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2014)
			    END) = 31
			THEN (SELECT n00_dias_mes
				FROM acero_gm@idsgye01:rolt000
				WHERE n00_serial = n30_compania)
			ELSE DAY(CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2014)
				 END) -
				CASE WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2014)
						THEN MDY(01, 01, 2014)
						ELSE MDY(MONTH(NVL(
							n30_fecha_reing,
							n30_fecha_ing)),
							DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
							2014)
						END) = 
					MONTH(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2014)
						THEN n30_fecha_sal
						ELSE MDY(12, 31, 2014)
						END)
					THEN DAY(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2014)
						THEN MDY(01, 01, 2014)
						ELSE MDY(MONTH(NVL(
							n30_fecha_reing,
							n30_fecha_ing)),
							DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
							2014)
						END) - 1
					ELSE 0
				END
		END +
	CASE WHEN (MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2014)
			END) = 02 AND
			EXTEND(CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2014)
			END, MONTH TO DAY) =
			EXTEND(MDY(MONTH(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2014)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2014)
				  END), 01,
				YEAR(CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2014)
				     END)) + 1 UNITS MONTH - 1 UNITS DAY,
				MONTH TO DAY))
		THEN CASE WHEN MOD(2014, 4) = 0 THEN 1 ELSE 2 END
		ELSE 0
	END) AS dias_carg,
	ROUND(NVL((SELECT SUM(n46_saldo)
			FROM acero_gm@idsgye01:rolt045,
				acero_gm@idsgye01:rolt046
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
			FROM acero_gm@idsgye01:rolt010
			WHERE n10_compania   = n30_compania
			  AND n10_cod_liqrol = "UT"
			  AND n10_cod_trab   = n30_cod_trab), 0), 2) AS dscto,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM acero_gm@idsgye01:rolt030
	WHERE n30_compania                               = 1
	  AND n30_estado                                 = 'I'
	  AND YEAR(n30_fecha_sal)                       >= 2014
	  AND YEAR(n30_fecha_sal)                       <= YEAR(TODAY)
	  AND YEAR(NVL(n30_fecha_reing, n30_fecha_ing)) <= 2014
	  AND n30_tipo_contr                             = 'F'
	  AND n30_tipo_trab                              = 'N'
	  AND n30_fec_jub                               IS NULL
UNION
SELECT (SELECT g02_abreviacion
		FROM acero_qm@idsuio01:gent002
		WHERE g02_compania  = n30_compania
		  AND g02_localidad = 3) AS lc,
	"ACERO COMERCIAL" AS cia,
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
	((12 - MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2014)
			THEN MDY(01, 01, 2014)
			ELSE MDY(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)),
				DAY(NVL(n30_fecha_reing, n30_fecha_ing)),
				2014)
		    END)) * (SELECT n00_dias_mes
				FROM acero_qm@idsuio01:rolt000
				WHERE n00_serial = n30_compania)) +
	((SELECT n00_dias_mes
		FROM acero_qm@idsuio01:rolt000
		WHERE n00_serial = n30_compania) -
	DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) < MDY(01, 01, 2014)
		THEN MDY(01, 01, 2014)
		ELSE MDY(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)),
			CASE WHEN DAY(NVL(n30_fecha_reing, n30_fecha_ing)) = 31
				THEN (SELECT n00_dias_mes
					FROM acero_qm@idsuio01:rolt000
					WHERE n00_serial = n30_compania)
				ELSE DAY(NVL(n30_fecha_reing, n30_fecha_ing))
			END,
			2014)
	    END) + 1) AS dias,
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
	(((12 - MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2014)
			THEN MDY(01, 01, 2014)
			ELSE MDY(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)),
				DAY(NVL(n30_fecha_reing, n30_fecha_ing)),
				2014)
		    END)) * (SELECT n00_dias_mes
				FROM acero_qm@idsuio01:rolt000
				WHERE n00_serial = n30_compania)) +
	((SELECT n00_dias_mes
		FROM acero_qm@idsuio01:rolt000
		WHERE n00_serial = n30_compania) -
	DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) < MDY(01, 01, 2014)
		THEN MDY(01, 01, 2014)
		ELSE MDY(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)),
			CASE WHEN DAY(NVL(n30_fecha_reing, n30_fecha_ing)) = 31
				THEN (SELECT n00_dias_mes
					FROM acero_qm@idsuio01:rolt000
					WHERE n00_serial = n30_compania)
				ELSE DAY(NVL(n30_fecha_reing, n30_fecha_ing))
			END,
			2014)
	    END) + 1)) AS dias_carg,
	ROUND(NVL((SELECT SUM(n46_saldo)
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
	WHERE n30_compania             = 1
	  AND n30_estado               = 'A'
	  AND ((YEAR(n30_fecha_ing)   <= 2014
	  AND   n30_fecha_sal         IS NULL)
	   OR  (YEAR(n30_fecha_reing) <= 2014
	  AND   n30_fecha_sal         IS NOT NULL))
	  AND n30_tipo_contr           = 'F'
	  AND n30_tipo_trab            = 'N'
	  AND n30_fec_jub             IS NULL
UNION
SELECT (SELECT g02_abreviacion
		FROM acero_qm@idsuio01:gent002
		WHERE g02_compania  = n30_compania
		  AND g02_localidad = 3) AS lc,
	"ACERO COMERCIAL" AS cia,
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
	CASE WHEN (MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2014)
			 END) - CASE WHEN MONTH(n30_fecha_sal) =
				MONTH(NVL(n30_fecha_reing, n30_fecha_ing))
					THEN 0 ELSE 1 END) >=
			MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2014)
					THEN MDY(01, 01, 2014)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						2014)
				END)
		THEN (((MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2014)
				END) - 1) -
			MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2014)
					THEN MDY(01, 01, 2014)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
								n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
								n30_fecha_ing)),
						2014)
				END)) * (SELECT n00_dias_mes
					FROM acero_qm@idsuio01:rolt000
					WHERE n00_serial = n30_compania)) +
			((SELECT n00_dias_mes
				FROM acero_qm@idsuio01:rolt000
				WHERE n00_serial = n30_compania) -
			DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2014)
				THEN MDY(01, 01, 2014)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					CASE WHEN DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)) = 31
						THEN (SELECT n00_dias_mes
						FROM acero_qm@idsuio01:rolt000
							WHERE n00_serial =
								n30_compania)
						ELSE DAY(NVL(n30_fecha_reing,
								n30_fecha_ing))
					END,
					2014)
			    END) + 1)
		ELSE 0
	END + CASE WHEN DAY(CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2014)
			    END) = 31
			THEN (SELECT n00_dias_mes
				FROM acero_qm@idsuio01:rolt000
				WHERE n00_serial = n30_compania)
			ELSE DAY(CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2014)
				 END) -
				CASE WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2014)
						THEN MDY(01, 01, 2014)
						ELSE MDY(MONTH(NVL(
							n30_fecha_reing,
							n30_fecha_ing)),
							DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
							2014)
						END) = 
					MONTH(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2014)
						THEN n30_fecha_sal
						ELSE MDY(12, 31, 2014)
						END)
					THEN DAY(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2014)
						THEN MDY(01, 01, 2014)
						ELSE MDY(MONTH(NVL(
							n30_fecha_reing,
							n30_fecha_ing)),
							DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
							2014)
						END) - 1
					ELSE 0
				END
		END +
	CASE WHEN (MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2014)
			END) = 02 AND
			EXTEND(CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2014)
			END, MONTH TO DAY) =
			EXTEND(MDY(MONTH(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2014)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2014)
				  END), 01,
				YEAR(CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2014)
				     END)) + 1 UNITS MONTH - 1 UNITS DAY,
				MONTH TO DAY))
		THEN CASE WHEN MOD(2014, 4) = 0 THEN 1 ELSE 2 END
		ELSE 0
	END AS dias,
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
	(CASE WHEN (MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2014)
			 END) - CASE WHEN MONTH(n30_fecha_sal) =
				MONTH(NVL(n30_fecha_reing, n30_fecha_ing))
					THEN 0 ELSE 1 END) >=
			MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2014)
					THEN MDY(01, 01, 2014)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						2014)
				END)
		THEN (((MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2014)
				END) - 1) -
			MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2014)
					THEN MDY(01, 01, 2014)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
								n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
								n30_fecha_ing)),
						2014)
				END)) * (SELECT n00_dias_mes
					FROM acero_qm@idsuio01:rolt000
					WHERE n00_serial = n30_compania)) +
			((SELECT n00_dias_mes
				FROM acero_qm@idsuio01:rolt000
				WHERE n00_serial = n30_compania) -
			DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2014)
				THEN MDY(01, 01, 2014)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					CASE WHEN DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)) = 31
						THEN (SELECT n00_dias_mes
						FROM acero_qm@idsuio01:rolt000
							WHERE n00_serial =
								n30_compania)
						ELSE DAY(NVL(n30_fecha_reing,
								n30_fecha_ing))
					END,
					2014)
			    END) + 1)
		ELSE 0
	END + CASE WHEN DAY(CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2014)
			    END) = 31
			THEN (SELECT n00_dias_mes
				FROM acero_qm@idsuio01:rolt000
				WHERE n00_serial = n30_compania)
			ELSE DAY(CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2014)
				 END) -
				CASE WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2014)
						THEN MDY(01, 01, 2014)
						ELSE MDY(MONTH(NVL(
							n30_fecha_reing,
							n30_fecha_ing)),
							DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
							2014)
						END) = 
					MONTH(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2014)
						THEN n30_fecha_sal
						ELSE MDY(12, 31, 2014)
						END)
					THEN DAY(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2014)
						THEN MDY(01, 01, 2014)
						ELSE MDY(MONTH(NVL(
							n30_fecha_reing,
							n30_fecha_ing)),
							DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
							2014)
						END) - 1
					ELSE 0
				END
		END +
	CASE WHEN (MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2014)
			END) = 02 AND
			EXTEND(CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2014)
			END, MONTH TO DAY) =
			EXTEND(MDY(MONTH(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2014)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2014)
				  END), 01,
				YEAR(CASE WHEN n30_fecha_sal < MDY(12, 31, 2014)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2014)
				     END)) + 1 UNITS MONTH - 1 UNITS DAY,
				MONTH TO DAY))
		THEN CASE WHEN MOD(2014, 4) = 0 THEN 1 ELSE 2 END
		ELSE 0
	END) AS dias_carg,
	ROUND(NVL((SELECT SUM(n46_saldo)
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
	WHERE n30_compania                               = 1
	  AND n30_estado                                 = 'I'
	  AND YEAR(n30_fecha_sal)                       >= 2014
	  AND YEAR(n30_fecha_sal)                       <= YEAR(TODAY)
	  AND YEAR(NVL(n30_fecha_reing, n30_fecha_ing)) <= 2014
	  AND n30_tipo_contr                             = 'F'
	  AND n30_tipo_trab                              = 'N'
	  AND n30_fec_jub                               IS NULL
	ORDER BY 1, n30_nombres;
