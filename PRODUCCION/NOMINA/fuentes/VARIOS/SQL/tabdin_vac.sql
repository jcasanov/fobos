SELECT YEAR(n39_periodo_ini) || "/" || YEAR(n39_periodo_fin) AS periodo,
	g34_nombre AS departamento,
	n39_cod_trab AS codigo,
	TRIM(n30_nombres) AS empleado,
	NVL(n30_fecha_reing, n30_fecha_ing) AS fecha_ing,
	n30_fecha_sal AS fecha_sal,
	n30_sueldo_mes AS sueldo,
	n39_periodo_ini AS per_ini,
	EXTEND(n39_periodo_fin, YEAR TO DAY) AS per_fin,
	(n39_dias_vac + n39_dias_adi) AS dias_vaca,
	(n39_valor_vaca + n39_valor_adic) AS valor_vac,
	(n39_otros_egr * (-1)) AS saldo_ant,
	(SELECT n17_descripcion
		FROM rolt017
		WHERE n17_sectorial = n30_sectorial) AS cargo,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS estado,
	CASE WHEN n39_estado = "A" THEN "ACTIVA"
	     WHEN n39_estado = "P" THEN "PROCESADA"
	END AS estado_vac
	FROM rolt039, rolt030, gent034
	WHERE n39_compania  = 1
	  AND n39_proceso  IN ("VA", "VP")
	  AND n30_compania  = n39_compania
	  AND n30_cod_trab  = n39_cod_trab
	  AND g34_compania  = n39_compania
	  AND g34_cod_depto = n39_cod_depto
UNION
SELECT YEAR(CASE WHEN (SELECT COUNT(*)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 1)
			  AND n32_fecha_ini <= TODAY
			  AND n32_cod_trab   = n30_cod_trab) <= 24
		THEN DATE(EXTEND(NVL(n30_fecha_reing, n30_fecha_ing),
				MONTH TO DAY) || "-" ||
			CASE WHEN YEAR(TODAY) - 1 < YEAR(NVL(n30_fecha_reing,
					n30_fecha_ing))
				THEN YEAR(NVL(n30_fecha_reing, n30_fecha_ing))
				ELSE YEAR(TODAY) - 1
			END)
		ELSE DATE(EXTEND(NVL(n30_fecha_reing, n30_fecha_ing),
				MONTH TO DAY) || "-" || YEAR(TODAY))
	END) || "/" || 
	CASE WHEN YEAR(CASE WHEN (SELECT COUNT(*)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 1)
			  AND n32_fecha_ini <= TODAY
			  AND n32_cod_trab   = n30_cod_trab) <= 24
			THEN DATE(EXTEND(NVL(n30_fecha_reing, n30_fecha_ing),
				MONTH TO DAY) || "-" ||
			CASE WHEN YEAR(TODAY) - 1 < YEAR(NVL(n30_fecha_reing,
					n30_fecha_ing))
				THEN YEAR(NVL(n30_fecha_reing, n30_fecha_ing))
				ELSE YEAR(TODAY) - 1
			END)
			ELSE DATE(EXTEND(NVL(n30_fecha_reing, n30_fecha_ing),
				MONTH TO DAY) || "-" || YEAR(TODAY))
		END) = YEAR(TODAY)
		THEN YEAR(TODAY) + 1
		ELSE YEAR(TODAY)
	END AS periodo,
	g34_nombre AS departamento,
	n30_cod_trab AS codigo,
	TRIM(n30_nombres) AS empleado,
	NVL(n30_fecha_reing, n30_fecha_ing) AS fecha_ing,
	n30_fecha_sal AS fecha_sal,
	n30_sueldo_mes AS sueldo,
	CASE WHEN (SELECT COUNT(*)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 1)
			  AND n32_fecha_ini <= TODAY
			  AND n32_cod_trab   = n30_cod_trab) <= 24
		THEN DATE(EXTEND(NVL(n30_fecha_reing, n30_fecha_ing),
				MONTH TO DAY) || "-" ||
			CASE WHEN YEAR(TODAY) - 1 < YEAR(NVL(n30_fecha_reing,
					n30_fecha_ing))
				THEN YEAR(NVL(n30_fecha_reing, n30_fecha_ing))
				ELSE YEAR(TODAY) - 1
			END)
		ELSE DATE(EXTEND(NVL(n30_fecha_reing, n30_fecha_ing),
				MONTH TO DAY) || "-" || YEAR(TODAY))
	END AS per_ini,
	EXTEND(TODAY, YEAR TO DAY) AS per_fin,
	CASE WHEN YEAR(TODAY) - YEAR(NVL(n30_fecha_reing, n30_fecha_ing)) <= 5
		THEN 15
		ELSE CASE WHEN (15 + (YEAR(TODAY) -
			YEAR(NVL(n30_fecha_reing, n30_fecha_ing)) - 5)) > 30
				THEN 30
				ELSE (15 + (YEAR(TODAY) -
					YEAR(NVL(n30_fecha_reing,
					n30_fecha_ing)) - 5))
			END
	END AS dias_vaca,
	(NVL(CASE WHEN (SELECT COUNT(*)
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
			  AND n32_cod_liqrol = "Q1"
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
			  AND n32_cod_liqrol = "Q2"
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
			  AND n32_cod_liqrol = "Q1"
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
			  AND n32_cod_liqrol = "Q2"
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
	END, 0)) / 360 *
	CASE WHEN YEAR(TODAY) - YEAR(NVL(n30_fecha_reing, n30_fecha_ing)) <= 5
		THEN 15
		ELSE CASE WHEN (15 + (YEAR(TODAY) -
			YEAR(NVL(n30_fecha_reing, n30_fecha_ing)) - 5)) > 30
				THEN 30
				ELSE (15 + (YEAR(TODAY) -
					YEAR(NVL(n30_fecha_reing,
					n30_fecha_ing)) - 5))
			END
	END AS valor_vac,
	CASE WHEN (SELECT COUNT(*)
			FROM rolt032
			WHERE n32_compania   = n30_compania
			  AND n32_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 1)
			  AND n32_fecha_ini <= TODAY
			  AND n32_cod_trab   = n30_cod_trab) <= 24
		THEN NVL((SELECT SUM(n46_saldo)
			FROM rolt045, rolt046
			WHERE n45_compania    = n30_compania
			  AND n45_cod_trab    = n30_cod_trab
			  AND n45_estado     IN ("A", "R")
			  AND n46_compania    = n45_compania
			  AND n46_num_prest   = n45_num_prest
			  AND n46_cod_liqrol IN ("VA", "VP")
			  AND n46_fecha_ini  >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 1)
			  AND n46_fecha_ini  <= TODAY
			  AND n46_saldo       > 0), 0)
		ELSE NVL((SELECT SUM(n46_saldo)
			FROM rolt045, rolt046
			WHERE n45_compania    = n30_compania
			  AND n45_cod_trab    = n30_cod_trab
			  AND n45_estado     IN ("A", "R")
			  AND n46_compania    = n45_compania
			  AND n46_num_prest   = n45_num_prest
			  AND n46_cod_liqrol IN ("VA", "VP")
			  AND n46_fecha_ini  >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY))
			  AND n46_fecha_ini  <= TODAY
			  AND n46_saldo       > 0), 0)
	END * (-1) AS saldo_ant,
	(SELECT n17_descripcion
		FROM rolt017
		WHERE n17_sectorial = n30_sectorial) AS cargo,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS estado,
	"EN PROCESO" AS estado_vac
	FROM rolt030, rolt001, gent034, gent001
	WHERE n30_compania  = 1
	  AND n30_estado    = "A"
	  AND n30_tipo_trab = "N"
	  AND EXTEND(NVL(n30_fecha_reing, n30_fecha_ing),
			MONTH TO DAY) <> "02-29"
	  AND g34_compania  = n30_compania
	  AND g34_cod_depto = n30_cod_depto
	  AND n01_compania  = n30_compania
	  AND g01_compania  = n01_compania
UNION
SELECT YEAR(DATE(EXTEND(NVL(n30_fecha_reing, n30_fecha_ing), MONTH TO DAY)
		|| "-" || YEAR(TODAY) - 1)) || "/" ||
	YEAR(DATE(EXTEND(NVL(n30_fecha_reing, n30_fecha_ing), MONTH TO DAY)
		|| "-" || YEAR(TODAY)) - 1 UNITS DAY) AS periodo,
	g34_nombre AS departamento,
	n30_cod_trab AS codigo,
	TRIM(n30_nombres) AS empleado,
	NVL(n30_fecha_reing, n30_fecha_ing) AS fecha_ing,
	n30_fecha_sal AS fecha_sal,
	n30_sueldo_mes AS sueldo,
	DATE(EXTEND(NVL(n30_fecha_reing, n30_fecha_ing), MONTH TO DAY)
		|| "-" || YEAR(TODAY) - 1) AS per_ini,
	DATE(EXTEND(NVL(n30_fecha_reing, n30_fecha_ing), MONTH TO DAY)
		|| "-" || YEAR(TODAY)) - 1 UNITS DAY AS per_fin,
	CASE WHEN (YEAR(TODAY) - 1) - YEAR(NVL(n30_fecha_reing, n30_fecha_ing))
			<= 5
		THEN 15
		ELSE CASE WHEN (15 + ((YEAR(TODAY) - 1) -
			YEAR(NVL(n30_fecha_reing, n30_fecha_ing)) - 5)) > 30
				THEN 30
				ELSE (15 + ((YEAR(TODAY) - 1) -
					YEAR(NVL(n30_fecha_reing,
					n30_fecha_ing)) - 5))
			END
	END AS dias_vaca,
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
	END, 0)) / 360 *
	CASE WHEN (YEAR(TODAY) - 1) - YEAR(NVL(n30_fecha_reing, n30_fecha_ing))
			<= 5
		THEN 15
		ELSE CASE WHEN (15 + ((YEAR(TODAY) - 1) -
			YEAR(NVL(n30_fecha_reing, n30_fecha_ing)) - 5)) > 30
				THEN 30
				ELSE (15 + ((YEAR(TODAY) - 1) -
					YEAR(NVL(n30_fecha_reing,
					n30_fecha_ing)) - 5))
			END
	END AS valor_vac,
	NVL((SELECT SUM(n46_saldo)
			FROM rolt045, rolt046
			WHERE n45_compania    = n30_compania
			  AND n45_cod_trab    = n30_cod_trab
			  AND n45_estado     IN ("A", "R")
			  AND n46_compania    = n45_compania
			  AND n46_num_prest   = n45_num_prest
			  AND n46_cod_liqrol IN ("VA", "VP")
			  AND n46_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 2)
			  AND n46_fecha_fin <= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 1) -
						1 UNITS DAY
			  AND n46_saldo       > 0), 0) * (-1) AS saldo_ant,
	(SELECT n17_descripcion
		FROM rolt017
		WHERE n17_sectorial = n30_sectorial) AS cargo,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS estado,
	"EN PROCESO" AS estado_vac
	FROM rolt030, rolt001, gent034, gent001
	WHERE n30_compania  = 1
	  AND n30_estado    = "A"
	  AND n30_tipo_trab = "N"
	  AND EXTEND(NVL(n30_fecha_reing, n30_fecha_ing),
			MONTH TO DAY) <> "02-29"
	  AND (DATE(EXTEND(NVL(n30_fecha_reing, n30_fecha_ing), MONTH TO DAY)
		|| "-" || YEAR(TODAY)) -
		NVL(n30_fecha_reing, n30_fecha_ing)) + 1 > 365
	  AND g34_compania  = n30_compania
	  AND g34_cod_depto = n30_cod_depto
	  AND n01_compania  = n30_compania
	  AND g01_compania  = n01_compania
	  AND NOT EXISTS
		(SELECT 1 FROM rolt039
			WHERE n39_compania     = n30_compania
			  AND n39_cod_trab     = n30_cod_trab
			  AND (n39_ano_proceso = 
	YEAR(DATE(EXTEND(NVL(n30_fecha_reing, n30_fecha_ing), MONTH TO DAY)
		|| "-" || YEAR(TODAY)) - 1 UNITS DAY)
			   OR  n39_ano_proceso = YEAR(TODAY) - 1))
UNION
SELECT YEAR(DATE(EXTEND(NVL(n30_fecha_reing, n30_fecha_ing), MONTH TO DAY)
		|| "-" || YEAR(TODAY) - 2)) || "/" ||
	YEAR(DATE(EXTEND(NVL(n30_fecha_reing, n30_fecha_ing), MONTH TO DAY)
		|| "-" || YEAR(TODAY) - 1) - 1 UNITS DAY) AS periodo,
	g34_nombre AS departamento,
	n30_cod_trab AS codigo,
	TRIM(n30_nombres) AS empleado,
	NVL(n30_fecha_reing, n30_fecha_ing) AS fecha_ing,
	n30_fecha_sal AS fecha_sal,
	n30_sueldo_mes AS sueldo,
	DATE(EXTEND(NVL(n30_fecha_reing, n30_fecha_ing), MONTH TO DAY)
		|| "-" || YEAR(TODAY) - 2) AS per_ini,
	DATE(EXTEND(NVL(n30_fecha_reing, n30_fecha_ing), MONTH TO DAY)
		|| "-" || YEAR(TODAY) - 1) - 1 UNITS DAY AS per_fin,
	CASE WHEN (YEAR(TODAY) - 2) - YEAR(NVL(n30_fecha_reing, n30_fecha_ing))
			<= 5
		THEN 15
		ELSE CASE WHEN (15 + ((YEAR(TODAY) - 2) -
			YEAR(NVL(n30_fecha_reing, n30_fecha_ing)) - 5)) > 30
				THEN 30
				ELSE (15 + ((YEAR(TODAY) - 2) -
					YEAR(NVL(n30_fecha_reing,
					n30_fecha_ing)) - 5))
			END
	END AS dias_vaca,
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
	END, 0) / 360 *
	CASE WHEN (YEAR(TODAY) - 2) - YEAR(NVL(n30_fecha_reing, n30_fecha_ing))
			<= 5
		THEN 15
		ELSE CASE WHEN (15 + ((YEAR(TODAY) - 2) -
			YEAR(NVL(n30_fecha_reing, n30_fecha_ing)) - 5)) > 30
				THEN 30
				ELSE (15 + ((YEAR(TODAY) - 2) -
					YEAR(NVL(n30_fecha_reing,
					n30_fecha_ing)) - 5))
			END
	END AS valor_vac,
	NVL((SELECT SUM(n46_saldo)
			FROM rolt045, rolt046
			WHERE n45_compania    = n30_compania
			  AND n45_cod_trab    = n30_cod_trab
			  AND n45_estado     IN ("A", "R")
			  AND n46_compania    = n45_compania
			  AND n46_num_prest   = n45_num_prest
			  AND n46_cod_liqrol IN ("VA", "VP")
			  AND n46_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 3)
			  AND n46_fecha_fin <= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 2) -
						1 UNITS DAY
			  AND n46_saldo       > 0), 0) * (-1) AS saldo_ant,
	(SELECT n17_descripcion
		FROM rolt017
		WHERE n17_sectorial = n30_sectorial) AS cargo,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS estado,
	"EN PROCESO" AS estado_vac
	FROM rolt030, rolt001, gent034, gent001
	WHERE n30_compania  = 1
	  AND n30_estado    = "A"
	  AND n30_tipo_trab = "N"
	  AND EXTEND(NVL(n30_fecha_reing, n30_fecha_ing),
			MONTH TO DAY) <> "02-29"
	  AND (DATE(EXTEND(NVL(n30_fecha_reing, n30_fecha_ing), MONTH TO DAY)
		|| "-" || YEAR(TODAY) - 1) -
		NVL(n30_fecha_reing, n30_fecha_ing)) + 1 > 730
	  AND g34_compania  = n30_compania
	  AND g34_cod_depto = n30_cod_depto
	  AND n01_compania  = n30_compania
	  AND g01_compania  = n01_compania
	  AND NOT EXISTS
		(SELECT 1 FROM rolt039
			WHERE n39_compania     = n30_compania
			  AND n39_cod_trab     = n30_cod_trab
			  AND (n39_ano_proceso =
	YEAR(DATE(EXTEND(NVL(n30_fecha_reing, n30_fecha_ing), MONTH TO DAY)
		|| "-" || YEAR(TODAY) - 1) - 1 UNITS DAY)
			   OR  n39_ano_proceso = YEAR(TODAY) - 2))
UNION
SELECT YEAR(DATE(EXTEND(NVL(n30_fecha_reing, n30_fecha_ing), MONTH TO DAY)
		|| "-" || YEAR(TODAY) - 3)) || "/" ||
	YEAR(DATE(EXTEND(NVL(n30_fecha_reing, n30_fecha_ing), MONTH TO DAY)
		|| "-" || YEAR(TODAY) - 2) - 1 UNITS DAY) AS periodo,
	g34_nombre AS departamento,
	n30_cod_trab AS codigo,
	TRIM(n30_nombres) AS empleado,
	NVL(n30_fecha_reing, n30_fecha_ing) AS fecha_ing,
	n30_fecha_sal AS fecha_sal,
	n30_sueldo_mes AS sueldo,
	DATE(EXTEND(NVL(n30_fecha_reing, n30_fecha_ing), MONTH TO DAY)
		|| "-" || YEAR(TODAY) - 3) AS per_ini,
	DATE(EXTEND(NVL(n30_fecha_reing, n30_fecha_ing), MONTH TO DAY)
		|| "-" || YEAR(TODAY) - 2) - 1 UNITS DAY AS per_fin,
	CASE WHEN (YEAR(TODAY) - 3) - YEAR(NVL(n30_fecha_reing, n30_fecha_ing))
			<= 5
		THEN 15
		ELSE CASE WHEN (15 + ((YEAR(TODAY) - 3) -
			YEAR(NVL(n30_fecha_reing, n30_fecha_ing)) - 5)) > 30
				THEN 30
				ELSE (15 + ((YEAR(TODAY) - 3) -
					YEAR(NVL(n30_fecha_reing,
					n30_fecha_ing)) - 5))
			END
	END AS dias_vaca,
	(NVL(CASE WHEN ((SELECT COUNT(*)
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
	END, 0)) / 360 *
	CASE WHEN (YEAR(TODAY) - 3) - YEAR(NVL(n30_fecha_reing, n30_fecha_ing))
			<= 5
		THEN 15
		ELSE CASE WHEN (15 + ((YEAR(TODAY) - 3) -
			YEAR(NVL(n30_fecha_reing, n30_fecha_ing)) - 5)) > 30
				THEN 30
				ELSE (15 + ((YEAR(TODAY) - 3) -
					YEAR(NVL(n30_fecha_reing,
					n30_fecha_ing)) - 5))
			END
	END AS valor_vac,
	NVL((SELECT SUM(n46_saldo)
			FROM rolt045, rolt046
			WHERE n45_compania    = n30_compania
			  AND n45_cod_trab    = n30_cod_trab
			  AND n45_estado     IN ("A", "R")
			  AND n46_compania    = n45_compania
			  AND n46_num_prest   = n45_num_prest
			  AND n46_cod_liqrol IN ("VA", "VP")
			  AND n46_fecha_ini >= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 4)
			  AND n46_fecha_fin <= DATE(EXTEND(NVL(n30_fecha_reing,
						n30_fecha_ing), MONTH TO DAY)
						|| "-" || YEAR(TODAY) - 3) -
						1 UNITS DAY
			  AND n46_saldo       > 0), 0) * (-1) AS saldo_ant,
	(SELECT n17_descripcion
		FROM rolt017
		WHERE n17_sectorial = n30_sectorial) AS cargo,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS estado,
	"EN PROCESO" AS estado_vac
	FROM rolt030, rolt001, gent034, gent001
	WHERE n30_compania  = 1
	  AND n30_estado    = "A"
	  AND n30_tipo_trab = "N"
	  AND EXTEND(NVL(n30_fecha_reing, n30_fecha_ing),
			MONTH TO DAY) <> "02-29"
	  AND (DATE(EXTEND(NVL(n30_fecha_reing, n30_fecha_ing), MONTH TO DAY)
		|| "-" || YEAR(TODAY) - 2) -
		NVL(n30_fecha_reing, n30_fecha_ing)) + 1 > 1095
	  AND g34_compania  = n30_compania
	  AND g34_cod_depto = n30_cod_depto
	  AND n01_compania  = n30_compania
	  AND g01_compania  = n01_compania
	  AND NOT EXISTS
		(SELECT 1 FROM rolt039
			WHERE n39_compania    = n30_compania
			  AND n39_cod_trab    = n30_cod_trab
			  AND n39_ano_proceso = 
	YEAR(DATE(EXTEND(NVL(n30_fecha_reing, n30_fecha_ing), MONTH TO DAY)
		|| "-" || YEAR(TODAY) - 2) - 1 UNITS DAY))
	ORDER BY 1 DESC, 4 ASC;
