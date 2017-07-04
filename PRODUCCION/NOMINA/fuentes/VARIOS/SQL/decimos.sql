SELECT n36_ano_proceso AS anio,
	CASE WHEN n36_mes_proceso = 01 THEN "01_ENERO"
	     WHEN n36_mes_proceso = 02 THEN "02_FEBRERO"
	     WHEN n36_mes_proceso = 03 THEN "03_MARZO"
	     WHEN n36_mes_proceso = 04 THEN "04_ABRIL"
	     WHEN n36_mes_proceso = 05 THEN "05_MAYO"
	     WHEN n36_mes_proceso = 06 THEN "06_JUNIO"
	     WHEN n36_mes_proceso = 07 THEN "07_JULIO"
	     WHEN n36_mes_proceso = 08 THEN "08_AGOSTO"
	     WHEN n36_mes_proceso = 09 THEN "09_SEPTIEMBRE"
	     WHEN n36_mes_proceso = 10 THEN "10_OCTUBRE"
	     WHEN n36_mes_proceso = 11 THEN "11_NOVIEMBRE"
	     WHEN n36_mes_proceso = 12 THEN "12_DICIEMBRE"
	END AS meses,
	n03_nombre AS decimo,
	n36_cod_trab AS codigo,
	n30_nombres AS empleados,
	NVL(n36_fecha_ing, n30_fecha_sal) AS fecha_emp,
	CASE WHEN n36_estado = 'A'
		THEN "EN PROCESO"
		ELSE "PROCESADO"
	END AS estado_fr,
	g34_nombre AS departamento,
	n36_ganado_per AS total_ganado,
	n36_valor_bruto AS valor_fr,
	n36_descuentos AS descuentos,
	n36_valor_neto AS pago_neto,
	CASE WHEN n36_tipo_pago = 'E' THEN "EFECTIVO"
	     WHEN n36_tipo_pago = 'C' THEN "CHEQUE"
	     WHEN n36_tipo_pago = 'T' THEN "TRANSFERENCIA"
	END AS tipo_pago,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM rolt036, rolt030, rolt003, gent034
	WHERE n36_compania  = 1
	  AND n30_compania  = n36_compania
	  AND n30_cod_trab  = n36_cod_trab
	  AND n03_proceso   = n36_proceso
	  AND g34_compania  = n36_compania
	  AND g34_cod_depto = n36_cod_depto
	ORDER BY 5;
