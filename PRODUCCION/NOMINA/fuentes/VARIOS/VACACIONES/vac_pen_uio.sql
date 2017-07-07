SELECT UNIQUE n32_compania cia, n32_cod_trab cod_trab, n32_ano_proceso anio
	FROM rolt090, rolt032
	WHERE n90_compania     = 1
	  AND n32_compania     = n90_compania
	  AND n32_cod_liqrol  IN ("Q1", "Q2")
	  AND n32_ano_proceso  > n90_anio_ini_vac
	INTO TEMP tmp_n32;

SELECT n30_compania, n30_cod_trab, n30_nombres, n30_cod_depto,
	CASE WHEN EXTEND(n30_fecha_ing, MONTH TO DAY) = "02-29"
		THEN MDY(MONTH(n30_fecha_ing), 28, YEAR(n30_fecha_ing))
		ELSE n30_fecha_ing
	END n30_fecha_ing
	FROM rolt030
	WHERE n30_compania  = 1
	  AND n30_estado    = "A"
	  AND n30_tipo_trab = "N"
	INTO TEMP tmp_n30;

CREATE PROCEDURE dia_mes (fecha DATE) RETURNING INT;
	DEFINE dia		INT;

	IF EXTEND(fecha, MONTH TO DAY) = "02-29" THEN
		IF MOD(YEAR(TODAY), 4) = 0 THEN
			RETURN 29;
		ELSE
			RETURN 28;
		END IF;
	END IF;

	LET dia = DAY(fecha);

	RETURN dia;

END PROCEDURE;

SELECT n30_cod_trab cod_t, n30_nombres nom,
	MDY(MONTH(n30_fecha_ing), dia_mes(n30_fecha_ing), anio - 1)
		- 1 UNITS DAY + 1 UNITS DAY p_ini,
	MDY(MONTH(n30_fecha_ing), dia_mes(n30_fecha_ing), anio)
		- 1 UNITS DAY p_fin,
	n00_dias_vacac d_vac,
	CASE WHEN (MDY(MONTH(n30_fecha_ing), dia_mes(n30_fecha_ing), anio))
		>= (n30_fecha_ing + (n00_ano_adi_vac - 1) UNITS YEAR
			- 1 UNITS DAY)
		THEN CASE WHEN (n00_dias_vacac +
			((YEAR(MDY(MONTH(n30_fecha_ing), dia_mes(n30_fecha_ing),
			anio)) - YEAR(n30_fecha_ing + (n00_ano_adi_vac
			- 1) UNITS YEAR - 1 UNITS DAY)) * n00_dias_adi_va)) >
			n00_max_vacac
			THEN n00_max_vacac - n00_dias_vacac
			ELSE ((YEAR(MDY(MONTH(n30_fecha_ing),
				dia_mes(n30_fecha_ing),
				anio)) - YEAR(n30_fecha_ing +
				(n00_ano_adi_vac - 1) UNITS YEAR
				- 1 UNITS DAY)) * n00_dias_adi_va)
			END
		ELSE 0
	END d_adi,
	ROUND(NVL((SELECT SUM(n32_tot_gan)
			FROM rolt032
			WHERE n32_compania     = n30_compania
			  AND n32_cod_liqrol  IN("Q1", "Q2")
			  AND n32_fecha_ini   >= 
				MDY(MONTH(n30_fecha_ing),
				(CASE WHEN dia_mes(n30_fecha_ing) >= 1
					AND dia_mes(n30_fecha_ing) <= 15
				THEN 1 ELSE 16 END), anio - 1)
			  AND n32_fecha_fin   <=
				MDY(MONTH(n30_fecha_ing),
				(CASE WHEN dia_mes(n30_fecha_ing) >= 1
					AND dia_mes(n30_fecha_ing) <= 15
				THEN 1 ELSE 16 END), anio) - 1 UNITS DAY
			  AND n32_cod_trab     = n30_cod_trab
			  AND n32_ano_proceso >=
				(SELECT n90_anio_ini_vac FROM rolt090
					WHERE n90_compania = n30_compania)
			  AND n32_estado      <> "E"), 0) /
		((SELECT n90_dias_ano_vac FROM rolt090
		WHERE n90_compania = n30_compania) / n00_dias_vacac), 2) v_vac,
	ROUND(((NVL((SELECT SUM(n32_tot_gan)
			FROM rolt032
			WHERE n32_compania     = n30_compania
			  AND n32_cod_liqrol  IN("Q1", "Q2")
			  AND n32_fecha_ini   >=
				MDY(MONTH(n30_fecha_ing),
				(CASE WHEN dia_mes(n30_fecha_ing) >= 1
					AND dia_mes(n30_fecha_ing) <= 15
				THEN 1 ELSE 16 END), anio - 1)
			  AND n32_fecha_fin   <=
				MDY(MONTH(n30_fecha_ing),
				(CASE WHEN dia_mes(n30_fecha_ing) >= 1
					AND dia_mes(n30_fecha_ing) <= 15
				THEN 1 ELSE 16 END), anio) - 1 UNITS DAY
			  AND n32_cod_trab     = n30_cod_trab
			  AND n32_ano_proceso >=
				(SELECT n90_anio_ini_vac FROM rolt090
					WHERE n90_compania = n30_compania)
			  AND n32_estado      <> "E"), 0) /
		((SELECT n90_dias_ano_vac FROM rolt090
		WHERE n90_compania = n30_compania) / n00_dias_vacac)) /
		n00_dias_vacac) *
	(CASE WHEN (MDY(MONTH(n30_fecha_ing), dia_mes(n30_fecha_ing), anio))
		>= (n30_fecha_ing + (n00_ano_adi_vac - 1) UNITS YEAR
			- 1 UNITS DAY)
		THEN CASE WHEN (n00_dias_vacac +
			((YEAR(MDY(MONTH(n30_fecha_ing), dia_mes(n30_fecha_ing),
			anio)) - YEAR(n30_fecha_ing + (n00_ano_adi_vac
			- 1) UNITS YEAR - 1 UNITS DAY)) * n00_dias_adi_va)) >
			n00_max_vacac
			THEN n00_max_vacac - n00_dias_vacac
			ELSE ((YEAR(MDY(MONTH(n30_fecha_ing),
				dia_mes(n30_fecha_ing),
				anio)) - YEAR(n30_fecha_ing +
				(n00_ano_adi_vac - 1) UNITS YEAR
				- 1 UNITS DAY)) * n00_dias_adi_va)
			END
		ELSE 0
		END), 2) v_adi, n30_cod_depto dp, n30_fecha_ing fec_ing,
	ROUND(NVL((SELECT SUM(n32_tot_gan)
			FROM rolt032
			WHERE n32_compania     = n30_compania
			  AND n32_cod_liqrol  IN("Q1", "Q2")
			  AND n32_fecha_ini   >= 
				MDY(MONTH(n30_fecha_ing),
				(CASE WHEN dia_mes(n30_fecha_ing) >= 1
					AND dia_mes(n30_fecha_ing) <= 15
				THEN 1 ELSE 16 END), anio - 1)
			  AND n32_fecha_fin   <=
				MDY(MONTH(n30_fecha_ing),
				(CASE WHEN dia_mes(n30_fecha_ing) >= 1
					AND dia_mes(n30_fecha_ing) <= 15
				THEN 1 ELSE 16 END), anio) - 1 UNITS DAY
			  AND n32_cod_trab     = n30_cod_trab
			  AND n32_ano_proceso >=
				(SELECT n90_anio_ini_vac FROM rolt090
					WHERE n90_compania = n30_compania)
			  AND n32_estado      <> "E"), 0), 2) tot_gan
	FROM tmp_n32, tmp_n30, rolt000
	WHERE n30_compania  = cia
	  AND n30_cod_trab  = cod_trab
	  AND MDY(MONTH(n30_fecha_ing),
		(CASE WHEN dia_mes(n30_fecha_ing) >= 1 AND
			dia_mes(n30_fecha_ing) <= 15
			THEN 1 ELSE 16 END),
		anio) - 1 UNITS DAY <= NVL((SELECT MAX(n32_fecha_fin)
					FROM rolt032
					WHERE n32_compania    = n30_compania
					  AND n32_cod_liqrol IN ("Q1", "Q2")
					  AND n32_cod_trab    = n30_cod_trab
					  AND n32_estado     <> "E"), TODAY)
	  AND NOT EXISTS
		(SELECT * FROM rolt039
		WHERE n39_compania     = n30_compania
		  AND n39_proceso     IN ("VA", "VP")
		  AND n39_cod_trab     = n30_cod_trab
		  AND n39_periodo_ini >= MDY(MONTH(n30_fecha_ing),
					dia_mes(n30_fecha_ing), anio - 1)
		  AND n39_periodo_fin <= MDY(MONTH(n30_fecha_ing),
					dia_mes(n30_fecha_ing), anio)
					- 1 UNITS DAY)
	  AND n00_serial    = n30_compania
	INTO TEMP t1;

DELETE FROM t1 WHERE v_vac <= 0;

select count(*) tot_t1_ant from t1;

INSERT INTO t1
	SELECT n30_cod_trab cod_t, n30_nombres nom, n39_perini_real p_ini,
		n39_perfin_real p_fin, n39_dias_vac d_vac, n39_dias_adi d_adi,
		ROUND(n39_valor_vaca, 2) v_vac, ROUND(n39_valor_adic, 2) v_adi,
		n39_cod_depto, n39_fecha_ing, n39_tot_ganado
	FROM tmp_n32, tmp_n30, rolt039
	WHERE n30_compania     = cia
	  AND n30_cod_trab     = cod_trab
	  AND n39_compania     = n30_compania
	  AND n39_proceso     IN ("VA", "VP")
	  AND n39_cod_trab     = n30_cod_trab
	  AND n39_periodo_ini >= MDY(MONTH(n30_fecha_ing),
					dia_mes(n30_fecha_ing), anio - 1)
	  AND n39_periodo_fin <= MDY(MONTH(n30_fecha_ing),
					dia_mes(n30_fecha_ing),	anio)
					- 1 UNITS DAY
	  AND n39_estado       = "A";

DROP TABLE tmp_n32;

DROP TABLE tmp_n30;

select count(*) tot_t1_des from t1;
--select * from t1 order by 2, 4;
UNLOAD TO "empleados_vac_uio.unl"
	SELECT 1 cia, "VA" proc, cod_t, nom, p_ini, p_fin, MDY(MONTH(p_ini),
		CASE WHEN DAY(p_ini) <= 15 THEN 1 ELSE 16 END, YEAR(p_ini))
		fec_ini_re,
		MDY(MONTH(p_fin), CASE WHEN DAY(p_fin) > 15 THEN
		DAY(MDY(MONTH(p_fin), 01, YEAR(p_fin)) + 1 UNITS MONTH
		- 1 UNITS DAY) ELSE 15 END, YEAR(p_fin)) fec_fin_re,
		'G' tipo, 'P' est, dp, YEAR(p_fin) ano_pro, MONTH(p_fin)
		mes_pro, fec_ing, d_vac, d_adi, 0 d_g, '' fec_ini_v,
		'' fec_fin_v, 'DO' mo, 1.00 par, tot_gan, v_vac, v_adi,
		0.00 ot_i, round((((v_vac + v_adi) * 9.35) / 100), 2) iess,
		0.00 ot_e, round((round(v_vac, 2) + round(v_adi, 2)
		- round((((v_vac + v_adi) * 9.35) / 100), 2)), 2) neto,
		'E' pago, '' bco, '' cta, '' cta_t, 'S' goza, 'FOBOS' usua,
		current fec_i
	FROM t1
	ORDER BY nom, p_fin;

DROP TABLE t1;

DROP PROCEDURE dia_mes;