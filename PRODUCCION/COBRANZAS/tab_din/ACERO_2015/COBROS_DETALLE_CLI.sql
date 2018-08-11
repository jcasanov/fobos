SELECT YEAR(z22_fecha_emi) AS anio,
	CASE WHEN MONTH(z22_fecha_emi) = 01 THEN "ENERO"
	     WHEN MONTH(z22_fecha_emi) = 02 THEN "FEBRERO"
	     WHEN MONTH(z22_fecha_emi) = 03 THEN "MARZO"
	     WHEN MONTH(z22_fecha_emi) = 04 THEN "ABRIL"
	     WHEN MONTH(z22_fecha_emi) = 05 THEN "MAYO"
	     WHEN MONTH(z22_fecha_emi) = 06 THEN "JUNIO"
	     WHEN MONTH(z22_fecha_emi) = 07 THEN "JULIO"
	     WHEN MONTH(z22_fecha_emi) = 08 THEN "AGOSTO"
	     WHEN MONTH(z22_fecha_emi) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(z22_fecha_emi) = 10 THEN "OCTUBRE"
	     WHEN MONTH(z22_fecha_emi) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(z22_fecha_emi) = 12 THEN "DICIEMBRE"
	END AS mes,
	LPAD(z22_localidad, 2, 0) || " " || TRIM(g02_nombre) AS local,
	NVL(z06_nombre, "SIN COBRADOR") AS cobrador,
	fp_numero_semana(z22_fecha_emi) AS num_sem,
	z22_fecha_emi AS fecha,
	z22_tipo_trn AS tp_trn,
	z22_num_trn AS num_trn,
	z23_codcli AS codcli,
	z01_nomcli AS nomcli,
	z23_tipo_doc AS tip_d,
	z23_num_doc AS num_d,
	z23_div_doc AS div_d,
	SUM((z23_valor_cap + z23_valor_int) * (-1)) AS valor,
	SUM(z23_saldo_cap + z23_saldo_int) AS saldo
	FROM cxct023, cxct022, gent002, cxct002, cxct001, OUTER cxct006
	WHERE z23_compania      = 1
	  AND z23_tipo_trn     IN ("PG", "AR", "PR")
	  AND z22_compania      = z23_compania
	  AND z22_localidad     = z23_localidad
	  AND z22_codcli        = z23_codcli
	  AND z22_tipo_trn      = z23_tipo_trn
	  AND z22_num_trn       = z23_num_trn
	  AND YEAR(z22_fecing)  > 2009
	  AND g02_compania      = z22_compania
	  AND g02_localidad     = z22_localidad
	  AND z02_compania      = z22_compania
	  AND z02_localidad     = z22_localidad
	  AND z02_codcli        = z22_codcli
	  AND z01_codcli        = z02_codcli
	  AND z06_zona_cobro    = z02_zona_cobro
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13
UNION
SELECT YEAR(z22_fecha_emi) AS anio,
	CASE WHEN MONTH(z22_fecha_emi) = 01 THEN "ENERO"
	     WHEN MONTH(z22_fecha_emi) = 02 THEN "FEBRERO"
	     WHEN MONTH(z22_fecha_emi) = 03 THEN "MARZO"
	     WHEN MONTH(z22_fecha_emi) = 04 THEN "ABRIL"
	     WHEN MONTH(z22_fecha_emi) = 05 THEN "MAYO"
	     WHEN MONTH(z22_fecha_emi) = 06 THEN "JUNIO"
	     WHEN MONTH(z22_fecha_emi) = 07 THEN "JULIO"
	     WHEN MONTH(z22_fecha_emi) = 08 THEN "AGOSTO"
	     WHEN MONTH(z22_fecha_emi) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(z22_fecha_emi) = 10 THEN "OCTUBRE"
	     WHEN MONTH(z22_fecha_emi) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(z22_fecha_emi) = 12 THEN "DICIEMBRE"
	END AS mes,
	LPAD(z22_localidad, 2, 0) || " " || TRIM(g02_nombre) AS local,
	NVL(z06_nombre, "SIN COBRADOR") AS cobrador,
	fp_numero_semana(z22_fecha_emi) AS num_sem,
	z22_fecha_emi AS fecha,
	z22_tipo_trn AS tp_trn,
	z22_num_trn AS num_trn,
	z23_codcli AS codcli,
	z01_nomcli AS nomcli,
	z23_tipo_doc AS tip_d,
	z23_num_doc AS num_d,
	z23_div_doc AS div_d,
	SUM((z23_valor_cap + z23_valor_int) * (-1)) AS valor,
	SUM(z23_saldo_cap + z23_saldo_int) AS saldo
	FROM acero_qm:cxct023, acero_qm:cxct022, acero_qm:gent002,
		acero_qm:cxct002, acero_qm:cxct001, OUTER acero_qm:cxct006
	WHERE z23_compania      = 1
	  AND z23_tipo_trn     IN ("PG", "AR", "PR")
	  AND z22_compania      = z23_compania
	  AND z22_localidad     = z23_localidad
	  AND z22_codcli        = z23_codcli
	  AND z22_tipo_trn      = z23_tipo_trn
	  AND z22_num_trn       = z23_num_trn
	  AND YEAR(z22_fecing)  > 2009
	  AND g02_compania      = z22_compania
	  AND g02_localidad     = z22_localidad
	  AND z02_compania      = z22_compania
	  AND z02_localidad     = z22_localidad
	  AND z02_codcli        = z22_codcli
	  AND z01_codcli        = z02_codcli
	  AND z06_zona_cobro    = z02_zona_cobro
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13;
