SELECT ROUND(COUNT(UNIQUE n32_fecha_ini) / 2, 2) AS mes_act_rol
	FROM rolt032
	WHERE n32_compania    = 1
	  AND n32_ano_proceso = 2014;
	  --AND n32_estado      = "C";
