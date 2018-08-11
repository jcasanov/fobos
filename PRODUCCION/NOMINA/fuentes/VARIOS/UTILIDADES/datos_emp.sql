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
		  AND n31_fecha_nacim <= MDY(12, 31, 2011))), 0) AS cargas,
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
	(((MDY(12, 30, 2011) - 
		CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
			THEN MDY(01, 01, 2011)
			ELSE MDY(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)),
				DAY(NVL(n30_fecha_reing, n30_fecha_ing)),
				2011)
		END) + 1) -
	(CASE WHEN (MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			  END) IN (01, 05) AND
			DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			    END) >= 5) OR
			MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			  END) = 04
		THEN 4
	      WHEN (MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			  END) = 02 AND
			DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			    END) >= CASE WHEN MOD(2011,4) = 0 THEN 2 ELSE 3 END)
		THEN CASE WHEN MOD(2011, 4) = 0 THEN 4 ELSE 3 END
	      WHEN (MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			  END) = 03 AND
			DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			    END) >= 6)
		THEN 5
	      WHEN (MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			  END) IN (06, 07) AND
			DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			    END) >= 4)
		THEN 3
	      WHEN (MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			  END) = 08 AND
			DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			    END) >= 3)
		THEN 2
	      WHEN (MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			  END) IN (09, 10) AND
			DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			    END) > 1)
		THEN 1
		ELSE 0
	 END) -
	(CASE WHEN (MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			  END) IN (01, 05) AND
			DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			    END) < 5)
		THEN 5 - DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			     END)
	      WHEN (MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			  END) = 02 AND
			DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			    END) < CASE WHEN MOD(2011, 4) = 0 THEN 2 ELSE 3 END)
		THEN CASE WHEN MOD(2011, 4) = 0 THEN 3 ELSE 4 END -
			DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			    END)
	      WHEN (MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			  END) = 03 AND
			DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			    END) < 6)
		THEN 6 - DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			     END)
	      WHEN (MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			  END) IN (06, 07) AND
			DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			    END) < 4)
		THEN 4 - DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			     END)
	      WHEN (MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			  END) = 08 AND
			DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			    END) < 3)
		THEN 3 - DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			     END)
	      WHEN EXTEND(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					2011)
			  END, MONTH TO DAY) IN ('09-01', '10-01')
		THEN 1
		ELSE 0
	 END)) AS dias,
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
		  AND n31_fecha_nacim <= MDY(12, 31, 2011))), 0) AS cargas,
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
	(((CASE WHEN n30_fecha_sal < MDY(12, 31, 2011)
		THEN CASE WHEN DAY(n30_fecha_sal) = 31
			THEN DATE(n30_fecha_sal - 1 UNITS DAY)
			ELSE n30_fecha_sal
		     END
		ELSE MDY(12, 30, 2011)
	   END - CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
						MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,n30_fecha_ing)),
					2011)
		 END) + 1) +
	(CASE WHEN (EXTEND(n30_fecha_sal, MONTH TO DAY) = '02-28' AND
		MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,n30_fecha_ing)),
					2011)
			END) < 03)
		THEN 1
	      WHEN MONTH(n30_fecha_sal) = 02
		THEN -1
		ELSE 0
	 END) -
	(CASE WHEN ((CASE WHEN n30_fecha_sal < MDY(12, 31, 2011)
				THEN CASE WHEN DAY(n30_fecha_sal) = 31
					THEN DATE(n30_fecha_sal - 1 UNITS DAY)
					ELSE n30_fecha_sal
				     END
				ELSE MDY(12, 30, 2011)
			END - CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
						MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,n30_fecha_ing)),
					2011)
			      END) + 1) > (SELECT n00_dias_mes
						FROM rolt000
						WHERE n00_serial = n30_compania)
			AND
			MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2011)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2011)
			      END) -
			MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2011)
				THEN MDY(01, 01, 2011)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					DAY(NVL(n30_fecha_reing,n30_fecha_ing)),
					2011)
			      END) > 1
		THEN CASE WHEN MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2011)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2011)
				     END) - 1 IN (11, 10)
				THEN 5
			  WHEN MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2011)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2011)
				     END) - 1 IN (09, 08)
				THEN 4
			  WHEN MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2011)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2011)
				     END) - 1 = 07
				THEN 3
			  WHEN MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2011)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2011)
				     END) - 1 IN (06, 05)
				THEN 2
			  WHEN MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2011)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2011)
				     END) - 1 IN (04, 03)
				THEN 1
			ELSE 0
		     END -
		     CASE WHEN (MONTH(CASE WHEN NVL(n30_fecha_reing,
					n30_fecha_ing) < MDY(01, 01, 2011)
					THEN MDY(01, 01, 2011)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
						n30_fecha_ing)),
						2011)
				     END) = 01 AND
				DAY(CASE WHEN NVL(n30_fecha_reing,
					n30_fecha_ing) < MDY(01, 01, 2011)
					THEN MDY(01, 01, 2011)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
						n30_fecha_ing)),
						2011)
				     END) < 5 AND
				MONTH(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2011)
						THEN n30_fecha_sal
						ELSE MDY(12, 31, 2011)
				      END) > 03)
				THEN 5 - DAY(CASE WHEN NVL(n30_fecha_reing,
						n30_fecha_ing) <
						MDY(01, 01, 2011)
							THEN MDY(01, 01, 2011)
							ELSE MDY(MONTH(NVL(
								n30_fecha_reing,
								n30_fecha_ing)),
							DAY(NVL(n30_fecha_reing,
								n30_fecha_ing)),
							2011)
					     END)
			  WHEN (MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2011)
					THEN MDY(01, 01, 2011)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						2011)
				      END) = 02 AND
				DAY(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2011)
					THEN MDY(01, 01, 2011)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						2011)
				    END) < CASE WHEN MOD(2011, 4) = 0
							THEN 2 ELSE 3 END AND
				MONTH(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2011)
						THEN n30_fecha_sal
						ELSE MDY(12, 31, 2011)
				      END) > 03)
				THEN CASE WHEN MOD(2011, 4) = 0
						THEN 3 ELSE 4 END -
					DAY(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2011)
						THEN MDY(01, 01, 2011)
						ELSE MDY(MONTH(NVL(
								n30_fecha_reing,
								n30_fecha_ing)),
							DAY(NVL(n30_fecha_reing,
								n30_fecha_ing)),
							2011)
					    END)
			  WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2011)
					THEN MDY(01, 01, 2011)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						2011)
				      END) = 03
				THEN 5
			  WHEN (MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2011)
					THEN MDY(01, 01, 2011)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						2011)
				      END) IN (04, 05) AND
				EXTEND(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2011)
						THEN n30_fecha_sal
						ELSE MDY(12, 31, 2011)
					END, MONTH TO DAY) =
				MDY(MONTH(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2011)
						THEN n30_fecha_sal
						ELSE MDY(12, 31, 2011)
					  END), 01,
					YEAR(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2011)
						THEN n30_fecha_sal
						ELSE MDY(12, 31, 2011)
					     END))
					+ 1 UNITS MONTH - 1 UNITS DAY)
				THEN 4
			  WHEN (MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2011)
					THEN MDY(01, 01, 2011)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						2011)
				      END) IN (06, 07) AND
				EXTEND(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2011)
						THEN n30_fecha_sal
						ELSE MDY(12, 31, 2011)
					END, MONTH TO DAY) =
				MDY(MONTH(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2011)
						THEN n30_fecha_sal
						ELSE MDY(12, 31, 2011)
					  END), 01,
					YEAR(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2011)
						THEN n30_fecha_sal
						ELSE MDY(12, 31, 2011)
					     END))
					+ 1 UNITS MONTH - 1 UNITS DAY)
				THEN 3
			  WHEN (MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2011)
					THEN MDY(01, 01, 2011)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						2011)
				      END) = 08 AND
				EXTEND(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2011)
						THEN n30_fecha_sal
						ELSE MDY(12, 31, 2011)
					END, MONTH TO DAY) =
				MDY(MONTH(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2011)
						THEN n30_fecha_sal
						ELSE MDY(12, 31, 2011)
					  END), 01,
					YEAR(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2011)
						THEN n30_fecha_sal
						ELSE MDY(12, 31, 2011)
					     END))
					+ 1 UNITS MONTH - 1 UNITS DAY)
				THEN 2
			  WHEN (MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2011)
					THEN MDY(01, 01, 2011)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						2011)
				      END) IN (09, 10) AND
				EXTEND(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2011)
						THEN n30_fecha_sal
						ELSE MDY(12, 31, 2011)
					END, MONTH TO DAY) =
				MDY(MONTH(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2011)
						THEN n30_fecha_sal
						ELSE MDY(12, 31, 2011)
					  END), 01,
					YEAR(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2011)
						THEN n30_fecha_sal
						ELSE MDY(12, 31, 2011)
					     END))
					+ 1 UNITS MONTH - 1 UNITS DAY)
				THEN 1
			ELSE CASE WHEN MONTH(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2011)
							THEN n30_fecha_sal
							ELSE MDY(12, 31, 2011)
						END) = 03
					THEN 1
					ELSE 0
			     END
		     END
		ELSE 0
	 END)) AS dias,
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
