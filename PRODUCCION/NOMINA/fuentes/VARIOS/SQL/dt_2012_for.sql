SELECT n30_num_doc_id AS cedula,
	n30_nombres AS empleados,
	CASE WHEN n30_sexo = 'M' THEN 0 END AS hom,
	CASE WHEN n30_sexo = 'F' THEN 1 END AS muj,
	CASE WHEN n30_fecha_ing < n36_fecha_ini
		THEN n36_fecha_ini
		ELSE n30_fecha_ing
	END AS fec_ini,
	n36_fecha_fin AS fec_fin,
	n36_ganado_real AS total_ganado,
	n36_valor_bruto AS valor,
	CASE WHEN n30_estado = "A"
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM rolt036, rolt030
	WHERE n36_compania    = 1
	  AND n36_proceso     = 'DT'
	  AND n36_ano_proceso = 2012
	  AND n30_compania    = n36_compania
	  AND n30_cod_trab    = n36_cod_trab
UNION
SELECT n30_num_doc_id AS cedula,
	n30_nombres AS empleados,
	CASE WHEN n30_sexo = 'M' THEN 0 END AS hom,
	CASE WHEN n30_sexo = 'F' THEN 1 END AS muj,
	CASE WHEN n30_fecha_ing < n48_fecha_ini
		THEN n48_fecha_ini
		ELSE n30_fecha_ing
	END AS fec_ini,
	n48_fecha_fin AS fec_fin,
	n48_tot_gan AS total_ganado,
	n48_val_jub_pat AS valor,
	CASE WHEN n30_estado = "A"
		THEN "ACTIVO"
		ELSE "JUBILADO"
	END AS estado
	FROM rolt048, rolt030
	WHERE n48_compania    = 1
	  AND n48_proceso     = 'JU'
	  AND n48_cod_liqrol  = 'DT'
	  AND n48_ano_proceso = 2012
	  AND n30_compania    = n48_compania
	  AND n30_cod_trab    = n48_cod_trab
	 ORDER BY 2;
