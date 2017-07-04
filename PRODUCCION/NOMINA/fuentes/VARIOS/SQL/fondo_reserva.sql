SELECT YEAR(n38_fecha_fin) AS anio,
	CASE WHEN MONTH(n38_fecha_fin) = 01 THEN "01_ENERO"
	     WHEN MONTH(n38_fecha_fin) = 02 THEN "02_FEBRERO"
	     WHEN MONTH(n38_fecha_fin) = 03 THEN "03_MARZO"
	     WHEN MONTH(n38_fecha_fin) = 04 THEN "04_ABRIL"
	     WHEN MONTH(n38_fecha_fin) = 05 THEN "05_MAYO"
	     WHEN MONTH(n38_fecha_fin) = 06 THEN "06_JUNIO"
	     WHEN MONTH(n38_fecha_fin) = 07 THEN "07_JULIO"
	     WHEN MONTH(n38_fecha_fin) = 08 THEN "08_AGOSTO"
	     WHEN MONTH(n38_fecha_fin) = 09 THEN "09_SEPTIEMBRE"
	     WHEN MONTH(n38_fecha_fin) = 10 THEN "10_OCTUBRE"
	     WHEN MONTH(n38_fecha_fin) = 11 THEN "11_NOVIEMBRE"
	     WHEN MONTH(n38_fecha_fin) = 12 THEN "12_DICIEMBRE"
	END AS meses,
	n38_cod_trab AS codigo,
	n30_nombres AS empleados,
	NVL(n38_fecha_ing, n30_fecha_sal) AS fecha_emp,
	CASE WHEN n38_estado = 'A'
		THEN "EN PROCESO"
		ELSE "PROCESADO"
	END AS estado_fr,
	g34_nombre AS departamento,
	n38_ganado_per AS total_ganado,
	n38_valor_fondo AS valor_fr,
	CASE WHEN n38_pago_iess = 'S'
		THEN "PAGADO EN IESS"
		ELSE "PAGADO EN ROL"
	END AS tipo_pago,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado,
	CASE WHEN (TODAY - n38_fecha_ing) >
			(SELECT n90_dias_anio
				FROM rolt090
				WHERE n90_compania = n30_compania)
		THEN "TIENE FR"
		ELSE "NO TIENE FR"
	END AS tipo
	FROM rolt038, rolt030, gent034
	WHERE n38_compania  = 1
	  AND n30_compania  = n38_compania
	  AND n30_cod_trab  = n38_cod_trab
	  AND g34_compania  = n30_compania
	  AND g34_cod_depto = n30_cod_depto
UNION
SELECT YEAR(n32_fecha_fin) AS anio,
	CASE WHEN MONTH(n32_fecha_fin) = 01 THEN "01_ENERO"
	     WHEN MONTH(n32_fecha_fin) = 02 THEN "02_FEBRERO"
	     WHEN MONTH(n32_fecha_fin) = 03 THEN "03_MARZO"
	     WHEN MONTH(n32_fecha_fin) = 04 THEN "04_ABRIL"
	     WHEN MONTH(n32_fecha_fin) = 05 THEN "05_MAYO"
	     WHEN MONTH(n32_fecha_fin) = 06 THEN "06_JUNIO"
	     WHEN MONTH(n32_fecha_fin) = 07 THEN "07_JULIO"
	     WHEN MONTH(n32_fecha_fin) = 08 THEN "08_AGOSTO"
	     WHEN MONTH(n32_fecha_fin) = 09 THEN "09_SEPTIEMBRE"
	     WHEN MONTH(n32_fecha_fin) = 10 THEN "10_OCTUBRE"
	     WHEN MONTH(n32_fecha_fin) = 11 THEN "11_NOVIEMBRE"
	     WHEN MONTH(n32_fecha_fin) = 12 THEN "12_DICIEMBRE"
	END AS meses,
	n32_cod_trab AS codigo,
	n30_nombres AS empleados,
	NVL(n30_fecha_ing, n30_fecha_reing) AS fecha_emp,
	CASE WHEN n32_estado = 'A'
		THEN "EN PROCESO"
		ELSE "PROCESADO"
	END AS estado_fr,
	g34_nombre AS departamento,
	NVL(SUM(n32_tot_gan), 0) AS total_ganado,
	0.00 AS valor_fr,
	CASE WHEN n30_fon_res_anio = 'S'
		THEN "PAGADO EN IESS"
		ELSE "PAGADO EN ROL"
	END AS tipo_pago,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado,
	CASE WHEN (TODAY - NVL(n30_fecha_ing, n30_fecha_reing)) >
			(SELECT n90_dias_anio
				FROM rolt090
				WHERE n90_compania = n30_compania)
		THEN "TIENE FR"
		ELSE "NO TIENE FR"
	END AS tipo
	FROM rolt030, rolt032, gent034
	WHERE n30_compania    = 1
	  AND n30_estado      = 'A'
	  AND (TODAY - NVL(n30_fecha_ing, n30_fecha_reing)) <=
			(SELECT n90_dias_anio
				FROM rolt090
				WHERE n90_compania = n30_compania)
	  AND n32_compania    = n30_compania
	  AND n32_cod_liqrol IN ("Q1", "Q2")
	  AND n32_cod_trab    = n30_cod_trab
	  AND g34_compania    = n32_compania
	  AND g34_cod_depto   = n32_cod_depto
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 9, 10, 11, 12
	ORDER BY 4;
