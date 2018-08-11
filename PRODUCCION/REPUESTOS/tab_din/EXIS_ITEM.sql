SELECT YEAR(TODAY) AS anio,
	CASE WHEN MONTH(TODAY) = 01 THEN "ENERO"
	     WHEN MONTH(TODAY) = 02 THEN "FEBRERO"
	     WHEN MONTH(TODAY) = 03 THEN "MARZO"
	     WHEN MONTH(TODAY) = 04 THEN "ABRIL"
	     WHEN MONTH(TODAY) = 05 THEN "MAYO"
	     WHEN MONTH(TODAY) = 06 THEN "JUNIO"
	     WHEN MONTH(TODAY) = 07 THEN "JULIO"
	     WHEN MONTH(TODAY) = 08 THEN "AGOSTO"
	     WHEN MONTH(TODAY) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(TODAY) = 10 THEN "OCTUBRE"
	     WHEN MONTH(TODAY) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(TODAY) = 12 THEN "DICIEMBRE"
	END AS mes,
	(SELECT CASE WHEN r02_localidad IN (1, 2) THEN
			(SELECT g02_abreviacion
				FROM gent002
				WHERE g02_compania  = r02_compania
				  AND g02_localidad = 1)
		     WHEN r02_localidad IN (3, 4, 5) THEN
			(SELECT g02_abreviacion
				FROM gent002
				WHERE g02_compania  = r02_compania
				  AND g02_localidad = 3)
		END
		FROM rept002
		WHERE r02_compania = r11_compania
		  AND r02_codigo   = r11_bodega) AS local,
	r11_bodega AS bd,
	CAST(r11_item AS INTEGER) AS item,
	r11_stock_act AS stock,
	0.00 AS prec,
	0.00 AS cost
	FROM rept011
	WHERE r11_compania   = 1
	  AND r11_stock_act <> 0
UNION ALL
SELECT r31_ano AS anio,
	CASE WHEN r31_mes = 01 THEN "ENERO"
	     WHEN r31_mes = 02 THEN "FEBRERO"
	     WHEN r31_mes = 03 THEN "MARZO"
	     WHEN r31_mes = 04 THEN "ABRIL"
	     WHEN r31_mes = 05 THEN "MAYO"
	     WHEN r31_mes = 06 THEN "JUNIO"
	     WHEN r31_mes = 07 THEN "JULIO"
	     WHEN r31_mes = 08 THEN "AGOSTO"
	     WHEN r31_mes = 09 THEN "SEPTIEMBRE"
	     WHEN r31_mes = 10 THEN "OCTUBRE"
	     WHEN r31_mes = 11 THEN "NOVIEMBRE"
	     WHEN r31_mes = 12 THEN "DICIEMBRE"
	END AS mes,
	(SELECT CASE WHEN r02_localidad IN (1, 2) THEN
			(SELECT g02_abreviacion
				FROM gent002
				WHERE g02_compania  = r02_compania
				  AND g02_localidad = 1)
		     WHEN r02_localidad IN (3, 4, 5) THEN
			(SELECT g02_abreviacion
				FROM gent002
				WHERE g02_compania  = r02_compania
				  AND g02_localidad = 3)
		END
		FROM rept002
		WHERE r02_compania = r31_compania
		  AND r02_codigo   = r31_bodega) AS local,
	r31_bodega AS bd,
	CAST(r31_item AS INTEGER) AS item,
	r31_stock AS stock,
	r31_precio_mb AS prec,
	r31_costo_mb AS cost
	FROM rept031
	WHERE r31_compania  = 1
	  AND r31_ano       > 2010
	  AND r31_stock    <> 0;
