SELECT n38_cod_trab AS cod_trab, n30_nombres AS empleados,
	SUM(CASE WHEN MONTH(n38_fecha_fin) = '06'
		THEN n38_valor_fondo
		ELSE 0.00
	END) fondo_jun09,
	SUM(CASE WHEN MONTH(n38_fecha_fin) = '07'
		THEN n38_valor_fondo
		ELSE 0.00
	END) fondo_jul09,
	SUM(CASE WHEN MONTH(n38_fecha_fin) = '08'
		THEN n38_valor_fondo
		ELSE 0.00
	END) fondo_ago09,
	SUM(CASE WHEN MONTH(n38_fecha_fin) = '09'
		THEN n38_valor_fondo
		ELSE 0.00
	END) fondo_sep09,
	SUM(CASE WHEN MONTH(n38_fecha_fin) = '10'
		THEN n38_valor_fondo
		ELSE 0.00
	END) fondo_oct09,
	SUM(CASE WHEN MONTH(n38_fecha_fin) = '11'
		THEN n38_valor_fondo
		ELSE 0.00
	END) fondo_nov09,
	SUM(CASE WHEN MONTH(n38_fecha_fin) = '12'
		THEN n38_valor_fondo
		ELSE 0.00
	END) fondo_dic09
	FROM rolt038, rolt030
	WHERE n38_compania        = 1
	  AND YEAR(n38_fecha_fin) = 2009
	  AND n30_compania        = n38_compania
	  AND n30_cod_trab        = n38_cod_trab
	GROUP BY 1, 2
	ORDER BY 2;
