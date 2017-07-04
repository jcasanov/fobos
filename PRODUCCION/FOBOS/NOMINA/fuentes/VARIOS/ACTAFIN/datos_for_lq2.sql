SELECT (TRIM(n30_num_doc_id) || " " || TRIM(n30_nombres)) AS identificacion,
	g01_razonsocial AS nombre_empresa,
	TRIM(n30_nombres) AS empleado,
	TRIM(n30_num_doc_id) AS cedula,
	NVL(n30_fecha_reing, n30_fecha_ing) AS fecha_ing,
	TODAY AS fecha_sal,
	n30_sueldo_mes AS sueldo,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032
		WHERE n32_compania = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
			(SELECT EXTEND(MAX(a.n32_fecha_fin), YEAR TO MONTH)
				FROM rolt032 a
				WHERE a.n32_compania   = n32_compania
				  AND a.n32_cod_liqrol = 'Q2'
				  AND a.n32_cod_trab   = n32_cod_trab)
		  AND n32_cod_trab = n30_cod_trab),
	n30_sueldo_mes) AS sueldo_prom,
	CASE WHEN (SELECT NVL(SUM(n33_valor), 0)
			FROM rolt032, rolt033
			WHERE n32_compania     = n30_compania
			  AND n32_ano_proceso  = n01_ano_proceso
			  AND n32_cod_trab     = n30_cod_trab
			  AND n33_compania     = n32_compania
			  AND n33_cod_liqrol   = n32_cod_liqrol
			  AND n33_fecha_ini    = n32_fecha_ini
			  AND n33_fecha_fin    = n32_fecha_fin
			  AND n33_cod_trab     = n32_cod_trab
			  AND n33_cod_rubro   IN
				(SELECT n08_cod_rubro
					FROM rolt008, rolt006
					WHERE n06_cod_rubro   = n08_cod_rubro
					  AND n06_flag_ident IN ('V1', 'V5'))
			  AND n33_valor        > 0) > 0
		THEN "SI"
		ELSE "NO"
	END AS sobre_t,
	CASE WHEN (SELECT NVL(SUM(n33_valor), 0)
			FROM rolt032, rolt033
			WHERE n32_compania     = n30_compania
			  AND n32_ano_proceso  = n01_ano_proceso
			  AND n32_cod_trab     = n30_cod_trab
			  AND n33_compania     = n32_compania
			  AND n33_cod_liqrol   = n32_cod_liqrol
			  AND n33_fecha_ini    = n32_fecha_ini
			  AND n33_fecha_fin    = n32_fecha_fin
			  AND n33_cod_trab     = n32_cod_trab
			  AND n33_cod_rubro   IN
				(SELECT n08_rubro_base
					FROM rolt008, rolt006
					WHERE n06_cod_rubro   = n08_rubro_base
					  AND n06_flag_ident IN ('CO', 'C1',
								'C2', 'C3'))
			  AND n33_valor        > 0) > 0
		THEN "SI"
		ELSE "NO"
	END AS comision,
	NVL((SELECT SUM(n10_valor)
		FROM rolt010
		WHERE n10_compania   = n30_compania
		  AND n10_cod_rubro  = (SELECT n06_cod_rubro
					FROM rolt006
					WHERE n06_flag_ident = 'MO')
		  AND n10_cod_trab   = n30_cod_trab), 0) AS movil,
	CASE WHEN ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) >
			(SELECT n90_dias_anio
				FROM rolt090
				WHERE n90_compania = n30_compania)
		THEN CASE WHEN n30_fon_res_anio = 'S'
			THEN "IESS"
			ELSE "ROL DE PAGO"
		     END
		ELSE "NO"
	END AS fr_iess,
	CASE WHEN ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) >
			(SELECT n90_dias_anio
				FROM rolt090
				WHERE n90_compania = n30_compania)
		THEN ROUND(NVL(CASE WHEN
			((SELECT UNIQUE n32_cod_liqrol
				FROM rolt032
				WHERE n32_compania  = n30_compania
				  AND n32_fecha_fin =
					(SELECT MAX(a.n32_fecha_fin)
					FROM rolt032 a
					WHERE a.n32_compania = n32_compania))
					= 'Q1' AND DAY(TODAY) <= 15)
				THEN (SELECT SUM(n32_tot_gan)
					FROM rolt032
					WHERE n32_compania   = n30_compania
					  AND EXTEND(n32_fecha_fin,
							YEAR TO MONTH) =
						(SELECT EXTEND(
							MAX(a.n32_fecha_fin),
							YEAR TO MONTH)
							- 1 UNITS MONTH
						FROM rolt032 a
						WHERE a.n32_compania =
							n32_compania)
					  AND n32_cod_trab   = n30_cod_trab)
				ELSE (SELECT SUM(n32_tot_gan)
					FROM rolt032
					WHERE n32_compania   = n30_compania
					  AND EXTEND(n32_fecha_fin,
							YEAR TO MONTH) =
						(SELECT EXTEND(
							MAX(a.n32_fecha_fin),
							YEAR TO MONTH)
						FROM rolt032 a
						WHERE a.n32_compania =
							n32_compania)
					  AND n32_cod_trab   = n30_cod_trab)
			END, 0), 2)
		ELSE 0.00
	END AS base_fr,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032, rolt003
		WHERE n03_proceso    = 'DT'
		  AND n32_compania   = n30_compania
		  AND n32_fecha_ini >= MDY(n03_mes_ini, 01,n01_ano_proceso - 1)
		  AND n32_fecha_fin <= MDY(n03_mes_fin, 01, n01_ano_proceso)
					+ 1 UNITS MONTH - 1 UNITS DAY
		  AND n32_cod_trab   = n30_cod_trab), 0) AS base_DT,
	NVL((SELECT n03_valor
		FROM rolt003
		WHERE n03_proceso = 'DC'), 0) AS base_DC,
	NVL((SELECT SUM(n10_valor)
		FROM rolt010
		WHERE n10_compania   = n30_compania
		  AND n10_cod_rubro IN (54, 62)
		  AND n10_cod_trab   = n30_cod_trab
		  AND n10_fecha_ini <= TODAY
		  AND n10_fecha_fin >= TODAY), 0) AS prest_iess,
	(NVL((SELECT NVL(SUM(n33_valor), 0)
		FROM rolt032, rolt033
		WHERE n32_compania     = n30_compania
		  AND n32_ano_proceso  = n01_ano_proceso
		  AND n32_cod_trab     = n30_cod_trab
		  AND n33_compania     = n32_compania
		  AND n33_cod_liqrol   = n32_cod_liqrol
		  AND n33_fecha_ini    = n32_fecha_ini
		  AND n33_fecha_fin    = n32_fecha_fin
		  AND n33_cod_trab     = n32_cod_trab
		  AND n33_cod_rubro   IN (51, 69)
		  AND n33_valor        > 0), 0)
		/ n01_mes_proceso) AS comisariato,
	NVL((SELECT SUM(n45_val_prest + n45_valor_int + n45_sal_prest_ant
			- n45_descontado)
		FROM rolt045
		WHERE n45_compania  = n30_compania
		  AND n45_cod_trab  = n30_cod_trab
		  AND n45_estado   IN ("A", "R")
		  AND (n45_val_prest + n45_valor_int + n45_sal_prest_ant
			- n45_descontado) > 0), 0) AS saldo_ant,
	NVL(CASE WHEN (SELECT COUNT(*)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 1)
			  AND n32_fecha_ini <= TODAY
			  AND n32_cod_trab   = n30_cod_trab) <= 24 THEN
		CASE WHEN (DAY(NVL(n30_fecha_reing, n30_fecha_ing)) > 1 AND
			DAY(NVL(n30_fecha_reing, n30_fecha_ing)) <= 15)
		THEN (SELECT (n32_tot_gan / 15) *
				(16 - DAY(NVL(n30_fecha_reing, n30_fecha_ing)))
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_cod_liqrol = 'Q1'
			  AND EXTEND(n32_fecha_ini, YEAR TO MONTH) =
					EXTEND(DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 1),
						YEAR TO MONTH)
			  AND n32_cod_trab    = n30_cod_trab)
	     WHEN DAY(NVL(n30_fecha_reing, n30_fecha_ing)) > 16
		THEN (SELECT (n32_tot_gan / 15) *
				(DAY(MDY(MONTH(NVL(n30_fecha_reing,
						n30_fecha_ing)), 01,
						YEAR(TODAY) - 1)
					+ 1 UNITS MONTH - 1 UNITS DAY)
				- DAY(NVL(n30_fecha_reing, n30_fecha_ing)) + 1)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_cod_liqrol = 'Q2'
			  AND EXTEND(n32_fecha_ini, YEAR TO MONTH) =
					EXTEND(DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 1),
						YEAR TO MONTH)
			  AND n32_cod_trab    = n30_cod_trab)
		END
	ELSE
		CASE WHEN (DAY(NVL(n30_fecha_reing, n30_fecha_ing)) > 1 AND
			DAY(NVL(n30_fecha_reing, n30_fecha_ing)) <= 15)
		THEN (SELECT (n32_tot_gan / 15) *
				(16 - DAY(NVL(n30_fecha_reing, n30_fecha_ing)))
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_cod_liqrol = 'Q1'
			  AND EXTEND(n32_fecha_ini, YEAR TO MONTH) =
					EXTEND(DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY)),
						YEAR TO MONTH)
			  AND n32_cod_trab    = n30_cod_trab)
	     WHEN DAY(NVL(n30_fecha_reing, n30_fecha_ing)) > 16
		THEN (SELECT (n32_tot_gan / 15) *
				(DAY(MDY(MONTH(NVL(n30_fecha_reing,
						n30_fecha_ing)), 01,
						YEAR(TODAY))
					+ 1 UNITS MONTH - 1 UNITS DAY)
				- DAY(NVL(n30_fecha_reing, n30_fecha_ing)) + 1)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_cod_liqrol = 'Q2'
			  AND EXTEND(n32_fecha_ini, YEAR TO MONTH) =
					EXTEND(DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY)),
						YEAR TO MONTH)
			  AND n32_cod_trab    = n30_cod_trab)
		END
	END, 0) +
	NVL(CASE WHEN (SELECT COUNT(*)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 1)
			  AND n32_fecha_ini <= TODAY
			  AND n32_cod_trab   = n30_cod_trab) <= 24
		THEN (SELECT SUM(n32_tot_gan)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 1)
			  AND n32_fecha_ini <= TODAY
			  AND n32_cod_trab   = n30_cod_trab)
		ELSE (SELECT SUM(n32_tot_gan)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY))
			  AND n32_fecha_ini <= TODAY
			  AND n32_cod_trab   = n30_cod_trab)
	END, 0) AS base_vac,
	CASE WHEN n30_estado = 'A' THEN "ACTIVO"
	     WHEN n30_estado = 'I' THEN "INACTIVO"
	     WHEN n30_estado = 'J' THEN "JUBILADO"
	END AS estado,
	g01_replegal AS patrono,
	NVL(CASE WHEN ((SELECT COUNT(*)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 1)
			  AND n32_fecha_ini <= TODAY
			  AND n32_cod_trab   = n30_cod_trab) > 24) AND
			((SELECT COUNT(*)
				FROM rolt039
				WHERE n39_compania    = n30_compania
				  AND n39_cod_trab    = n30_cod_trab
				  AND n39_ano_proceso = YEAR(TODAY)) = 0)
		THEN (SELECT SUM(n32_tot_gan)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 1)
			  AND n32_fecha_fin <= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY)) -
						1 UNITS DAY
			  AND n32_cod_trab   = n30_cod_trab)
	END,
	NVL(CASE WHEN ((SELECT COUNT(*)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 2)
			  AND n32_fecha_ini <= TODAY
			  AND n32_cod_trab   = n30_cod_trab) > 24) AND
			((SELECT COUNT(*)
				FROM rolt039
				WHERE n39_compania    = n30_compania
				  AND n39_cod_trab    = n30_cod_trab
				  AND n39_ano_proceso = YEAR(TODAY) - 1) = 0)
		THEN (SELECT SUM(n32_tot_gan)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 2)
			  AND n32_fecha_fin <= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 1) -
						1 UNITS DAY
			  AND n32_cod_trab   = n30_cod_trab)
	END, 0)) AS base_vac1,
	NVL(CASE WHEN NVL(CASE WHEN ((SELECT COUNT(*)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 1)
			  AND n32_fecha_ini <= TODAY
			  AND n32_cod_trab   = n30_cod_trab) > 24) AND
			((SELECT COUNT(*)
				FROM rolt039
				WHERE n39_compania    = n30_compania
				  AND n39_cod_trab    = n30_cod_trab
				  AND n39_ano_proceso = YEAR(TODAY)) = 0)
		THEN (SELECT SUM(n32_tot_gan)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 1)
			  AND n32_fecha_fin <= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY)) -
						1 UNITS DAY
			  AND n32_cod_trab   = n30_cod_trab)
	END, 0) > 0 THEN
	CASE WHEN ((SELECT COUNT(*)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 2)
			  AND n32_fecha_ini <= TODAY
			  AND n32_cod_trab   = n30_cod_trab) > 24) AND
			((SELECT COUNT(*)
				FROM rolt039
				WHERE n39_compania    = n30_compania
				  AND n39_cod_trab    = n30_cod_trab
				  AND n39_ano_proceso = YEAR(TODAY) - 1) = 0)
		THEN (SELECT SUM(n32_tot_gan)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 2)
			  AND n32_fecha_fin <= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 1) -
						1 UNITS DAY
			  AND n32_cod_trab   = n30_cod_trab)
		END
	END, 0) AS base_vac2,
	NVL(CASE WHEN ((SELECT COUNT(*)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 3)
			  AND n32_fecha_ini <= TODAY
			  AND n32_cod_trab   = n30_cod_trab) > 24) AND
			((SELECT COUNT(*)
				FROM rolt039
				WHERE n39_compania    = n30_compania
				  AND n39_cod_trab    = n30_cod_trab
				  AND n39_ano_proceso = YEAR(TODAY) - 2) = 0)
		THEN (SELECT SUM(n32_tot_gan)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 3)
			  AND n32_fecha_fin <= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 2) -
						1 UNITS DAY
			  AND n32_cod_trab   = n30_cod_trab)
	END, 0) AS base_vac3,
	n30_tipo_trab AS tipo_trab,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032, rolt003
		WHERE n03_proceso    = 'DT'
		  AND n32_compania   = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
			EXTEND(MDY(n03_mes_ini, 01, n01_ano_proceso - 1),
				YEAR TO MONTH)
		  AND n32_cod_trab   = n30_cod_trab), 0) AS base_DT_01,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032, rolt003
		WHERE n03_proceso    = 'DT'
		  AND n32_compania   = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
		  	EXTEND(MDY(n03_mes_ini, 01, n01_ano_proceso - 1)
				+ 1 UNITS MONTH,
				YEAR TO MONTH)
		  AND n32_cod_trab   = n30_cod_trab), 0) AS base_DT_02,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032, rolt003
		WHERE n03_proceso    = 'DT'
		  AND n32_compania   = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
		  	EXTEND(MDY(n03_mes_ini, 01, n01_ano_proceso - 1)
				+ 2 UNITS MONTH,
				YEAR TO MONTH)
		  AND n32_cod_trab   = n30_cod_trab), 0) AS base_DT_03,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032, rolt003
		WHERE n03_proceso    = 'DT'
		  AND n32_compania   = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
		  	EXTEND(MDY(n03_mes_ini, 01, n01_ano_proceso - 1)
				+ 3 UNITS MONTH,
				YEAR TO MONTH)
		  AND n32_cod_trab   = n30_cod_trab), 0) AS base_DT_04,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032, rolt003
		WHERE n03_proceso    = 'DT'
		  AND n32_compania   = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
		  	EXTEND(MDY(n03_mes_ini, 01, n01_ano_proceso - 1)
				+ 4 UNITS MONTH,
				YEAR TO MONTH)
		  AND n32_cod_trab   = n30_cod_trab), 0) AS base_DT_05,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032, rolt003
		WHERE n03_proceso    = 'DT'
		  AND n32_compania   = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
		  	EXTEND(MDY(n03_mes_ini, 01, n01_ano_proceso - 1)
				+ 5 UNITS MONTH,
				YEAR TO MONTH)
		  AND n32_cod_trab   = n30_cod_trab), 0) AS base_DT_06,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032, rolt003
		WHERE n03_proceso    = 'DT'
		  AND n32_compania   = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
		  	EXTEND(MDY(n03_mes_ini, 01, n01_ano_proceso - 1)
				+ 6 UNITS MONTH,
				YEAR TO MONTH)
		  AND n32_cod_trab   = n30_cod_trab), 0) AS base_DT_07,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032, rolt003
		WHERE n03_proceso    = 'DT'
		  AND n32_compania   = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
		  	EXTEND(MDY(n03_mes_ini, 01, n01_ano_proceso - 1)
				+ 7 UNITS MONTH,
				YEAR TO MONTH)
		  AND n32_cod_trab   = n30_cod_trab), 0) AS base_DT_08,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032, rolt003
		WHERE n03_proceso    = 'DT'
		  AND n32_compania   = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
		  	EXTEND(MDY(n03_mes_ini, 01, n01_ano_proceso - 1)
				+ 8 UNITS MONTH,
				YEAR TO MONTH)
		  AND n32_cod_trab   = n30_cod_trab), 0) AS base_DT_09,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032, rolt003
		WHERE n03_proceso    = 'DT'
		  AND n32_compania   = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
		  	EXTEND(MDY(n03_mes_ini, 01, n01_ano_proceso - 1)
				+ 9 UNITS MONTH,
				YEAR TO MONTH)
		  AND n32_cod_trab   = n30_cod_trab), 0) AS base_DT_10,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032, rolt003
		WHERE n03_proceso    = 'DT'
		  AND n32_compania   = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
		  	EXTEND(MDY(n03_mes_ini, 01, n01_ano_proceso - 1)
				+ 10 UNITS MONTH,
				YEAR TO MONTH)
		  AND n32_cod_trab   = n30_cod_trab), 0) AS base_DT_11,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032, rolt003
		WHERE n03_proceso    = 'DT'
		  AND n32_compania   = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
		  	EXTEND(MDY(n03_mes_ini, 01, n01_ano_proceso - 1)
				+ 11 UNITS MONTH,
				YEAR TO MONTH)
		  AND n32_cod_trab   = n30_cod_trab), 0) AS base_DT_12,
	n30_fecha_nacim AS fecha_nacim,
	(SELECT n17_descripcion
		FROM rolt017
		WHERE n17_compania  = n30_compania
		  AND n17_ano_sect  = n30_ano_sect
		  AND n17_sectorial = n30_sectorial) AS cargo
	FROM rolt030, rolt001, gent001
	WHERE n30_compania = 1
	  AND n30_estado   = 'A'
	  AND EXTEND(n30_fecha_ing, MONTH TO DAY) <> '02-29'
	  AND g01_compania = n30_compania
	  AND g01_compania = n01_compania
UNION
SELECT (TRIM(n30_num_doc_id) || " " || TRIM(n30_nombres)) AS identificacion,
	g01_razonsocial AS nombre_empresa,
	TRIM(n30_nombres) AS empleado,
	TRIM(n30_num_doc_id) AS cedula,
	NVL(n30_fecha_reing, n30_fecha_ing) AS fecha_ing,
	NVL(n30_fecha_sal, TODAY) AS fecha_sal,
	n30_sueldo_mes AS sueldo,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032
		WHERE n32_compania = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
			(SELECT EXTEND(MAX(a.n32_fecha_fin), YEAR TO MONTH)
				FROM rolt032 a
				WHERE a.n32_compania   = n32_compania
				  AND a.n32_cod_liqrol = 'Q2'
				  AND a.n32_cod_trab   = n32_cod_trab)
		  AND n32_cod_trab = n30_cod_trab),
	n30_sueldo_mes) AS sueldo_prom,
	CASE WHEN (SELECT NVL(SUM(n33_valor), 0)
			FROM rolt032, rolt033
			WHERE n32_compania     = n30_compania
			  AND n32_ano_proceso  = n01_ano_proceso
			  AND n32_cod_trab     = n30_cod_trab
			  AND n33_compania     = n32_compania
			  AND n33_cod_liqrol   = n32_cod_liqrol
			  AND n33_fecha_ini    = n32_fecha_ini
			  AND n33_fecha_fin    = n32_fecha_fin
			  AND n33_cod_trab     = n32_cod_trab
			  AND n33_cod_rubro IN
				(SELECT n08_cod_rubro
					FROM rolt008, rolt006
					WHERE n06_cod_rubro   = n08_cod_rubro
					  AND n06_flag_ident IN ('V1', 'V5'))
			  AND n33_valor    > 0) > 0
		THEN "SI"
		ELSE "NO"
	END AS sobre_t,
	CASE WHEN (SELECT NVL(SUM(n33_valor), 0)
			FROM rolt032, rolt033
			WHERE n32_compania     = n30_compania
			  AND n32_ano_proceso  = n01_ano_proceso
			  AND n32_cod_trab     = n30_cod_trab
			  AND n33_compania     = n32_compania
			  AND n33_cod_liqrol   = n32_cod_liqrol
			  AND n33_fecha_ini    = n32_fecha_ini
			  AND n33_fecha_fin    = n32_fecha_fin
			  AND n33_cod_trab     = n32_cod_trab
			  AND n33_cod_rubro   IN
				(SELECT n08_rubro_base
					FROM rolt008, rolt006
					WHERE n06_cod_rubro   = n08_rubro_base
					  AND n06_flag_ident IN ('CO', 'C1',
								'C2', 'C3'))
			  AND n33_valor    > 0) > 0
		THEN "SI"
		ELSE "NO"
	END AS comision,
	NVL((SELECT SUM(n10_valor)
		FROM rolt010
		WHERE n10_compania   = n30_compania
		  AND n10_cod_rubro  = (SELECT n06_cod_rubro
					FROM rolt006
					WHERE n06_flag_ident = 'MO')
		  AND n10_cod_trab   = n30_cod_trab), 0) AS movil,
	CASE WHEN ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) >
			(SELECT n90_dias_anio
				FROM rolt090
				WHERE n90_compania = n30_compania)
		THEN CASE WHEN n30_fon_res_anio = 'S'
			THEN "IESS"
			ELSE "ROL DE PAGO"
		     END
		ELSE "NO"
	END AS fr_iess,
	CASE WHEN ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) >
			(SELECT n90_dias_anio
				FROM rolt090
				WHERE n90_compania = n30_compania)
		THEN ROUND(NVL(CASE WHEN
			((SELECT UNIQUE n32_cod_liqrol
				FROM rolt032
				WHERE n32_compania  = n30_compania
				  AND n32_fecha_fin =
					(SELECT MAX(a.n32_fecha_fin)
					FROM rolt032 a
					WHERE a.n32_compania = n32_compania))
					= 'Q1' AND DAY(TODAY) <= 15)
				THEN (SELECT SUM(n32_tot_gan)
					FROM rolt032
					WHERE n32_compania   = n30_compania
					  AND EXTEND(n32_fecha_fin,
							YEAR TO MONTH) =
						(SELECT EXTEND(
							MAX(a.n32_fecha_fin),
							YEAR TO MONTH)
							- 1 UNITS MONTH
						FROM rolt032 a
						WHERE a.n32_compania =
							n32_compania)
					  AND n32_cod_trab   = n30_cod_trab)
				ELSE (SELECT SUM(n32_tot_gan)
					FROM rolt032
					WHERE n32_compania   = n30_compania
					  AND EXTEND(n32_fecha_fin,
							YEAR TO MONTH) =
						(SELECT EXTEND(
							MAX(a.n32_fecha_fin),
							YEAR TO MONTH)
						FROM rolt032 a
						WHERE a.n32_compania =
							n32_compania)
					  AND n32_cod_trab   = n30_cod_trab)
			END, 0), 2)
		ELSE 0.00
	END AS base_fr,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032, rolt003
		WHERE n03_proceso    = 'DT'
		  AND n32_compania   = n30_compania
		  AND n32_fecha_ini >= MDY(n03_mes_ini, 01,n01_ano_proceso - 1)
		  AND n32_fecha_fin <= MDY(n03_mes_fin, 01, n01_ano_proceso)
					+ 1 UNITS MONTH - 1 UNITS DAY
		  AND n32_cod_trab   = n30_cod_trab), 0) AS base_DT,
	NVL((SELECT n03_valor
		FROM rolt003
		WHERE n03_proceso = 'DC'), 0) AS base_DC,
	NVL((SELECT SUM(n10_valor)
		FROM rolt010
		WHERE n10_compania   = n30_compania
		  AND n10_cod_rubro IN (54, 62)
		  AND n10_cod_trab   = n30_cod_trab
		  AND n10_fecha_ini <= TODAY
		  AND n10_fecha_fin >= TODAY), 0) AS prest_iess,
	(NVL((SELECT NVL(SUM(n33_valor), 0)
		FROM rolt032, rolt033
		WHERE n32_compania     = n30_compania
		  AND n32_ano_proceso  = n01_ano_proceso
		  AND n32_cod_trab     = n30_cod_trab
		  AND n33_compania     = n32_compania
		  AND n33_cod_liqrol   = n32_cod_liqrol
		  AND n33_fecha_ini    = n32_fecha_ini
		  AND n33_fecha_fin    = n32_fecha_fin
		  AND n33_cod_trab     = n32_cod_trab
		  AND n33_cod_rubro   IN (51, 69)
		  AND n33_valor        > 0), 0)
		/ n01_mes_proceso) AS comisariato,
	NVL((SELECT SUM(n45_val_prest + n45_valor_int + n45_sal_prest_ant
			- n45_descontado)
		FROM rolt045
		WHERE n45_compania  = n30_compania
		  AND n45_cod_trab  = n30_cod_trab
		  AND n45_estado   IN ("A", "R")
		  AND (n45_val_prest + n45_valor_int + n45_sal_prest_ant
			- n45_descontado) > 0), 0) AS saldo_ant,
	NVL(CASE WHEN (SELECT COUNT(*)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 1)
			  AND n32_fecha_ini <= NVL(n30_fecha_sal, TODAY)
			  AND n32_cod_trab   = n30_cod_trab) <= 24 THEN
		CASE WHEN (DAY(NVL(n30_fecha_reing, n30_fecha_ing)) > 1 AND
			DAY(NVL(n30_fecha_reing, n30_fecha_ing)) <= 15)
		THEN (SELECT (n32_tot_gan / 15) *
				(16 - DAY(NVL(n30_fecha_reing, n30_fecha_ing)))
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_cod_liqrol = 'Q1'
			  AND EXTEND(n32_fecha_ini, YEAR TO MONTH) =
					EXTEND(DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 1),
						YEAR TO MONTH)
			  AND n32_cod_trab    = n30_cod_trab)
	     WHEN DAY(NVL(n30_fecha_reing, n30_fecha_ing)) > 16
		THEN (SELECT (n32_tot_gan / 15) *
				(DAY(MDY(MONTH(NVL(n30_fecha_reing,
						n30_fecha_ing)), 01,
						YEAR(TODAY) - 1)
					+ 1 UNITS MONTH - 1 UNITS DAY)
				- DAY(NVL(n30_fecha_reing, n30_fecha_ing)) + 1)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_cod_liqrol = 'Q2'
			  AND EXTEND(n32_fecha_ini, YEAR TO MONTH) =
					EXTEND(DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 1),
						YEAR TO MONTH)
			  AND n32_cod_trab    = n30_cod_trab)
		END
	ELSE
		CASE WHEN (DAY(NVL(n30_fecha_reing, n30_fecha_ing)) > 1 AND
			DAY(NVL(n30_fecha_reing, n30_fecha_ing)) <= 15)
		THEN (SELECT (n32_tot_gan / 15) *
				(16 - DAY(NVL(n30_fecha_reing, n30_fecha_ing)))
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_cod_liqrol = 'Q1'
			  AND EXTEND(n32_fecha_ini, YEAR TO MONTH) =
					EXTEND(DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY)),
						YEAR TO MONTH)
			  AND n32_cod_trab    = n30_cod_trab)
	     WHEN DAY(NVL(n30_fecha_reing, n30_fecha_ing)) > 16
		THEN (SELECT (n32_tot_gan / 15) *
				(DAY(MDY(MONTH(NVL(n30_fecha_reing,
						n30_fecha_ing)), 01,
						YEAR(TODAY))
					+ 1 UNITS MONTH - 1 UNITS DAY)
				- DAY(NVL(n30_fecha_reing, n30_fecha_ing)) + 1)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_cod_liqrol = 'Q2'
			  AND EXTEND(n32_fecha_ini, YEAR TO MONTH) =
					EXTEND(DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY)),
						YEAR TO MONTH)
			  AND n32_cod_trab    = n30_cod_trab)
		END
	END, 0) +
	NVL(CASE WHEN (SELECT COUNT(*)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 1)
			  AND n32_fecha_ini <= NVL(n30_fecha_sal, TODAY)
			  AND n32_cod_trab   = n30_cod_trab) <= 24
		THEN (SELECT SUM(n32_tot_gan)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 1)
			  AND n32_fecha_ini <= NVL(n30_fecha_sal, TODAY)
			  AND n32_cod_trab   = n30_cod_trab)
		ELSE (SELECT SUM(n32_tot_gan)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY))
			  AND n32_fecha_ini <= NVL(n30_fecha_sal, TODAY)
			  AND n32_cod_trab   = n30_cod_trab)
	END, 0) AS base_vac,
	CASE WHEN n30_estado = 'A' THEN "ACTIVO"
	     WHEN n30_estado = 'I' THEN "INACTIVO"
	     WHEN n30_estado = 'J' THEN "JUBILADO"
	END AS estado,
	g01_replegal AS patrono,
	NVL(CASE WHEN ((SELECT COUNT(*)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 1)
			  AND n32_fecha_ini <= NVL(n30_fecha_sal, TODAY)
			  AND n32_cod_trab   = n30_cod_trab) > 24) AND
			((SELECT COUNT(*)
				FROM rolt039
				WHERE n39_compania    = n30_compania
				  AND n39_cod_trab    = n30_cod_trab
				  AND n39_ano_proceso = YEAR(TODAY)) = 0)
		THEN (SELECT SUM(n32_tot_gan)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 1)
			  AND n32_fecha_fin <= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY)) -
						1 UNITS DAY
			  AND n32_cod_trab   = n30_cod_trab)
	END,
	NVL(CASE WHEN ((SELECT COUNT(*)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 2)
			  AND n32_fecha_ini <= NVL(n30_fecha_sal, TODAY)
			  AND n32_cod_trab   = n30_cod_trab) > 24) AND
			((SELECT COUNT(*)
				FROM rolt039
				WHERE n39_compania    = n30_compania
				  AND n39_cod_trab    = n30_cod_trab
				  AND n39_ano_proceso = YEAR(TODAY) - 1) = 0)
		THEN (SELECT SUM(n32_tot_gan)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 2)
			  AND n32_fecha_fin <= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 1) -
						1 UNITS DAY
			  AND n32_cod_trab   = n30_cod_trab)
	END, 0)) AS base_vac1,
	NVL(CASE WHEN NVL(CASE WHEN ((SELECT COUNT(*)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 1)
			  AND n32_fecha_ini <= NVL(n30_fecha_sal, TODAY)
			  AND n32_cod_trab   = n30_cod_trab) > 24) AND
			((SELECT COUNT(*)
				FROM rolt039
				WHERE n39_compania    = n30_compania
				  AND n39_cod_trab    = n30_cod_trab
				  AND n39_ano_proceso = YEAR(TODAY)) = 0)
		THEN (SELECT SUM(n32_tot_gan)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 1)
			  AND n32_fecha_fin <= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY)) -
						1 UNITS DAY
			  AND n32_cod_trab   = n30_cod_trab)
	END, 0) > 0 THEN
	CASE WHEN ((SELECT COUNT(*)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 2)
			  AND n32_fecha_ini <= NVL(n30_fecha_sal, TODAY)
			  AND n32_cod_trab   = n30_cod_trab) > 24) AND
			((SELECT COUNT(*)
				FROM rolt039
				WHERE n39_compania    = n30_compania
				  AND n39_cod_trab    = n30_cod_trab
				  AND n39_ano_proceso = YEAR(TODAY) - 1) = 0)
		THEN (SELECT SUM(n32_tot_gan)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 2)
			  AND n32_fecha_fin <= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 1) -
						1 UNITS DAY
			  AND n32_cod_trab   = n30_cod_trab)
		END
	END, 0) AS base_vac2,
	NVL(CASE WHEN ((SELECT COUNT(*)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 3)
			  AND n32_fecha_ini <= NVL(n30_fecha_sal, TODAY)
			  AND n32_cod_trab   = n30_cod_trab) > 24) AND
			((SELECT COUNT(*)
				FROM rolt039
				WHERE n39_compania    = n30_compania
				  AND n39_cod_trab    = n30_cod_trab
				  AND n39_ano_proceso = YEAR(TODAY) - 2) = 0)
		THEN (SELECT SUM(n32_tot_gan)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 3)
			  AND n32_fecha_fin <= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 2) -
						1 UNITS DAY
			  AND n32_cod_trab   = n30_cod_trab)
	END, 0) AS base_vac3,
	n30_tipo_trab AS tipo_trab,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032, rolt003
		WHERE n03_proceso    = 'DT'
		  AND n32_compania   = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
			EXTEND(MDY(n03_mes_ini, 01, n01_ano_proceso - 1),
				YEAR TO MONTH)
		  AND n32_cod_trab   = n30_cod_trab), 0) AS base_DT_01,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032, rolt003
		WHERE n03_proceso    = 'DT'
		  AND n32_compania   = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
		  	EXTEND(MDY(n03_mes_ini, 01, n01_ano_proceso - 1)
				+ 1 UNITS MONTH,
				YEAR TO MONTH)
		  AND n32_cod_trab   = n30_cod_trab), 0) AS base_DT_02,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032, rolt003
		WHERE n03_proceso    = 'DT'
		  AND n32_compania   = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
		  	EXTEND(MDY(n03_mes_ini, 01, n01_ano_proceso - 1)
				+ 2 UNITS MONTH,
				YEAR TO MONTH)
		  AND n32_cod_trab   = n30_cod_trab), 0) AS base_DT_03,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032, rolt003
		WHERE n03_proceso    = 'DT'
		  AND n32_compania   = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
		  	EXTEND(MDY(n03_mes_ini, 01, n01_ano_proceso - 1)
				+ 3 UNITS MONTH,
				YEAR TO MONTH)
		  AND n32_cod_trab   = n30_cod_trab), 0) AS base_DT_04,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032, rolt003
		WHERE n03_proceso    = 'DT'
		  AND n32_compania   = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
		  	EXTEND(MDY(n03_mes_ini, 01, n01_ano_proceso - 1)
				+ 4 UNITS MONTH,
				YEAR TO MONTH)
		  AND n32_cod_trab   = n30_cod_trab), 0) AS base_DT_05,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032, rolt003
		WHERE n03_proceso    = 'DT'
		  AND n32_compania   = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
		  	EXTEND(MDY(n03_mes_ini, 01, n01_ano_proceso - 1)
				+ 5 UNITS MONTH,
				YEAR TO MONTH)
		  AND n32_cod_trab   = n30_cod_trab), 0) AS base_DT_06,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032, rolt003
		WHERE n03_proceso    = 'DT'
		  AND n32_compania   = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
		  	EXTEND(MDY(n03_mes_ini, 01, n01_ano_proceso - 1)
				+ 6 UNITS MONTH,
				YEAR TO MONTH)
		  AND n32_cod_trab   = n30_cod_trab), 0) AS base_DT_07,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032, rolt003
		WHERE n03_proceso    = 'DT'
		  AND n32_compania   = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
		  	EXTEND(MDY(n03_mes_ini, 01, n01_ano_proceso - 1)
				+ 7 UNITS MONTH,
				YEAR TO MONTH)
		  AND n32_cod_trab   = n30_cod_trab), 0) AS base_DT_08,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032, rolt003
		WHERE n03_proceso    = 'DT'
		  AND n32_compania   = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
		  	EXTEND(MDY(n03_mes_ini, 01, n01_ano_proceso - 1)
				+ 8 UNITS MONTH,
				YEAR TO MONTH)
		  AND n32_cod_trab   = n30_cod_trab), 0) AS base_DT_09,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032, rolt003
		WHERE n03_proceso    = 'DT'
		  AND n32_compania   = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
		  	EXTEND(MDY(n03_mes_ini, 01, n01_ano_proceso - 1)
				+ 9 UNITS MONTH,
				YEAR TO MONTH)
		  AND n32_cod_trab   = n30_cod_trab), 0) AS base_DT_10,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032, rolt003
		WHERE n03_proceso    = 'DT'
		  AND n32_compania   = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
		  	EXTEND(MDY(n03_mes_ini, 01, n01_ano_proceso - 1)
				+ 10 UNITS MONTH,
				YEAR TO MONTH)
		  AND n32_cod_trab   = n30_cod_trab), 0) AS base_DT_11,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032, rolt003
		WHERE n03_proceso    = 'DT'
		  AND n32_compania   = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
		  	EXTEND(MDY(n03_mes_ini, 01, n01_ano_proceso - 1)
				+ 11 UNITS MONTH,
				YEAR TO MONTH)
		  AND n32_cod_trab   = n30_cod_trab), 0) AS base_DT_12,
	n30_fecha_nacim AS fecha_nacim,
	(SELECT n17_descripcion
		FROM rolt017
		WHERE n17_compania  = n30_compania
		  AND n17_ano_sect  = n30_ano_sect
		  AND n17_sectorial = n30_sectorial) AS cargo
	FROM rolt030, rolt001, gent001
	WHERE n30_compania = 1
	  AND n30_estado   = 'I'
	  AND EXTEND(n30_fecha_ing, MONTH TO DAY) <> '02-29'
	  AND EXTEND(NVL(n30_fecha_sal, TODAY), YEAR TO MONTH) =
		EXTEND(MDY(n01_mes_proceso, 01, n01_ano_proceso),YEAR TO MONTH)
	  AND n01_compania = n30_compania
	  AND g01_compania = n01_compania
	ORDER BY 3 ASC;
