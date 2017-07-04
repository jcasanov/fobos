SELECT "GUAYAQUIL" AS loc,
	YEAR(p20_fecha_emi) AS anio,
	CASE WHEN MONTH(p20_fecha_emi) = 01 THEN "ENERO"
	     WHEN MONTH(p20_fecha_emi) = 02 THEN "FEBRERO"
	     WHEN MONTH(p20_fecha_emi) = 03 THEN "MARZO"
	     WHEN MONTH(p20_fecha_emi) = 04 THEN "ABRIL"
	     WHEN MONTH(p20_fecha_emi) = 05 THEN "MAYO"
	     WHEN MONTH(p20_fecha_emi) = 06 THEN "JUNIO"
	     WHEN MONTH(p20_fecha_emi) = 07 THEN "JULIO"
	     WHEN MONTH(p20_fecha_emi) = 08 THEN "AGOSTO"
	     WHEN MONTH(p20_fecha_emi) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(p20_fecha_emi) = 10 THEN "OCTUBRE"
	     WHEN MONTH(p20_fecha_emi) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(p20_fecha_emi) = 12 THEN "DICIEMBRE"
	END AS mes,
	p01_num_doc AS num_d,
	p01_nomprov AS prov,
	p01_direccion1 AS direc,
	CASE WHEN p01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est,
	SUM(p20_valor_cap + p20_valor_int) AS val_doc
	FROM cxpt020, cxpt001
	WHERE p20_compania        = 1
	  AND p20_localidad       = 1
	  AND YEAR(p20_fecha_emi) = 2014
	  AND p01_codprov         = p20_codprov
	GROUP BY 1, 2, 3, 4, 5, 6, 7
UNION ALL
SELECT "GUAYAQUIL" AS loc,
	YEAR(p21_fecha_emi) AS anio,
	CASE WHEN MONTH(p21_fecha_emi) = 01 THEN "ENERO"
	     WHEN MONTH(p21_fecha_emi) = 02 THEN "FEBRERO"
	     WHEN MONTH(p21_fecha_emi) = 03 THEN "MARZO"
	     WHEN MONTH(p21_fecha_emi) = 04 THEN "ABRIL"
	     WHEN MONTH(p21_fecha_emi) = 05 THEN "MAYO"
	     WHEN MONTH(p21_fecha_emi) = 06 THEN "JUNIO"
	     WHEN MONTH(p21_fecha_emi) = 07 THEN "JULIO"
	     WHEN MONTH(p21_fecha_emi) = 08 THEN "AGOSTO"
	     WHEN MONTH(p21_fecha_emi) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(p21_fecha_emi) = 10 THEN "OCTUBRE"
	     WHEN MONTH(p21_fecha_emi) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(p21_fecha_emi) = 12 THEN "DICIEMBRE"
	END AS mes,
	p01_num_doc AS num_d,
	p01_nomprov AS prov,
	p01_direccion1 AS direc,
	CASE WHEN p01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est,
	SUM(p21_valor * (-1)) AS val_doc
	FROM cxpt021, cxpt001
	WHERE p21_compania        = 1
	  AND p21_localidad       = 1
	  AND YEAR(p21_fecha_emi) = 2014
	  AND p01_codprov         = p21_codprov
	GROUP BY 1, 2, 3, 4, 5, 6, 7
UNION ALL
SELECT "QUITO" AS loc,
	YEAR(p20_fecha_emi) AS anio,
	CASE WHEN MONTH(p20_fecha_emi) = 01 THEN "ENERO"
	     WHEN MONTH(p20_fecha_emi) = 02 THEN "FEBRERO"
	     WHEN MONTH(p20_fecha_emi) = 03 THEN "MARZO"
	     WHEN MONTH(p20_fecha_emi) = 04 THEN "ABRIL"
	     WHEN MONTH(p20_fecha_emi) = 05 THEN "MAYO"
	     WHEN MONTH(p20_fecha_emi) = 06 THEN "JUNIO"
	     WHEN MONTH(p20_fecha_emi) = 07 THEN "JULIO"
	     WHEN MONTH(p20_fecha_emi) = 08 THEN "AGOSTO"
	     WHEN MONTH(p20_fecha_emi) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(p20_fecha_emi) = 10 THEN "OCTUBRE"
	     WHEN MONTH(p20_fecha_emi) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(p20_fecha_emi) = 12 THEN "DICIEMBRE"
	END AS mes,
	p01_num_doc AS num_d,
	p01_nomprov AS prov,
	p01_direccion1 AS direc,
	CASE WHEN p01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est,
	SUM(p20_valor_cap + p20_valor_int) AS val_doc
	FROM acero_qm@idsuio01:cxpt020,
		acero_qm@idsuio01:cxpt001
	WHERE p20_compania         = 1
	  AND p20_localidad       IN (3, 4, 5)
	  AND YEAR(p20_fecha_emi)  = 2014
	  AND p01_codprov          = p20_codprov
	GROUP BY 1, 2, 3, 4, 5, 6, 7
UNION ALL
SELECT "QUITO" AS loc,
	YEAR(p21_fecha_emi) AS anio,
	CASE WHEN MONTH(p21_fecha_emi) = 01 THEN "ENERO"
	     WHEN MONTH(p21_fecha_emi) = 02 THEN "FEBRERO"
	     WHEN MONTH(p21_fecha_emi) = 03 THEN "MARZO"
	     WHEN MONTH(p21_fecha_emi) = 04 THEN "ABRIL"
	     WHEN MONTH(p21_fecha_emi) = 05 THEN "MAYO"
	     WHEN MONTH(p21_fecha_emi) = 06 THEN "JUNIO"
	     WHEN MONTH(p21_fecha_emi) = 07 THEN "JULIO"
	     WHEN MONTH(p21_fecha_emi) = 08 THEN "AGOSTO"
	     WHEN MONTH(p21_fecha_emi) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(p21_fecha_emi) = 10 THEN "OCTUBRE"
	     WHEN MONTH(p21_fecha_emi) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(p21_fecha_emi) = 12 THEN "DICIEMBRE"
	END AS mes,
	p01_num_doc AS num_d,
	p01_nomprov AS prov,
	p01_direccion1 AS direc,
	CASE WHEN p01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS est,
	SUM(p21_valor * (-1)) AS val_doc
	FROM acero_qm@idsuio01:cxpt021,
		acero_qm@idsuio01:cxpt001
	WHERE p21_compania         = 1
	  AND p21_localidad       IN (3, 4, 5)
	  AND YEAR(p21_fecha_emi)  = 2014
	  AND p01_codprov          = p21_codprov
	GROUP BY 1, 2, 3, 4, 5, 6, 7;
