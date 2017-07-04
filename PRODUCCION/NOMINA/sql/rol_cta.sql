SELECT n03_nombre AS cod_rol, n32_fecha_ini AS fecha_ini,
	n32_fecha_fin AS fecha_fin, n32_cod_trab AS cod_emp,
	g09_numero_cta AS cuenta_empresa,
	CASE WHEN n32_cod_trab = 24
		THEN '0920503067'
		ELSE n30_num_doc_id
	END AS cedula,
	CASE WHEN n32_cod_trab = 24
		THEN 'CHILA RUA EMILIANO FRANCISCO'
		ELSE n30_nombres
	END AS empleados,
	n32_cta_trabaj AS cuenta_empl, n32_tot_neto AS neto_recibir
	FROM rolt032, rolt030, gent009, rolt003
	WHERE n32_compania    = 1
	  AND n32_cod_liqrol IN ('Q1', 'Q2')
	  AND n32_estado     <> 'E'
	  AND n30_compania    = n32_compania
	  AND n30_cod_trab    = n32_cod_trab
	  AND g09_compania    = n32_compania
	  AND g09_banco       = n32_bco_empresa
	  AND n03_proceso     = n32_cod_liqrol
	ORDER BY 7;
