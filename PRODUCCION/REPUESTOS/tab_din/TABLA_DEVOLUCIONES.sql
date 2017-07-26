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
	LPAD(r19_localidad, 2, 0) || " " || TRIM(g02_abreviacion) AS local,
	r19_cod_tran AS tp,
	r19_num_tran AS num,
	r19_tipo_dev AS tp_f,
	r19_num_dev AS num_f,
	r19_codcli AS codcli,
	r19_nomcli AS nomcli,
	r01_nombres AS vend,
	r19_referencia AS refer,
	DATE(r19_fecing) AS fecha,
	fp_numero_semana(DATE(r19_fecing)) AS num_sem,
	CASE WHEN (SELECT 1 FROM rept088
			WHERE r88_compania  = r19_compania
			  AND r88_localidad = r19_localidad
			  AND r88_cod_dev   = r19_cod_tran
			  AND r88_num_dev   = r19_num_tran) = 1
		THEN "REFACTURACION"
		ELSE "DEVOLUCION REAL"
	END AS tipo,
	CASE WHEN r19_ord_trabajo IS NOT NULL
		THEN "INVENTARIO"
		ELSE "ASOCIADO OT"
	END AS area,
	(r19_tot_bruto - r19_tot_dscto) AS subt
	FROM rept019, rept001, gent002
	WHERE  r19_compania    = 1
	  AND  r19_localidad   = 1
	  AND  r19_cod_tran    = "DF"
	  AND (r19_referencia MATCHES "DEVOLUCI*"
	   OR  r19_referencia MATCHES "REFACTURAC*")
	  AND  r01_compania    = r19_compania
	  AND  r01_codigo      = r19_vendedor
	  AND  g02_compania    = r19_compania
	  AND  g02_localidad   = r19_localidad
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
	LPAD(r19_localidad, 2, 0) || " " || TRIM(g02_abreviacion) AS local,
	r19_cod_tran AS tp,
	r19_num_tran AS num,
	r19_tipo_dev AS tp_f,
	r19_num_dev AS num_f,
	r19_codcli AS codcli,
	r19_nomcli AS nomcli,
	r01_nombres AS vend,
	r19_referencia AS refer,
	DATE(r19_fecing) AS fecha,
	fp_numero_semana(DATE(r19_fecing)) AS num_sem,
	"DEVOLUCION" AS tipo,
	CASE WHEN r19_ord_trabajo IS NOT NULL
		THEN "INVENTARIO"
		ELSE "ASOCIADO OT"
	END AS area,
	(r19_tot_bruto - r19_tot_dscto) AS subt
	FROM rept019, rept001, gent002
	WHERE  r19_compania    = 1
	  AND  r19_localidad   = 1
	  AND  r19_cod_tran    = "DF"
	  AND (r19_referencia NOT MATCHES "DEVOLUCI*"
	  AND  r19_referencia NOT MATCHES "REFACTURAC*")
	  AND  r01_compania    = r19_compania
	  AND  r01_codigo      = r19_vendedor
	  AND  g02_compania    = r19_compania
	  AND  g02_localidad   = r19_localidad
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
	LPAD(r19_localidad, 2, 0) || " " || TRIM(g02_abreviacion) AS local,
	r19_cod_tran AS tp,
	r19_num_tran AS num,
	r19_tipo_dev AS tp_f,
	r19_num_dev AS num_f,
	r19_codcli AS codcli,
	r19_nomcli AS nomcli,
	r01_nombres AS vend,
	r19_referencia AS refer,
	DATE(r19_fecing) AS fecha,
	fp_numero_semana(DATE(r19_fecing)) AS num_sem,
	CASE WHEN (SELECT 1 FROM acero_qm@acgyede:rept088
			WHERE r88_compania  = r19_compania
			  AND r88_localidad = r19_localidad
			  AND r88_cod_dev   = r19_cod_tran
			  AND r88_num_dev   = r19_num_tran) = 1
		THEN "REFACTURACION"
		ELSE "DEVOLUCION REAL"
	END AS tipo,
	CASE WHEN r19_ord_trabajo IS NOT NULL
		THEN "INVENTARIO"
		ELSE "ASOCIADO OT"
	END AS area,
	(r19_tot_bruto - r19_tot_dscto) AS subt
	FROM acero_qm@acgyede:rept019, acero_qm@acgyede:rept001,
		acero_qm@acgyede:gent002
	WHERE  r19_compania    = 1
	  AND  r19_localidad  IN (3, 5)
	  AND  r19_cod_tran    = "DF"
	  AND (r19_referencia MATCHES "DEVOLUCI*"
	   OR  r19_referencia MATCHES "REFACTURAC*")
	  AND  r01_compania    = r19_compania
	  AND  r01_codigo      = r19_vendedor
	  AND  g02_compania    = r19_compania
	  AND  g02_localidad   = r19_localidad
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
	LPAD(r19_localidad, 2, 0) || " " || TRIM(g02_abreviacion) AS local,
	r19_cod_tran AS tp,
	r19_num_tran AS num,
	r19_tipo_dev AS tp_f,
	r19_num_dev AS num_f,
	r19_codcli AS codcli,
	r19_nomcli AS nomcli,
	r01_nombres AS vend,
	r19_referencia AS refer,
	DATE(r19_fecing) AS fecha,
	fp_numero_semana(DATE(r19_fecing)) AS num_sem,
	"DEVOLUCION" AS tipo,
	CASE WHEN r19_ord_trabajo IS NOT NULL
		THEN "INVENTARIO"
		ELSE "ASOCIADO OT"
	END AS area,
	(r19_tot_bruto - r19_tot_dscto) AS subt
	FROM acero_qm@acgyede:rept019, acero_qm@acgyede:rept001,
		acero_qm@acgyede:gent002
	WHERE  r19_compania    = 1
	  AND  r19_localidad  IN (3, 5)
	  AND  r19_cod_tran    = "DF"
	  AND (r19_referencia NOT MATCHES "DEVOLUCI*"
	  AND  r19_referencia NOT MATCHES "REFACTURAC*")
	  AND  r01_compania    = r19_compania
	  AND  r01_codigo      = r19_vendedor
	  AND  g02_compania    = r19_compania
	  AND  g02_localidad   = r19_localidad
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
	LPAD(r19_localidad, 2, 0) || " " || TRIM(g02_abreviacion) AS local,
	r19_cod_tran AS tp,
	r19_num_tran AS num,
	r19_tipo_dev AS tp_f,
	r19_num_dev AS num_f,
	r19_codcli AS codcli,
	r19_nomcli AS nomcli,
	r01_nombres AS vend,
	r19_referencia AS refer,
	DATE(r19_fecing) AS fecha,
	fp_numero_semana(DATE(r19_fecing)) AS num_sem,
	CASE WHEN (SELECT 1 FROM acero_qs@acgyede:rept088
			WHERE r88_compania  = r19_compania
			  AND r88_localidad = r19_localidad
			  AND r88_cod_dev   = r19_cod_tran
			  AND r88_num_dev   = r19_num_tran) = 1
		THEN "REFACTURACION"
		ELSE "DEVOLUCION REAL"
	END AS tipo,
	CASE WHEN r19_ord_trabajo IS NOT NULL
		THEN "INVENTARIO"
		ELSE "ASOCIADO OT"
	END AS area,
	(r19_tot_bruto - r19_tot_dscto) AS subt
	FROM acero_qs@acgyede:rept019, acero_qs@acgyede:rept001,
		acero_qs@acgyede:gent002
	WHERE  r19_compania    = 1
	  AND  r19_localidad   = 4
	  AND  r19_cod_tran    = "DF"
	  AND (r19_referencia MATCHES "DEVOLUCI*"
	   OR  r19_referencia MATCHES "REFACTURAC*")
	  AND  r01_compania    = r19_compania
	  AND  r01_codigo      = r19_vendedor
	  AND  g02_compania    = r19_compania
	  AND  g02_localidad   = r19_localidad
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
	LPAD(r19_localidad, 2, 0) || " " || TRIM(g02_abreviacion) AS local,
	r19_cod_tran AS tp,
	r19_num_tran AS num,
	r19_tipo_dev AS tp_f,
	r19_num_dev AS num_f,
	r19_codcli AS codcli,
	r19_nomcli AS nomcli,
	r01_nombres AS vend,
	r19_referencia AS refer,
	DATE(r19_fecing) AS fecha,
	fp_numero_semana(DATE(r19_fecing)) AS num_sem,
	"DEVOLUCION" AS tipo,
	CASE WHEN r19_ord_trabajo IS NOT NULL
		THEN "INVENTARIO"
		ELSE "ASOCIADO OT"
	END AS area,
	(r19_tot_bruto - r19_tot_dscto) AS subt
	FROM acero_qs@acgyede:rept019, acero_qs@acgyede:rept001,
		acero_qs@acgyede:gent002
	WHERE  r19_compania    = 1
	  AND  r19_localidad   = 4
	  AND  r19_cod_tran    = "DF"
	  AND (r19_referencia NOT MATCHES "DEVOLUCI*"
	  AND  r19_referencia NOT MATCHES "REFACTURAC*")
	  AND  r01_compania    = r19_compania
	  AND  r01_codigo      = r19_vendedor
	  AND  g02_compania    = r19_compania
	  AND  g02_localidad   = r19_localidad;
