SELECT 1 loc_c, n31_cod_trab, n31_tipo_carga, COUNT(n31_secuencia) tot_carg
	FROM aceros:rolt031, aceros:rolt030
	WHERE n31_compania     = 1
	  AND n31_tipo_carga  <> 'H'
	  AND n31_fecha_nacim <= MDY(12, 31, 2009)
	  AND n30_compania     = n31_compania
	  AND n30_cod_trab     = n31_cod_trab
	  AND (n30_est_civil   = 'C'
	   OR  n30_est_civil   = 'U')
	GROUP BY 1, 2, 3
	UNION ALL
	SELECT 1 loc_c, n31_cod_trab, n31_tipo_carga,
		COUNT(n31_secuencia) tot_carg
		FROM aceros:rolt031
		WHERE n31_compania     = 1
		  AND n31_tipo_carga   = 'H'
		  AND n31_fecha_nacim >= MDY(12, 31, 2009)
					- 19 UNITS YEAR + 1 UNITS DAY
		  AND n31_fecha_nacim <= MDY(12, 31, 2009)
		GROUP BY 1, 2, 3
	UNION ALL
	SELECT 3 loc_c, n31_cod_trab, n31_tipo_carga,
		COUNT(n31_secuencia) tot_carg
		FROM acero_qm:rolt031, acero_qm:rolt030
		WHERE n31_compania     = 1
		  AND n31_tipo_carga  <> 'H'
		  AND n31_fecha_nacim <= MDY(12, 31, 2009)
		  AND n30_compania     = n31_compania
		  AND n30_cod_trab     = n31_cod_trab
		  AND (n30_est_civil   = 'C'
		   OR  n30_est_civil   = 'U')
		GROUP BY 1, 2, 3
	UNION ALL
	SELECT 3 loc_c, n31_cod_trab, n31_tipo_carga,
		COUNT(n31_secuencia) tot_carg
		FROM acero_qm:rolt031
		WHERE n31_compania     = 1
		  AND n31_tipo_carga   = 'H'
		  AND n31_fecha_nacim >= MDY(12, 31, 2009)
					- 19 UNITS YEAR + 1 UNITS DAY
		  AND n31_fecha_nacim <= MDY(12, 31, 2009)
		GROUP BY 1, 2, 3
	INTO TEMP tmp_car;

SELECT 1 localidad, n30_cod_trab cod_trab, n30_nombres nombres,
	n30_fecha_ing fecha_ing, n30_fecha_reing fecha_reing,
	n30_fecha_sal fecha_sal,
	NVL((SELECT n42_dias_trab
		FROM aceros:rolt042
		WHERE n42_compania = n30_compania
		  AND n42_cod_trab = n30_cod_trab
		  AND n42_ano      = 2009),
	CASE WHEN YEAR(n30_fecha_ing) = 2009
		THEN ((MDY(12, 31, 2009) -
			CASE WHEN n30_fecha_reing IS NULL
				THEN n30_fecha_ing
				ELSE n30_fecha_reing
			END) + 1)
		ELSE (SELECT n90_dias_ano_ut
			FROM aceros:rolt090
			WHERE n90_compania = n30_compania)
	END) dias_trab,
	NVL((SELECT n42_num_cargas
		FROM aceros:rolt042, aceros:rolt041
		WHERE n42_compania  = n30_compania
		  AND n42_cod_trab  = n30_cod_trab
		  AND n42_ano       = 2009
		  AND n41_compania  = n42_compania
		  AND n41_proceso   = n42_proceso
		  AND n41_fecha_ini = n42_fecha_ini
		  AND n41_fecha_fin = n42_fecha_fin
		  AND n41_estado    = 'P'),
	(SELECT SUM(tot_carg)
		FROM tmp_car
		WHERE loc_c        = 1
		  AND n31_cod_trab = n30_cod_trab)) num_cargas
	FROM aceros:rolt030
	WHERE n30_compania    = 1
	  AND n30_fecha_ing  <= MDY(12, 31, 2009)
	  AND n30_fecha_sal  IS NULL
	  AND n30_tipo_contr  = 'F'
	  AND n30_estado     <> 'J'
	  AND n30_tipo_trab   = 'N'
	  AND n30_fec_jub    IS NULL
	UNION ALL
	SELECT 1 localidad, n30_cod_trab cod_trab, n30_nombres nombres,
		n30_fecha_ing fecha_ing, n30_fecha_reing fecha_reing,
		n30_fecha_sal fecha_sal,
		NVL((SELECT n42_dias_trab
			FROM aceros:rolt042
			WHERE n42_compania = n30_compania
			  AND n42_cod_trab = n30_cod_trab
			  AND n42_ano      = 2009),
		CASE WHEN YEAR(n30_fecha_ing) <> 2009 AND
			n30_fecha_reing IS NULL
			THEN (n30_fecha_sal - MDY(01, 01, 2009) + 1)
		     WHEN YEAR(n30_fecha_ing) = 2009 AND
			n30_fecha_reing IS NOT NULL
			THEN (MDY(12, 31, 2009) - n30_fecha_reing) + 1
		     WHEN n30_fecha_ing > MDY(01, 01, 2009) AND
				YEAR(n30_fecha_sal) > 2009
			THEN (MDY(12, 31, 2009) - n30_fecha_ing) + 1
		     WHEN n30_fecha_ing > MDY(01, 01, 2009) AND
			  n30_fecha_sal > MDY(01, 01, 2009) AND
			  n30_fecha_sal < MDY(12, 31, 2009)
			THEN (n30_fecha_sal - n30_fecha_ing) + 1
		     WHEN n30_fecha_reing > MDY(01, 01, 2009) AND
			  n30_fecha_sal   >= n30_fecha_reing  AND
			  n30_fecha_sal   > MDY(01, 01, 2009) AND
			  n30_fecha_sal   < MDY(12, 31, 2009)
			THEN (n30_fecha_sal - n30_fecha_reing) + 1
		     WHEN n30_fecha_reing > MDY(01, 01, 2009) AND
				YEAR(n30_fecha_sal) > 2009
			THEN (MDY(12, 31, 2009) - n30_fecha_reing) + 1
		     WHEN n30_fecha_reing > MDY(01, 01, 2009) AND
			  YEAR(n30_fecha_sal) <> 2009
			THEN (MDY(12, 31, 2009) - n30_fecha_reing) + 1
			ELSE (SELECT n90_dias_ano_ut
				FROM aceros:rolt090
				WHERE n90_compania = n30_compania)
		END) dias_trab,
		NVL((SELECT n42_num_cargas
			FROM aceros:rolt042, aceros:rolt041
			WHERE n42_compania  = n30_compania
			  AND n42_cod_trab  = n30_cod_trab
			  AND n42_ano       = 2009
			  AND n41_compania  = n42_compania
			  AND n41_proceso   = n42_proceso
			  AND n41_fecha_ini = n42_fecha_ini
			  AND n41_fecha_fin = n42_fecha_fin
			  AND n41_estado    = 'P'),
		(SELECT SUM(tot_carg)
			FROM tmp_car
			WHERE loc_c        = 1
			  AND n31_cod_trab = n30_cod_trab)) num_cargas
		FROM aceros:rolt030
		WHERE n30_compania    = 1
		  AND n30_fecha_ing  <= MDY(12, 31, 2009)
		  AND n30_fecha_sal  <= MDY(12, 31, YEAR(TODAY))
		  AND n30_tipo_contr  = 'F'
		  AND n30_estado     <> 'J'
		  AND n30_tipo_trab   = 'N'
		  AND n30_fec_jub    IS NULL
	UNION ALL
	SELECT 3 localidad, n30_cod_trab cod_trab, n30_nombres nombres,
		n30_fecha_ing fecha_ing, n30_fecha_reing fecha_reing,
		n30_fecha_sal fecha_sal,
		NVL((SELECT n42_dias_trab
			FROM acero_qm:rolt042
			WHERE n42_compania = n30_compania
			  AND n42_cod_trab = n30_cod_trab
			  AND n42_ano      = 2009),
		CASE WHEN YEAR(n30_fecha_ing) = 2009
			THEN ((MDY(12, 31, 2009) -
				CASE WHEN n30_fecha_reing IS NULL
					THEN n30_fecha_ing
					ELSE n30_fecha_reing
				END) + 1)
			ELSE (SELECT n90_dias_ano_ut
				FROM acero_qm:rolt090
				WHERE n90_compania = n30_compania)
		END) dias_trab,
		NVL((SELECT n42_num_cargas
			FROM acero_qm:rolt042, acero_qm:rolt041
			WHERE n42_compania  = n30_compania
			  AND n42_cod_trab  = n30_cod_trab
			  AND n42_ano       = 2009
			  AND n41_compania  = n42_compania
			  AND n41_proceso   = n42_proceso
			  AND n41_fecha_ini = n42_fecha_ini
			  AND n41_fecha_fin = n42_fecha_fin
			  AND n41_estado    = 'P'),
		(SELECT SUM(tot_carg)
			FROM tmp_car
			WHERE loc_c        = 3
			  AND n31_cod_trab = n30_cod_trab)) num_cargas
		FROM acero_qm:rolt030
		WHERE n30_compania    = 1
		  AND n30_fecha_ing  <= MDY(12, 31, 2009)
		  AND n30_fecha_sal  IS NULL
		  AND n30_tipo_contr  = 'F'
		  AND n30_estado     <> 'J'
		  AND n30_tipo_trab   = 'N'
		  AND n30_fec_jub    IS NULL
	UNION ALL
	SELECT 3 localidad, n30_cod_trab cod_trab, n30_nombres nombres,
		n30_fecha_ing fecha_ing, n30_fecha_reing fecha_reing,
		n30_fecha_sal fecha_sal,
		NVL((SELECT n42_dias_trab
			FROM acero_qm:rolt042
			WHERE n42_compania = n30_compania
			  AND n42_cod_trab = n30_cod_trab
			  AND n42_ano      = 2009),
		CASE WHEN YEAR(n30_fecha_ing) <> 2009 AND
			n30_fecha_reing IS NULL
			THEN (n30_fecha_sal - MDY(01, 01, 2009) + 1)
		     WHEN YEAR(n30_fecha_ing) = 2009 AND
			n30_fecha_reing IS NOT NULL
			THEN (MDY(12, 31, 2009) - n30_fecha_reing) + 1
		     WHEN n30_fecha_ing > MDY(01, 01, 2009) AND
				YEAR(n30_fecha_sal) > 2009
			THEN (MDY(12, 31, 2009) - n30_fecha_ing) + 1
		     WHEN n30_fecha_ing > MDY(01, 01, 2009) AND
			  n30_fecha_sal > MDY(01, 01, 2009) AND
			  n30_fecha_sal < MDY(12, 31, 2009)
			THEN (n30_fecha_sal - n30_fecha_ing) + 1
		     WHEN n30_fecha_reing > MDY(01, 01, 2009) AND
			  n30_fecha_sal   >= n30_fecha_reing  AND
			  n30_fecha_sal   > MDY(01, 01, 2009) AND
			  n30_fecha_sal   < MDY(12, 31, 2009)
			THEN (n30_fecha_sal - n30_fecha_reing) + 1
		     WHEN n30_fecha_reing > MDY(01, 01, 2009) AND
				YEAR(n30_fecha_sal) > 2009
			THEN (MDY(12, 31, 2009) - n30_fecha_reing) + 1
		     WHEN n30_fecha_reing > MDY(01, 01, 2009) AND
			  YEAR(n30_fecha_sal) <> 2009
			THEN (MDY(12, 31, 2009) - n30_fecha_reing) + 1
			ELSE (SELECT n90_dias_ano_ut
				FROM acero_qm:rolt090
				WHERE n90_compania = n30_compania)
		END) dias_trab,
		NVL((SELECT n42_num_cargas
			FROM acero_qm:rolt042, acero_qm:rolt041
			WHERE n42_compania  = n30_compania
			  AND n42_cod_trab  = n30_cod_trab
			  AND n42_ano       = 2009
			  AND n41_compania  = n42_compania
			  AND n41_proceso   = n42_proceso
			  AND n41_fecha_ini = n42_fecha_ini
			  AND n41_fecha_fin = n42_fecha_fin
			  AND n41_estado    = 'P'),
		(SELECT SUM(tot_carg)
			FROM tmp_car
			WHERE loc_c        = 3
			  AND n31_cod_trab = n30_cod_trab)) num_cargas
		FROM acero_qm:rolt030
		WHERE n30_compania    = 1
		  AND n30_fecha_ing  <= MDY(12, 31, 2009)
		  AND n30_fecha_sal  <= MDY(12, 31, YEAR(TODAY))
		  AND n30_tipo_contr  = 'F'
		  AND n30_estado     <> 'J'
		  AND n30_tipo_trab   = 'N'
		  AND n30_fec_jub    IS NULL
	INTO TEMP te_trab;

DROP TABLE tmp_car;

DELETE FROM te_trab
	WHERE fecha_reing      > MDY(12, 31, 2009)
	  AND YEAR(fecha_sal) <> 2009;

DELETE FROM te_trab
	WHERE  fecha_sal   < MDY(01, 01, 2009)
	  AND (fecha_reing IS NULL
	   OR  fecha_reing > MDY(12, 31, 2009));

DELETE FROM te_trab
	WHERE fecha_sal         < MDY(01, 01, 2009)
	  AND YEAR(fecha_reing) = YEAR(fecha_sal);

UPDATE te_trab
	SET dias_trab = (SELECT n90_dias_ano_ut
			FROM aceros:rolt090
			WHERE n90_compania = 1)
	WHERE localidad = 1
	  AND dias_trab > (SELECT n90_dias_ano_ut
				FROM aceros:rolt090
				WHERE n90_compania = 1);

UPDATE te_trab
	SET dias_trab = (SELECT n90_dias_ano_ut
			FROM acero_qm:rolt090
			WHERE n90_compania = 1)
	WHERE localidad = 3
	  AND dias_trab > (SELECT n90_dias_ano_ut
				FROM acero_qm:rolt090
				WHERE n90_compania = 1);

{--
SELECT LPAD(localidad, 2, 0) loc, LPAD(cod_trab, 3, 0) cod,
	nombres[1, 40] empleado, LPAD(dias_trab, 3, 0) dias,
	LPAD(num_cargas, 2, 0) car, LPAD(dias_trab * num_cargas, 4, 0) p_car,
	LPAD(dias_trab + NVL(dias_trab * num_cargas, 0), 4, 0) tot_p
	FROM te_trab
	--WHERE localidad = 1
	ORDER BY 1, 3;
--}

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
	  AND YEAR(b12_fec_proceso) = 2009
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
		  AND YEAR(b12_fec_proceso) = 2009
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

SELECT ROUND((val_rep_trab / puntos_trab) * 365, 2) val_ut_trab,
	ROUND((val_rep_carg / puntos_carg) * 365, 2) val_ut_carg
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
