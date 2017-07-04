SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		|| " (GM)"
		FROM acero_gm@idsgye01:gent002
		WHERE g02_compania  = j10_compania
		  AND g02_localidad = j10_localidad) AS local,
	YEAR(j10_fecha_pro) AS anio,
	CASE WHEN MONTH(j10_fecha_pro) = 01 THEN "ENERO"
	     WHEN MONTH(j10_fecha_pro) = 02 THEN "FEBRERO"
	     WHEN MONTH(j10_fecha_pro) = 03 THEN "MARZO"
	     WHEN MONTH(j10_fecha_pro) = 04 THEN "ABRIL"
	     WHEN MONTH(j10_fecha_pro) = 05 THEN "MAYO"
	     WHEN MONTH(j10_fecha_pro) = 06 THEN "JUNIO"
	     WHEN MONTH(j10_fecha_pro) = 07 THEN "JULIO"
	     WHEN MONTH(j10_fecha_pro) = 08 THEN "AGOSTO"
	     WHEN MONTH(j10_fecha_pro) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(j10_fecha_pro) = 10 THEN "OCTUBRE"
	     WHEN MONTH(j10_fecha_pro) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(j10_fecha_pro) = 12 THEN "DICIEMBRE"
	END AS mes,
	TO_CHAR(j10_fecha_pro, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(j10_fecha_pro)), 2, 0) AS num_sem,
	j10_codigo_caja AS cod_caj,
	(SELECT j02_nombre_caja
		FROM acero_gm@idsgye01:cajt002
		WHERE j02_compania    = j10_compania
		  AND j02_localidad   = j10_localidad
		  AND j02_codigo_caja = j10_codigo_caja) AS nom_caj,
	j10_fecha_pro AS fec_pro,
	j10_nomcli AS nomcli,
	j10_tipo_destino AS tip_des,
	j10_num_destino AS num_des,
	j10_referencia AS refer,
	CASE WHEN j10_valor > 0
		THEN "EF"
		ELSE "CH"
	END AS cod_pag,
	CASE WHEN j10_valor > 0
		THEN j10_valor
		ELSE NVL((SELECT SUM(j11_valor)
			FROM acero_gm@idsgye01:cajt011
			WHERE j11_compania   = j10_compania
			  AND j11_localidad  = j10_localidad
			  AND j11_num_egreso = j10_num_fuente), 0)
	END * (-1) AS val_trn,
	j10_tipo_fuente AS tip_fue,
	j10_num_fuente AS num_fue,
	j10_codcli AS codcli
	FROM acero_gm@idsgye01:cajt010
	WHERE j10_compania     = 1
	  AND j10_localidad   IN (1, 2)
	  AND j10_tipo_fuente  = "EC"
	  AND j10_estado       = "P"
UNION ALL
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		|| " (GM)"
		FROM acero_gm@idsgye01:gent002
		WHERE g02_compania  = j10_compania
		  AND g02_localidad = j10_localidad) AS local,
	YEAR(j10_fecha_pro) AS anio,
	CASE WHEN MONTH(j10_fecha_pro) = 01 THEN "ENERO"
	     WHEN MONTH(j10_fecha_pro) = 02 THEN "FEBRERO"
	     WHEN MONTH(j10_fecha_pro) = 03 THEN "MARZO"
	     WHEN MONTH(j10_fecha_pro) = 04 THEN "ABRIL"
	     WHEN MONTH(j10_fecha_pro) = 05 THEN "MAYO"
	     WHEN MONTH(j10_fecha_pro) = 06 THEN "JUNIO"
	     WHEN MONTH(j10_fecha_pro) = 07 THEN "JULIO"
	     WHEN MONTH(j10_fecha_pro) = 08 THEN "AGOSTO"
	     WHEN MONTH(j10_fecha_pro) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(j10_fecha_pro) = 10 THEN "OCTUBRE"
	     WHEN MONTH(j10_fecha_pro) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(j10_fecha_pro) = 12 THEN "DICIEMBRE"
	END AS mes,
	TO_CHAR(j10_fecha_pro, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(j10_fecha_pro)), 2, 0) AS num_sem,
	j10_codigo_caja AS cod_caj,
	(SELECT j02_nombre_caja
		FROM acero_gm@idsgye01:cajt002
		WHERE j02_compania    = j10_compania
		  AND j02_localidad   = j10_localidad
		  AND j02_codigo_caja = j10_codigo_caja) AS nom_caj,
	j10_fecha_pro AS fec_pro,
	j10_nomcli AS nomcli,
	j10_tipo_destino AS tip_des,
	j10_num_destino AS num_des,
	j10_referencia AS refer,
	j11_codigo_pago AS cod_pag,
	j11_valor AS val_trn,
	j10_tipo_fuente AS tip_fue,
	j10_num_fuente AS num_fue,
	j10_codcli AS codcli
	FROM acero_gm@idsgye01:cajt010, acero_gm@idsgye01:cajt011
	WHERE j10_compania     = 1
	  AND j10_localidad   IN (1, 2)
	  AND j10_tipo_fuente <> "EC"
	  AND j10_estado       = "P"
	  AND j11_compania     = j10_compania
	  AND j11_localidad    = j10_localidad
	  AND j11_tipo_fuente  = j10_tipo_fuente
	  AND j11_num_fuente   = j10_num_fuente
UNION ALL
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		|| " (GM)"
		FROM acero_gm@idsgye01:gent002
		WHERE g02_compania  = j10_compania
		  AND g02_localidad = j10_localidad) AS local,
	YEAR(j10_fecha_pro) AS anio,
	CASE WHEN MONTH(j10_fecha_pro) = 01 THEN "ENERO"
	     WHEN MONTH(j10_fecha_pro) = 02 THEN "FEBRERO"
	     WHEN MONTH(j10_fecha_pro) = 03 THEN "MARZO"
	     WHEN MONTH(j10_fecha_pro) = 04 THEN "ABRIL"
	     WHEN MONTH(j10_fecha_pro) = 05 THEN "MAYO"
	     WHEN MONTH(j10_fecha_pro) = 06 THEN "JUNIO"
	     WHEN MONTH(j10_fecha_pro) = 07 THEN "JULIO"
	     WHEN MONTH(j10_fecha_pro) = 08 THEN "AGOSTO"
	     WHEN MONTH(j10_fecha_pro) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(j10_fecha_pro) = 10 THEN "OCTUBRE"
	     WHEN MONTH(j10_fecha_pro) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(j10_fecha_pro) = 12 THEN "DICIEMBRE"
	END AS mes,
	TO_CHAR(j10_fecha_pro, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(j10_fecha_pro)), 2, 0) AS num_sem,
	j10_codigo_caja AS cod_caj,
	(SELECT j02_nombre_caja
		FROM acero_gm@idsgye01:cajt002
		WHERE j02_compania    = j10_compania
		  AND j02_localidad   = j10_localidad
		  AND j02_codigo_caja = j10_codigo_caja) AS nom_caj,
	j10_fecha_pro AS fec_pro,
	j10_nomcli AS nomcli,
	j10_tipo_destino AS tip_des,
	j10_num_destino AS num_des,
	j10_referencia AS refer,
	j11_codigo_pago AS cod_pag,
	SUM(j11_valor * (-1)) AS val_trn,
	j10_tipo_fuente AS tip_fue,
	j10_num_fuente AS num_fue,
	j10_codcli AS codcli
	FROM acero_gm@idsgye01:cajt010, acero_gm@idsgye01:cajt011
	WHERE j10_compania     = 1
	  AND j10_localidad   IN (1, 2)
	  AND j10_tipo_fuente  = "EC"
	  AND j10_estado       = "P"
	  AND j10_valor        > 0
	  AND j11_compania     = j10_compania
	  AND j11_localidad    = j10_localidad
	  AND j11_num_egreso   = j10_num_fuente
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 15, 16
UNION ALL
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		|| " (GC)"
		FROM acero_gc@idsgye01:gent002
		WHERE g02_compania  = j10_compania
		  AND g02_localidad = j10_localidad) AS local,
	YEAR(j10_fecha_pro) AS anio,
	CASE WHEN MONTH(j10_fecha_pro) = 01 THEN "ENERO"
	     WHEN MONTH(j10_fecha_pro) = 02 THEN "FEBRERO"
	     WHEN MONTH(j10_fecha_pro) = 03 THEN "MARZO"
	     WHEN MONTH(j10_fecha_pro) = 04 THEN "ABRIL"
	     WHEN MONTH(j10_fecha_pro) = 05 THEN "MAYO"
	     WHEN MONTH(j10_fecha_pro) = 06 THEN "JUNIO"
	     WHEN MONTH(j10_fecha_pro) = 07 THEN "JULIO"
	     WHEN MONTH(j10_fecha_pro) = 08 THEN "AGOSTO"
	     WHEN MONTH(j10_fecha_pro) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(j10_fecha_pro) = 10 THEN "OCTUBRE"
	     WHEN MONTH(j10_fecha_pro) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(j10_fecha_pro) = 12 THEN "DICIEMBRE"
	END AS mes,
	TO_CHAR(j10_fecha_pro, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(j10_fecha_pro)), 2, 0) AS num_sem,
	j10_codigo_caja AS cod_caj,
	(SELECT j02_nombre_caja
		FROM acero_gc@idsgye01:cajt002
		WHERE j02_compania    = j10_compania
		  AND j02_localidad   = j10_localidad
		  AND j02_codigo_caja = j10_codigo_caja) AS nom_caj,
	j10_fecha_pro AS fec_pro,
	j10_nomcli AS nomcli,
	j10_tipo_destino AS tip_des,
	j10_num_destino AS num_des,
	j10_referencia AS refer,
	CASE WHEN j10_valor > 0
		THEN "EF"
		ELSE "CH"
	END AS cod_pag,
	CASE WHEN j10_valor > 0
		THEN j10_valor
		ELSE NVL((SELECT SUM(j11_valor)
			FROM acero_gc@idsgye01:cajt011
			WHERE j11_compania   = j10_compania
			  AND j11_localidad  = j10_localidad
			  AND j11_num_egreso = j10_num_fuente), 0)
	END * (-1) AS val_trn,
	j10_tipo_fuente AS tip_fue,
	j10_num_fuente AS num_fue,
	j10_codcli AS codcli
	FROM acero_gc@idsgye01:cajt010
	WHERE j10_compania    = 1
	  AND j10_localidad   = 2
	  AND j10_tipo_fuente = "EC"
	  AND j10_estado      = "P"
UNION ALL
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		|| " (GC)"
		FROM acero_gc@idsgye01:gent002
		WHERE g02_compania  = j10_compania
		  AND g02_localidad = j10_localidad) AS local,
	YEAR(j10_fecha_pro) AS anio,
	CASE WHEN MONTH(j10_fecha_pro) = 01 THEN "ENERO"
	     WHEN MONTH(j10_fecha_pro) = 02 THEN "FEBRERO"
	     WHEN MONTH(j10_fecha_pro) = 03 THEN "MARZO"
	     WHEN MONTH(j10_fecha_pro) = 04 THEN "ABRIL"
	     WHEN MONTH(j10_fecha_pro) = 05 THEN "MAYO"
	     WHEN MONTH(j10_fecha_pro) = 06 THEN "JUNIO"
	     WHEN MONTH(j10_fecha_pro) = 07 THEN "JULIO"
	     WHEN MONTH(j10_fecha_pro) = 08 THEN "AGOSTO"
	     WHEN MONTH(j10_fecha_pro) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(j10_fecha_pro) = 10 THEN "OCTUBRE"
	     WHEN MONTH(j10_fecha_pro) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(j10_fecha_pro) = 12 THEN "DICIEMBRE"
	END AS mes,
	TO_CHAR(j10_fecha_pro, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(j10_fecha_pro)), 2, 0) AS num_sem,
	j10_codigo_caja AS cod_caj,
	(SELECT j02_nombre_caja
		FROM acero_gc@idsgye01:cajt002
		WHERE j02_compania    = j10_compania
		  AND j02_localidad   = j10_localidad
		  AND j02_codigo_caja = j10_codigo_caja) AS nom_caj,
	j10_fecha_pro AS fec_pro,
	j10_nomcli AS nomcli,
	j10_tipo_destino AS tip_des,
	j10_num_destino AS num_des,
	j10_referencia AS refer,
	j11_codigo_pago AS cod_pag,
	j11_valor AS val_trn,
	j10_tipo_fuente AS tip_fue,
	j10_num_fuente AS num_fue,
	j10_codcli AS codcli
	FROM acero_gc@idsgye01:cajt010, acero_gc@idsgye01:cajt011
	WHERE j10_compania     = 1
	  AND j10_localidad    = 2
	  AND j10_tipo_fuente <> "EC"
	  AND j10_estado       = "P"
	  AND j11_compania     = j10_compania
	  AND j11_localidad    = j10_localidad
	  AND j11_tipo_fuente  = j10_tipo_fuente
	  AND j11_num_fuente   = j10_num_fuente
UNION ALL
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		|| " (QM)"
		FROM acero_qm@acgyede:gent002
		WHERE g02_compania  = j10_compania
		  AND g02_localidad = j10_localidad) AS local,
	YEAR(j10_fecha_pro) AS anio,
	CASE WHEN MONTH(j10_fecha_pro) = 01 THEN "ENERO"
	     WHEN MONTH(j10_fecha_pro) = 02 THEN "FEBRERO"
	     WHEN MONTH(j10_fecha_pro) = 03 THEN "MARZO"
	     WHEN MONTH(j10_fecha_pro) = 04 THEN "ABRIL"
	     WHEN MONTH(j10_fecha_pro) = 05 THEN "MAYO"
	     WHEN MONTH(j10_fecha_pro) = 06 THEN "JUNIO"
	     WHEN MONTH(j10_fecha_pro) = 07 THEN "JULIO"
	     WHEN MONTH(j10_fecha_pro) = 08 THEN "AGOSTO"
	     WHEN MONTH(j10_fecha_pro) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(j10_fecha_pro) = 10 THEN "OCTUBRE"
	     WHEN MONTH(j10_fecha_pro) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(j10_fecha_pro) = 12 THEN "DICIEMBRE"
	END AS mes,
	TO_CHAR(j10_fecha_pro, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(j10_fecha_pro)), 2, 0) AS num_sem,
	j10_codigo_caja AS cod_caj,
	(SELECT j02_nombre_caja
		FROM acero_qm@acgyede:cajt002
		WHERE j02_compania    = j10_compania
		  AND j02_localidad   = j10_localidad
		  AND j02_codigo_caja = j10_codigo_caja) AS nom_caj,
	j10_fecha_pro AS fec_pro,
	j10_nomcli AS nomcli,
	j10_tipo_destino AS tip_des,
	j10_num_destino AS num_des,
	j10_referencia AS refer,
	CASE WHEN j10_valor > 0
		THEN "EF"
		ELSE "CH"
	END AS cod_pag,
	CASE WHEN j10_valor > 0
		THEN j10_valor
		ELSE NVL((SELECT SUM(j11_valor)
			FROM acero_qm@acgyede:cajt011
			WHERE j11_compania   = j10_compania
			  AND j11_localidad  = j10_localidad
			  AND j11_num_egreso = j10_num_fuente), 0)
	END * (-1) AS val_trn,
	j10_tipo_fuente AS tip_fue,
	j10_num_fuente AS num_fue,
	j10_codcli AS codcli
	FROM acero_qm@acgyede:cajt010
	WHERE j10_compania     = 1
	  AND j10_localidad   IN (3, 4, 5)
	  AND j10_tipo_fuente  = "EC"
	  AND j10_estado       = "P"
UNION ALL
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		|| " (QM)"
		FROM acero_qm@acgyede:gent002
		WHERE g02_compania  = j10_compania
		  AND g02_localidad = j10_localidad) AS local,
	YEAR(j10_fecha_pro) AS anio,
	CASE WHEN MONTH(j10_fecha_pro) = 01 THEN "ENERO"
	     WHEN MONTH(j10_fecha_pro) = 02 THEN "FEBRERO"
	     WHEN MONTH(j10_fecha_pro) = 03 THEN "MARZO"
	     WHEN MONTH(j10_fecha_pro) = 04 THEN "ABRIL"
	     WHEN MONTH(j10_fecha_pro) = 05 THEN "MAYO"
	     WHEN MONTH(j10_fecha_pro) = 06 THEN "JUNIO"
	     WHEN MONTH(j10_fecha_pro) = 07 THEN "JULIO"
	     WHEN MONTH(j10_fecha_pro) = 08 THEN "AGOSTO"
	     WHEN MONTH(j10_fecha_pro) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(j10_fecha_pro) = 10 THEN "OCTUBRE"
	     WHEN MONTH(j10_fecha_pro) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(j10_fecha_pro) = 12 THEN "DICIEMBRE"
	END AS mes,
	TO_CHAR(j10_fecha_pro, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(j10_fecha_pro)), 2, 0) AS num_sem,
	j10_codigo_caja AS cod_caj,
	(SELECT j02_nombre_caja
		FROM acero_qm@acgyede:cajt002
		WHERE j02_compania    = j10_compania
		  AND j02_localidad   = j10_localidad
		  AND j02_codigo_caja = j10_codigo_caja) AS nom_caj,
	j10_fecha_pro AS fec_pro,
	j10_nomcli AS nomcli,
	j10_tipo_destino AS tip_des,
	j10_num_destino AS num_des,
	j10_referencia AS refer,
	j11_codigo_pago AS cod_pag,
	j11_valor AS val_trn,
	j10_tipo_fuente AS tip_fue,
	j10_num_fuente AS num_fue,
	j10_codcli AS codcli
	FROM acero_qm@acgyede:cajt010, acero_qm@acgyede:cajt011
	WHERE j10_compania     = 1
	  AND j10_localidad   IN (3, 4, 5)
	  AND j10_tipo_fuente <> "EC"
	  AND j10_estado       = "P"
	  AND j11_compania     = j10_compania
	  AND j11_localidad    = j10_localidad
	  AND j11_tipo_fuente  = j10_tipo_fuente
	  AND j11_num_fuente   = j10_num_fuente
UNION ALL
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		|| " (QM)"
		FROM acero_qm@acgyede:gent002
		WHERE g02_compania  = j10_compania
		  AND g02_localidad = j10_localidad) AS local,
	YEAR(j10_fecha_pro) AS anio,
	CASE WHEN MONTH(j10_fecha_pro) = 01 THEN "ENERO"
	     WHEN MONTH(j10_fecha_pro) = 02 THEN "FEBRERO"
	     WHEN MONTH(j10_fecha_pro) = 03 THEN "MARZO"
	     WHEN MONTH(j10_fecha_pro) = 04 THEN "ABRIL"
	     WHEN MONTH(j10_fecha_pro) = 05 THEN "MAYO"
	     WHEN MONTH(j10_fecha_pro) = 06 THEN "JUNIO"
	     WHEN MONTH(j10_fecha_pro) = 07 THEN "JULIO"
	     WHEN MONTH(j10_fecha_pro) = 08 THEN "AGOSTO"
	     WHEN MONTH(j10_fecha_pro) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(j10_fecha_pro) = 10 THEN "OCTUBRE"
	     WHEN MONTH(j10_fecha_pro) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(j10_fecha_pro) = 12 THEN "DICIEMBRE"
	END AS mes,
	TO_CHAR(j10_fecha_pro, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(j10_fecha_pro)), 2, 0) AS num_sem,
	j10_codigo_caja AS cod_caj,
	(SELECT j02_nombre_caja
		FROM acero_qm@acgyede:cajt002
		WHERE j02_compania    = j10_compania
		  AND j02_localidad   = j10_localidad
		  AND j02_codigo_caja = j10_codigo_caja) AS nom_caj,
	j10_fecha_pro AS fec_pro,
	j10_nomcli AS nomcli,
	j10_tipo_destino AS tip_des,
	j10_num_destino AS num_des,
	j10_referencia AS refer,
	j11_codigo_pago AS cod_pag,
	SUM(j11_valor * (-1)) AS val_trn,
	j10_tipo_fuente AS tip_fue,
	j10_num_fuente AS num_fue,
	j10_codcli AS codcli
	FROM acero_qm@acgyede:cajt010, acero_qm@acgyede:cajt011
	WHERE j10_compania     = 1
	  AND j10_localidad   IN (3, 4, 5)
	  AND j10_tipo_fuente  = "EC"
	  AND j10_estado       = "P"
	  AND j10_valor        > 0
	  AND j11_compania     = j10_compania
	  AND j11_localidad    = j10_localidad
	  AND j11_num_egreso   = j10_num_fuente
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 15, 16
UNION ALL
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		|| " (QS)"
		FROM acero_qs@acgyede:gent002
		WHERE g02_compania  = j10_compania
		  AND g02_localidad = j10_localidad) AS local,
	YEAR(j10_fecha_pro) AS anio,
	CASE WHEN MONTH(j10_fecha_pro) = 01 THEN "ENERO"
	     WHEN MONTH(j10_fecha_pro) = 02 THEN "FEBRERO"
	     WHEN MONTH(j10_fecha_pro) = 03 THEN "MARZO"
	     WHEN MONTH(j10_fecha_pro) = 04 THEN "ABRIL"
	     WHEN MONTH(j10_fecha_pro) = 05 THEN "MAYO"
	     WHEN MONTH(j10_fecha_pro) = 06 THEN "JUNIO"
	     WHEN MONTH(j10_fecha_pro) = 07 THEN "JULIO"
	     WHEN MONTH(j10_fecha_pro) = 08 THEN "AGOSTO"
	     WHEN MONTH(j10_fecha_pro) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(j10_fecha_pro) = 10 THEN "OCTUBRE"
	     WHEN MONTH(j10_fecha_pro) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(j10_fecha_pro) = 12 THEN "DICIEMBRE"
	END AS mes,
	TO_CHAR(j10_fecha_pro, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(j10_fecha_pro)), 2, 0) AS num_sem,
	j10_codigo_caja AS cod_caj,
	(SELECT j02_nombre_caja
		FROM acero_qs@acgyede:cajt002
		WHERE j02_compania    = j10_compania
		  AND j02_localidad   = j10_localidad
		  AND j02_codigo_caja = j10_codigo_caja) AS nom_caj,
	j10_fecha_pro AS fec_pro,
	j10_nomcli AS nomcli,
	j10_tipo_destino AS tip_des,
	j10_num_destino AS num_des,
	j10_referencia AS refer,
	CASE WHEN j10_valor > 0
		THEN "EF"
		ELSE "CH"
	END AS cod_pag,
	CASE WHEN j10_valor > 0
		THEN j10_valor
		ELSE NVL((SELECT SUM(j11_valor)
			FROM acero_qs@acgyede:cajt011
			WHERE j11_compania   = j10_compania
			  AND j11_localidad  = j10_localidad
			  AND j11_num_egreso = j10_num_fuente), 0)
	END * (-1) AS val_trn,
	j10_tipo_fuente AS tip_fue,
	j10_num_fuente AS num_fue,
	j10_codcli AS codcli
	FROM acero_qs@acgyede:cajt010
	WHERE j10_compania    = 1
	  AND j10_localidad   = 4
	  AND j10_tipo_fuente = "EC"
	  AND j10_estado      = "P"
UNION ALL
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		|| " (QS)"
		FROM acero_qs@acgyede:gent002
		WHERE g02_compania  = j10_compania
		  AND g02_localidad = j10_localidad) AS local,
	YEAR(j10_fecha_pro) AS anio,
	CASE WHEN MONTH(j10_fecha_pro) = 01 THEN "ENERO"
	     WHEN MONTH(j10_fecha_pro) = 02 THEN "FEBRERO"
	     WHEN MONTH(j10_fecha_pro) = 03 THEN "MARZO"
	     WHEN MONTH(j10_fecha_pro) = 04 THEN "ABRIL"
	     WHEN MONTH(j10_fecha_pro) = 05 THEN "MAYO"
	     WHEN MONTH(j10_fecha_pro) = 06 THEN "JUNIO"
	     WHEN MONTH(j10_fecha_pro) = 07 THEN "JULIO"
	     WHEN MONTH(j10_fecha_pro) = 08 THEN "AGOSTO"
	     WHEN MONTH(j10_fecha_pro) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(j10_fecha_pro) = 10 THEN "OCTUBRE"
	     WHEN MONTH(j10_fecha_pro) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(j10_fecha_pro) = 12 THEN "DICIEMBRE"
	END AS mes,
	TO_CHAR(j10_fecha_pro, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(j10_fecha_pro)), 2, 0) AS num_sem,
	j10_codigo_caja AS cod_caj,
	(SELECT j02_nombre_caja
		FROM acero_qs@acgyede:cajt002
		WHERE j02_compania    = j10_compania
		  AND j02_localidad   = j10_localidad
		  AND j02_codigo_caja = j10_codigo_caja) AS nom_caj,
	j10_fecha_pro AS fec_pro,
	j10_nomcli AS nomcli,
	j10_tipo_destino AS tip_des,
	j10_num_destino AS num_des,
	j10_referencia AS refer,
	j11_codigo_pago AS cod_pag,
	j11_valor AS val_trn,
	j10_tipo_fuente AS tip_fue,
	j10_num_fuente AS num_fue,
	j10_codcli AS codcli
	FROM acero_qs@acgyede:cajt010, acero_qs@acgyede:cajt011
	WHERE j10_compania     = 1
	  AND j10_localidad    = 4
	  AND j10_tipo_fuente <> "EC"
	  AND j10_estado       = "P"
	  AND j11_compania     = j10_compania
	  AND j11_localidad    = j10_localidad
	  AND j11_tipo_fuente  = j10_tipo_fuente
	  AND j11_num_fuente   = j10_num_fuente;
