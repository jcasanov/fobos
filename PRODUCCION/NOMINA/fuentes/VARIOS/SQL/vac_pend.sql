SELECT n47_cod_trab AS codigo, n30_nombres AS empleados,
	YEAR(n47_periodo_ini) || "/" || YEAR(n47_periodo_fin) AS periodo,
	n03_proceso AS quincena,
	CASE WHEN MONTH(n47_fecha_fin) = 01 THEN "01-ENERO"
	     WHEN MONTH(n47_fecha_fin) = 02 THEN "02-FEBRERO"
	     WHEN MONTH(n47_fecha_fin) = 03 THEN "03-MARZO"
	     WHEN MONTH(n47_fecha_fin) = 04 THEN "04-ABRIL"
	     WHEN MONTH(n47_fecha_fin) = 05 THEN "05-MAYO"
	     WHEN MONTH(n47_fecha_fin) = 06 THEN "06-JUNIO"
	     WHEN MONTH(n47_fecha_fin) = 07 THEN "07-JULIO"
	     WHEN MONTH(n47_fecha_fin) = 08 THEN "08-AGOSTO"
	     WHEN MONTH(n47_fecha_fin) = 09 THEN "09-SEPTIEMBRE"
	     WHEN MONTH(n47_fecha_fin) = 10 THEN "10-OCTUBRE"
	     WHEN MONTH(n47_fecha_fin) = 11 THEN "11-NOVIEMBRE"
	     WHEN MONTH(n47_fecha_fin) = 12 THEN "12-DICIEMBRE"
	END AS mes,
	YEAR(n47_fecha_fin) AS anio, n47_max_dias AS dias,
	n47_valor_pag AS valor
	FROM rolt047, rolt030, rolt003
	WHERE n47_compania = 1
	  AND n47_proceso  = 'VA'
	  AND n47_estado   = 'A'
	  AND n30_compania = n47_compania
	  AND n30_cod_trab = n47_cod_trab
	  AND n30_estado   = 'A'
	  AND n03_proceso  = n47_cod_liqrol
	ORDER BY n30_nombres, 5, 4, 6;
