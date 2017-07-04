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
	r11_stock_act AS stock
	FROM rept011
	WHERE r11_compania   = 1
	  AND r11_stock_act <> 0;
