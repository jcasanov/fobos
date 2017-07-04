SELECT MONTH(MAX(n32_fecha_fin)) AS mes_act_rol
	FROM rolt032
	WHERE n32_compania    = 1
	  AND n32_cod_liqrol  = "Q2"
	  AND n32_ano_proceso = 2014
	  AND n32_estado      = "C"
