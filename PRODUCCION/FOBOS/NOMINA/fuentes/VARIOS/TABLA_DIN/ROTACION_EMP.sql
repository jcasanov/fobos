SELECT n30_nombres AS empleados,
	CASE WHEN YEAR(n30_fecha_ing) = 2009 THEN 1
	END AS anio_09_ing,
	CASE WHEN YEAR(n30_fecha_sal) = 2009 THEN 1
	END AS anio_09_sal,
	CASE WHEN YEAR(n30_fecha_ing) = 2010 THEN 1
	END AS anio_10_ing,
	CASE WHEN YEAR(n30_fecha_sal) = 2010 THEN 1
	END AS anio_10_sal,
	CASE WHEN YEAR(n30_fecha_ing) = 2011 THEN 1
	END AS anio_11_ing,
	CASE WHEN YEAR(n30_fecha_sal) = 2011 THEN 1
	END AS anio_11_sal,
	CASE WHEN YEAR(n30_fecha_ing) = 2012 THEN 1
	END AS anio_12_ing,
	CASE WHEN YEAR(n30_fecha_sal) = 2012 THEN 1
	END AS anio_12_sal
	FROM rolt030
	WHERE n30_compania          = 1
	  AND n30_cod_depto        IN (7, 8)
	  AND ((n30_estado          = 'A'
	  AND  YEAR(n30_fecha_ing)  > 2008)
	   OR  YEAR(n30_fecha_sal) BETWEEN 2009 AND 2012)
	ORDER BY 1;
