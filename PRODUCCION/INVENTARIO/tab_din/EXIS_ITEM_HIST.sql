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
