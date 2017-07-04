SELECT YEAR(j10_fecha_pro) AS anio,
	CASE WHEN MONTH(j10_fecha_pro) = 01 THEN "01_ENERO"
	     WHEN MONTH(j10_fecha_pro) = 02 THEN "02_FEBRERO"
	     WHEN MONTH(j10_fecha_pro) = 03 THEN "03_MARZO"
	     WHEN MONTH(j10_fecha_pro) = 04 THEN "04_ABRIL"
	     WHEN MONTH(j10_fecha_pro) = 05 THEN "05_MAYO"
	     WHEN MONTH(j10_fecha_pro) = 06 THEN "06_JUNIO"
	     WHEN MONTH(j10_fecha_pro) = 07 THEN "07_JULIO"
	     WHEN MONTH(j10_fecha_pro) = 08 THEN "08_AGOSTO"
	     WHEN MONTH(j10_fecha_pro) = 09 THEN "09_SEPTIEMBRE"
	     WHEN MONTH(j10_fecha_pro) = 10 THEN "10_OCTUBRE"
	     WHEN MONTH(j10_fecha_pro) = 11 THEN "11_NOVIEMBRE"
	     WHEN MONTH(j10_fecha_pro) = 12 THEN "12_DICIEMBRE"
	END AS mes,
	DAY(j10_fecha_pro) AS dia_p,
	0 AS codcli,
	j10_nomcli AS refer,
	j10_tipo_destino AS tipo,
	j10_num_destino AS numero,
	CASE WHEN j10_valor > 0
		THEN "EF"
		ELSE "CH"
	END AS tp,
	CASE WHEN j10_valor > 0
		THEN "EFECTIVO"
		ELSE "CHEQUE"
	END AS nom_tp,
	CASE WHEN j10_valor > 0
		THEN j10_valor
		ELSE (SELECT SUM(j11_valor)
			FROM cajt011
			WHERE j11_compania   = j10_compania
			  AND j11_localidad  = j10_localidad
			  AND j11_num_egreso = j10_num_fuente)
	END * (-1) AS valor,
	CASE WHEN j10_localidad = 1 THEN "GYE_JTM"
	     WHEN j10_localidad = 2 THEN "GYE_CENTRO"
	END AS loc,
	j10_tipo_fuente AS tipo_f,
	j10_num_fuente AS num_f,
	j10_codigo_caja AS cod_caj,
	j02_nombre_caja AS nom_caj,
	"DEPOSITADO" AS tip_c
	FROM cajt010, cajt002
	WHERE j10_compania    = 1
	  AND j10_tipo_fuente = "EC"
	  AND j10_estado      = "P"
	  AND j02_compania    = j10_compania
	  AND j02_localidad   = j10_localidad
	  AND j02_codigo_caja = j10_codigo_caja
UNION
SELECT YEAR(j10_fecha_pro) AS anio,
	CASE WHEN MONTH(j10_fecha_pro) = 01 THEN "01_ENERO"
	     WHEN MONTH(j10_fecha_pro) = 02 THEN "02_FEBRERO"
	     WHEN MONTH(j10_fecha_pro) = 03 THEN "03_MARZO"
	     WHEN MONTH(j10_fecha_pro) = 04 THEN "04_ABRIL"
	     WHEN MONTH(j10_fecha_pro) = 05 THEN "05_MAYO"
	     WHEN MONTH(j10_fecha_pro) = 06 THEN "06_JUNIO"
	     WHEN MONTH(j10_fecha_pro) = 07 THEN "07_JULIO"
	     WHEN MONTH(j10_fecha_pro) = 08 THEN "08_AGOSTO"
	     WHEN MONTH(j10_fecha_pro) = 09 THEN "09_SEPTIEMBRE"
	     WHEN MONTH(j10_fecha_pro) = 10 THEN "10_OCTUBRE"
	     WHEN MONTH(j10_fecha_pro) = 11 THEN "11_NOVIEMBRE"
	     WHEN MONTH(j10_fecha_pro) = 12 THEN "12_DICIEMBRE"
	END AS mes,
	DAY(j10_fecha_pro) AS dia_p,
	j10_codcli AS codcli,
	j10_nomcli AS refer,
	j10_tipo_destino AS tipo,
	j10_num_destino AS numero,
	CASE WHEN j10_banco = 0
		THEN "EF"
		ELSE j11_codigo_pago
	END AS tp,
	CASE WHEN j11_tipo_fuente IS NULL THEN "CREDITO"
	     WHEN j10_tipo_fuente = "SC"
		THEN (SELECT j01_nombre
			FROM cajt001
			WHERE j01_compania    = j11_compania
			  AND j01_codigo_pago = j11_codigo_pago
			  AND j01_cont_cred   = 'R')
	     WHEN j10_tipo_fuente <> "SC"
		THEN (SELECT j01_nombre
			FROM cajt001
			WHERE j01_compania    = j11_compania
			  AND j01_codigo_pago = j11_codigo_pago
			  AND j01_cont_cred   = 'C')
	END AS nom_tp,
	CASE WHEN j10_banco = 0
		THEN j10_valor * (-1)
		ELSE j11_valor
	END AS valor,
	CASE WHEN j10_localidad = 1 THEN "GYE_JTM"
	     WHEN j10_localidad = 2 THEN "GYE_CENTRO"
	END AS loc,
	j10_tipo_fuente AS tipo_f,
	j10_num_fuente AS num_f,
	j10_codigo_caja AS cod_caj,
	j02_nombre_caja AS nom_caj,
	CASE WHEN j11_tipo_fuente IS NULL
		THEN "CREDITO"
		ELSE "CANCELADO"
	END AS tip_c
	FROM cajt010, cajt002, OUTER cajt011
	WHERE j10_compania     = 1
	  AND j10_tipo_fuente <> "EC"
	  AND j10_estado       = "P"
	  AND j02_compania     = j10_compania
	  AND j02_localidad    = j10_localidad
	  AND j02_codigo_caja  = j10_codigo_caja
	  AND j10_compania     = j11_compania
	  AND j10_localidad    = j11_localidad
	  AND j10_tipo_fuente  = j11_tipo_fuente
	  AND j10_num_fuente   = j11_num_fuente
	ORDER BY 3 DESC;
