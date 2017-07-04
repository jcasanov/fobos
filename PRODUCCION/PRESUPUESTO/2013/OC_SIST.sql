SELECT YEAR(c13_fecha_recep) AS anio,
	CASE WHEN MONTH(c13_fecha_recep) = 01 THEN "ENERO"
	     WHEN MONTH(c13_fecha_recep) = 02 THEN "FEBRERO"
	     WHEN MONTH(c13_fecha_recep) = 03 THEN "MARZO"
	     WHEN MONTH(c13_fecha_recep) = 04 THEN "ABRIL"
	     WHEN MONTH(c13_fecha_recep) = 05 THEN "MAYO"
	     WHEN MONTH(c13_fecha_recep) = 06 THEN "JUNIO"
	     WHEN MONTH(c13_fecha_recep) = 07 THEN "JULIO"
	     WHEN MONTH(c13_fecha_recep) = 08 THEN "AGOSTO"
	     WHEN MONTH(c13_fecha_recep) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(c13_fecha_recep) = 10 THEN "OCTUBRE"
	     WHEN MONTH(c13_fecha_recep) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(c13_fecha_recep) = 12 THEN "DICIEMBRE"
	END AS mes,
	c13_numero_oc AS num_oc,
	c13_factura AS fact,
	c10_referencia AS refer,
	c10_solicitado AS solic,
	c10_tipo_orden AS tip_oc,
	c01_nombre AS nom_tip,
	c10_codprov AS codprov,
	p01_nomprov AS nomprov,
	c14_codigo AS item,
	c14_descrip AS descrip,
	c14_cantidad AS cant,
	NVL((c14_cantidad * c14_precio) - c14_val_descto, 0.00) AS prec,
	CASE WHEN c10_estado = "A" THEN "ACTIVA"
	     WHEN c10_estado = "P" THEN "APROBADA"
	     WHEN c10_estado = "C" THEN "CERRADA"
	     WHEN c10_estado = "E" THEN "ELIMINADA"
	END AS est
	FROM ordt010, ordt001, ordt013, ordt014, cxpt001
	WHERE  c10_compania    = 1
	  AND  c10_localidad   = 1
	  AND  c10_estado      = "C"
	  AND (c10_cod_depto   = 5
	   OR  c10_codprov    IN (112, 296, 371, 480, 593, 624, 793, 634, 886,
				1117, 1155, 1176))
	  AND c01_tipo_orden   = c10_tipo_orden
	  AND c13_compania     = c10_compania
	  AND c13_localidad    = c10_localidad
	  AND c13_numero_oc    = c10_numero_oc
	  AND c14_compania     = c13_compania
	  AND c14_localidad    = c13_localidad
	  AND c14_numero_oc    = c13_numero_oc
	  AND c14_num_recep    = c13_num_recep
	  AND p01_codprov      = c10_codprov;
