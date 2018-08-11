SELECT YEAR(r19_fecing) AS anio,
	CASE WHEN MONTH(r19_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(r19_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(r19_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(r19_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(r19_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(r19_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(r19_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(r19_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(r19_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(r19_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(r19_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(r19_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	(SELECT LPAD(r19_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM gent002
		WHERE g02_compania  = r19_compania
		  AND g02_localidad = r19_localidad) AS local,
	DATE(r19_fecing) AS fecha,
	r19_cod_tran AS tp,
	r19_num_tran AS num,
	r19_codcli AS codcli,
	r19_nomcli AS nomcli,
	LPAD(r19_vendedor, 3, 0) || " " || TRIM(r01_nombres) AS vend,
	NVL((SELECT LPAD(z02_zona_cobro, 2, 0) || " " || TRIM(z06_nombre)
		FROM cxct002, cxct006
		WHERE z02_compania   = r19_compania
		  AND z02_localidad  = r19_localidad
		  AND z02_codcli     = r19_codcli
		  AND z06_zona_cobro = z02_zona_cobro),
		"SIN COBRADOR") AS zon_c,
	NVL((SELECT LPAD(z02_zona_venta, 3, 0) || " " || TRIM(g32_nombre)
		FROM cxct002, gent032
		WHERE z02_compania   = r19_compania
		  AND z02_localidad  = r19_localidad
		  AND z02_codcli     = r19_codcli
		  AND g32_compania   = z02_compania
		  AND g32_zona_venta = z02_zona_venta),
		"SIN ZONA VENTA") AS zon_v,
	CASE WHEN r19_cont_cred = "C"
		THEN "CONTADO"
		ELSE "CREDITO"
	END AS for_pag,
	CASE WHEN (SELECT COUNT(*)
			FROM cajt014
			WHERE j14_compania  = r19_compania
			  AND j14_localidad = r19_localidad
			  AND j14_cod_tran  = r19_cod_tran
			  AND j14_num_tran  = r19_num_tran) > 0
		THEN "CON RETENCION"
		ELSE "SIN RETENCION"
	END AS reten,
	(r19_tot_bruto - r19_tot_dscto) AS subt
	FROM rept019, rept001
	WHERE  r19_compania      = 1
	  AND  r19_localidad     = 1
	  AND  r19_cod_tran      = "FA"
	  AND (r19_tipo_dev     IS NULL
	   OR  r19_tipo_dev     <> "AF")
	  AND  YEAR(r19_fecing)  > 2007
	  AND  r01_compania      = r19_compania
	  AND  r01_codigo        = r19_vendedor
{--
UNION
SELECT YEAR(r19_fecing) AS anio,
	CASE WHEN MONTH(r19_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(r19_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(r19_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(r19_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(r19_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(r19_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(r19_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(r19_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(r19_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(r19_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(r19_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(r19_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	(SELECT LPAD(r19_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_gc:gent002
		WHERE g02_compania  = r19_compania
		  AND g02_localidad = r19_localidad) AS local,
	DATE(r19_fecing) AS fecha,
	r19_cod_tran AS tp,
	r19_num_tran AS num,
	r19_codcli AS codcli,
	r19_nomcli AS nomcli,
	LPAD(r19_vendedor, 3, 0) || " " || TRIM(r01_nombres) AS vend,
	NVL((SELECT LPAD(z02_zona_cobro, 2, 0) || " " || TRIM(z06_nombre)
		FROM acero_gc:cxct002, acero_gc:cxct006
		WHERE z02_compania   = r19_compania
		  AND z02_localidad  = r19_localidad
		  AND z02_codcli     = r19_codcli
		  AND z06_zona_cobro = z02_zona_cobro),
		"SIN COBRADOR") AS zon_c,
	NVL((SELECT LPAD(z02_zona_venta, 3, 0) || " " || TRIM(g32_nombre)
		FROM acero_gc:cxct002, acero_gc:gent032
		WHERE z02_compania   = r19_compania
		  AND z02_localidad  = r19_localidad
		  AND z02_codcli     = r19_codcli
		  AND g32_compania   = z02_compania
		  AND g32_zona_venta = z02_zona_venta),
		"SIN ZONA VENTA") AS zon_v,
	CASE WHEN r19_cont_cred = "C"
		THEN "CONTADO"
		ELSE "CREDITO"
	END AS for_pag,
	CASE WHEN (SELECT COUNT(*)
			FROM acero_gc:cajt014
			WHERE j14_compania  = r19_compania
			  AND j14_localidad = r19_localidad
			  AND j14_cod_tran  = r19_cod_tran
			  AND j14_num_tran  = r19_num_tran) > 0
		THEN "CON RETENCION"
		ELSE "SIN RETENCION"
	END AS reten,
	DATE(r19_fecing) AS fecha,
	(r19_tot_bruto - r19_tot_dscto) AS subt
	FROM acero_gc:rept019, acero_gc:rept001
	WHERE  r19_compania      = 1
	  AND  r19_localidad     = 2
	  AND  r19_cod_tran      = "FA"
	  AND (r19_tipo_dev     IS NULL
	   OR  r19_tipo_dev     <> "AF")
	  AND  YEAR(r19_fecing)  > 2007
	  AND  r01_compania      = r19_compania
	  AND  r01_codigo        = r19_vendedor
UNION
SELECT YEAR(r19_fecing) AS anio,
	CASE WHEN MONTH(r19_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(r19_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(r19_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(r19_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(r19_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(r19_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(r19_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(r19_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(r19_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(r19_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(r19_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(r19_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	(SELECT LPAD(r19_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_qm:gent002
		WHERE g02_compania  = r19_compania
		  AND g02_localidad = r19_localidad) AS local,
	DATE(r19_fecing) AS fecha,
	r19_cod_tran AS tp,
	r19_num_tran AS num,
	r19_codcli AS codcli,
	r19_nomcli AS nomcli,
	LPAD(r19_vendedor, 3, 0) || " " || TRIM(r01_nombres) AS vend,
	NVL((SELECT LPAD(z02_zona_cobro, 2, 0) || " " || TRIM(z06_nombre)
		FROM acero_qm:cxct002, acero_qm:cxct006
		WHERE z02_compania   = r19_compania
		  AND z02_localidad  = r19_localidad
		  AND z02_codcli     = r19_codcli
		  AND z06_zona_cobro = z02_zona_cobro),
		"SIN COBRADOR") AS zon_c,
	NVL((SELECT LPAD(z02_zona_venta, 3, 0) || " " || TRIM(g32_nombre)
		FROM acero_qm:cxct002, acero_qm:gent032
		WHERE z02_compania   = r19_compania
		  AND z02_localidad  = r19_localidad
		  AND z02_codcli     = r19_codcli
		  AND g32_compania   = z02_compania
		  AND g32_zona_venta = z02_zona_venta),
		"SIN ZONA VENTA") AS zon_v,
	CASE WHEN r19_cont_cred = "C"
		THEN "CONTADO"
		ELSE "CREDITO"
	END AS for_pag,
	CASE WHEN (SELECT COUNT(*)
			FROM acero_qm:cajt014
			WHERE j14_compania  = r19_compania
			  AND j14_localidad = r19_localidad
			  AND j14_cod_tran  = r19_cod_tran
			  AND j14_num_tran  = r19_num_tran) > 0
		THEN "CON RETENCION"
		ELSE "SIN RETENCION"
	END AS reten,
	DATE(r19_fecing) AS fecha,
	(r19_tot_bruto - r19_tot_dscto) AS subt
	FROM acero_qm:rept019, acero_qm:rept001
	WHERE  r19_compania      = 1
	  AND  r19_localidad    IN (3, 5)
	  AND  r19_cod_tran      = "FA"
	  AND (r19_tipo_dev     IS NULL
	   OR  r19_tipo_dev     <> "AF")
	  AND  YEAR(r19_fecing)  > 2007
	  AND  r01_compania      = r19_compania
	  AND  r01_codigo        = r19_vendedor
UNION
SELECT YEAR(r19_fecing) AS anio,
	CASE WHEN MONTH(r19_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(r19_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(r19_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(r19_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(r19_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(r19_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(r19_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(r19_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(r19_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(r19_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(r19_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(r19_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	(SELECT LPAD(r19_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_qs:gent002
		WHERE g02_compania  = r19_compania
		  AND g02_localidad = r19_localidad) AS local,
	DATE(r19_fecing) AS fecha,
	r19_cod_tran AS tp,
	r19_num_tran AS num,
	r19_codcli AS codcli,
	r19_nomcli AS nomcli,
	LPAD(r19_vendedor, 3, 0) || " " || TRIM(r01_nombres) AS vend,
	NVL((SELECT LPAD(z02_zona_cobro, 2, 0) || " " || TRIM(z06_nombre)
		FROM acero_qs:cxct002, acero_qs:cxct006
		WHERE z02_compania   = r19_compania
		  AND z02_localidad  = r19_localidad
		  AND z02_codcli     = r19_codcli
		  AND z06_zona_cobro = z02_zona_cobro),
		"SIN COBRADOR") AS zon_c,
	NVL((SELECT LPAD(z02_zona_venta, 3, 0) || " " || TRIM(g32_nombre)
		FROM acero_qs:cxct002, acero_qs:gent032
		WHERE z02_compania   = r19_compania
		  AND z02_localidad  = r19_localidad
		  AND z02_codcli     = r19_codcli
		  AND g32_compania   = z02_compania
		  AND g32_zona_venta = z02_zona_venta),
		"SIN ZONA VENTA") AS zon_v,
	CASE WHEN r19_cont_cred = "C"
		THEN "CONTADO"
		ELSE "CREDITO"
	END AS for_pag,
	CASE WHEN (SELECT COUNT(*)
			FROM acero_qs:cajt014
			WHERE j14_compania  = r19_compania
			  AND j14_localidad = r19_localidad
			  AND j14_cod_tran  = r19_cod_tran
			  AND j14_num_tran  = r19_num_tran) > 0
		THEN "CON RETENCION"
		ELSE "SIN RETENCION"
	END AS reten,
	DATE(r19_fecing) AS fecha,
	(r19_tot_bruto - r19_tot_dscto) AS subt
	FROM acero_qs:rept019, acero_qs:rept001
	WHERE  r19_compania      = 1
	  AND  r19_localidad     = 4
	  AND  r19_cod_tran      = "FA"
	  AND (r19_tipo_dev     IS NULL
	   OR  r19_tipo_dev     <> "AF")
	  AND  YEAR(r19_fecing)  > 2007
	  AND  r01_compania      = r19_compania
	  AND  r01_codigo        = r19_vendedor
--}
