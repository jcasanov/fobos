SELECT n30_cod_trab AS codigo,
	n30_nombres AS empleados,
	NVL(n30_fecha_reing, n30_fecha_ing) AS fecha_ing,
	CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) >
			MDY(12, 01, YEAR(TODAY) - 1)
		THEN NVL(n30_fecha_reing, n30_fecha_ing)
		ELSE MDY(12, 01, YEAR(TODAY) - 1)
	END AS fecha_ini,
	CASE WHEN TODAY < MDY(11, 30, YEAR(TODAY))
		THEN TODAY
		ELSE MDY(11, 30, YEAR(TODAY))
	END AS fecha_fin,
	fp_dias360(
	CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) >
			MDY(12, 01, YEAR(TODAY) - 1)
		THEN NVL(n30_fecha_reing, n30_fecha_ing)
		ELSE MDY(12, 01, YEAR(TODAY) - 1)
	END,
	CASE WHEN TODAY < MDY(11, 30, YEAR(TODAY))
		THEN TODAY
		ELSE MDY(11, 30, YEAR(TODAY))
	END, 1) AS dias_trab,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032
		WHERE n32_compania    = n30_compania
		  AND n32_cod_liqrol IN ("Q1", "Q2")
		  AND n32_fecha_ini  >=
			CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) >
					MDY(12, 01, YEAR(TODAY) - 1)
				THEN MDY(MONTH(NVL(n30_fecha_reing,
						n30_fecha_ing)),
					CASE WHEN DAY(NVL(n30_fecha_reing,
						n30_fecha_ing)) <= 16
						THEN 1
						ELSE 16
					END,
					YEAR(NVL(n30_fecha_reing,
						n30_fecha_ing)))
				ELSE MDY(12, 01, YEAR(TODAY) - 1)
			END
		  AND n32_fecha_fin  <=
			CASE WHEN TODAY < MDY(11, 30, YEAR(TODAY))
				THEN TODAY
				ELSE MDY(11, 30, YEAR(TODAY))
			END
		  AND n32_cod_trab    = n30_cod_trab), 0.00) AS total_gan,
	ROUND(NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032
		WHERE n32_compania    = n30_compania
		  AND n32_cod_liqrol IN ("Q1", "Q2")
		  AND n32_fecha_ini  >=
			CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) >
					MDY(12, 01, YEAR(TODAY) - 1)
				THEN MDY(MONTH(NVL(n30_fecha_reing,
						n30_fecha_ing)),
					CASE WHEN DAY(NVL(n30_fecha_reing,
						n30_fecha_ing)) <= 16
						THEN 1
						ELSE 16
					END,
					YEAR(NVL(n30_fecha_reing,
						n30_fecha_ing)))
				ELSE MDY(12, 01, YEAR(TODAY) - 1)
			END
		  AND n32_fecha_fin  <=
			CASE WHEN TODAY < MDY(11, 30, YEAR(TODAY))
				THEN TODAY
				ELSE MDY(11, 30, YEAR(TODAY))
			END
		  AND n32_cod_trab    = n30_cod_trab),
		0.00) / 12, 2) AS valor_dec,
	ROUND(NVL((SELECT SUM(n46_saldo)
		FROM rolt045, rolt046
		WHERE n45_compania   = n30_compania
		  AND n45_cod_trab   = n30_cod_trab
		  AND n45_estado    IN ("A", "R")
		  AND n46_compania   = n45_compania
		  AND n46_num_prest  = n45_num_prest
		  AND n46_cod_liqrol = "DT"
		  AND n46_fecha_ini  = MDY(12, 01, YEAR(TODAY) - 1)
		  AND n46_fecha_fin  = MDY(11, 30, YEAR(TODAY))),
		0.00), 2) AS anticipos,
	ROUND((NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032
		WHERE n32_compania    = n30_compania
		  AND n32_cod_liqrol IN ("Q1", "Q2")
		  AND n32_fecha_ini  >=
			CASE WHEN NVL(n30_fecha_reing, n30_fecha_ing) >
					MDY(12, 01, YEAR(TODAY) - 1)
				THEN MDY(MONTH(NVL(n30_fecha_reing,
						n30_fecha_ing)),
					CASE WHEN DAY(NVL(n30_fecha_reing,
						n30_fecha_ing)) <= 16
						THEN 1
						ELSE 16
					END,
					YEAR(NVL(n30_fecha_reing,
						n30_fecha_ing)))
				ELSE MDY(12, 01, YEAR(TODAY) - 1)
			END
		  AND n32_fecha_fin  <=
			CASE WHEN TODAY < MDY(11, 30, YEAR(TODAY))
				THEN TODAY
				ELSE MDY(11, 30, YEAR(TODAY))
			END
		  AND n32_cod_trab    = n30_cod_trab),
		0.00) / 12) -
	NVL((SELECT SUM(n46_saldo)
		FROM rolt045, rolt046
		WHERE n45_compania   = n30_compania
		  AND n45_cod_trab   = n30_cod_trab
		  AND n45_estado    IN ("A", "R")
		  AND n46_compania   = n45_compania
		  AND n46_num_prest  = n45_num_prest
		  AND n46_cod_liqrol = "DT"
		  AND n46_fecha_ini  = MDY(12, 01, YEAR(TODAY) - 1)
		  AND n46_fecha_fin  = MDY(11, 30, YEAR(TODAY))),
		0.00), 2) AS neto_recibir,
	"ACTIVO" AS estado,
	CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	     WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	     WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	     WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS GYE"
	END AS localidad
	FROM rolt030
	WHERE n30_compania  = 1
	  AND n30_estado    = "A"
	  AND n30_tipo_trab = "N"
UNION
SELECT n30_cod_trab AS codigo,
	n30_nombres AS empleados,
	n30_fec_jub AS fecha_ing,
	CASE WHEN n30_fec_jub > MDY(12, 01, YEAR(TODAY) - 1)
		THEN n30_fec_jub
		ELSE MDY(12, 01, YEAR(TODAY) - 1)
	END AS fecha_ini,
	CASE WHEN TODAY < MDY(11, 30, YEAR(TODAY))
		THEN TODAY
		ELSE MDY(11, 30, YEAR(TODAY))
	END AS fecha_fin,
	fp_dias360(
	CASE WHEN n30_fec_jub > MDY(12, 01, YEAR(TODAY) - 1)
		THEN n30_fec_jub
		ELSE MDY(12, 01, YEAR(TODAY) - 1)
	END,
	CASE WHEN TODAY < MDY(11, 30, YEAR(TODAY))
		THEN TODAY
		ELSE MDY(11, 30, YEAR(TODAY))
	END, 1) AS dias_trab,
	NVL((SELECT SUM(n48_tot_gan)
		FROM rolt048
		WHERE n48_compania    = n30_compania
		  AND n48_proceso     = "JU"
		  AND n48_cod_liqrol  = "ME"
		  AND n48_fecha_ini  >=
			CASE WHEN n30_fec_jub > MDY(12, 01, YEAR(TODAY) - 1)
				THEN MDY(MONTH(n30_fec_jub),
					CASE WHEN DAY(n30_fec_jub) <= 16
						THEN 1
						ELSE 16
					END,
					YEAR(n30_fec_jub))
				ELSE MDY(12, 01, YEAR(TODAY) - 1)
			END
		  AND n48_fecha_fin  <=
			CASE WHEN TODAY < MDY(11, 30, YEAR(TODAY))
				THEN TODAY
				ELSE MDY(11, 30, YEAR(TODAY))
			END
		  AND n48_cod_trab    = n30_cod_trab), 0.00) AS total_gan,
	ROUND(NVL((SELECT SUM(n48_tot_gan)
		FROM rolt048
		WHERE n48_compania    = n30_compania
		  AND n48_proceso     = "JU"
		  AND n48_cod_liqrol  = "ME"
		  AND n48_fecha_ini  >=
			CASE WHEN n30_fec_jub > MDY(12, 01, YEAR(TODAY) - 1)
				THEN MDY(MONTH(n30_fec_jub),
					CASE WHEN DAY(n30_fec_jub) <= 16
						THEN 1
						ELSE 16
					END,
					YEAR(n30_fec_jub))
				ELSE MDY(12, 01, YEAR(TODAY) - 1)
			END
		  AND n48_fecha_fin  <=
			CASE WHEN TODAY < MDY(11, 30, YEAR(TODAY))
				THEN TODAY
				ELSE MDY(11, 30, YEAR(TODAY))
			END
		  AND n48_cod_trab    = n30_cod_trab),
		0.00) / 12, 2) AS valor_dec,
	0.00 AS anticipos,
	ROUND((NVL((SELECT SUM(n48_tot_gan)
		FROM rolt048
		WHERE n48_compania    = n30_compania
		  AND n48_proceso     = "JU"
		  AND n48_cod_liqrol  = "ME"
		  AND n48_fecha_ini  >=
			CASE WHEN n30_fec_jub > MDY(12, 01, YEAR(TODAY) - 1)
				THEN MDY(MONTH(n30_fec_jub),
					CASE WHEN DAY(n30_fec_jub) <= 16
						THEN 1
						ELSE 16
					END,
					YEAR(n30_fec_jub))
				ELSE MDY(12, 01, YEAR(TODAY) - 1)
			END
		  AND n48_fecha_fin  <=
			CASE WHEN TODAY < MDY(11, 30, YEAR(TODAY))
				THEN TODAY
				ELSE MDY(11, 30, YEAR(TODAY))
			END
		  AND n48_cod_trab    = n30_cod_trab),
		0.00) / 12), 2) AS neto_recibir,
	"JUBILADO" AS estado,
	CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	     WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	     WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	     WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS GYE"
	END AS localidad
	FROM rolt030
	WHERE n30_compania  = 1
	  AND n30_estado    = "J"
	  AND n30_tipo_trab = "N"
	ORDER BY 12 ASC, 11 ASC, 2 ASC;
