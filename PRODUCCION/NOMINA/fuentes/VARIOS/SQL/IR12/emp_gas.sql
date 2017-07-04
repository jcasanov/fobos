SELECT n30_cod_trab AS CODIGO,
	n30_nombres AS EMPLEADOS
	FROM rolt032, rolt030
	WHERE n32_compania     = 1
	  AND n32_cod_liqrol  IN ("Q1", "Q2")
	  AND n32_ano_proceso  = 2012
	  AND n32_mes_proceso  = 08
	  AND n30_compania     = n32_compania
	  AND n30_cod_trab     = n32_cod_trab
	ORDER BY 2;