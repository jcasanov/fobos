SELECT YEAR(TODAY) AS anio,
	CASE WHEN MONTH(n30_fecha_nacim) = 01 THEN "01_ENERO"
	     WHEN MONTH(n30_fecha_nacim) = 02 THEN "02_FEBRERO"
	     WHEN MONTH(n30_fecha_nacim) = 03 THEN "03_MARZO"
	     WHEN MONTH(n30_fecha_nacim) = 04 THEN "04_ABRIL"
	     WHEN MONTH(n30_fecha_nacim) = 05 THEN "05_MAYO"
	     WHEN MONTH(n30_fecha_nacim) = 06 THEN "06_JUNIO"
	     WHEN MONTH(n30_fecha_nacim) = 07 THEN "07_JULIO"
	     WHEN MONTH(n30_fecha_nacim) = 08 THEN "08_AGOSTO"
	     WHEN MONTH(n30_fecha_nacim) = 09 THEN "09_SEPTIEMBRE"
	     WHEN MONTH(n30_fecha_nacim) = 10 THEN "10_OCTUBRE"
	     WHEN MONTH(n30_fecha_nacim) = 11 THEN "11_NOVIEMBRE"
	     WHEN MONTH(n30_fecha_nacim) = 12 THEN "12_DICIEMBRE"
	END AS mes,
	n30_cod_trab AS cod,
	n30_nombres AS empleado,
	MDY(MONTH(n30_fecha_nacim), DAY(n30_fecha_nacim), YEAR(TODAY)) AS fecha,
	CASE WHEN TODAY < MDY(MONTH(n30_fecha_nacim), DAY(n30_fecha_nacim),
			YEAR(TODAY))
		THEN "FALTAN " || (MDY(MONTH(n30_fecha_nacim),
				 DAY(n30_fecha_nacim), YEAR(TODAY)) - TODAY)
			|| " DÍAS"
	     WHEN TODAY = MDY(MONTH(n30_fecha_nacim), DAY(n30_fecha_nacim),
			YEAR(TODAY))
		THEN "HOY ES SU CUMPLEAÑOS"
		ELSE "EL CUMPLEAÑOS FUE HACE " || (TODAY -
			MDY(MONTH(n30_fecha_nacim), DAY(n30_fecha_nacim),
				YEAR(TODAY)))
			|| " DÍAS"
	END AS est
	FROM rolt030
	WHERE n30_compania = 1
	  AND n30_estado   = 'A'
	ORDER BY 5, 4;
