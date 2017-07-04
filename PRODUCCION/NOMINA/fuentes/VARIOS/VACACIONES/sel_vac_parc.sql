SELECT UNIQUE n32_compania cia, n32_cod_trab cod_trab,
	CASE WHEN YEAR(TODAY) > n32_ano_proceso
		THEN YEAR(TODAY)
		ELSE n32_ano_proceso
	END anio
	FROM rolt090, rolt032
	WHERE n90_compania     = 1
	  AND n32_compania     = n90_compania
	  AND n32_cod_liqrol  IN ("Q1", "Q2")
	  AND n32_ano_proceso  > n90_anio_ini_vac
	INTO TEMP tmp_trab;
SELECT * FROM rolt032
	WHERE n32_compania    = 1
	  AND n32_cod_liqrol IN ("Q1", "Q2")
	  AND n32_fecha_fin   > NVL((SELECT MAX(n39_periodo_fin)
				FROM rolt039
				WHERE n39_compania = n32_compania
				  AND n39_proceso  = "VA"
				  AND n39_cod_trab = n32_cod_trab),
				TODAY - 1 UNITS YEAR)
	INTO TEMP tmp_rol;
SELECT UNIQUE cia, cod_trab, anio
	FROM tmp_trab, tmp_rol
	WHERE cia      = n32_compania
	  AND cod_trab = n32_cod_trab
	INTO TEMP tmp_n32;
DROP TABLE tmp_trab;
SELECT n30_compania, n30_cod_trab, n30_nombres,
	CASE WHEN EXTEND(n30_fecha_ing, MONTH TO DAY) = "02-29"
		THEN MDY(MONTH(n30_fecha_ing), 28, YEAR(n30_fecha_ing))
		ELSE n30_fecha_ing
	END n30_fecha_ing
	FROM rolt030
	WHERE n30_compania  = 1
	  AND n30_estado    = "A"
	  AND n30_tipo_trab = "N"
	INTO TEMP tmp_n30;
SELECT n30_cod_trab cod_t, n30_nombres nom, MDY(MONTH(n30_fecha_ing),
		DAY(n30_fecha_ing), anio - 1) - 1 UNITS DAY + 1 UNITS DAY p_ini,
	MDY(MONTH(n30_fecha_ing), DAY(n30_fecha_ing), anio) - 1 UNITS DAY p_fin,
	n00_dias_vacac +
	(CASE WHEN (MDY(MONTH(n30_fecha_ing), DAY(n30_fecha_ing), anio))
		>= (n30_fecha_ing + (n00_ano_adi_vac - 1) UNITS YEAR
			- 1 UNITS DAY)
		THEN CASE WHEN (n00_dias_vacac +
			((YEAR(MDY(MONTH(n30_fecha_ing), DAY(n30_fecha_ing),
			anio)) - YEAR(n30_fecha_ing + (n00_ano_adi_vac
			- 1) UNITS YEAR - 1 UNITS DAY)) * n00_dias_adi_va)) >
			n00_max_vacac
			THEN n00_max_vacac - n00_dias_vacac
			ELSE ((YEAR(MDY(MONTH(n30_fecha_ing),DAY(n30_fecha_ing),
				anio)) - YEAR(n30_fecha_ing +
				(n00_ano_adi_vac - 1) UNITS YEAR
				- 1 UNITS DAY)) * n00_dias_adi_va)
			END
		ELSE 0
		END) d_vac,
	ROUND(NVL((SELECT SUM(n32_tot_gan)
			FROM tmp_rol
			WHERE n32_compania     = n30_compania
			  AND n32_cod_liqrol  IN("Q1", "Q2")
			  AND n32_fecha_ini   >= 
				MDY(MONTH(n30_fecha_ing),
				(CASE WHEN DAY(n30_fecha_ing) >= 1
					AND DAY(n30_fecha_ing) <= 15
				THEN 1 ELSE 16 END), anio - 1)
			  AND n32_fecha_fin   <=
				MDY(MONTH(n30_fecha_ing),
				(CASE WHEN DAY(n30_fecha_ing) >= 1
					AND DAY(n30_fecha_ing) <= 15
				THEN 1 ELSE 16 END), anio) - 1 UNITS DAY
			  AND n32_cod_trab     = n30_cod_trab
			  AND n32_ano_proceso >=
				(SELECT n90_anio_ini_vac FROM rolt090
					WHERE n90_compania = n30_compania)
			  AND n32_estado      <> "E"), 0) /
		((SELECT n90_dias_ano_vac FROM rolt090
		WHERE n90_compania = n30_compania) / n00_dias_vacac) +
		((NVL((SELECT SUM(n32_tot_gan)
			FROM tmp_rol
			WHERE n32_compania     = n30_compania
			  AND n32_cod_liqrol  IN("Q1", "Q2")
			  AND n32_fecha_ini   >=
				MDY(MONTH(n30_fecha_ing),
				(CASE WHEN DAY(n30_fecha_ing) >= 1
					AND DAY(n30_fecha_ing) <= 15
				THEN 1 ELSE 16 END), anio - 1)
			  AND n32_fecha_fin   <=
				MDY(MONTH(n30_fecha_ing),
				(CASE WHEN DAY(n30_fecha_ing) >= 1
					AND DAY(n30_fecha_ing) <= 15
				THEN 1 ELSE 16 END), anio) - 1 UNITS DAY
			  AND n32_cod_trab     = n30_cod_trab
			  AND n32_ano_proceso >=
				(SELECT n90_anio_ini_vac FROM rolt090
					WHERE n90_compania = n30_compania)
			  AND n32_estado      <> "E"), 0) /
		((SELECT n90_dias_ano_vac FROM rolt090
		WHERE n90_compania = n30_compania) / n00_dias_vacac)) /
		n00_dias_vacac) *
	(CASE WHEN (MDY(MONTH(n30_fecha_ing), DAY(n30_fecha_ing), anio))
		>= (n30_fecha_ing + (n00_ano_adi_vac - 1) UNITS YEAR
			- 1 UNITS DAY)
		THEN CASE WHEN (n00_dias_vacac +
			((YEAR(MDY(MONTH(n30_fecha_ing), DAY(n30_fecha_ing),
			anio)) - YEAR(n30_fecha_ing + (n00_ano_adi_vac
			- 1) UNITS YEAR - 1 UNITS DAY)) * n00_dias_adi_va)) >
			n00_max_vacac
			THEN n00_max_vacac - n00_dias_vacac
			ELSE ((YEAR(MDY(MONTH(n30_fecha_ing),DAY(n30_fecha_ing),
				anio)) - YEAR(n30_fecha_ing +
				(n00_ano_adi_vac - 1) UNITS YEAR
				- 1 UNITS DAY)) * n00_dias_adi_va)
			END
		ELSE 0
		END), 2) v_vac
	FROM tmp_n32, tmp_n30, rolt000
	WHERE n30_compania  = cia
	  AND n30_cod_trab  = cod_trab
	  AND NOT EXISTS
		(SELECT 1 FROM rolt039
		WHERE n39_compania     = n30_compania
		  AND n39_proceso     IN ("VA", "VP")
		  AND n39_cod_trab     = n30_cod_trab
		  AND n39_periodo_ini >= MDY(MONTH(n30_fecha_ing),
						DAY(n30_fecha_ing), anio - 1)
		  AND n39_periodo_fin <= MDY(MONTH(n30_fecha_ing),
					DAY(n30_fecha_ing), anio) - 1 UNITS DAY)
	  AND n00_serial    = n30_compania
	INTO TEMP t1;
DROP TABLE tmp_rol;
DELETE FROM t1 WHERE v_vac <= 0;
select count(*) tot_t1_ant from t1;
INSERT INTO t1
	SELECT n30_cod_trab cod_t, n30_nombres nom, n39_perini_real p_ini,
		n39_perfin_real p_fin, (n39_dias_vac + n39_dias_adi) d_vac,
		ROUND(n39_valor_vaca, 2) v_vac
	FROM tmp_n32, tmp_n30, rolt039
	WHERE n30_compania     = cia
	  AND n30_cod_trab     = cod_trab
	  AND n39_compania     = n30_compania
	  AND n39_proceso     IN ("VA", "VP")
	  AND n39_cod_trab     = n30_cod_trab
	  AND n39_periodo_ini >= MDY(MONTH(n30_fecha_ing), DAY(n30_fecha_ing),
					anio - 1)
	  AND n39_periodo_fin <= MDY(MONTH(n30_fecha_ing), DAY(n30_fecha_ing),
					anio) - 1 UNITS DAY
	  AND n39_estado       = "A";
DROP TABLE tmp_n32;
DROP TABLE tmp_n30;
select count(*) tot_t1_des from t1;
select cod_t, nom, p_ini, p_fin, d_vac, v_vac,
	round((v_vac * 9.35 / 100), 2) v_apo,
	round(v_vac - (v_vac * 9.35 / 100), 2) v_net
	from t1
	order by 2, 4;
--select * from t1 where cod_t in (99, 116, 117, 125) order by 2, 4;
DROP TABLE t1;
