SELECT anio, mes,
	CASE WHEN 1 = 1
		THEN loc
		ELSE ""
	END AS localidad,
	tipo AS tipo_tran, linea, clase, item, desc_item AS descripcion, marca,
	filtro, costo
	FROM tmp_vcs_bd
	WHERE tipo = "01_STOCK_INICIAL"
UNION ALL
SELECT anio, "TODOS" mes,
	CASE WHEN 1 = 1
		THEN loc
		ELSE ""
	END AS localidad,
	tipo AS tipo_tran, linea, clase, item, desc_item AS descripcion, marca,
	filtro, costo
	FROM tmp_vcs_bd
	WHERE tipo = "01_STOCK_INICIAL"
	  AND mes  = "DIC"
UNION ALL
SELECT anio, "TODOS" mes,
	CASE WHEN 1 = 1
		THEN loc
		ELSE ""
	END AS localidad,
	tipo AS tipo_tran, linea, clase, item, desc_item AS descripcion, marca,
	filtro, SUM(costo) costo
	FROM tmp_vcs_bd
	WHERE tipo = "02_COMPRAS"
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
UNION ALL
SELECT anio, "TODOS" mes,
	CASE WHEN 1 = 1
		THEN loc
		ELSE ""
	END AS localidad,
	tipo AS tipo_tran, linea, clase, item, desc_item AS descripcion, marca,
	filtro, SUM(costo) costo
	FROM tmp_vcs_bd
	WHERE tipo = "03_TRANSFERENCIA"
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
UNION ALL
SELECT anio, "TODOS" mes,
	CASE WHEN 1 = 1
		THEN loc
		ELSE ""
	END AS localidad,
	tipo AS tipo_tran, linea, clase, item, desc_item AS descripcion, marca,
	filtro, SUM(costo) costo
	FROM tmp_vcs_bd
	WHERE tipo = "04_AJUSTES"
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
UNION ALL
SELECT anio, "TODOS" mes,
	CASE WHEN 1 = 1
		THEN loc
		ELSE ""
	END AS localidad,
	tipo AS tipo_tran, linea, clase, item, desc_item AS descripcion, marca,
	filtro, SUM(costo) costo
	FROM tmp_vcs_bd
	WHERE tipo = "05_VENTAS"
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10;
