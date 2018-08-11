SELECT YEAR(j10_fecha_pro) AS anio,
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
	j10_codcli AS codcli,
	j10_nomcli AS nomcli,
	j10_tipo_fuente AS tipfue,
	j10_num_fuente AS numfue,
	j10_tipo_destino AS tipdes,
	j10_num_destino AS numdes,
	CASE WHEN j10_estado = "A" THEN "EN PROCESO"
	     WHEN j10_estado = "P" THEN "PROCESADO"
	     WHEN j10_estado = "E" THEN "ELIMINADO"
	     WHEN j10_estado = "*" THEN "CON ERROR"
	END AS est,
	j10_usuario AS usua,
	CASE WHEN ((j10_tipo_fuente = "PR" OR j10_tipo_fuente = "OT") AND
			j10_valor = 0)
		THEN "CREDITO"
	     WHEN ((j10_tipo_fuente = "PR" OR j10_tipo_fuente = "OT") AND
			j10_valor > 0)
		THEN "CONTADO"
		ELSE "OTROS"
	END AS forpag,
	j10_codigo_caja AS codcaj,
	(SELECT j02_nombre_caja
		FROM cajt002
		WHERE j02_compania    = j10_compania
		  AND j02_localidad   = j10_localidad
		  AND j02_codigo_caja = j10_codigo_caja) AS nomcaj,
	NVL(j11_codigo_pago, "") AS codpag,
	NVL((SELECT UNIQUE j01_nombre
		FROM cajt001
		WHERE j01_compania    = j11_compania
		  AND j01_codigo_pago = j11_codigo_pago), "CREDITO") AS nomfopa,
	DATE(j10_fecha_pro) AS fecpro,
	NVL(j11_valor, 0.00) AS valor
	FROM cajt010, OUTER cajt011
	WHERE j10_compania         = 1
	  AND j10_localidad        = 1
	  AND j10_tipo_fuente     IN ("SC", "PR", "OT")
	  AND DATE(j10_fecha_pro) >= MDY(06, 04, 2014)
	  AND j10_codigo_caja     IN (13, 14)
	  AND j11_compania         = j10_compania
	  AND j11_localidad        = j10_localidad
	  AND j11_tipo_fuente      = j10_tipo_fuente
	  AND j11_num_fuente       = j10_num_fuente
UNION
SELECT YEAR(j10_fecha_pro) AS anio,
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
	j10_codcli AS codcli,
	j10_nomcli AS nomcli,
	j10_tipo_fuente AS tipfue,
	j10_num_fuente AS numfue,
	j10_tipo_destino AS tipdes,
	j10_num_destino AS numdes,
	CASE WHEN j10_estado = "A" THEN "EN PROCESO"
	     WHEN j10_estado = "P" THEN "PROCESADO"
	     WHEN j10_estado = "E" THEN "ELIMINADO"
	     WHEN j10_estado = "*" THEN "CON ERROR"
	END AS est,
	j10_usuario AS usua,
	"EGRESOS" AS forpag,
	j10_codigo_caja AS codcaj,
	(SELECT j02_nombre_caja
		FROM cajt002
		WHERE j02_compania    = j10_compania
		  AND j02_localidad   = j10_localidad
		  AND j02_codigo_caja = j10_codigo_caja) AS nomcaj,
	CASE WHEN j10_valor = 0
		THEN j11_codigo_pago
		ELSE "EF"
	END AS codpag,
	CASE WHEN j10_valor = 0
		THEN "EGRESO CHE"
		ELSE "EGRESO EFE"
	END AS nomfopa,
	DATE(j10_fecha_pro) AS fecpro,
	SUM(CASE WHEN j10_valor = 0
		THEN j11_valor
		ELSE j10_valor
	END * (-1)) AS valor
	FROM cajt010, OUTER cajt011
	WHERE j10_compania         = 1
	  AND j10_localidad        = 1
	  AND j10_tipo_fuente      = "EC"
	  AND DATE(j10_fecha_pro) >= MDY(06, 05, 2014)
	  AND j10_codigo_caja     IN (13, 14)
	  AND j11_compania         = j10_compania
	  AND j11_localidad        = j10_localidad
	  AND j11_num_egreso       = j10_num_fuente
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17;
