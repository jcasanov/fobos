SELECT n48_ano_proceso AS anios,
	CASE WHEN n48_mes_proceso = 01 THEN "01_ENERO"
	     WHEN n48_mes_proceso = 02 THEN "02_FEBRERO"
	     WHEN n48_mes_proceso = 03 THEN "02_MARZO"
	     WHEN n48_mes_proceso = 04 THEN "04_ABRIL"
	     WHEN n48_mes_proceso = 05 THEN "05_MAYO"
	     WHEN n48_mes_proceso = 06 THEN "06_JUNIO"
	     WHEN n48_mes_proceso = 07 THEN "07_JULIO"
	     WHEN n48_mes_proceso = 08 THEN "08_AGOSTO"
	     WHEN n48_mes_proceso = 09 THEN "09_SEPTIEMBRE"
	     WHEN n48_mes_proceso = 10 THEN "10_OCTUBRE"
	     WHEN n48_mes_proceso = 11 THEN "11_NOVIEMBRE"
	     WHEN n48_mes_proceso = 12 THEN "12_DICIEMBRE"
	END AS meses,
	n48_num_dias AS dias_jub,
	CASE WHEN n48_tipo_pago = 'E' THEN "EFECTIVO"
	     WHEN n48_tipo_pago = 'C' THEN "CHEQUE"
	     WHEN n48_tipo_pago = 'T' THEN "TRANSFERENCIA"
	END AS tipo_pago,
	(SELECT n03_nombre
		FROM rolt003
		WHERE n03_proceso = n48_cod_liqrol) AS proceso,
	n30_num_doc_id AS cedula,
	n30_nombres AS jubilados,
	(SELECT g08_nombre
		FROM gent008
		WHERE g08_banco = n48_bco_empresa) AS banco,
	n48_cta_empresa AS cta_cia,
	n48_cta_trabaj AS cta_emp,
	CASE WHEN n48_estado = 'A' THEN "EN PROCESO"
	     WHEN n48_estado = 'P' THEN "PROCESADO"
	     WHEN n48_estado = 'E' THEN "ELIMINADO"
	END AS estado,
	n48_tipo_comp AS t_comp,
	n48_num_comp AS n_comp,
	(SELECT b13_valor_base
		FROM rolt048 b, ctbt012, ctbt013
		WHERE b.n48_compania   = n48_compania
		  AND b.n48_proceso    = n48_proceso
		  AND b.n48_cod_liqrol = n48_cod_liqrol
		  AND b.n48_fecha_ini  = n48_fecha_ini
		  AND b.n48_fecha_fin  = n48_fecha_fin
		  AND b.n48_cod_trab   = n48_cod_trab
		  AND b12_compania     = b.n48_compania
		  AND b12_tipo_comp    = b.n48_tipo_comp
		  AND b12_num_comp     = b.n48_num_comp
		  AND b13_compania     = b12_compania
		  AND b13_tipo_comp    = b12_tipo_comp
		  AND b13_num_comp     = b12_num_comp
		  AND b13_valor_base   = b.n48_val_jub_pat
		  AND b13_valor_base   > 0) AS valor_ctb,
	(SELECT CASE WHEN b12_estado = 'A' THEN "ACTIVO"
		     WHEN b12_estado = 'M' THEN "MAYORIZADO"
		     WHEN b12_estado = 'E' THEN "ELIMINADO"
		END
		FROM rolt048 b, ctbt012, ctbt013
		WHERE b.n48_compania   = n48_compania
		  AND b.n48_proceso    = n48_proceso
		  AND b.n48_cod_liqrol = n48_cod_liqrol
		  AND b.n48_fecha_ini  = n48_fecha_ini
		  AND b.n48_fecha_fin  = n48_fecha_fin
		  AND b.n48_cod_trab   = n48_cod_trab
		  AND b12_compania     = b.n48_compania
		  AND b12_tipo_comp    = b.n48_tipo_comp
		  AND b12_num_comp     = b.n48_num_comp
		  AND b13_compania     = b12_compania
		  AND b13_tipo_comp    = b12_tipo_comp
		  AND b13_num_comp     = b12_num_comp
		  AND b13_valor_base   = b.n48_val_jub_pat
		  AND b13_valor_base   > 0) AS est_ctb,
	(SELECT UNIQUE b13_cuenta
		FROM rolt048 b, ctbt012, ctbt013
		WHERE b.n48_compania   = n48_compania
		  AND b.n48_proceso    = n48_proceso
		  AND b.n48_cod_liqrol = n48_cod_liqrol
		  AND b.n48_fecha_ini  = n48_fecha_ini
		  AND b.n48_fecha_fin  = n48_fecha_fin
		  AND b.n48_cod_trab   = n48_cod_trab
		  AND b12_compania     = b.n48_compania
		  AND b12_tipo_comp    = b.n48_tipo_comp
		  AND b12_num_comp     = b.n48_num_comp
		  AND b13_compania     = b12_compania
		  AND b13_tipo_comp    = b12_tipo_comp
		  AND b13_num_comp     = b12_num_comp
		  AND b13_valor_base   = b.n48_val_jub_pat
		  AND b13_valor_base   > 0) AS cuenta,
	(SELECT UNIQUE b10_descripcion
		FROM rolt048 b, ctbt012, ctbt013, ctbt010
		WHERE b.n48_compania   = n48_compania
		  AND b.n48_proceso    = n48_proceso
		  AND b.n48_cod_liqrol = n48_cod_liqrol
		  AND b.n48_fecha_ini  = n48_fecha_ini
		  AND b.n48_fecha_fin  = n48_fecha_fin
		  AND b.n48_cod_trab   = n48_cod_trab
		  AND b12_compania     = b.n48_compania
		  AND b12_tipo_comp    = b.n48_tipo_comp
		  AND b12_num_comp     = b.n48_num_comp
		  AND b13_compania     = b12_compania
		  AND b13_tipo_comp    = b12_tipo_comp
		  AND b13_num_comp     = b12_num_comp
		  AND b13_valor_base   = b.n48_val_jub_pat
		  AND b13_valor_base   > 0
		  AND b10_compania     = b13_compania
		  AND b10_cuenta       = b13_cuenta) AS nom_cta,
	n48_tot_gan AS tot_gan,
	n48_val_jub_pat AS valor
	FROM rolt048, rolt030
	WHERE n48_compania   = 1
	  AND n48_proceso    = 'JU'
	  AND n48_cod_liqrol = 'ME'
	  AND n30_compania   = n48_compania
	  AND n48_cod_trab   = n30_cod_trab
