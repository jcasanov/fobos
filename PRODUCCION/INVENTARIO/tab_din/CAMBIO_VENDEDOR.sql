SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM gent002
		WHERE g02_compania  = r98_compania
		  AND g02_localidad = r98_localidad) AS local,
	YEAR(r98_fecing) AS anio,
	CASE WHEN MONTH(r98_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(r98_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(r98_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(r98_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(r98_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(r98_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(r98_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(r98_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(r98_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(r98_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(r98_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(r98_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	(SELECT r01_nombres
		FROM rept001
		WHERE r01_compania = r98_compania
		  AND r01_codigo   = r98_vend_ant) AS vend_ant,
	(SELECT r01_nombres
		FROM rept001
		WHERE r01_compania = r98_compania
		  AND r01_codigo   = r98_vend_nue) AS vend_nue,
	NVL(r98_codcli, (SELECT r19_codcli
			FROM rept019
			WHERE r19_compania  = r98_compania
			  AND r19_localidad = r98_localidad
			  AND r19_cod_tran  = NVL(r99_cod_tran, r98_cod_tran)
			  AND r19_num_tran  = NVL(r99_num_tran, r98_num_tran)))
	AS codcli,
	NVL((SELECT z01_nomcli
		FROM cxct001
		WHERE z01_codcli = r98_codcli),
	(SELECT r19_codcli
		FROM rept019
		WHERE r19_compania  = r98_compania
		  AND r19_localidad = r98_localidad
		  AND r19_cod_tran  = NVL(r99_cod_tran, r98_cod_tran)
		  AND r19_num_tran  = NVL(r99_num_tran, r98_num_tran)))
 	AS nomcli,
	NVL(r99_cod_tran, r98_cod_tran) AS codtra,
	NVL(r99_num_tran, r98_num_tran) AS numtra,
	r98_secuencia AS secu,
	r98_usuario AS usua,
	r98_fecha_ini AS fec_ini,
	r98_fecha_fin AS fec_fin,
	r98_fecing AS fec_pro,
	CASE WHEN r98_estado = "P" THEN "PROCESADO"
	     WHEN r98_estado = "R" THEN "REVERSADO"
	END AS est,
	(SELECT r19_tot_bruto - r19_tot_dscto
		FROM rept019
		WHERE r19_compania  = r98_compania
		  AND r19_localidad = r98_localidad
		  AND r19_cod_tran  = NVL(r99_cod_tran, r98_cod_tran)
		  AND r19_num_tran  = NVL(r99_num_tran, r98_num_tran)) AS tot
	FROM rept098, OUTER rept099
	WHERE r98_compania  = 1
	  AND r98_localidad = 1
	  AND r99_compania  = r98_compania
	  AND r99_localidad = r98_localidad
	  AND r99_vend_ant  = r98_vend_ant
	  AND r99_vend_nue  = r98_vend_nue
UNION
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_qm@acgyede:gent002
		WHERE g02_compania  = r98_compania
		  AND g02_localidad = r98_localidad) AS local,
	YEAR(r98_fecing) AS anio,
	CASE WHEN MONTH(r98_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(r98_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(r98_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(r98_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(r98_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(r98_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(r98_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(r98_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(r98_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(r98_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(r98_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(r98_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	(SELECT r01_nombres
		FROM acero_qm@acgyede:rept001
		WHERE r01_compania = r98_compania
		  AND r01_codigo   = r98_vend_ant) AS vend_ant,
	(SELECT r01_nombres
		FROM acero_qm@acgyede:rept001
		WHERE r01_compania = r98_compania
		  AND r01_codigo   = r98_vend_nue) AS vend_nue,
	NVL(r98_codcli, (SELECT r19_codcli
			FROM acero_qm@acgyede:rept019
			WHERE r19_compania  = r98_compania
			  AND r19_localidad = r98_localidad
			  AND r19_cod_tran  = NVL(r99_cod_tran, r98_cod_tran)
			  AND r19_num_tran  = NVL(r99_num_tran, r98_num_tran)))
	AS codcli,
	NVL((SELECT z01_nomcli
		FROM acero_qm@acgyede:cxct001
		WHERE z01_codcli = r98_codcli),
	(SELECT r19_codcli
		FROM acero_qm@acgyede:rept019
		WHERE r19_compania  = r98_compania
		  AND r19_localidad = r98_localidad
		  AND r19_cod_tran  = NVL(r99_cod_tran, r98_cod_tran)
		  AND r19_num_tran  = NVL(r99_num_tran, r98_num_tran)))
 	AS nomcli,
	NVL(r99_cod_tran, r98_cod_tran) AS codtra,
	NVL(r99_num_tran, r98_num_tran) AS numtra,
	r98_secuencia AS secu,
	r98_usuario AS usua,
	r98_fecha_ini AS fec_ini,
	r98_fecha_fin AS fec_fin,
	r98_fecing AS fec_pro,
	CASE WHEN r98_estado = "P" THEN "PROCESADO"
	     WHEN r98_estado = "R" THEN "REVERSADO"
	END AS est,
	(SELECT r19_tot_bruto - r19_tot_dscto
		FROM acero_qm@acgyede:rept019
		WHERE r19_compania  = r98_compania
		  AND r19_localidad = r98_localidad
		  AND r19_cod_tran  = NVL(r99_cod_tran, r98_cod_tran)
		  AND r19_num_tran  = NVL(r99_num_tran, r98_num_tran)) AS tot
	FROM acero_qm@acgyede:rept098, OUTER acero_qm@acgyede:rept099
	WHERE r98_compania  = 1
	  AND r98_localidad = 3
	  AND r99_compania  = r98_compania
	  AND r99_localidad = r98_localidad
	  AND r99_vend_ant  = r98_vend_ant
	  AND r99_vend_nue  = r98_vend_nue
UNION
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_qs@acgyede:gent002
		WHERE g02_compania  = r98_compania
		  AND g02_localidad = r98_localidad) AS local,
	YEAR(r98_fecing) AS anio,
	CASE WHEN MONTH(r98_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(r98_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(r98_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(r98_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(r98_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(r98_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(r98_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(r98_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(r98_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(r98_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(r98_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(r98_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	(SELECT r01_nombres
		FROM acero_qs@acgyede:rept001
		WHERE r01_compania = r98_compania
		  AND r01_codigo   = r98_vend_ant) AS vend_ant,
	(SELECT r01_nombres
		FROM acero_qs@acgyede:rept001
		WHERE r01_compania = r98_compania
		  AND r01_codigo   = r98_vend_nue) AS vend_nue,
	NVL(r98_codcli, (SELECT r19_codcli
			FROM acero_qs@acgyede:rept019
			WHERE r19_compania  = r98_compania
			  AND r19_localidad = r98_localidad
			  AND r19_cod_tran  = NVL(r99_cod_tran, r98_cod_tran)
			  AND r19_num_tran  = NVL(r99_num_tran, r98_num_tran)))
	AS codcli,
	NVL((SELECT z01_nomcli
		FROM acero_qs@acgyede:cxct001
		WHERE z01_codcli = r98_codcli),
	(SELECT r19_codcli
		FROM acero_qs@acgyede:rept019
		WHERE r19_compania  = r98_compania
		  AND r19_localidad = r98_localidad
		  AND r19_cod_tran  = NVL(r99_cod_tran, r98_cod_tran)
		  AND r19_num_tran  = NVL(r99_num_tran, r98_num_tran)))
 	AS nomcli,
	NVL(r99_cod_tran, r98_cod_tran) AS codtra,
	NVL(r99_num_tran, r98_num_tran) AS numtra,
	r98_secuencia AS secu,
	r98_usuario AS usua,
	r98_fecha_ini AS fec_ini,
	r98_fecha_fin AS fec_fin,
	r98_fecing AS fec_pro,
	CASE WHEN r98_estado = "P" THEN "PROCESADO"
	     WHEN r98_estado = "R" THEN "REVERSADO"
	END AS est,
	(SELECT r19_tot_bruto - r19_tot_dscto
		FROM acero_qs@acgyede:rept019
		WHERE r19_compania  = r98_compania
		  AND r19_localidad = r98_localidad
		  AND r19_cod_tran  = NVL(r99_cod_tran, r98_cod_tran)
		  AND r19_num_tran  = NVL(r99_num_tran, r98_num_tran)) AS tot
	FROM acero_qs@acgyede:rept098, OUTER acero_qs@acgyede:rept099
	WHERE r98_compania  = 1
	  AND r98_localidad = 4
	  AND r99_compania  = r98_compania
	  AND r99_localidad = r98_localidad
	  AND r99_vend_ant  = r98_vend_ant
	  AND r99_vend_nue  = r98_vend_nue;
