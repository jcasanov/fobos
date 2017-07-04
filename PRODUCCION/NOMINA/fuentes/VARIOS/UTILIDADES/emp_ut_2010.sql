SELECT 1 AS lc, n30_cod_trab AS cod_trab, n30_num_doc_id AS cedula,
	n30_nombres AS empleados,
	NVL((CASE WHEN (n30_est_civil = 'C' OR n30_est_civil = 'U')
		THEN (SELECT COUNT(n31_secuencia)
			FROM acero_gm@idsgye01:rolt031
			WHERE n31_compania           = n30_compania
			  AND n31_cod_trab           = n30_cod_trab
			  AND n31_tipo_carga        <> 'H'
			  AND YEAR(n31_fecha_nacim) <= 2010)
		ELSE 0
	 END +
	(SELECT COUNT(n31_secuencia)
		FROM acero_gm@idsgye01:rolt031
		WHERE n31_compania     = n30_compania 
		  AND n31_cod_trab     = n30_cod_trab
		  AND n31_tipo_carga   = 'H'
		  AND n31_fecha_nacim >= MDY(12, 31, 2010)
					- 19 UNITS YEAR + 1 UNITS DAY
		  AND n31_fecha_nacim <= MDY(12, 31, 2010))), 0) AS carga,
	CASE WHEN (YEAR(NVL(n30_fecha_reing, n30_fecha_ing)) < 2010) OR
			(NVL(n30_fecha_reing,n30_fecha_ing) < MDY(01, 01, 2010))
		THEN (SELECT n90_dias_ano_ut
			FROM acero_gm@idsgye01:rolt090
			WHERE n90_compania = n30_compania)
		ELSE ((MDY(12, 31, 2010) -
			CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2010)
				THEN MDY(01, 01, 2010)
				ELSE NVL(n30_fecha_reing, n30_fecha_ing)
			END) + 1) -
			CASE WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 01
				THEN CASE WHEN MOD(2010, 4) = 0
						THEN 6
						ELSE 5
					END
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 02
				THEN CASE WHEN MOD(2010, 4) = 0
						THEN 5
						ELSE 4
					END
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 03
				THEN 6
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 04
				THEN 5
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 05
				THEN 5
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 06
				THEN 4
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 07
				THEN 4
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 08
				THEN 3
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 09
				THEN 2
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 10
				THEN 2
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 11
				THEN 1
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 12
				THEN 1
				ELSE 0
			END
	END dias,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM acero_gm@idsgye01:rolt030
	WHERE n30_compania             = 1
	  AND n30_estado               = 'A'
	  AND ((YEAR(n30_fecha_ing)   <= 2010
	  AND   n30_fecha_sal         IS NULL)
	   OR  (YEAR(n30_fecha_reing) <= 2010
	  AND   n30_fecha_sal         IS NOT NULL))
	  AND n30_tipo_contr           = 'F'
	  AND n30_tipo_trab            = 'N'
	  AND n30_fec_jub             IS NULL
UNION
SELECT 1 AS lc, n30_cod_trab AS cod_trab, n30_num_doc_id AS cedula,
	n30_nombres AS empleados,
	NVL((CASE WHEN (n30_est_civil = 'C' OR n30_est_civil = 'U')
		THEN (SELECT COUNT(n31_secuencia)
			FROM acero_gm@idsgye01:rolt031
			WHERE n31_compania           = n30_compania
			  AND n31_cod_trab           = n30_cod_trab
			  AND n31_tipo_carga        <> 'H'
			  AND YEAR(n31_fecha_nacim) <= 2010)
		ELSE 0
	 END +
	(SELECT COUNT(n31_secuencia)
		FROM acero_gm@idsgye01:rolt031
		WHERE n31_compania     = n30_compania 
		  AND n31_cod_trab     = n30_cod_trab
		  AND n31_tipo_carga   = 'H'
		  AND n31_fecha_nacim >= MDY(12, 31, 2010)
					- 19 UNITS YEAR + 1 UNITS DAY
		  AND n31_fecha_nacim <= MDY(12, 31, 2010))), 0) AS carga,
	CASE WHEN ((CASE WHEN n30_fecha_sal > MDY(12, 31, 2010)
				THEN MDY(12, 31, 2010)
				ELSE n30_fecha_sal
			END -
			CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01,01,2010)
				THEN MDY(01, 01, 2010)
				ELSE NVL(n30_fecha_reing, n30_fecha_ing)
			END) + 1) >
			(SELECT n90_dias_ano_ut
				FROM acero_gm@idsgye01:rolt090
				WHERE n90_compania = n30_compania)
		THEN (SELECT n90_dias_ano_ut
			FROM acero_gm@idsgye01:rolt090
			WHERE n90_compania = n30_compania)
		ELSE ((CASE WHEN n30_fecha_sal > MDY(12, 31, 2010)
				THEN MDY(12, 31, 2010)
				ELSE n30_fecha_sal
			END -
			CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2010)
				THEN MDY(01, 01, 2010)
				ELSE NVL(n30_fecha_reing, n30_fecha_ing)
			END) + 1) -
			(CASE WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 01
				THEN CASE WHEN MOD(2010, 4) = 0
						THEN 6
						ELSE 5
					END
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 02
				THEN CASE WHEN MOD(2010, 4) = 0
						THEN 5
						ELSE 4
					END
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 03
				THEN 6
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 04
				THEN 5
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 05
				THEN 5
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 06
				THEN 4
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 07
				THEN 4
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 08
				THEN 3
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 09
				THEN 2
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 10
				THEN 2
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 11
				THEN 1
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 12
				THEN 1
				ELSE 0
			END -
			CASE WHEN MONTH(CASE WHEN n30_fecha_sal >
						MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END) = 01
				THEN CASE WHEN MOD(2010, 4) = 0
						THEN 6
						ELSE 5
					END
			     WHEN MONTH(CASE WHEN n30_fecha_sal >
						MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END) = 02
				THEN CASE WHEN MOD(2010, 4) = 0
						THEN 5
						ELSE 4
					END
			     WHEN MONTH(CASE WHEN n30_fecha_sal >
						MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END) = 03
				THEN 6
			     WHEN MONTH(CASE WHEN n30_fecha_sal >
						MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END) = 04
				THEN 5
			     WHEN MONTH(CASE WHEN n30_fecha_sal >
						MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END) = 05
				THEN 5
			     WHEN MONTH(CASE WHEN n30_fecha_sal >
						MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END) = 06
				THEN 4
			     WHEN MONTH(CASE WHEN n30_fecha_sal >
						MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END) = 07
				THEN 4
			     WHEN MONTH(CASE WHEN n30_fecha_sal >
						MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END) = 08
				THEN 3
			     WHEN MONTH(CASE WHEN n30_fecha_sal >
						MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END) = 09
				THEN 2
			     WHEN MONTH(CASE WHEN n30_fecha_sal >
						MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END) = 10
				THEN 2
			     WHEN MONTH(CASE WHEN n30_fecha_sal >
						MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END) = 11
				THEN 1
			     WHEN MONTH(CASE WHEN n30_fecha_sal >
						MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END) = 12
				THEN 1
				ELSE 0
			END) +
			CASE WHEN (MONTH(CASE WHEN n30_fecha_sal >
							MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END) -
					MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END)) = 1
				THEN 1
			     WHEN (MONTH(CASE WHEN n30_fecha_sal >
							MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END) -
					MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END)) = 0
				THEN CASE WHEN DAY(CASE WHEN n30_fecha_sal >
								MDY(12,31,2010)
							THEN MDY(12, 31, 2010)
							ELSE n30_fecha_sal
						END) = 31
						THEN -1
						ELSE 0
					END
				ELSE 0
			END +
			CASE WHEN EXTEND(CASE WHEN n30_fecha_sal >
								MDY(12,31,2010)
							THEN MDY(12, 31, 2010)
							ELSE n30_fecha_sal
						END, MONTH TO DAY) = '02-28'
				THEN CASE WHEN DAY(CASE WHEN
							NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
						END) = 1
						THEN 1
						ELSE 2
					END
				ELSE 0
			END +
			CASE WHEN EXTEND(CASE WHEN n30_fecha_sal >
								MDY(12,31,2010)
							THEN MDY(12, 31, 2010)
							ELSE n30_fecha_sal
						END, MONTH TO DAY) = '02-29'
				THEN CASE WHEN DAY(CASE WHEN
							NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
						END) = 1
						THEN 0
						ELSE 1
					END
				ELSE 0
			END -
			CASE WHEN (CASE WHEN n30_fecha_sal > MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END =
					MDY(MONTH(CASE WHEN n30_fecha_sal >
							MDY(12, 31, 2010)
							THEN MDY(12, 31, 2010)
							ELSE n30_fecha_sal
						END), 01,
						YEAR(CASE WHEN n30_fecha_sal >
							MDY(12, 31, 2010)
							THEN MDY(12, 31, 2010)
							ELSE n30_fecha_sal
						END)) + 1 UNITS MONTH
						- 1 UNITS DAY) AND
					(EXTEND(CASE WHEN n30_fecha_sal >
							MDY(12, 31, 2010)
							THEN MDY(12, 31, 2010)
							ELSE n30_fecha_sal
						END, MONTH TO DAY) <> '02-28')
					AND
			     		(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END <> MDY(01, 01, 2010))
				THEN 1
		     WHEN (((CASE WHEN n30_fecha_sal > MDY(12, 31, 2010)
					THEN MDY(12, 31, 2010)
					ELSE n30_fecha_sal
				END -
				CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
						MDY(01, 01, 2010)
					THEN MDY(01, 01, 2010)
					ELSE NVL(n30_fecha_reing, n30_fecha_ing)
				END) + 1) >
				(SELECT n00_dias_mes
					FROM acero_gm@idsgye01:rolt000
					WHERE n00_serial = n30_compania)) AND
			(((CASE WHEN n30_fecha_sal > MDY(12, 31, 2010)
					THEN MDY(12, 31, 2010)
					ELSE n30_fecha_sal
				END -
				CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
						MDY(01, 01, 2010)
					THEN MDY(01, 01, 2010)
					ELSE NVL(n30_fecha_reing, n30_fecha_ing)
				END) + 1) <
				(SELECT n00_dias_mes * 2
					FROM acero_gm@idsgye01:rolt000
					WHERE n00_serial = n30_compania)) AND
			     	(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END = MDY(01, 01, 2010) OR
				 CASE WHEN n30_fecha_sal > MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END = MDY(12, 31, 2010)) AND
				(EXTEND(CASE WHEN n30_fecha_sal >
							MDY(12, 31, 2010)
							THEN MDY(12, 31, 2010)
							ELSE n30_fecha_sal
						END, MONTH TO DAY) <> '02-28')
				THEN 1
				ELSE 0
			END
	END dias,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM acero_gm@idsgye01:rolt030
	WHERE n30_compania         = 1
	  AND n30_estado           = 'I'
	  AND YEAR(n30_fecha_sal) >= 2010
	  AND YEAR(n30_fecha_sal) <= YEAR(TODAY)
	  AND n30_tipo_contr       = 'F'
	  AND n30_tipo_trab        = 'N'
	  AND n30_fec_jub         IS NULL
UNION
SELECT 3 AS lc, n30_cod_trab AS cod_trab, n30_num_doc_id AS cedula,
	n30_nombres AS empleados,
	NVL((CASE WHEN (n30_est_civil = 'C' OR n30_est_civil = 'U')
		THEN (SELECT COUNT(n31_secuencia)
			FROM acero_qm@idsuio01:rolt031
			WHERE n31_compania           = n30_compania
			  AND n31_cod_trab           = n30_cod_trab
			  AND n31_tipo_carga        <> 'H'
			  AND YEAR(n31_fecha_nacim) <= 2010)
		ELSE 0
	 END +
	(SELECT COUNT(n31_secuencia)
		FROM acero_qm@idsuio01:rolt031
		WHERE n31_compania     = n30_compania 
		  AND n31_cod_trab     = n30_cod_trab
		  AND n31_tipo_carga   = 'H'
		  AND n31_fecha_nacim >= MDY(12, 31, 2010)
					- 19 UNITS YEAR + 1 UNITS DAY
		  AND n31_fecha_nacim <= MDY(12, 31, 2010))), 0) AS carga,
	CASE WHEN (YEAR(NVL(n30_fecha_reing, n30_fecha_ing)) < 2010) OR
			(NVL(n30_fecha_reing,n30_fecha_ing) < MDY(01, 01, 2010))
		THEN (SELECT n90_dias_ano_ut
			FROM acero_qm@idsuio01:rolt090
			WHERE n90_compania = n30_compania)
		ELSE ((MDY(12, 31, 2010) -
			CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2010)
				THEN MDY(01, 01, 2010)
				ELSE NVL(n30_fecha_reing, n30_fecha_ing)
			END) + 1) -
			CASE WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 01
				THEN CASE WHEN MOD(2010, 4) = 0
						THEN 6
						ELSE 5
					END
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 02
				THEN CASE WHEN MOD(2010, 4) = 0
						THEN 5
						ELSE 4
					END
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 03
				THEN 6
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 04
				THEN 5
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 05
				THEN 5
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 06
				THEN 4
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 07
				THEN 4
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 08
				THEN 3
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 09
				THEN 2
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 10
				THEN 2
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 11
				THEN 1
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 12
				THEN 1
				ELSE 0
			END
	END dias,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM acero_qm@idsuio01:rolt030
	WHERE n30_compania             = 1
	  AND n30_estado               = 'A'
	  AND ((YEAR(n30_fecha_ing)   <= 2010
	  AND   n30_fecha_sal         IS NULL)
	   OR  (YEAR(n30_fecha_reing) <= 2010
	  AND   n30_fecha_sal         IS NOT NULL))
	  AND n30_tipo_contr           = 'F'
	  AND n30_tipo_trab            = 'N'
	  AND n30_fec_jub             IS NULL
UNION
SELECT 3 AS lc, n30_cod_trab AS cod_trab, n30_num_doc_id AS cedula,
	n30_nombres AS empleados,
	NVL((CASE WHEN (n30_est_civil = 'C' OR n30_est_civil = 'U')
		THEN (SELECT COUNT(n31_secuencia)
			FROM acero_qm@idsuio01:rolt031
			WHERE n31_compania           = n30_compania
			  AND n31_cod_trab           = n30_cod_trab
			  AND n31_tipo_carga        <> 'H'
			  AND YEAR(n31_fecha_nacim) <= 2010)
		ELSE 0
	 END +
	(SELECT COUNT(n31_secuencia)
		FROM acero_qm@idsuio01:rolt031
		WHERE n31_compania     = n30_compania 
		  AND n31_cod_trab     = n30_cod_trab
		  AND n31_tipo_carga   = 'H'
		  AND n31_fecha_nacim >= MDY(12, 31, 2010)
					- 19 UNITS YEAR + 1 UNITS DAY
		  AND n31_fecha_nacim <= MDY(12, 31, 2010))), 0) AS carga,
	CASE WHEN ((CASE WHEN n30_fecha_sal > MDY(12, 31, 2010)
				THEN MDY(12, 31, 2010)
				ELSE n30_fecha_sal
			END -
			CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
						MDY(01,01,2010)
				THEN MDY(01, 01, 2010)
				ELSE NVL(n30_fecha_reing, n30_fecha_ing)
			END) + 1) >
			(SELECT n90_dias_ano_ut
				FROM acero_qm@idsuio01:rolt090
				WHERE n90_compania = n30_compania)
		THEN (SELECT n90_dias_ano_ut
			FROM acero_qm@idsuio01:rolt090
			WHERE n90_compania = n30_compania)
		ELSE ((CASE WHEN n30_fecha_sal > MDY(12, 31, 2010)
				THEN MDY(12, 31, 2010)
				ELSE n30_fecha_sal
			END -
			CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
					MDY(01, 01, 2010)
				THEN MDY(01, 01, 2010)
				ELSE NVL(n30_fecha_reing, n30_fecha_ing)
			END) + 1) -
			(CASE WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 01
				THEN CASE WHEN MOD(2010, 4) = 0
						THEN 6
						ELSE 5
					END
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 02
				THEN CASE WHEN MOD(2010, 4) = 0
						THEN 5
						ELSE 4
					END
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 03
				THEN 6
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 04
				THEN 5
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 05
				THEN 5
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 06
				THEN 4
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 07
				THEN 4
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 08
				THEN 3
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 09
				THEN 2
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 10
				THEN 2
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 11
				THEN 1
			     WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END) = 12
				THEN 1
				ELSE 0
			END -
			CASE WHEN MONTH(CASE WHEN n30_fecha_sal >
						MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END) = 01
				THEN CASE WHEN MOD(2010, 4) = 0
						THEN 6
						ELSE 5
					END
			     WHEN MONTH(CASE WHEN n30_fecha_sal >
						MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END) = 02
				THEN CASE WHEN MOD(2010, 4) = 0
						THEN 5
						ELSE 4
					END
			     WHEN MONTH(CASE WHEN n30_fecha_sal >
						MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END) = 03
				THEN 6
			     WHEN MONTH(CASE WHEN n30_fecha_sal >
						MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END) = 04
				THEN 5
			     WHEN MONTH(CASE WHEN n30_fecha_sal >
						MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END) = 05
				THEN 5
			     WHEN MONTH(CASE WHEN n30_fecha_sal >
						MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END) = 06
				THEN 4
			     WHEN MONTH(CASE WHEN n30_fecha_sal >
						MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END) = 07
				THEN 4
			     WHEN MONTH(CASE WHEN n30_fecha_sal >
						MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END) = 08
				THEN 3
			     WHEN MONTH(CASE WHEN n30_fecha_sal >
						MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END) = 09
				THEN 2
			     WHEN MONTH(CASE WHEN n30_fecha_sal >
						MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END) = 10
				THEN 2
			     WHEN MONTH(CASE WHEN n30_fecha_sal >
						MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END) = 11
				THEN 1
			     WHEN MONTH(CASE WHEN n30_fecha_sal >
						MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END) = 12
				THEN 1
				ELSE 0
			END) +
			CASE WHEN (MONTH(CASE WHEN n30_fecha_sal >
							MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END) -
					MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END)) = 1 AND n30_cod_trab <> 425
					AND n30_cod_trab <> 426
				THEN 1
			     WHEN (MONTH(CASE WHEN n30_fecha_sal >
							MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END) -
					MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END)) = 0
				THEN CASE WHEN DAY(CASE WHEN n30_fecha_sal >
								MDY(12,31,2010)
							THEN MDY(12, 31, 2010)
							ELSE n30_fecha_sal
						END) = 31
						THEN -1
						ELSE 0
					END
				ELSE 0
			END +
			CASE WHEN EXTEND(CASE WHEN n30_fecha_sal >
								MDY(12,31,2010)
							THEN MDY(12, 31, 2010)
							ELSE n30_fecha_sal
						END, MONTH TO DAY) = '02-28'
				THEN CASE WHEN DAY(CASE WHEN
							NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
						END) = 1
						THEN 1
						ELSE 2
					END
				ELSE 0
			END +
			CASE WHEN EXTEND(CASE WHEN n30_fecha_sal >
								MDY(12,31,2010)
							THEN MDY(12, 31, 2010)
							ELSE n30_fecha_sal
						END, MONTH TO DAY) = '02-29'
				THEN CASE WHEN DAY(CASE WHEN
							NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
						END) = 1
						THEN 0
						ELSE 1
					END
				ELSE 0
			END -
			CASE WHEN (CASE WHEN n30_fecha_sal > MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END =
					MDY(MONTH(CASE WHEN n30_fecha_sal >
							MDY(12, 31, 2010)
							THEN MDY(12, 31, 2010)
							ELSE n30_fecha_sal
						END), 01,
						YEAR(CASE WHEN n30_fecha_sal >
							MDY(12, 31, 2010)
							THEN MDY(12, 31, 2010)
							ELSE n30_fecha_sal
						END)) + 1 UNITS MONTH
						- 1 UNITS DAY) AND
					(EXTEND(CASE WHEN n30_fecha_sal >
							MDY(12, 31, 2010)
							THEN MDY(12, 31, 2010)
							ELSE n30_fecha_sal
						END, MONTH TO DAY) <> '02-28')
					AND
			     		(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END <> MDY(01, 01, 2010))
				THEN 1
		     WHEN (((CASE WHEN n30_fecha_sal > MDY(12, 31, 2010)
					THEN MDY(12, 31, 2010)
					ELSE n30_fecha_sal
				END -
				CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
						MDY(01, 01, 2010)
					THEN MDY(01, 01, 2010)
					ELSE NVL(n30_fecha_reing, n30_fecha_ing)
				END) + 1) >
				(SELECT n00_dias_mes
					FROM acero_qm@idsuio01:rolt000
					WHERE n00_serial = n30_compania)) AND
			(((CASE WHEN n30_fecha_sal > MDY(12, 31, 2010)
					THEN MDY(12, 31, 2010)
					ELSE n30_fecha_sal
				END -
				CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
						MDY(01, 01, 2010)
					THEN MDY(01, 01, 2010)
					ELSE NVL(n30_fecha_reing, n30_fecha_ing)
				END) + 1) <
				(SELECT n00_dias_mes * 2
					FROM acero_qm@idsuio01:rolt000
					WHERE n00_serial = n30_compania)) AND
			     	(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2010)
						THEN MDY(01, 01, 2010)
						ELSE NVL(n30_fecha_reing,
								n30_fecha_ing)
					END = MDY(01, 01, 2010) OR
				 CASE WHEN n30_fecha_sal > MDY(12, 31, 2010)
						THEN MDY(12, 31, 2010)
						ELSE n30_fecha_sal
					END = MDY(12, 31, 2010)) AND
				(EXTEND(CASE WHEN n30_fecha_sal >
							MDY(12, 31, 2010)
							THEN MDY(12, 31, 2010)
							ELSE n30_fecha_sal
						END, MONTH TO DAY) <> '02-28')
				THEN 1
				ELSE 0
			END
	END dias,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM acero_qm@idsuio01:rolt030
	WHERE n30_compania         = 1
	  AND n30_estado           = 'I'
	  AND YEAR(n30_fecha_sal) >= 2010
	  AND YEAR(n30_fecha_sal) <= YEAR(TODAY)
	  AND n30_tipo_contr       = 'F'
	  AND n30_tipo_trab        = 'N'
	  AND n30_fec_jub         IS NULL
	ORDER BY 1, n30_nombres;
