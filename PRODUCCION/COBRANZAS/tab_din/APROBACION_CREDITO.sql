SELECT LPAD(j10_localidad, 2, 0) || "-" || TRIM(g02_nombre) AS local,
	YEAR(j10_fecing) AS anio,
	CASE WHEN MONTH(j10_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(j10_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(j10_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(j10_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(j10_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(j10_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(j10_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(j10_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(j10_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(j10_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(j10_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(j10_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	CASE WHEN j10_areaneg = 1 THEN "01 INVENTARIO"
	     WHEN j10_areaneg = 2 THEN "02 TALLER"
	END AS area,
	j10_codcli AS codcli,
	j10_nomcli AS nomcli,
	j10_fecing AS fecing,
	r25_cod_tran AS cod_t,
	r25_num_tran AS num_t,
	r25_valor_cred AS valor,
	LPAD(j10_localidad, 2, 0) || "-" || TRIM(g02_nombre) || " " ||
	j10_usuario AS usuario,
	j10_tipo_fuente AS tipo_t,
	LPAD(j10_localidad, 2, 0) || "-" || TRIM(g02_nombre) || " " ||
	r01_nombres AS vend
	FROM cajt010, gent002, rept025, rept019, rept001
	WHERE j10_compania    = 1
	  AND j10_localidad   = 1
	  AND j10_tipo_fuente = "PR"
	  AND j10_estado      = "P"
	  AND j10_valor       = 0
	  AND g02_compania    = j10_compania
	  AND g02_localidad   = j10_localidad
	  AND r25_compania    = j10_compania
	  AND r25_localidad   = j10_localidad
	  AND r25_numprev     = j10_num_fuente
	  AND r19_compania    = r25_compania
	  AND r19_localidad   = r25_localidad
	  AND r19_cod_tran    = r25_cod_tran
	  AND r19_num_tran    = r25_num_tran
	  AND r01_compania    = r19_compania
	  AND r01_codigo      = r19_vendedor
UNION
SELECT LPAD(j10_localidad, 2, 0) || "-" || TRIM(g02_nombre) AS local,
	YEAR(j10_fecing) AS anio,
	CASE WHEN MONTH(j10_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(j10_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(j10_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(j10_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(j10_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(j10_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(j10_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(j10_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(j10_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(j10_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(j10_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(j10_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	CASE WHEN j10_areaneg = 1 THEN "01 INVENTARIO"
	     WHEN j10_areaneg = 2 THEN "02 TALLER"
	END AS area,
	j10_codcli AS codcli,
	j10_nomcli AS nomcli,
	j10_fecing AS fecing,
	"FA" AS cod_t,
	t23_num_factura AS num_t,
	t25_valor_cred AS valor,
	LPAD(j10_localidad, 2, 0) || "-" || TRIM(g02_nombre) || " " ||
	j10_usuario AS usuario,
	j10_tipo_fuente AS tipo_t,
	LPAD(j10_localidad, 2, 0) || "-" || TRIM(g02_nombre) || " " ||
	r01_nombres AS vend
	FROM cajt010, gent002, talt025, talt023, talt061, rept001
	WHERE j10_compania    = 1
	  AND j10_localidad   = 1
	  AND j10_tipo_fuente = "OT"
	  AND j10_estado      = "P"
	  AND j10_valor       = 0
	  AND g02_compania    = j10_compania
	  AND g02_localidad   = j10_localidad
	  AND t25_compania    = j10_compania
	  AND t25_localidad   = j10_localidad
	  AND t25_orden       = j10_num_fuente
	  AND t23_compania    = t25_compania
	  AND t23_localidad   = t25_localidad
	  AND t23_orden       = t25_orden
	  AND t61_compania    = t23_compania
	  AND t61_cod_asesor  = t23_cod_asesor
	  AND r01_compania    = t61_compania
	  AND r01_codigo      = t61_cod_vendedor
UNION
SELECT LPAD(j10_localidad, 2, 0) || "-" || TRIM(g02_nombre) AS local,
	YEAR(j10_fecing) AS anio,
	CASE WHEN MONTH(j10_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(j10_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(j10_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(j10_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(j10_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(j10_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(j10_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(j10_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(j10_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(j10_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(j10_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(j10_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	CASE WHEN j10_areaneg = 1 THEN "01 INVENTARIO"
	     WHEN j10_areaneg = 2 THEN "02 TALLER"
	END AS area,
	j10_codcli AS codcli,
	j10_nomcli AS nomcli,
	j10_fecing AS fecing,
	r25_cod_tran AS cod_t,
	r25_num_tran AS num_t,
	r25_valor_cred AS valor,
	LPAD(j10_localidad, 2, 0) || "-" || TRIM(g02_nombre) || " " ||
	j10_usuario AS usuario,
	j10_tipo_fuente AS tipo_t,
	LPAD(j10_localidad, 2, 0) || "-" || TRIM(g02_nombre) || " " ||
	r01_nombres AS vend
	FROM acero_qm:cajt010, acero_qm:gent002, acero_qm:rept025,
		acero_qm:rept019, acero_qm:rept001
	WHERE j10_compania    = 1
	  AND j10_localidad   IN(3, 5)
	  AND j10_tipo_fuente = "PR"
	  AND j10_estado      = "P"
	  AND j10_valor       = 0
	  AND g02_compania    = j10_compania
	  AND g02_localidad   = j10_localidad
	  AND r25_compania    = j10_compania
	  AND r25_localidad   = j10_localidad
	  AND r25_numprev     = j10_num_fuente
	  AND r19_compania    = r25_compania
	  AND r19_localidad   = r25_localidad
	  AND r19_cod_tran    = r25_cod_tran
	  AND r19_num_tran    = r25_num_tran
	  AND r01_compania    = r19_compania
	  AND r01_codigo      = r19_vendedor
UNION
SELECT LPAD(j10_localidad, 2, 0) || "-" || TRIM(g02_nombre) AS local,
	YEAR(j10_fecing) AS anio,
	CASE WHEN MONTH(j10_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(j10_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(j10_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(j10_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(j10_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(j10_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(j10_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(j10_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(j10_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(j10_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(j10_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(j10_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	CASE WHEN j10_areaneg = 1 THEN "01 INVENTARIO"
	     WHEN j10_areaneg = 2 THEN "02 TALLER"
	END AS area,
	j10_codcli AS codcli,
	j10_nomcli AS nomcli,
	j10_fecing AS fecing,
	"FA" AS cod_t,
	t23_num_factura AS num_t,
	t25_valor_cred AS valor,
	LPAD(j10_localidad, 2, 0) || "-" || TRIM(g02_nombre) || " " ||
	j10_usuario AS usuario,
	j10_tipo_fuente AS tipo_t,
	LPAD(j10_localidad, 2, 0) || "-" || TRIM(g02_nombre) || " " ||
	r01_nombres AS vend
	FROM acero_qm:cajt010, acero_qm:gent002, acero_qm:talt025,
		acero_qm:talt023, acero_qm:talt061, acero_qm:rept001
	WHERE j10_compania    = 1
	  AND j10_localidad   = 3
	  AND j10_tipo_fuente = "OT"
	  AND j10_estado      = "P"
	  AND j10_valor       = 0
	  AND g02_compania    = j10_compania
	  AND g02_localidad   = j10_localidad
	  AND t25_compania    = j10_compania
	  AND t25_localidad   = j10_localidad
	  AND t25_orden       = j10_num_fuente
	  AND t23_compania    = t25_compania
	  AND t23_localidad   = t25_localidad
	  AND t23_orden       = t25_orden
	  AND t61_compania    = t23_compania
	  AND t61_cod_asesor  = t23_cod_asesor
	  AND r01_compania    = t61_compania
	  AND r01_codigo      = t61_cod_vendedor
UNION
SELECT LPAD(j10_localidad, 2, 0) || "-" || TRIM(g02_nombre) AS local,
	YEAR(j10_fecing) AS anio,
	CASE WHEN MONTH(j10_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(j10_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(j10_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(j10_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(j10_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(j10_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(j10_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(j10_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(j10_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(j10_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(j10_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(j10_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	CASE WHEN j10_areaneg = 1 THEN "01 INVENTARIO"
	     WHEN j10_areaneg = 2 THEN "02 TALLER"
	END AS area,
	j10_codcli AS codcli,
	j10_nomcli AS nomcli,
	j10_fecing AS fecing,
	r25_cod_tran AS cod_t,
	r25_num_tran AS num_t,
	r25_valor_cred AS valor,
	LPAD(j10_localidad, 2, 0) || "-" || TRIM(g02_nombre) || " " ||
	j10_usuario AS usuario,
	j10_tipo_fuente AS tipo_t,
	LPAD(j10_localidad, 2, 0) || "-" || TRIM(g02_nombre) || " " ||
	r01_nombres AS vend
	FROM acero_gc:cajt010, acero_gc:gent002, acero_gc:rept025,
		acero_gc:rept019, acero_gc:rept001
	WHERE j10_compania    = 1
	  AND j10_localidad   = 2
	  AND j10_tipo_fuente = "PR"
	  AND j10_estado      = "P"
	  AND j10_valor       = 0
	  AND g02_compania    = j10_compania
	  AND g02_localidad   = j10_localidad
	  AND r25_compania    = j10_compania
	  AND r25_localidad   = j10_localidad
	  AND r25_numprev     = j10_num_fuente
	  AND r19_compania    = r25_compania
	  AND r19_localidad   = r25_localidad
	  AND r19_cod_tran    = r25_cod_tran
	  AND r19_num_tran    = r25_num_tran
	  AND r01_compania    = r19_compania
	  AND r01_codigo      = r19_vendedor
UNION
SELECT LPAD(j10_localidad, 2, 0) || "-" || TRIM(g02_nombre) AS local,
	YEAR(j10_fecing) AS anio,
	CASE WHEN MONTH(j10_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(j10_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(j10_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(j10_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(j10_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(j10_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(j10_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(j10_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(j10_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(j10_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(j10_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(j10_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	CASE WHEN j10_areaneg = 1 THEN "01 INVENTARIO"
	     WHEN j10_areaneg = 2 THEN "02 TALLER"
	END AS area,
	j10_codcli AS codcli,
	j10_nomcli AS nomcli,
	j10_fecing AS fecing,
	r25_cod_tran AS cod_t,
	r25_num_tran AS num_t,
	r25_valor_cred AS valor,
	LPAD(j10_localidad, 2, 0) || "-" || TRIM(g02_nombre) || " " ||
	j10_usuario AS usuario,
	j10_tipo_fuente AS tipo_t,
	LPAD(j10_localidad, 2, 0) || "-" || TRIM(g02_nombre) || " " ||
	r01_nombres AS vend
	FROM acero_qs:cajt010, acero_qs:gent002, acero_qs:rept025,
		acero_qs:rept019, acero_qs:rept001
	WHERE j10_compania    = 1
	  AND j10_localidad   = 4
	  AND j10_tipo_fuente = "PR"
	  AND j10_estado      = "P"
	  AND j10_valor       = 0
	  AND g02_compania    = j10_compania
	  AND g02_localidad   = j10_localidad
	  AND r25_compania    = j10_compania
	  AND r25_localidad   = j10_localidad
	  AND r25_numprev     = j10_num_fuente
	  AND r19_compania    = r25_compania
	  AND r19_localidad   = r25_localidad
	  AND r19_cod_tran    = r25_cod_tran
	  AND r19_num_tran    = r25_num_tran
	  AND r01_compania    = r19_compania
	  AND r01_codigo      = r19_vendedor;
