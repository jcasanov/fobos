SELECT n42_cod_trab AS codigo, n30_nombres AS empleados,
	n42_dias_trab AS dias, n42_num_cargas AS tot_cargas,
	(n42_num_cargas * n42_dias_trab) AS puntos_car,
	(n42_dias_trab + (n42_num_cargas * n42_dias_trab)) AS total_puntos,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM rolt041, rolt042, rolt030
	WHERE n41_compania  = 1
	  AND n41_proceso   = 'UT'
	  AND n41_ano       = 2010
	  AND n42_compania  = n41_compania
	  AND n42_proceso   = n41_proceso
	  AND n42_fecha_ini = n41_fecha_ini
	  AND n42_fecha_fin = n41_fecha_fin
	  AND n30_compania  = n42_compania
	  AND n30_cod_trab  = n42_cod_trab
	ORDER BY 2;
