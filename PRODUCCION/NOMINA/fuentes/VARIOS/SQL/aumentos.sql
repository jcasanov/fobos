SELECT a.n32_ano_proceso AS anios,
	CASE WHEN MONTH(n32_fecha_ini) = 01 THEN "01_ENERO"
	     WHEN MONTH(n32_fecha_ini) = 02 THEN "02_FEBRERO"
	     WHEN MONTH(n32_fecha_ini) = 03 THEN "03_MARZO"
	     WHEN MONTH(n32_fecha_ini) = 04 THEN "04_ABRIL"
	     WHEN MONTH(n32_fecha_ini) = 05 THEN "05_MAYO"
	     WHEN MONTH(n32_fecha_ini) = 06 THEN "06_JUNIO"
	     WHEN MONTH(n32_fecha_ini) = 07 THEN "07_JULIO"
	     WHEN MONTH(n32_fecha_ini) = 08 THEN "08_AGOSTO"
	     WHEN MONTH(n32_fecha_ini) = 09 THEN "09_SEPTIEMBRE"
	     WHEN MONTH(n32_fecha_ini) = 10 THEN "10_OCTUBRE"
	     WHEN MONTH(n32_fecha_ini) = 11 THEN "11_NOVIEMBRE"
	     WHEN MONTH(n32_fecha_ini) = 12 THEN "12_DICIEMBRE"
	END AS meses,
	LPAD(a.n32_cod_trab, 3, 0) AS cod,
	n30_nombres AS empleado,
	a.n32_sueldo AS sueldo,
	n30_sueldo_mes AS sueldo_act,
	TO_CHAR(a.n32_fecha_ini, "%d-%m-%Y") AS fecha,
	CASE WHEN n30_estado = 'A' THEN "ACTIVO"
	     WHEN n30_estado = 'I' THEN "INACTIVO"
	     WHEN n30_estado = 'J' THEN "JUBILADO"
	END AS estado
	FROM rolt032 a, rolt030
	WHERE a.n32_compania    = 1
	  AND a.n32_cod_liqrol IN ('Q1', 'Q2')
	  AND a.n32_fecha_fin  IN
		(SELECT MIN(b.n32_fecha_fin)
			FROM rolt032 b
			WHERE b.n32_compania   = a.n32_compania
			  AND b.n32_cod_trab   = a.n32_cod_trab
			  AND b.n32_sueldo     = a.n32_sueldo)
	  AND n30_compania      = a.n32_compania
	  AND n30_cod_trab      = a.n32_cod_trab
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
	ORDER BY 4 ASC, 7 DESC;
