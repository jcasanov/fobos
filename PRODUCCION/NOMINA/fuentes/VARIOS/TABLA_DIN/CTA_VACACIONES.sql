SELECT n56_compania AS cia,
	n56_proceso AS proc,
	n03_nombre AS nom_proc,
	n56_cod_depto AS cod_depto,
	g34_nombre AS nom_depto,
	n56_cod_trab AS cod_trab,
	n30_nombres AS empleados,
	n56_estado AS est,
	n56_aux_val_vac,
	(SELECT b10_descripcion
		FROM ctbt010
		WHERE b10_compania = n56_compania
		  AND b10_cuenta   = n56_aux_val_vac) AS nom_aux_val_vac,
	n56_aux_val_adi,
	(SELECT b10_descripcion
		FROM ctbt010
		WHERE b10_compania = n56_compania
		  AND b10_cuenta   = n56_aux_val_adi) AS nom_aux_val_adi,
	n56_aux_otr_ing,
	(SELECT b10_descripcion
		FROM ctbt010
		WHERE b10_compania = n56_compania
		  AND b10_cuenta   = n56_aux_otr_ing) AS nom_aux_otr_ing,
	n56_aux_iess,
	(SELECT b10_descripcion
		FROM ctbt010
		WHERE b10_compania = n56_compania
		  AND b10_cuenta   = n56_aux_iess) AS nom_aux_iess,
	n56_aux_otr_egr,
	(SELECT b10_descripcion
		FROM ctbt010
		WHERE b10_compania = n56_compania
		  AND b10_cuenta   = n56_aux_otr_egr) AS nom_aux_otr_egr,
	n56_aux_banco,
	(SELECT b10_descripcion
		FROM ctbt010
		WHERE b10_compania = n56_compania
		  AND b10_cuenta   = n56_aux_banco) AS nom_aux_banco,
	n56_usuario AS usuario,
	n56_fecing AS fecing,
	CASE WHEN n30_estado = "A"
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS est_emp
	FROM rolt056, rolt003, gent034, rolt030
	WHERE n56_compania  = 1
	  AND n56_proceso  IN ("VA", "VP")
	  AND n03_proceso   = n56_proceso
	  AND g34_compania  = n56_compania
	  AND g34_cod_depto = n56_cod_depto
	  AND n30_compania  = n56_compania
	  AND n30_cod_trab  = n56_cod_trab
	ORDER BY 7;
