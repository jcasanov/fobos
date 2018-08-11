SELECT YEAR(t23_fecing) AS anio,
	CASE WHEN MONTH(t23_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(t23_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(t23_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(t23_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(t23_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(t23_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(t23_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(t23_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(t23_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(t23_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(t23_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(t23_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	"ORDENES ACTIVAS" AS tipo,
	fp_numero_semana(DATE(t23_fecing)) AS num_sem,
	COUNT(*) AS ctas
	FROM talt023
	WHERE t23_compania  = 1
	  AND t23_localidad = 1
	  AND t23_estado    = "A"
	GROUP BY 1, 2, 3, 4
UNION
SELECT YEAR(t23_fec_cierre) AS anio,
	CASE WHEN MONTH(t23_fec_cierre) = 01 THEN "ENERO"
	     WHEN MONTH(t23_fec_cierre) = 02 THEN "FEBRERO"
	     WHEN MONTH(t23_fec_cierre) = 03 THEN "MARZO"
	     WHEN MONTH(t23_fec_cierre) = 04 THEN "ABRIL"
	     WHEN MONTH(t23_fec_cierre) = 05 THEN "MAYO"
	     WHEN MONTH(t23_fec_cierre) = 06 THEN "JUNIO"
	     WHEN MONTH(t23_fec_cierre) = 07 THEN "JULIO"
	     WHEN MONTH(t23_fec_cierre) = 08 THEN "AGOSTO"
	     WHEN MONTH(t23_fec_cierre) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(t23_fec_cierre) = 10 THEN "OCTUBRE"
	     WHEN MONTH(t23_fec_cierre) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(t23_fec_cierre) = 12 THEN "DICIEMBRE"
	END AS mes,
	"ORDENES ACTIVAS" AS tipo,
	fp_numero_semana(DATE(t23_fec_cierre)) AS num_sem,
	COUNT(*) AS ctas
	FROM talt023
	WHERE t23_compania  = 1
	  AND t23_localidad = 1
	  AND t23_estado    = "C"
	GROUP BY 1, 2, 3, 4
UNION
SELECT YEAR(t23_fec_cierre) AS anio,
	CASE WHEN MONTH(t23_fec_cierre) = 01 THEN "ENERO"
	     WHEN MONTH(t23_fec_cierre) = 02 THEN "FEBRERO"
	     WHEN MONTH(t23_fec_cierre) = 03 THEN "MARZO"
	     WHEN MONTH(t23_fec_cierre) = 04 THEN "ABRIL"
	     WHEN MONTH(t23_fec_cierre) = 05 THEN "MAYO"
	     WHEN MONTH(t23_fec_cierre) = 06 THEN "JUNIO"
	     WHEN MONTH(t23_fec_cierre) = 07 THEN "JULIO"
	     WHEN MONTH(t23_fec_cierre) = 08 THEN "AGOSTO"
	     WHEN MONTH(t23_fec_cierre) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(t23_fec_cierre) = 10 THEN "OCTUBRE"
	     WHEN MONTH(t23_fec_cierre) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(t23_fec_cierre) = 12 THEN "DICIEMBRE"
	END AS mes,
	"ORDENES ACTIVAS" AS tipo,
	fp_numero_semana(DATE(t23_fec_elimin)) AS num_sem,
	COUNT(*) AS ctas
	FROM talt023
	WHERE t23_compania  = 1
	  AND t23_localidad = 1
	  AND t23_estado    = "E"
	GROUP BY 1, 2, 3, 4
UNION
SELECT YEAR(t23_fec_factura) AS anio,
	CASE WHEN MONTH(t23_fec_factura) = 01 THEN "ENERO"
	     WHEN MONTH(t23_fec_factura) = 02 THEN "FEBRERO"
	     WHEN MONTH(t23_fec_factura) = 03 THEN "MARZO"
	     WHEN MONTH(t23_fec_factura) = 04 THEN "ABRIL"
	     WHEN MONTH(t23_fec_factura) = 05 THEN "MAYO"
	     WHEN MONTH(t23_fec_factura) = 06 THEN "JUNIO"
	     WHEN MONTH(t23_fec_factura) = 07 THEN "JULIO"
	     WHEN MONTH(t23_fec_factura) = 08 THEN "AGOSTO"
	     WHEN MONTH(t23_fec_factura) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(t23_fec_factura) = 10 THEN "OCTUBRE"
	     WHEN MONTH(t23_fec_factura) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(t23_fec_factura) = 12 THEN "DICIEMBRE"
	END AS mes,
	"ORDENES ACTIVAS" AS tipo,
	fp_numero_semana(DATE(t23_fec_factura)) AS num_sem,
	COUNT(*) AS ctas
	FROM talt023
	WHERE t23_compania  = 1
	  AND t23_localidad = 1
	  AND t23_estado    = "F"
	GROUP BY 1, 2, 3, 4
UNION
SELECT YEAR(t28_fec_anula) AS anio,
	CASE WHEN MONTH(t28_fec_anula) = 01 THEN "ENERO"
	     WHEN MONTH(t28_fec_anula) = 02 THEN "FEBRERO"
	     WHEN MONTH(t28_fec_anula) = 03 THEN "MARZO"
	     WHEN MONTH(t28_fec_anula) = 04 THEN "ABRIL"
	     WHEN MONTH(t28_fec_anula) = 05 THEN "MAYO"
	     WHEN MONTH(t28_fec_anula) = 06 THEN "JUNIO"
	     WHEN MONTH(t28_fec_anula) = 07 THEN "JULIO"
	     WHEN MONTH(t28_fec_anula) = 08 THEN "AGOSTO"
	     WHEN MONTH(t28_fec_anula) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(t28_fec_anula) = 10 THEN "OCTUBRE"
	     WHEN MONTH(t28_fec_anula) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(t28_fec_anula) = 12 THEN "DICIEMBRE"
	END AS mes,
	"ORDENES ACTIVAS" AS tipo,
	fp_numero_semana(DATE(t28_fec_anula)) AS num_sem,
	COUNT(*) AS ctas
	FROM talt023, talt028
	WHERE t23_compania  = 1
	  AND t23_localidad = 1
	  AND t23_estado    = "D"
	  AND t28_compania  = t23_compania
	  AND t28_localidad = t23_localidad
	  AND t28_factura   = t23_num_factura
	GROUP BY 1, 2, 3, 4
