SELECT anio, mes, "TODOS" mes_sto,
	CASE WHEN 1 = 1
		THEN loc
		ELSE ""
	END AS localidad,
	tipo AS tipo_tran, linea, clase, item, desc_item AS descripcion, marca,
	filtro, costo
	FROM tmp_vcs_bd
	WHERE tipo = "01_STOCK_INICIAL"
UNION ALL
SELECT anio, "TODOS" mes, mes mes_sto,
	CASE WHEN 1 = 1
		THEN loc
		ELSE ""
	END AS localidad,
	tipo AS tipo_tran, linea, clase, item, desc_item AS descripcion, marca,
	filtro, costo
	FROM tmp_vcs_bd
	WHERE tipo = "02_COMPRAS"
UNION ALL
SELECT anio, "TODOS" mes, mes mes_sto,
	CASE WHEN 1 = 1
		THEN loc
		ELSE ""
	END AS localidad,
	tipo AS tipo_tran, linea, clase, item, desc_item AS descripcion, marca,
	filtro, costo
	FROM tmp_vcs_bd
	WHERE tipo = "03_TRANSFERENCIA"
UNION ALL
SELECT anio, "TODOS" mes, mes mes_sto,
	CASE WHEN 1 = 1
		THEN loc
		ELSE ""
	END AS localidad,
	tipo AS tipo_tran, linea, clase, item, desc_item AS descripcion, marca,
	filtro, costo
	FROM tmp_vcs_bd
	WHERE tipo = "04_AJUSTES"
UNION ALL
SELECT anio, "TODOS" mes, mes mes_sto,
	CASE WHEN 1 = 1
		THEN loc
		ELSE ""
	END AS localidad,
	tipo AS tipo_tran, linea, clase, item, desc_item AS descripcion, marca,
	filtro, costo
	FROM tmp_vcs_bd
	WHERE tipo = "05_VENTAS"
