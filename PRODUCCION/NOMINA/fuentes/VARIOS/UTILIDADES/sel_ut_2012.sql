SET ISOLATION TO DIRTY READ;
SELECT 1 AS localidad, n30_cod_trab AS cod_trab, n30_nombres AS nombres,
	NVL((CASE WHEN (n30_est_civil = 'C' OR n30_est_civil = 'U')
		THEN (SELECT COUNT(n31_secuencia)
			FROM aceros:rolt031
			WHERE n31_compania           = n30_compania
			  AND n31_cod_trab           = n30_cod_trab
			  AND n31_tipo_carga        <> 'H'
			  AND YEAR(n31_fecha_nacim) <= 2012)
		ELSE 0
	 END +
	(SELECT COUNT(n31_secuencia)
		FROM aceros:rolt031
		WHERE n31_compania     = n30_compania 
		  AND n31_cod_trab     = n30_cod_trab
		  AND n31_tipo_carga   = 'H'
		  AND n31_fecha_nacim >= MDY(12, 31, 2012)
					- 19 UNITS YEAR + 1 UNITS DAY
		  AND n31_fecha_nacim <= MDY(12, 31, 2012))), 0) AS num_cargas,
	((12 - MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2012)
			THEN MDY(01, 01, 2012)
			ELSE MDY(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)),
				DAY(NVL(n30_fecha_reing, n30_fecha_ing)),
				2012)
		    END)) * (SELECT n00_dias_mes
				FROM aceros:rolt000
				WHERE n00_serial = n30_compania)) +
	((SELECT n00_dias_mes
		FROM aceros:rolt000
		WHERE n00_serial = n30_compania) -
	DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) < MDY(01, 01, 2012)
		THEN MDY(01, 01, 2012)
		ELSE MDY(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)),
			CASE WHEN DAY(NVL(n30_fecha_reing, n30_fecha_ing)) = 31
				THEN (SELECT n00_dias_mes
					FROM aceros:rolt000
					WHERE n00_serial = n30_compania)
				ELSE DAY(NVL(n30_fecha_reing, n30_fecha_ing))
			END,
			2012)
	    END) + 1) AS dias_trab,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM aceros:rolt030
	WHERE n30_compania             = 1
	  AND n30_estado               = 'A'
	  AND ((YEAR(n30_fecha_ing)   <= 2012
	  AND   n30_fecha_sal         IS NULL)
	   OR  (YEAR(n30_fecha_reing) <= 2012
	  AND   n30_fecha_sal         IS NOT NULL))
	  AND n30_tipo_contr           = 'F'
	  AND n30_tipo_trab            = 'N'
	  AND n30_fec_jub             IS NULL
UNION
SELECT 1 AS localidad, n30_cod_trab AS cod_trab, n30_nombres AS nombres,
	NVL((CASE WHEN (n30_est_civil = 'C' OR n30_est_civil = 'U')
		THEN (SELECT COUNT(n31_secuencia)
			FROM aceros:rolt031
			WHERE n31_compania           = n30_compania
			  AND n31_cod_trab           = n30_cod_trab
			  AND n31_tipo_carga        <> 'H'
			  AND YEAR(n31_fecha_nacim) <= 2012)
		ELSE 0
	 END +
	(SELECT COUNT(n31_secuencia)
		FROM aceros:rolt031
		WHERE n31_compania     = n30_compania 
		  AND n31_cod_trab     = n30_cod_trab
		  AND n31_tipo_carga   = 'H'
		  AND n31_fecha_nacim >= MDY(12, 31, 2012)
					- 19 UNITS YEAR + 1 UNITS DAY
		  AND n31_fecha_nacim <= MDY(12, 31, 2012))), 0) AS num_cargas,
	CASE WHEN (MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2012)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2012)
			 END) - 1) >=
			MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2012)
					THEN MDY(01, 01, 2012)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						2012)
				END)
		THEN (((MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2012)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2012)
				END) - 1) -
			MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2012)
					THEN MDY(01, 01, 2012)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
								n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
								n30_fecha_ing)),
						2012)
				END)) * (SELECT n00_dias_mes
					FROM aceros:rolt000
					WHERE n00_serial = n30_compania)) +
			((SELECT n00_dias_mes
				FROM aceros:rolt000
				WHERE n00_serial = n30_compania) -
			DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2012)
				THEN MDY(01, 01, 2012)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					CASE WHEN DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)) = 31
						THEN (SELECT n00_dias_mes
						FROM aceros:rolt000
							WHERE n00_serial =
								n30_compania)
						ELSE DAY(NVL(n30_fecha_reing,
								n30_fecha_ing))
					END,
					2012)
			    END) + 1)
		ELSE 0
	END + CASE WHEN DAY(CASE WHEN n30_fecha_sal < MDY(12, 31, 2012)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2012)
			    END) = 31
			THEN (SELECT n00_dias_mes
				FROM aceros:rolt000
				WHERE n00_serial = n30_compania)
			ELSE DAY(CASE WHEN n30_fecha_sal < MDY(12, 31, 2012)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2012)
				 END) -
				CASE WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2012)
						THEN MDY(01, 01, 2012)
						ELSE MDY(MONTH(NVL(
							n30_fecha_reing,
							n30_fecha_ing)),
							DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
							2012)
						END) = 
					MONTH(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2012)
						THEN n30_fecha_sal
						ELSE MDY(12, 31, 2012)
						END)
					THEN DAY(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2012)
						THEN MDY(01, 01, 2012)
						ELSE MDY(MONTH(NVL(
							n30_fecha_reing,
							n30_fecha_ing)),
							DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
							2012)
						END) - 1
					ELSE 0
				END
		END +
	CASE WHEN (MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2012)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2012)
			END) = 02 AND
			EXTEND(CASE WHEN n30_fecha_sal < MDY(12, 31, 2012)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2012)
			END, MONTH TO DAY) =
			EXTEND(MDY(MONTH(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2012)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2012)
				  END), 01,
				YEAR(CASE WHEN n30_fecha_sal < MDY(12, 31, 2012)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2012)
				     END)) + 1 UNITS MONTH - 1 UNITS DAY,
				MONTH TO DAY))
		THEN CASE WHEN MOD(2012, 4) = 0 THEN 1 ELSE 2 END
		ELSE 0
	END dias_trab,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM aceros:rolt030
	WHERE n30_compania         = 1
	  AND n30_estado           = 'I'
	  AND YEAR(n30_fecha_sal) >= 2012
	  AND YEAR(n30_fecha_sal) <= YEAR(TODAY)
	  AND n30_tipo_contr       = 'F'
	  AND n30_tipo_trab        = 'N'
	  AND n30_fec_jub         IS NULL
UNION
SELECT 3 AS localidad, n30_cod_trab AS cod_trab, n30_nombres AS nombres,
	NVL((CASE WHEN (n30_est_civil = 'C' OR n30_est_civil = 'U')
		THEN (SELECT COUNT(n31_secuencia)
			FROM acero_qm:rolt031
			WHERE n31_compania           = n30_compania
			  AND n31_cod_trab           = n30_cod_trab
			  AND n31_tipo_carga        <> 'H'
			  AND YEAR(n31_fecha_nacim) <= 2012)
		ELSE 0
	 END +
	(SELECT COUNT(n31_secuencia)
		FROM acero_qm:rolt031
		WHERE n31_compania     = n30_compania 
		  AND n31_cod_trab     = n30_cod_trab
		  AND n31_tipo_carga   = 'H'
		  AND n31_fecha_nacim >= MDY(12, 31, 2012)
					- 19 UNITS YEAR + 1 UNITS DAY
		  AND n31_fecha_nacim <= MDY(12, 31, 2012))), 0) AS num_cargas,
	((12 - MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2012)
			THEN MDY(01, 01, 2012)
			ELSE MDY(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)),
				DAY(NVL(n30_fecha_reing, n30_fecha_ing)),
				2012)
		    END)) * (SELECT n00_dias_mes
				FROM acero_qm:rolt000
				WHERE n00_serial = n30_compania)) +
	((SELECT n00_dias_mes
		FROM acero_qm:rolt000
		WHERE n00_serial = n30_compania) -
	DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) < MDY(01, 01, 2012)
		THEN MDY(01, 01, 2012)
		ELSE MDY(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)),
			CASE WHEN DAY(NVL(n30_fecha_reing, n30_fecha_ing)) = 31
				THEN (SELECT n00_dias_mes
					FROM acero_qm:rolt000
					WHERE n00_serial = n30_compania)
				ELSE DAY(NVL(n30_fecha_reing, n30_fecha_ing))
			END,
			2012)
	    END) + 1) AS dias_trab,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM acero_qm:rolt030
	WHERE n30_compania             = 1
	  AND n30_estado               = 'A'
	  AND ((YEAR(n30_fecha_ing)   <= 2012
	  AND   n30_fecha_sal         IS NULL)
	   OR  (YEAR(n30_fecha_reing) <= 2012
	  AND   n30_fecha_sal         IS NOT NULL))
	  AND n30_tipo_contr           = 'F'
	  AND n30_tipo_trab            = 'N'
	  AND n30_fec_jub             IS NULL
UNION
SELECT 3 AS localidad, n30_cod_trab AS cod_trab, n30_nombres AS nombres,
	NVL((CASE WHEN (n30_est_civil = 'C' OR n30_est_civil = 'U')
		THEN (SELECT COUNT(n31_secuencia)
			FROM acero_qm:rolt031
			WHERE n31_compania           = n30_compania
			  AND n31_cod_trab           = n30_cod_trab
			  AND n31_tipo_carga        <> 'H'
			  AND YEAR(n31_fecha_nacim) <= 2012)
		ELSE 0
	 END +
	(SELECT COUNT(n31_secuencia)
		FROM acero_qm:rolt031
		WHERE n31_compania     = n30_compania 
		  AND n31_cod_trab     = n30_cod_trab
		  AND n31_tipo_carga   = 'H'
		  AND n31_fecha_nacim >= MDY(12, 31, 2012)
					- 19 UNITS YEAR + 1 UNITS DAY
		  AND n31_fecha_nacim <= MDY(12, 31, 2012))), 0) AS num_cargas,
	CASE WHEN (MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2012)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2012)
			 END) - 1) >=
			MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2012)
					THEN MDY(01, 01, 2012)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
						2012)
				END)
		THEN (((MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2012)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2012)
				END) - 1) -
			MONTH(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2012)
					THEN MDY(01, 01, 2012)
					ELSE MDY(MONTH(NVL(n30_fecha_reing,
								n30_fecha_ing)),
						DAY(NVL(n30_fecha_reing,
								n30_fecha_ing)),
						2012)
				END)) * (SELECT n00_dias_mes
					FROM acero_qm:rolt000
					WHERE n00_serial = n30_compania)) +
			((SELECT n00_dias_mes
				FROM acero_qm:rolt000
				WHERE n00_serial = n30_compania) -
			DAY(CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) <
							MDY(01, 01, 2012)
				THEN MDY(01, 01, 2012)
				ELSE MDY(MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)),
					CASE WHEN DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)) = 31
						THEN (SELECT n00_dias_mes
						FROM acero_qm:rolt000
							WHERE n00_serial =
								n30_compania)
						ELSE DAY(NVL(n30_fecha_reing,
								n30_fecha_ing))
					END,
					2012)
			    END) + 1)
		ELSE 0
	END + CASE WHEN DAY(CASE WHEN n30_fecha_sal < MDY(12, 31, 2012)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2012)
			    END) = 31
			THEN (SELECT n00_dias_mes
				FROM acero_qm:rolt000
				WHERE n00_serial = n30_compania)
			ELSE DAY(CASE WHEN n30_fecha_sal < MDY(12, 31, 2012)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2012)
				 END) -
				CASE WHEN MONTH(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2012)
						THEN MDY(01, 01, 2012)
						ELSE MDY(MONTH(NVL(
							n30_fecha_reing,
							n30_fecha_ing)),
							DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
							2012)
						END) = 
					MONTH(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2012)
						THEN n30_fecha_sal
						ELSE MDY(12, 31, 2012)
						END)
					THEN DAY(CASE WHEN NVL(n30_fecha_reing,
							n30_fecha_ing) <
							MDY(01, 01, 2012)
						THEN MDY(01, 01, 2012)
						ELSE MDY(MONTH(NVL(
							n30_fecha_reing,
							n30_fecha_ing)),
							DAY(NVL(n30_fecha_reing,
							n30_fecha_ing)),
							2012)
						END) - 1
					ELSE 0
				END
		END +
	CASE WHEN (MONTH(CASE WHEN n30_fecha_sal < MDY(12, 31, 2012)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2012)
			END) = 02 AND
			EXTEND(CASE WHEN n30_fecha_sal < MDY(12, 31, 2012)
				THEN n30_fecha_sal
				ELSE MDY(12, 31, 2012)
			END, MONTH TO DAY) =
			EXTEND(MDY(MONTH(CASE WHEN n30_fecha_sal <
							MDY(12, 31, 2012)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2012)
				  END), 01,
				YEAR(CASE WHEN n30_fecha_sal < MDY(12, 31, 2012)
					THEN n30_fecha_sal
					ELSE MDY(12, 31, 2012)
				     END)) + 1 UNITS MONTH - 1 UNITS DAY,
				MONTH TO DAY))
		THEN CASE WHEN MOD(2012, 4) = 0 THEN 1 ELSE 2 END
		ELSE 0
	END dias_trab,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM acero_qm:rolt030
	WHERE n30_compania         = 1
	  AND n30_estado           = 'I'
	  AND YEAR(n30_fecha_sal) >= 2012
	  AND YEAR(n30_fecha_sal) <= YEAR(TODAY)
	  AND n30_tipo_contr       = 'F'
	  AND n30_tipo_trab        = 'N'
	  AND n30_fec_jub         IS NULL
	INTO TEMP te_trab;

--
SELECT LPAD(localidad, 2, 0) loc, LPAD(cod_trab, 3, 0) cod,
	nombres[1, 40] empleado, LPAD(dias_trab, 3, 0) dias,
	LPAD(num_cargas, 2, 0) car, LPAD(dias_trab * num_cargas, 4, 0) p_car,
	LPAD(dias_trab + NVL(dias_trab * num_cargas, 0), 4, 0) tot_p
	FROM te_trab
	--WHERE localidad = 3
	ORDER BY 1, 3;
--

SELECT LPAD(localidad, 2, 0) loc, COUNT(cod_trab) t_emp,
	ROUND(SUM(NVL(num_cargas, 0)), 2) t_car,
	NVL(ROUND(SUM(dias_trab), 2), 0) puntos_trab,
	NVL(ROUND(SUM(dias_trab * num_cargas), 2), 0) puntos_carg
	FROM te_trab
	GROUP BY 1
	INTO TEMP t1;

SELECT 1 local, NVL(ROUND(SUM(b13_valor_base), 2), 0) utilidad
	FROM aceros:ctbt012, aceros:ctbt013
	WHERE b12_compania          = 1
	  AND b12_estado            = 'M'
	  AND YEAR(b12_fec_proceso) = 2012
	  AND NOT EXISTS
		(SELECT 1 FROM aceros:ctbt050
			WHERE b50_compania  = b12_compania
			  AND b50_tipo_comp = b12_tipo_comp
			  AND b50_num_comp  = b12_num_comp
			  AND b50_anio      = YEAR(b12_fec_proceso))
	  AND b13_compania          = b12_compania
	  AND b13_tipo_comp         = b12_tipo_comp
	  AND b13_num_comp          = b12_num_comp
	  AND b13_cuenta[1, 1]      > 3
	GROUP BY 1
	UNION ALL
	SELECT 3 local, NVL(ROUND(SUM(b13_valor_base), 2), 0) utilidad
		FROM acero_qm:ctbt012, acero_qm:ctbt013
		WHERE b12_compania          = 1
		  AND b12_estado            = 'M'
		  AND YEAR(b12_fec_proceso) = 2012
		  AND NOT EXISTS
			(SELECT 1 FROM acero_qm:ctbt050
			WHERE b50_compania  = b12_compania
			  AND b50_tipo_comp = b12_tipo_comp
			  AND b50_num_comp  = b12_num_comp
			  AND b50_anio      = YEAR(b12_fec_proceso))
		  AND b13_compania          = b12_compania
		  AND b13_tipo_comp         = b12_tipo_comp
		  AND b13_num_comp          = b12_num_comp
		  AND b13_cuenta[1, 1]      > 3
		GROUP BY 1
	INTO TEMP tmp_ctb;

SELECT * FROM t1 ORDER BY 1;

SELECT * FROM tmp_ctb ORDER BY 1;

SELECT NVL(ROUND(SUM(utilidad), 2), 0) utilidad_neta
	FROM tmp_ctb
	INTO TEMP t2;

DROP TABLE tmp_ctb;

SELECT * FROM t2;

SELECT ROUND((((utilidad_neta * (-0.15)) / 3) * 2), 2) val_rep_trab,
	ROUND(((utilidad_neta * (-0.15)) / 3), 2) val_rep_carg
	FROM t2
	INTO TEMP t3;

SELECT NVL(ROUND(SUM(puntos_trab), 2), 0) puntos_trab,
	NVL(ROUND(SUM(puntos_carg), 2), 0) puntos_carg
	FROM t1
	INTO TEMP t4;

DROP TABLE t1;

DROP TABLE t2;

SELECT * FROM t3;

SELECT * FROM t4;

SELECT (val_rep_trab / puntos_trab) fact_ut_trab,
	(val_rep_carg / puntos_carg) fact_ut_carg
	FROM t3, t4
	INTO TEMP tmp_fact;

SELECT ROUND((val_rep_trab / puntos_trab) * 360, 2) val_ut_trab,
	ROUND((val_rep_carg / puntos_carg) * 360, 2) val_ut_carg
	FROM t3, t4;

DROP TABLE t3;

DROP TABLE t4;

CREATE TEMP TABLE tmp_ut
	(
		loc		CHAR(2),
		cod		CHAR(3),
		empleado	VARCHAR(38),
		val_ut		DECIMAL(7,2),
		val_c		DECIMAL(7,2),
		tot_ut		DECIMAL(7,2)
	);

INSERT INTO tmp_ut
	SELECT LPAD(localidad, 2, 0) loc, LPAD(cod_trab, 3, 0) cod,
		nombres empleado, ROUND(fact_ut_trab * dias_trab, 2) val_ut,
		ROUND(NVL(fact_ut_carg * dias_trab * num_cargas, 0), 2) val_c,
		ROUND((fact_ut_trab * dias_trab) + NVL(fact_ut_carg *
			dias_trab * num_cargas, 0), 2) tot_ut
		FROM te_trab, tmp_fact;

SELECT * FROM tmp_ut ORDER BY 1, 3;

SELECT LPAD(loc, 2, 0) l_t, ROUND(SUM(val_ut), 2) v_r_trab,
	ROUND(SUM(val_c), 2) v_r_carg, ROUND(SUM(tot_ut), 2) ut_15
	FROM tmp_ut
	GROUP BY 1
	ORDER BY 1;

SELECT LPAD(localidad, 2, 0) loc,
	ROUND(SUM(fact_ut_trab * dias_trab), 2) val_rep_trab,
	ROUND(SUM(NVL(fact_ut_carg * dias_trab * num_cargas,0)),2) val_rep_carg,
	ROUND(SUM((fact_ut_trab * dias_trab) + NVL(fact_ut_carg * dias_trab
			* num_cargas, 0)), 2) partic_15
	FROM te_trab, tmp_fact
	GROUP BY 1
	ORDER BY 1;

DROP TABLE tmp_ut;

DROP TABLE te_trab;

DROP TABLE tmp_fact;
