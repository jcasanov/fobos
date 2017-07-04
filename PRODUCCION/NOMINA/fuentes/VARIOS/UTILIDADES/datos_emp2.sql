SELECT n30_cod_trab AS codigo,
	n30_nombres AS empleados_gye,
	NVL((CASE WHEN (n30_est_civil = 'C' OR n30_est_civil = 'U')
			THEN (SELECT COUNT(n31_secuencia)
				FROM rolt031
				WHERE n31_compania           = n30_compania
				  AND n31_cod_trab           = n30_cod_trab
				  AND n31_tipo_carga        <> 'H'
				  AND YEAR(n31_fecha_nacim) <= 2011)
			ELSE 0
		END +
		(SELECT COUNT(n31_secuencia)
			FROM rolt031
			WHERE n31_compania     = n30_compania 
			  AND n31_cod_trab     = n30_cod_trab
			  AND n31_tipo_carga   = 'H'
			  AND n31_fecha_nacim >= MDY(12, 31, 2011)
						- 19 UNITS YEAR + 1 UNITS DAY
			  AND n31_fecha_nacim <= MDY(12, 31, 2011))), 0)
	AS cargas,
	n30_fecha_ing AS fec_ing,
	n30_fecha_reing AS fec_reing,
	n30_fecha_sal AS fec_sal,
	CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) < MDY(01, 01, 2011)
		THEN MDY(01, 01, 2011)
		ELSE MDY(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)),
			DAY(NVL(n30_fecha_reing, n30_fecha_ing)),
			2011)
	END AS fec_ini,
	MDY(12, 31, 2011) AS fec_fin,
	((12 - MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2011)
			THEN MDY(01, 01, 2011)
			ELSE MDY(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)),
				DAY(NVL(n30_fecha_reing, n30_fecha_ing)),
				2011)
		    END)) * (SELECT n00_dias_mes
				FROM rolt000
				WHERE n00_serial = n30_compania)) +
	((SELECT n00_dias_mes
		FROM rolt000
		WHERE n00_serial = n30_compania) -
	DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) < MDY(01, 01, 2011)
		THEN MDY(01, 01, 2011)
		ELSE MDY(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)),
			CASE WHEN DAY(NVL(n30_fecha_reing, n30_fecha_ing)) = 31
				THEN (SELECT n00_dias_mes
					FROM rolt000
					WHERE n00_serial = n30_compania)
				ELSE DAY(NVL(n30_fecha_reing, n30_fecha_ing))
			END,
			2011)
	    END) + 1) AS dias_trab,
	NVL((CASE WHEN (n30_est_civil = 'C' OR n30_est_civil = 'U')
			THEN (SELECT COUNT(n31_secuencia)
				FROM rolt031
				WHERE n31_compania           = n30_compania
				  AND n31_cod_trab           = n30_cod_trab
				  AND n31_tipo_carga        <> 'H'
				  AND YEAR(n31_fecha_nacim) <= 2011)
			ELSE 0
		END +
		(SELECT COUNT(n31_secuencia)
			FROM rolt031
			WHERE n31_compania     = n30_compania 
			  AND n31_cod_trab     = n30_cod_trab
			  AND n31_tipo_carga   = 'H'
			  AND n31_fecha_nacim >= MDY(12, 31, 2011)
						- 19 UNITS YEAR + 1 UNITS DAY
			  AND n31_fecha_nacim <= MDY(12, 31, 2011))), 0) *
	(((12 - MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2011)
			THEN MDY(01, 01, 2011)
			ELSE MDY(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)),
				DAY(NVL(n30_fecha_reing, n30_fecha_ing)),
				2011)
		    END)) * (SELECT n00_dias_mes
				FROM rolt000
				WHERE n00_serial = n30_compania)) +
	((SELECT n00_dias_mes
		FROM rolt000
		WHERE n00_serial = n30_compania) -
	DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) < MDY(01, 01, 2011)
		THEN MDY(01, 01, 2011)
		ELSE MDY(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)),
			CASE WHEN DAY(NVL(n30_fecha_reing, n30_fecha_ing)) = 31
				THEN (SELECT n00_dias_mes
					FROM rolt000
					WHERE n00_serial = n30_compania)
				ELSE DAY(NVL(n30_fecha_reing, n30_fecha_ing))
			END,
			2011)
	    END) + 1)) AS dias_carg,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM rolt030
	WHERE n30_compania             = 1
	  AND n30_estado               = 'A'
	  AND ((YEAR(n30_fecha_ing)   <= 2011
	  AND   n30_fecha_sal         IS NULL)
	   OR  (YEAR(n30_fecha_reing) <= 2011
	  AND   n30_fecha_sal         IS NOT NULL))
	  AND n30_tipo_contr           = 'F'
	  AND n30_tipo_trab            = 'N'
	  AND n30_fec_jub             IS NULL
UNION
SELECT n30_cod_trab AS codigo,
	n30_nombres AS empleados_gye,
	NVL((CASE WHEN (n30_est_civil = 'C' OR n30_est_civil = 'U')
			THEN (SELECT COUNT(n31_secuencia)
				FROM rolt031
				WHERE n31_compania           = n30_compania
				  AND n31_cod_trab           = n30_cod_trab
				  AND n31_tipo_carga        <> 'H'
				  AND YEAR(n31_fecha_nacim) <= 2011)
			ELSE 0
		 END +
		(SELECT COUNT(n31_secuencia)
			FROM rolt031
			WHERE n31_compania     = n30_compania 
			  AND n31_cod_trab     = n30_cod_trab
			  AND n31_tipo_carga   = 'H'
			  AND n31_fecha_nacim >= MDY(12, 31, 2011)
						- 19 UNITS YEAR + 1 UNITS DAY
			  AND n31_fecha_nacim <= MDY(12, 31, 2011))), 0)
	AS cargas,
	n30_fecha_ing AS fec_ing,
	n30_fecha_reing AS fec_reing,
	n30_fecha_sal AS fec_sal,
	CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) < MDY(01, 01, 2011)
		THEN MDY(01, 01, 2011)
		ELSE MDY(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)),
			DAY(NVL(n30_fecha_reing, n30_fecha_ing)),
			2011)
	END AS fec_ini,
	CASE WHEN n30_fecha_sal < MDY(12, 31, 2011)
		THEN n30_fecha_sal
		ELSE MDY(12, 31, 2011)
	END AS fec_fin,
	CASE WHEN (MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2011)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2011)
			 END) - 1) >=
			MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2011)
					THEN MDY(01, 01, 2011)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						2011)
				END)
		THEN (((MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2011)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2011)
				END) - 1) -
			MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2011)
					THEN MDY(01, 01, 2011)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
								n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
								n30_fecha_ing)),
						2011)
				END)) * (SELECT n00_dias_mes
					FROM rolt000
					WHERE n00_serial = n30_compania)) +
			((SELECT n00_dias_mes
				FROM rolt000
				WHERE n00_serial = n30_compania) -
			DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					CASE WHEN DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)) = 31
						THEN (SELECT n00_dias_mes
							FROM rolt000
							WHERE n00_serial =
								n30_compania)
						ELSE DAY(NVL(n30_fecha_reing,
								n30_fecha_ing))
					END,
					2011)
			    END) + 1)
		ELSE 0
	END + CASE WHEN DAY(CASE WHEN n30_fecha_sal < MDY(12, 31, 2011)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2011)
			    END) = 31
			THEN (SELECT n00_dias_mes
				FROM rolt000
				WHERE n00_serial = n30_compania)
			ELSE DAY(CASE WHEN n30_fecha_sal < MDY(12, 31, 2011)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2011)
				 END) -
				CASE WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2011)
						THEN MDY(01, 01, 2011)
						ELSE MDY(MONTH(NVL(
							n30_fecha_reing,
							n30_fecha_ing)),
							DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
							2011)
						END) = 
					MONTH(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2011)
						THEN n30_fecha_sal
						ELSE MDY(12, 31, 2011)
						END)
					THEN DAY(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2011)
						THEN MDY(01, 01, 2011)
						ELSE MDY(MONTH(NVL(
							n30_fecha_reing,
							n30_fecha_ing)),
							DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
							2011)
						END) - 1
					ELSE 0
				END
		END +
	CASE WHEN (MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2011)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2011)
			END) = 02 AND
			EXTEND(CASE WHEN n30_fecha_sal < MDY(12, 31, 2011)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2011)
			END, MONTH TO DAY) =
			EXTEND(MDY(MONTH(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2011)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2011)
				  END), 01,
				YEAR(CASE WHEN n30_fecha_sal < MDY(12, 31, 2011)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2011)
				     END)) + 1 UNITS MONTH - 1 UNITS DAY,
				MONTH TO DAY))
		THEN CASE WHEN MOD(2011, 4) = 0 THEN 1 ELSE 2 END
		ELSE 0
	END AS dias_trab,
	NVL((CASE WHEN (n30_est_civil = 'C' OR n30_est_civil = 'U')
			THEN (SELECT COUNT(n31_secuencia)
				FROM rolt031
				WHERE n31_compania           = n30_compania
				  AND n31_cod_trab           = n30_cod_trab
				  AND n31_tipo_carga        <> 'H'
				  AND YEAR(n31_fecha_nacim) <= 2011)
			ELSE 0
		 END +
		(SELECT COUNT(n31_secuencia)
			FROM rolt031
			WHERE n31_compania     = n30_compania 
			  AND n31_cod_trab     = n30_cod_trab
			  AND n31_tipo_carga   = 'H'
			  AND n31_fecha_nacim >= MDY(12, 31, 2011)
						- 19 UNITS YEAR + 1 UNITS DAY
			  AND n31_fecha_nacim <= MDY(12, 31, 2011))), 0) *
	(CASE WHEN (MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2011)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2011)
			 END) - 1) >=
			MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2011)
					THEN MDY(01, 01, 2011)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						2011)
				END)
		THEN (((MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2011)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2011)
				END) - 1) -
			MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2011)
					THEN MDY(01, 01, 2011)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
								n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
								n30_fecha_ing)),
						2011)
				END)) * (SELECT n00_dias_mes
					FROM rolt000
					WHERE n00_serial = n30_compania)) +
			((SELECT n00_dias_mes
				FROM rolt000
				WHERE n00_serial = n30_compania) -
			DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					CASE WHEN DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)) = 31
						THEN (SELECT n00_dias_mes
							FROM rolt000
							WHERE n00_serial =
								n30_compania)
						ELSE DAY(NVL(n30_fecha_reing,
								n30_fecha_ing))
					END,
					2011)
			    END) + 1)
		ELSE 0
	END + CASE WHEN DAY(CASE WHEN n30_fecha_sal < MDY(12, 31, 2011)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2011)
			    END) = 31
			THEN (SELECT n00_dias_mes
				FROM rolt000
				WHERE n00_serial = n30_compania)
			ELSE DAY(CASE WHEN n30_fecha_sal < MDY(12, 31, 2011)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2011)
				 END) -
				CASE WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2011)
						THEN MDY(01, 01, 2011)
						ELSE MDY(MONTH(NVL(
							n30_fecha_reing,
							n30_fecha_ing)),
							DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
							2011)
						END) = 
					MONTH(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2011)
						THEN n30_fecha_sal
						ELSE MDY(12, 31, 2011)
						END)
					THEN DAY(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2011)
						THEN MDY(01, 01, 2011)
						ELSE MDY(MONTH(NVL(
							n30_fecha_reing,
							n30_fecha_ing)),
							DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
							2011)
						END) - 1
					ELSE 0
				END
		END +
	CASE WHEN (MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2011)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2011)
			END) = 02 AND
			EXTEND(CASE WHEN n30_fecha_sal < MDY(12, 31, 2011)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2011)
			END, MONTH TO DAY) =
			EXTEND(MDY(MONTH(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2011)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2011)
				  END), 01,
				YEAR(CASE WHEN n30_fecha_sal < MDY(12, 31, 2011)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2011)
				     END)) + 1 UNITS MONTH - 1 UNITS DAY,
				MONTH TO DAY))
		THEN CASE WHEN MOD(2011, 4) = 0 THEN 1 ELSE 2 END
		ELSE 0
	END) AS dias_carg,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM rolt030
	WHERE n30_compania         = 1
	  AND n30_estado           = 'I'
	  AND YEAR(n30_fecha_sal) >= 2011
	  AND YEAR(n30_fecha_sal) <= YEAR(TODAY)
	  AND n30_tipo_contr       = 'F'
	  AND n30_tipo_trab        = 'N'
	  AND n30_fec_jub         IS NULL
	ORDER BY n30_nombres;
