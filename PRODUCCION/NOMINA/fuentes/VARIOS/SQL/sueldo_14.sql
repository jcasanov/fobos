SELECT n30_cod_trab AS codigo,
	n30_nombres AS empleados,
	n30_sueldo_mes AS sueldo_act,
	NVL(n30_fecha_reing, n30_fecha_ing) AS fec_ing,
	MDY(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)),
		DAY(NVL(n30_fecha_reing, n30_fecha_ing)),
		YEAR(TODAY) - 2) AS fec_ini,
	MDY(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)),
		DAY(NVL(n30_fecha_reing, n30_fecha_ing)),
		YEAR(TODAY) - 1) - 1 UNITS DAY AS fec_fin,
	NVL((SELECT SUM(n32_tot_gan)
		FROM rolt032
		WHERE n32_compania    = n30_compania
		  AND n32_cod_liqrol IN ("Q1", "Q2")
		  AND n32_fecha_ini  >= 
			MDY(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)),
				CASE WHEN DAY(NVL(n30_fecha_reing,
						n30_fecha_ing)) >= 1 AND
					DAY(NVL(n30_fecha_reing,
						n30_fecha_ing)) < 15
					THEN 1
					ELSE 16
				END,
				YEAR(TODAY) - 2)
		  AND n32_fecha_fin  <= 
			MDY(MONTH(NVL(n30_fecha_reing, n30_fecha_ing)),
				CASE WHEN DAY(NVL(n30_fecha_reing,
						n30_fecha_ing)) >= 1 AND
					DAY(NVL(n30_fecha_reing,
						n30_fecha_ing)) < 15
					THEN 1
					ELSE 16
				END,
				YEAR(TODAY) - 2) +
				CASE WHEN MONTH(NVL(n30_fecha_reing,
							n30_fecha_ing)) > 2
					THEN 364 UNITS DAY
					ELSE 365 UNITS DAY
				END
		  AND n32_cod_trab    = n30_cod_trab), 0.00) AS tot_gan,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS estado
	FROM rolt030
	WHERE n30_compania  = 1
	  AND n30_tipo_trab = "N"
	  AND n30_estado    = "A"
	  AND TODAY - NVL(n30_fecha_reing, n30_fecha_ing) > 365
	ORDER BY 2;
