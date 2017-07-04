SELECT CASE WHEN MONTH(t23_fec_factura) = 01 THEN "ENERO"
	    WHEN MONTH(t23_fec_factura) = 02 THEN "FEBRERO"
	    WHEN MONTH(t23_fec_factura) = 03 THEN "MARZO"
	    WHEN MONTH(t23_fec_factura) = 04 THEN "ABRIL"
	    WHEN MONTH(t23_fec_factura) = 05 THEN "MAYO"
	    WHEN MONTH(t23_fec_factura) = 06 THEN "JUNIO"
	    WHEN MONTH(t23_fec_factura) = 07 THEN "JULIO"
	    WHEN MONTH(t23_fec_factura) = 08 THEN "AGOSTO"
	    WHEN MONTH(t23_fec_factura) = 09 THEN "SEPTIEMBRE"
	    WHEN MONTH(t23_fec_factura) = 00 THEN "OCTUBRE"
	    WHEN MONTH(t23_fec_factura) = 11 THEN "NOVIEMBRE"
	    WHEN MONTH(t23_fec_factura) = 12 THEN "DICIEMBRE"
	END AS mes_vta,
	t03_iniciales AS AGT,
	t23_cod_cliente AS codcli,
	t23_nom_cliente AS nomcli,
	t23_numpre AS presup,
	t23_orden AS orden,
	"FA" AS codtran,
	CAST (t23_num_factura AS INTEGER) AS numtran,
	CASE WHEN t23_cont_cred = "C"
		THEN "CONTADO"
		ELSE "CREDTIO"
	END AS formpago,
	DATE(t23_fec_factura) AS fecha,
	t24_porc_descto AS dscto,
	SUM(t24_val_descto) AS val_des,
	SUM(t24_valor_tarea) AS val_mo,
	SUM(t24_valor_tarea - t24_val_descto) AS val_tot,
	CASE WHEN t28_num_dev IS NOT NULL
		THEN "DF"
	END AS tipdev,
	t28_num_dev AS numdev
	FROM talt023, talt024, talt003, OUTER talt028
	WHERE t23_compania           = 1
	  AND t23_localidad          = 1
	  AND t23_estado            IN ("F", "D")
	  AND YEAR(t23_fec_factura)  = 2013
	  AND t24_compania           = t23_compania
	  AND t24_localidad          = t23_localidad
	  AND t24_orden              = t23_orden
	  AND t03_compania           = t24_compania
	  AND t03_mecanico           = t24_mecanico
	  AND t28_compania           = t23_compania
	  AND t28_localidad          = t23_localidad
	  AND t28_factura            = t23_num_factura
	  AND YEAR(t28_fec_anula)    = 2013
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 15, 16
UNION
SELECT CASE WHEN MONTH(t28_fec_anula) = 01 THEN "ENERO"
	    WHEN MONTH(t28_fec_anula) = 02 THEN "FEBRERO"
	    WHEN MONTH(t28_fec_anula) = 03 THEN "MARZO"
	    WHEN MONTH(t28_fec_anula) = 04 THEN "ABRIL"
	    WHEN MONTH(t28_fec_anula) = 05 THEN "MAYO"
	    WHEN MONTH(t28_fec_anula) = 06 THEN "JUNIO"
	    WHEN MONTH(t28_fec_anula) = 07 THEN "JULIO"
	    WHEN MONTH(t28_fec_anula) = 08 THEN "AGOSTO"
	    WHEN MONTH(t28_fec_anula) = 09 THEN "SEPTIEMBRE"
	    WHEN MONTH(t28_fec_anula) = 00 THEN "OCTUBRE"
	    WHEN MONTH(t28_fec_anula) = 11 THEN "NOVIEMBRE"
	    WHEN MONTH(t28_fec_anula) = 12 THEN "DICIEMBRE"
	END AS mes_vta,
	t03_iniciales AS AGT,
	t23_cod_cliente AS codcli,
	t23_nom_cliente AS nomcli,
	t23_numpre AS presup,
	t23_orden AS orden,
	"DF" AS codtran,
	CAST (t28_num_dev AS INTEGER) AS numtran,
	CASE WHEN t23_cont_cred = "C"
		THEN "CONTADO"
		ELSE "CREDTIO"
	END AS formpago,
	DATE(t28_fec_anula) AS fecha,
	t24_porc_descto AS dscto,
	SUM(t24_val_descto * (-1)) AS val_des,
	SUM(t24_valor_tarea * (-1)) AS val_mo,
	SUM((t24_valor_tarea - t24_val_descto) * (-1)) AS val_tot,
	"FA" AS tipdev,
	CAST (t28_factura AS INTEGER) AS numdev
	FROM talt028, talt023, talt024, talt003
	WHERE t28_compania        = 1
	  AND t28_localidad       = 1
	  AND YEAR(t28_fec_anula) = 2013
	  AND t23_compania        = t28_compania
	  AND t23_localidad       = t28_localidad
	  AND t23_num_factura     = t28_factura
	  AND t23_estado          = "D"
	  AND t24_compania        = t23_compania
	  AND t24_localidad       = t23_localidad
	  AND t24_orden           = t23_orden
	  AND t03_compania        = t24_compania
	  AND t03_mecanico        = t24_mecanico
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 15, 16
	ORDER BY 10 ASC, 2 ASC;
