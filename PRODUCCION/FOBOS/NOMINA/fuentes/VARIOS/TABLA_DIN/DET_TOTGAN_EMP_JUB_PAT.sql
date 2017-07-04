SELECT n30_cod_trab AS codi,
	CASE WHEN n30_tipo_doc_id = "C"
		THEN "CEDULA"
		ELSE "PASAPORTE"
	END AS tip,
	n30_num_doc_id AS cedula,
	n30_nombres AS empl,
	NVL(n30_fecha_reing, n30_fecha_ing) AS fec_ing,
	CAST(CASE WHEN TRUNC((((TODAY - NVL(n30_fecha_reing, n30_fecha_ing))
		+ 1) / n90_dias_anio), 0) > 0
                THEN TRUNC((((TODAY - NVL(n30_fecha_reing, n30_fecha_ing))
                         + 1) / n90_dias_anio), 0)
                ELSE 0
        END AS INTEGER) AS anio_ser,
	CASE WHEN TRUNC((((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) /
                 n90_dias_anio), 0) > 0
                THEN LPAD(TRUNC((((TODAY - NVL(n30_fecha_reing, n30_fecha_ing))
                         + 1) / n90_dias_anio), 0), 2, 0)
                ELSE ""
        END ||
        CASE WHEN TRUNC((((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) /
                 n90_dias_anio), 0) = 1
                THEN " Año "
             WHEN TRUNC((((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) /
                 n90_dias_anio), 0) > 1
                THEN " Años "
                ELSE ""
        END ||
        CASE WHEN TRUNC(MOD(((TODAY - NVL(n30_fecha_reing, n30_fecha_ing))
                         + 1), n90_dias_anio) / n00_dias_mes, 0) > 0
                THEN CASE WHEN (MOD(MOD(((TODAY - NVL(n30_fecha_reing,
                         n30_fecha_ing)) + 1),
                        n90_dias_anio), n00_dias_mes) = 0)
                     OR NOT ((TRUNC((((TODAY - NVL(n30_fecha_reing,
                                n30_fecha_ing)) + 1) / n90_dias_anio), 0) > 0)
                        OR (TRUNC(MOD(((TODAY - NVL(n30_fecha_reing,
                                n30_fecha_ing)) + 1), n90_dias_anio) /
                                n00_dias_mes, 0) > 0))
                                THEN "y "
                                ELSE ""
                        END ||
                        LPAD(TRUNC(MOD(((TODAY - NVL(n30_fecha_reing,
                                n30_fecha_ing)) + 1), n90_dias_anio) /
                                n00_dias_mes, 0), 2, 0)
                ELSE ""
        END ||
        CASE WHEN TRUNC(MOD(((TODAY - NVL(n30_fecha_reing, n30_fecha_ing))
                                + 1), n90_dias_anio) / n00_dias_mes, 0) = 1
                THEN " Mes "
             WHEN TRUNC(MOD(((TODAY - NVL(n30_fecha_reing, n30_fecha_ing))
                                + 1), n90_dias_anio) / n00_dias_mes, 0) > 1
                THEN " Meses "
                ELSE ""
        END ||
        CASE WHEN MOD(MOD(((TODAY - NVL(n30_fecha_reing, n30_fecha_ing))
                                + 1), n90_dias_anio), n00_dias_mes) > 0
                THEN CASE WHEN (TRUNC((((TODAY - NVL(n30_fecha_reing,
                                n30_fecha_ing)) + 1) / n90_dias_anio), 0) > 0)
                        OR (TRUNC(MOD(((TODAY - NVL(n30_fecha_reing,
                                n30_fecha_ing)) + 1), n90_dias_anio) /
                                n00_dias_mes, 0) > 0)
                                THEN "y "
                                ELSE ""
                        END ||
                        LPAD(MOD(MOD(((TODAY - NVL(n30_fecha_reing,
                                n30_fecha_ing)) + 1), n90_dias_anio),
                                n00_dias_mes), 2, 0)
                ELSE ""
        END ||
        CASE WHEN MOD(MOD(((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1),
                        n90_dias_anio), n00_dias_mes) = 1
                THEN " Día"
             WHEN MOD(MOD(((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1),
                        n90_dias_anio), n00_dias_mes) > 1
                THEN " Días"
                ELSE ""
        END AS tie_ser,
	CAST(CASE WHEN TRUNC((((TODAY - n30_fecha_nacim) + 1) /
                 n90_dias_anio), 0) > 0
                THEN LPAD(TRUNC((((TODAY - n30_fecha_nacim)
                         + 1) / n90_dias_anio), 0), 2, 0)
                ELSE ""
        END  AS INTEGER)AS anio_edad,
	CASE WHEN TRUNC((((TODAY - n30_fecha_nacim) + 1) /
                 n90_dias_anio), 0) > 0
                THEN LPAD(TRUNC((((TODAY - n30_fecha_nacim)
                         + 1) / n90_dias_anio), 0), 2, 0)
                ELSE ""
        END ||
        CASE WHEN TRUNC((((TODAY - n30_fecha_nacim) + 1) /
                 n90_dias_anio), 0) = 1
                THEN " Año "
             WHEN TRUNC((((TODAY - n30_fecha_nacim) + 1) /
                 n90_dias_anio), 0) > 1
                THEN " Años "
                ELSE ""
        END ||
        CASE WHEN TRUNC(MOD(((TODAY - n30_fecha_nacim)
                         + 1), n90_dias_anio) / n00_dias_mes, 0) > 0
                THEN CASE WHEN (MOD(MOD(((TODAY - n30_fecha_nacim) + 1),
                        n90_dias_anio), n00_dias_mes) = 0)
                     OR NOT ((TRUNC((((TODAY - n30_fecha_nacim) + 1) /
				n90_dias_anio), 0) > 0)
                        OR (TRUNC(MOD(((TODAY - n30_fecha_nacim) + 1),
				n90_dias_anio) / n00_dias_mes, 0) > 0))
                                THEN "y "
                                ELSE ""
                        END ||
                        LPAD(TRUNC(MOD(((TODAY - n30_fecha_nacim) + 1),
				n90_dias_anio) / n00_dias_mes, 0), 2, 0)
                ELSE ""
        END ||
        CASE WHEN TRUNC(MOD(((TODAY - n30_fecha_nacim)
                                + 1), n90_dias_anio) / n00_dias_mes, 0) = 1
                THEN " Mes "
             WHEN TRUNC(MOD(((TODAY - n30_fecha_nacim)
                                + 1), n90_dias_anio) / n00_dias_mes, 0) > 1
                THEN " Meses "
                ELSE ""
        END ||
        CASE WHEN MOD(MOD(((TODAY - n30_fecha_nacim)
                                + 1), n90_dias_anio), n00_dias_mes) > 0
                THEN CASE WHEN (TRUNC((((TODAY - n30_fecha_nacim) + 1) /
				n90_dias_anio), 0) > 0)
                        OR (TRUNC(MOD(((TODAY - n30_fecha_nacim) + 1),
				n90_dias_anio) / n00_dias_mes, 0) > 0)
                                THEN "y "
                                ELSE ""
                        END ||
                        LPAD(MOD(MOD(((TODAY - n30_fecha_nacim) + 1),
				n90_dias_anio), n00_dias_mes), 2, 0)
                ELSE ""
        END ||
        CASE WHEN MOD(MOD(((TODAY - n30_fecha_nacim) + 1),
                        n90_dias_anio), n00_dias_mes) = 1
                THEN " Día"
             WHEN MOD(MOD(((TODAY - n30_fecha_nacim) + 1),
                        n90_dias_anio), n00_dias_mes) > 1
                THEN " Días"
                ELSE ""
        END AS tie_eda,
        ROUND(NVL(SUM(
		CASE WHEN YEAR(MDY(MONTH(TODAY), DAY(TODAY), YEAR(TODAY) - 5)) =
			a.n32_ano_proceso
			THEN a.n32_tot_gan
			ELSE 0.00
		END), 0.00), 2) AS t_gan_anio1,
        ROUND(NVL(SUM(
		CASE WHEN YEAR(MDY(MONTH(TODAY), DAY(TODAY), YEAR(TODAY) - 5)) =
			a.n32_ano_proceso
			THEN a.n32_tot_gan /
		ROUND((SELECT COUNT(*)
		FROM rolt032 b
		WHERE b.n32_compania         = n30_compania
		  AND b.n32_cod_liqrol      IN ("Q1", "Q2")
		  AND b.n32_cod_trab         = n30_cod_trab
		  AND DATE(b.n32_fecha_ini) BETWEEN
			DATE(MDY(MONTH(TODAY), DAY(TODAY), YEAR(TODAY) - 5))
			AND DATE(MDY(12, 31, YEAR(TODAY) - 5))) / 2, 2)
			ELSE 0.00
		END), 0.00), 2) AS prom_anio1,
        ROUND(NVL(SUM(
		CASE WHEN YEAR(MDY(MONTH(TODAY), DAY(TODAY), YEAR(TODAY) - 4)) =
			a.n32_ano_proceso
			THEN a.n32_tot_gan
			ELSE 0.00
		END), 0.00), 2) AS t_gan_anio2,
        ROUND(NVL(SUM(
		CASE WHEN YEAR(MDY(MONTH(TODAY), DAY(TODAY), YEAR(TODAY) - 4)) =
			a.n32_ano_proceso
			THEN a.n32_tot_gan /
		ROUND((SELECT COUNT(*)
		FROM rolt032 b
		WHERE b.n32_compania         = n30_compania
		  AND b.n32_cod_liqrol      IN ("Q1", "Q2")
		  AND b.n32_cod_trab         = n30_cod_trab
		  AND DATE(b.n32_fecha_ini) BETWEEN
			DATE(MDY(01, 01, YEAR(TODAY) - 4))
			AND DATE(MDY(12, 31, YEAR(TODAY) - 4))) / 2, 2)
			ELSE 0.00
		END), 0.00), 2) AS prom_anio2,
        ROUND(NVL(SUM(
		CASE WHEN YEAR(MDY(MONTH(TODAY), DAY(TODAY), YEAR(TODAY) - 3)) =
			a.n32_ano_proceso
			THEN a.n32_tot_gan
			ELSE 0.00
		END), 0.00), 2) AS t_gan_anio3,
        ROUND(NVL(SUM(
		CASE WHEN YEAR(MDY(MONTH(TODAY), DAY(TODAY), YEAR(TODAY) - 3)) =
			a.n32_ano_proceso
			THEN a.n32_tot_gan /
		ROUND((SELECT COUNT(*)
		FROM rolt032 b
		WHERE b.n32_compania         = n30_compania
		  AND b.n32_cod_liqrol      IN ("Q1", "Q2")
		  AND b.n32_cod_trab         = n30_cod_trab
		  AND DATE(b.n32_fecha_ini) BETWEEN
			DATE(MDY(01, 01, YEAR(TODAY) - 3))
			AND DATE(MDY(12, 31, YEAR(TODAY) - 3))) / 2, 2)
			ELSE 0.00
		END), 0.00), 2) AS prom_anio3,
        ROUND(NVL(SUM(
		CASE WHEN YEAR(MDY(MONTH(TODAY), DAY(TODAY), YEAR(TODAY) - 2)) =
			a.n32_ano_proceso
			THEN a.n32_tot_gan
			ELSE 0.00
		END), 0.00), 2) AS t_gan_anio4,
        ROUND(NVL(SUM(
		CASE WHEN YEAR(MDY(MONTH(TODAY), DAY(TODAY), YEAR(TODAY) - 2)) =
			a.n32_ano_proceso
			THEN a.n32_tot_gan /
		ROUND((SELECT COUNT(*)
		FROM rolt032 b
		WHERE b.n32_compania         = n30_compania
		  AND b.n32_cod_liqrol      IN ("Q1", "Q2")
		  AND b.n32_cod_trab         = n30_cod_trab
		  AND DATE(b.n32_fecha_ini) BETWEEN
			DATE(MDY(01, 01, YEAR(TODAY) - 2))
			AND DATE(MDY(12, 31, YEAR(TODAY) - 2))) / 2, 2)
			ELSE 0.00
		END), 0.00), 2) AS prom_anio4,
        ROUND(NVL(SUM(
		CASE WHEN YEAR(MDY(MONTH(TODAY), DAY(TODAY), YEAR(TODAY) - 1)) =
			a.n32_ano_proceso
			THEN a.n32_tot_gan
			ELSE 0.00
		END), 0.00), 2) AS t_gan_anio5,
        ROUND(NVL(SUM(
		CASE WHEN YEAR(MDY(MONTH(TODAY), DAY(TODAY), YEAR(TODAY) - 1)) =
			a.n32_ano_proceso
			THEN a.n32_tot_gan /
		ROUND((SELECT COUNT(*)
		FROM rolt032 b
		WHERE b.n32_compania         = n30_compania
		  AND b.n32_cod_liqrol      IN ("Q1", "Q2")
		  AND b.n32_cod_trab         = n30_cod_trab
		  AND DATE(b.n32_fecha_ini) BETWEEN
			DATE(MDY(01, 01, YEAR(TODAY) - 1))
			AND DATE(MDY(12, 31, YEAR(TODAY) - 1))) / 2, 2)
			ELSE 0.00
		END), 0.00), 2) AS prom_anio5,
        ROUND(NVL(SUM(
		CASE WHEN YEAR(TODAY) = a.n32_ano_proceso
			THEN a.n32_tot_gan
			ELSE 0.00
		END), 0.00), 2) AS t_gan_anio6,
        ROUND(NVL(SUM(
		CASE WHEN YEAR(TODAY) = a.n32_ano_proceso
			THEN a.n32_tot_gan /
		ROUND((SELECT COUNT(*)
		FROM rolt032 b
		WHERE b.n32_compania         = n30_compania
		  AND b.n32_cod_liqrol      IN ("Q1", "Q2")
		  AND b.n32_cod_trab         = n30_cod_trab
		  AND YEAR(b.n32_fecha_ini)  = YEAR(TODAY)) / 2, 2)
			ELSE 0.00
		END), 0.00), 2) AS prom_anio6
	FROM rolt030, rolt090, rolt000, rolt032 a
	WHERE n30_compania           = 1
	  AND n30_estado             = "A"
	  AND n90_compania           = n30_compania
          AND n00_serial             = n90_compania
	  AND a.n32_compania         = n30_compania
	  AND a.n32_cod_liqrol      IN ("Q1", "Q2")
	  AND a.n32_cod_trab         = n30_cod_trab
	  AND DATE(a.n32_fecha_fin) BETWEEN
		DATE(MDY(MONTH(TODAY), DAY(TODAY), YEAR(TODAY) - 5))
			AND DATE(TODAY)
        GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
	ORDER BY 4 ASC;
