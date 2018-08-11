SELECT n41_ano AS anio,
	CASE WHEN MONTH(n41_fecing) = 01 THEN "01_ENERO"
	     WHEN MONTH(n41_fecing) = 02 THEN "02_FEBRERO"
	     WHEN MONTH(n41_fecing) = 03 THEN "03_MARZO"
	     WHEN MONTH(n41_fecing) = 04 THEN "04_ABRIL"
	     WHEN MONTH(n41_fecing) = 05 THEN "05_MAYO"
	     WHEN MONTH(n41_fecing) = 06 THEN "06_JUNIO"
	     WHEN MONTH(n41_fecing) = 07 THEN "07_JULIO"
	     WHEN MONTH(n41_fecing) = 08 THEN "08_AGOSTO"
	     WHEN MONTH(n41_fecing) = 09 THEN "09_SEPTIEMBRE"
	     WHEN MONTH(n41_fecing) = 10 THEN "10_OCTUBRE"
	     WHEN MONTH(n41_fecing) = 11 THEN "11_NOVIEMBRE"
	     WHEN MONTH(n41_fecing) = 12 THEN "12_DICIEMBRE"
	END AS meses,
	n03_nombre AS proceso,
	n42_cod_trab AS codigo,
	n30_nombres AS empleados,
	n30_num_doc_id AS cedula,
	n42_fecha_ing AS fec_ing,
	NVL(TO_CHAR(n30_fecha_sal, "%Y-%m-%d"), "") AS fecha_sal,
	CASE WHEN n41_estado = 'A'
		THEN "EN PROCESO"
		ELSE "PROCESADO"
	END AS estado_ut,
	CASE WHEN n41_util_bonif = 'U'
		THEN "UTILIDADES"
		ELSE "BONIFICACION"
	END AS tip_ut,
	n41_val_trabaj AS repar_trab,
	n41_val_cargas AS repar_carg,
	(n41_val_trabaj + n41_val_cargas) AS total_repar,
	g34_nombre AS departamento,
	n42_dias_trab AS d_trab,
	n42_num_cargas AS cargas,
	n42_val_trabaj AS val_trab,
	n42_val_cargas AS val_carg,
	--n42_descuentos AS dscto,
	NVL(n49_cod_rubro, "") AS rub_des,
	NVL(n06_nombre_abr, "") AS nom_rub,
	NVL(n49_num_prest, "") AS num_ant,
	NVL(n49_valor * (-1), 0.00) AS dscto,
	(n42_val_trabaj + n42_val_cargas - n42_descuentos) AS val_net,
	CASE WHEN n42_tipo_pago = 'E' THEN "EFECTIVO"
	     WHEN n42_tipo_pago = 'C' THEN "CHEQUE"
	     WHEN n42_tipo_pago = 'T' THEN "TRANSFERENCIA"
	END AS tipo_pago,
	n42_bco_empresa AS cod_bco,
	NVL(g08_nombre, "") AS banco,
	n42_cta_empresa AS cta_empr,
	n42_cta_trabaj AS cta_trab,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM rolt041, rolt042, rolt030, rolt003, gent034,
		OUTER (gent008, rolt049, rolt006)
	WHERE n41_compania  = 1
	  AND n42_compania  = n41_compania
	  AND n42_proceso   = n41_proceso
	  AND n42_fecha_ini = n41_fecha_ini
	  AND n42_fecha_fin = n41_fecha_fin
	  AND n30_compania  = n42_compania
	  AND n30_cod_trab  = n42_cod_trab
	  AND n03_proceso   = n42_proceso
	  AND g34_compania  = n42_compania
	  AND g34_cod_depto = n42_cod_depto
	  AND g08_banco     = n42_bco_empresa
	  AND n49_compania  = n42_compania
	  AND n49_proceso   = n42_proceso
	  AND n49_cod_trab  = n42_cod_trab
	  AND n49_fecha_ini = n42_fecha_ini
	  AND n49_fecha_fin = n42_fecha_fin
	  AND n06_cod_rubro = n49_cod_rubro
	ORDER BY 1, 5;
