SELECT CASE WHEN r22_localidad = 01 THEN "01 GYE J T M"
	    WHEN r22_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r22_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r22_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r22_localidad = 05 THEN "05 ACERO KHOLER"
	END AS localidad,
	YEAR(r21_fecing) AS anio,
	r01_nombres AS vendedor,
	r21_codcli AS cod_cli,
	r21_nomcli AS nom_cli,
	LPAD(ROUND((DATE(r21_fecing) - MDY(1, 3, YEAR(DATE(r21_fecing)
		- WEEKDAY(DATE(r21_fecing) - 1 UNITS DAY) + 4 UNITS DAY))
		+ WEEKDAY(MDY(1, 3, YEAR(DATE(r21_fecing)
		- WEEKDAY(DATE(r21_fecing) - 1 UNITS DAY) + 4 UNITS DAY)))
		+ 5) / 7, 0), 2, 0) || " - " ||
	CASE WHEN MONTH(r21_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(r21_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(r21_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(r21_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(r21_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(r21_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(r21_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(r21_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(r21_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(r21_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(r21_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(r21_fecing) = 12 THEN "DICIEMBRE"
	END || " " || YEAR(r21_fecing) AS num_sem,
	CASE WHEN r01_tipo = "I" THEN "VENDEDOR ALMACEN"
	     WHEN r01_tipo = "E" THEN "VENDEDOR EXTERNO"
	     WHEN r01_tipo = "B" THEN "BODEGUERO"
	     WHEN r01_tipo = "J" THEN "JEFE DE VENTAS"
	     WHEN r01_tipo = "G" THEN "GERENTE VENTAS"
	END AS tip_v,
	NVL(SUM((r22_cantidad * r22_precio) - r22_val_descto), 0) AS valor
	FROM acero_gm@idsgye01:rept021, acero_gm@idsgye01:rept022,
		acero_gm@idsgye01:rept001
	WHERE r21_compania      = 1
	  AND r21_localidad     = 1
	  AND YEAR(r21_fecing) >= 2012
	  AND r22_compania      = r21_compania
	  AND r22_localidad     = r21_localidad
	  AND r22_numprof       = r21_numprof
	  AND r01_compania      = r21_compania
	  AND r01_codigo        = r21_vendedor
	GROUP BY 1, 2, 3, 4, 5, 6, 7
UNION
SELECT CASE WHEN r22_localidad = 01 THEN "01 GYE J T M"
	    WHEN r22_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r22_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r22_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r22_localidad = 05 THEN "05 ACERO KHOLER"
	END AS localidad,
	YEAR(r21_fecing) AS anio,
	r01_nombres AS vendedor,
	r21_codcli AS cod_cli,
	r21_nomcli AS nom_cli,
	LPAD(ROUND((DATE(r21_fecing) - MDY(1, 3, YEAR(DATE(r21_fecing)
		- WEEKDAY(DATE(r21_fecing) - 1 UNITS DAY) + 4 UNITS DAY))
		+ WEEKDAY(MDY(1, 3, YEAR(DATE(r21_fecing)
		- WEEKDAY(DATE(r21_fecing) - 1 UNITS DAY) + 4 UNITS DAY)))
		+ 5) / 7, 0), 2, 0) || " - " ||
	CASE WHEN MONTH(r21_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(r21_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(r21_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(r21_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(r21_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(r21_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(r21_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(r21_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(r21_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(r21_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(r21_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(r21_fecing) = 12 THEN "DICIEMBRE"
	END || " " || YEAR(r21_fecing) AS num_sem,
	CASE WHEN r01_tipo = "I" THEN "VENDEDOR ALMACEN"
	     WHEN r01_tipo = "E" THEN "VENDEDOR EXTERNO"
	     WHEN r01_tipo = "B" THEN "BODEGUERO"
	     WHEN r01_tipo = "J" THEN "JEFE DE VENTAS"
	     WHEN r01_tipo = "G" THEN "GERENTE VENTAS"
	END AS tip_v,
	NVL(SUM((r22_cantidad * r22_precio) - r22_val_descto), 0) AS valor
	FROM acero_qm@acgyede:rept021, acero_qm@acgyede:rept022,
		acero_qm@acgyede:rept001
	WHERE r21_compania      = 1
	  AND r21_localidad    IN (3, 5)
	  AND YEAR(r21_fecing) >= 2012
	  AND r22_compania      = r21_compania
	  AND r22_localidad     = r21_localidad
	  AND r22_numprof       = r21_numprof
	  AND r01_compania      = r21_compania
	  AND r01_codigo        = r21_vendedor
	GROUP BY 1, 2, 3, 4, 5, 6, 7
UNION
SELECT CASE WHEN r22_localidad = 01 THEN "01 GYE J T M"
	    WHEN r22_localidad = 02 THEN "02 GYE CENTRO"
	    WHEN r22_localidad = 03 THEN "03 ACERO MATRIZ"
	    WHEN r22_localidad = 04 THEN "04 ACERO SUR"
	    WHEN r22_localidad = 05 THEN "05 ACERO KHOLER"
	END AS localidad,
	YEAR(r21_fecing) AS anio,
	r01_nombres AS vendedor,
	r21_codcli AS cod_cli,
	r21_nomcli AS nom_cli,
	LPAD(ROUND((DATE(r21_fecing) - MDY(1, 3, YEAR(DATE(r21_fecing)
		- WEEKDAY(DATE(r21_fecing) - 1 UNITS DAY) + 4 UNITS DAY))
		+ WEEKDAY(MDY(1, 3, YEAR(DATE(r21_fecing)
		- WEEKDAY(DATE(r21_fecing) - 1 UNITS DAY) + 4 UNITS DAY)))
		+ 5) / 7, 0), 2, 0) || " - " ||
	CASE WHEN MONTH(r21_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(r21_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(r21_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(r21_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(r21_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(r21_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(r21_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(r21_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(r21_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(r21_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(r21_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(r21_fecing) = 12 THEN "DICIEMBRE"
	END || " " || YEAR(r21_fecing) AS num_sem,
	CASE WHEN r01_tipo = "I" THEN "VENDEDOR ALMACEN"
	     WHEN r01_tipo = "E" THEN "VENDEDOR EXTERNO"
	     WHEN r01_tipo = "B" THEN "BODEGUERO"
	     WHEN r01_tipo = "J" THEN "JEFE DE VENTAS"
	     WHEN r01_tipo = "G" THEN "GERENTE VENTAS"
	END AS tip_v,
	NVL(SUM((r22_cantidad * r22_precio) - r22_val_descto), 0) AS valor
	FROM acero_qs@acgyede:rept021, acero_qs@acgyede:rept022,
		acero_qs@acgyede:rept001
	WHERE r21_compania      = 1
	  AND r21_localidad     = 4
	  AND YEAR(r21_fecing) >= 2012
	  AND r22_compania      = r21_compania
	  AND r22_localidad     = r21_localidad
	  AND r22_numprof       = r21_numprof
	  AND r01_compania      = r21_compania
	  AND r01_codigo        = r21_vendedor
	GROUP BY 1, 2, 3, 4, 5, 6, 7;
