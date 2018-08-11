SELECT EXTEND(MDY(CASE WHEN mes = "ENE" THEN 01
		     WHEN mes = "FEB" THEN 02
		     WHEN mes = "MAR" THEN 03
		     WHEN mes = "ABR" THEN 04
		     WHEN mes = "MAY" THEN 05
		     WHEN mes = "JUN" THEN 06
		     WHEN mes = "JUL" THEN 07
		     WHEN mes = "AGO" THEN 08
		     WHEN mes = "SEP" THEN 09
		     WHEN mes = "OCT" THEN 10
		     WHEN mes = "NOV" THEN 11
		     WHEN mes = "DIC" THEN 12
		END,
		01,
		anio),
		YEAR TO MONTH) AS periodo,
	CASE WHEN 1 = 1 THEN loc ELSE "" END AS localidad,
	tipo,
	linea,
	grupo,
	cod_cla,
	clase,
	item,
	desc_item,
	marca,
	filtro,
	bodega,
	cantidad AS unidades,
	costo AS valoracion
	FROM tmp_vcs_bd
	WHERE tipo = "01_STOCK_INICIAL"
	  AND anio > 2008
UNION
SELECT EXTEND(MDY(CASE WHEN mes = "ENE" THEN 01
		     WHEN mes = "FEB" THEN 02
		     WHEN mes = "MAR" THEN 03
		     WHEN mes = "ABR" THEN 04
		     WHEN mes = "MAY" THEN 05
		     WHEN mes = "JUN" THEN 06
		     WHEN mes = "JUL" THEN 07
		     WHEN mes = "AGO" THEN 08
		     WHEN mes = "SEP" THEN 09
		     WHEN mes = "OCT" THEN 10
		     WHEN mes = "NOV" THEN 11
		     WHEN mes = "DIC" THEN 12
		END,
		01,
		anio),
		YEAR TO MONTH) AS periodo,
	loc AS localidad,
	tipo,
	linea,
	grupo,
	cod_cla,
	clase,
	item,
	desc_item,
	marca,
	filtro,
	bodega,
	cantidad AS unidades,
	valor AS valoracion
	FROM tmp_vcs_bd
	WHERE tipo = "05_VENTAS"
	  AND anio > 2008
