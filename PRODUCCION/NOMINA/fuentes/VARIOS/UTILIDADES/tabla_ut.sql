SELECT n41_ano AS anios, n42_cod_trab AS codigo, n30_nombres AS empleados,
	n42_dias_trab AS dias, n42_num_cargas AS tot_cargas,
	g34_nombre AS departamento, n42_fecha_ing AS fecha_ing,
	n42_fecha_sal AS fecha_sal,
	CASE WHEN n42_tipo_pago = 'E' THEN "EFECTIVO"
	     WHEN n42_tipo_pago = 'C' THEN "CHEQUE"
	     WHEN n42_tipo_pago = 'T' THEN "TRANSFERENCIA"
	END AS tipo_pago,
	NVL((SELECT g08_nombre
		FROM gent008
		WHERE g08_banco = n42_bco_empresa), "") AS banco,
	n42_cta_empresa AS cta_empresa, n42_cta_trabaj AS cta_trab,
	n42_val_trabaj AS valor_trab, n42_val_cargas AS valor_carg,
	n42_descuentos AS descuentos,
	(n42_val_trabaj + n42_val_cargas) AS valor_ut,
	(n42_val_trabaj + n42_val_cargas - n42_descuentos) AS valor_neto,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM rolt041, rolt042, rolt030, gent034
	WHERE n41_compania  = 1
	  AND n41_proceso   = 'UT'
	  AND n42_compania  = n41_compania
	  AND n42_proceso   = n41_proceso
	  AND n42_fecha_ini = n41_fecha_ini
	  AND n42_fecha_fin = n41_fecha_fin
	  AND n30_compania  = n42_compania
	  AND n30_cod_trab  = n42_cod_trab
	  AND g34_compania  = n42_compania
	  AND g34_cod_depto = n42_cod_depto
	ORDER BY n41_ano, n30_nombres;
