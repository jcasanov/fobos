SELECT CASE WHEN r20_localidad = 01 THEN "01 GYE J T M"
	    WHEN r20_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r20_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r20_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r20_localidad = 05 THEN "05 ACERO KHOLER"
	END AS localidad,
	r20_cliente AS cod_cli,
	z01_nomcli AS nom_cli,
	r01_nombres AS vendedor,
	(EXTEND(TODAY - 1 UNITS YEAR, YEAR TO MONTH) || " - " ||
	 EXTEND(TODAY, YEAR TO MONTH)) AS periodo,
	NVL(SUM((r20_cant_ven * r20_precio) - r20_val_descto), 0) AS valor,
	r10_marca AS marca
	FROM venta, item, vendedor, cliente
	WHERE r20_localidad IN (1, 2)
	  AND EXTEND(r20_fecing, YEAR TO MONTH) >=
		EXTEND(TODAY - 1 UNITS YEAR, YEAR TO MONTH)
	  AND r10_codigo     = r20_item
	  AND z01_localidad  = r20_localidad
	  AND z01_codcli     = r20_cliente
	  AND r01_localidad  = r20_localidad
	  AND r01_codigo     = r20_vendedor
	GROUP BY 1, 2, 3, 4, 5, 7
	ORDER BY 6 DESC, 3 ASC;
