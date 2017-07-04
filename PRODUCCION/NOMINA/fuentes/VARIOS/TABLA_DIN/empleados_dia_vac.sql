SELECT n47_cod_trab AS codigo,
	n30_nombres AS empleados,
	YEAR(n47_fecha_fin) AS anio,
	MONTH(n47_fecha_fin) AS num_mes,
	CASE WHEN MONTH(n47_fecha_fin) = 01 THEN "ENERO"
	     WHEN MONTH(n47_fecha_fin) = 02 THEN "FEBRERO"
	     WHEN MONTH(n47_fecha_fin) = 03 THEN "MARZO"
	     WHEN MONTH(n47_fecha_fin) = 04 THEN "ABRIL"
	     WHEN MONTH(n47_fecha_fin) = 05 THEN "MAYO"
	     WHEN MONTH(n47_fecha_fin) = 06 THEN "JUNIO"
	     WHEN MONTH(n47_fecha_fin) = 07 THEN "JULIO"
	     WHEN MONTH(n47_fecha_fin) = 08 THEN "AGOSTO"
	     WHEN MONTH(n47_fecha_fin) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(n47_fecha_fin) = 10 THEN "OCTUBRE"
	     WHEN MONTH(n47_fecha_fin) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(n47_fecha_fin) = 12 THEN "DICIEMBRE"
	END AS mes,
	NVL(SUM(n47_dias_real), 0) AS dias_vac,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS estado,
	NVL(n30_fecha_reing, n30_fecha_ing) AS fec_ing,
	n30_fecha_sal AS fec_sal
	FROM rolt030, rolt047
	WHERE n30_compania        = 1
	  AND n47_compania        = n30_compania
	  AND n47_cod_trab        = n30_cod_trab
	  AND YEAR(n47_fecha_fin) > 2012
	GROUP BY 1, 2, 3, 4, 5, 7, 8, 9
	ORDER BY 3, 4, 2;
