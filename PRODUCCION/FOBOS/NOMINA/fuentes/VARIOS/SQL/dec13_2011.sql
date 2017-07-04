SELECT n30_num_doc_id AS cedula,
	n30_nombres AS empleado,
	CASE WHEN n36_fecha_ini < NVL(n30_fecha_ing, n30_fecha_reing)
		THEN NVL(n30_fecha_ing, n30_fecha_reing)
		ELSE n36_fecha_ini
	END AS fec_ini,
	n36_fecha_fin AS fec_fin,
	n30_sexo AS genero,
	g35_nombre AS cargo,
	n36_ganado_per AS total_ganado,
	0 dias_t,
	0.00 AS valor_mrl,
	CASE WHEN n36_tipo_pago <> "T"
		THEN n36_valor_bruto
		ELSE 0.00
	END AS pago_dir,
	CASE WHEN n36_tipo_pago = "T"
		THEN n36_valor_bruto
		ELSE 0.00
	END AS acreditado
	FROM rolt036, rolt030, gent035
	WHERE n36_compania    = 1
	  AND n36_proceso     = "DT"
	  AND n36_ano_proceso = 2011
	  AND n30_compania    = n36_compania
	  AND n30_cod_trab    = n36_cod_trab
	  AND g35_compania    = n30_compania
	  AND g35_cod_cargo   = n30_cod_cargo
UNION
SELECT n30_num_doc_id AS cedula,
	n30_nombres AS empleado,
	CASE WHEN n48_fecha_ini < NVL(n30_fecha_ing, n30_fecha_reing)
		THEN NVL(n30_fecha_ing, n30_fecha_reing)
		ELSE n48_fecha_ini
	END AS fec_ini,
	n48_fecha_fin AS fec_fin,
	n30_sexo AS genero,
	"JUBILADO" AS cargo,
	n48_tot_gan AS total_ganado,
	n48_num_dias AS dias_t,
	0.00 AS valor_mrl,
	CASE WHEN n48_tipo_pago <> "T"
		THEN n48_val_jub_pat
		ELSE 0.00
	END AS pago_dir,
	CASE WHEN n48_tipo_pago = "T"
		THEN n48_val_jub_pat
		ELSE 0.00
	END AS acreditado
	FROM rolt048, rolt030
	WHERE n48_compania    = 1
	  AND n48_proceso     = "JU"
	  AND n48_cod_liqrol  = "DT"
	  AND n48_ano_proceso = 2011
	  AND n30_compania    = n48_compania
	  AND n30_cod_trab    = n48_cod_trab
	ORDER BY 2;
