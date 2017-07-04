SELECT YEAR(r21_fecing) AS anio,
	CASE WHEN MONTH(r21_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(r21_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(r21_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(r21_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(r21_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(r21_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(r21_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(r21_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(r21_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(r21_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(r21_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(r21_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	TO_CHAR(r21_fecing, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(r21_fecing)), 2, 0) AS num_sem,
	r21_codcli AS codcli,
	r21_nomcli AS nomcli,
	(SELECT r01_nombres
		FROM acero_gm@idsgye01:rept001
		WHERE r01_compania = r21_compania
		  AND r01_codigo   = r21_vendedor) AS vend,
	"PROFORMAS" AS tipo,
	COUNT(UNIQUE r21_numprof) AS tot_reg,
	SUM((r22_cantidad * r22_precio) - r22_val_descto) AS total
	FROM acero_gm@idsgye01:rept021, acero_gm@idsgye01:rept022
	WHERE r21_compania      = 1
	  AND r21_localidad     = 1
	  AND YEAR(r21_fecing) >= 2014
	  AND r22_compania      = r21_compania
	  AND r22_localidad     = r21_localidad
	  AND r22_numprof       = r21_numprof
	GROUP BY 1, 2, 3, 4, 5, 6, 7
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
	TO_CHAR(r19_fecing, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(r19_fecing)), 2, 0) AS num_sem,
	r19_codcli AS codcli,
	r19_nomcli AS nomcli,
	(SELECT r01_nombres
		FROM acero_gm@idsgye01:rept001
		WHERE r01_compania = r19_compania
		  AND r01_codigo   = r19_vendedor) AS vend,
	CASE WHEN r19_cod_tran = "FA" THEN "FACTURAS"
	     WHEN r19_cod_tran = "DF" THEN "DEVOLUCION"
	     WHEN r19_cod_tran = "AF" THEN "ANULACION"
	END AS tipo,
	COUNT(UNIQUE r19_num_tran) AS tot_reg,
	SUM(CASE WHEN r19_cod_tran = "FA"
			THEN (r20_cant_ven * r20_precio) - r20_val_descto
			ELSE ((r20_cant_ven * r20_precio) - r20_val_descto)
				* (-1)
		END) AS total
	FROM acero_gm@idsgye01:rept019, acero_gm@idsgye01:rept020
	WHERE r19_compania      = 1
	  AND r19_localidad     = 1
	  AND r19_cod_tran     IN ("FA", "DF", "AF")
	  AND YEAR(r19_fecing) >= 2014
	  AND r20_compania      = r19_compania
	  AND r20_localidad     = r19_localidad
	  AND r20_cod_tran      = r19_cod_tran
	  AND r20_num_tran      = r19_num_tran
	GROUP BY 1, 2, 3, 4, 5, 6, 7
UNION
SELECT YEAR(a.r19_fecing) AS anio,
	CASE WHEN MONTH(a.r19_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(a.r19_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(a.r19_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(a.r19_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(a.r19_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(a.r19_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(a.r19_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(a.r19_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(a.r19_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(a.r19_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(a.r19_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(a.r19_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	TO_CHAR(a.r19_fecing, "%y") || "_" ||
	LPAD(fp_numero_semana(DATE(a.r19_fecing)), 2, 0) AS num_sem,
	a.r19_codcli AS codcli,
	a.r19_nomcli AS nomcli,
	(SELECT r01_nombres
		FROM acero_gm@idsgye01:rept001
		WHERE r01_compania = a.r19_compania
		  AND r01_codigo   = a.r19_vendedor) AS vend,
	"VENTAS" AS tipo,
	CASE WHEN a.r19_cod_tran = "FA"
		THEN (SELECT COUNT(UNIQUE b.r19_num_tran)
			FROM acero_gm@idsgye01:rept019 b
			WHERE b.r19_compania  = a.r19_compania
			  AND b.r19_localidad = a.r19_localidad
			  AND b.r19_cod_tran  = a.r19_cod_tran
			  AND b.r19_num_tran  = a.r19_num_tran)
		ELSE (SELECT COUNT(UNIQUE b.r19_num_tran)
			FROM acero_gm@idsgye01:rept019 b
			WHERE b.r19_compania  = a.r19_compania
			  AND b.r19_localidad = a.r19_localidad
			  AND b.r19_cod_tran  = a.r19_cod_tran
			  AND b.r19_num_tran  = a.r19_num_tran) * (-1)
	END AS tot_reg,
	SUM(CASE WHEN a.r19_cod_tran = "FA"
			THEN (r20_cant_ven * r20_precio) - r20_val_descto
			ELSE ((r20_cant_ven * r20_precio) - r20_val_descto)
				* (-1)
		END) AS total
	FROM acero_gm@idsgye01:rept019 a, acero_gm@idsgye01:rept020
	WHERE a.r19_compania      = 1
	  AND a.r19_localidad     = 1
	  AND a.r19_cod_tran     IN ("FA", "DF", "AF")
	  AND YEAR(a.r19_fecing) >= 2014
	  AND r20_compania      = a.r19_compania
	  AND r20_localidad     = a.r19_localidad
	  AND r20_cod_tran      = a.r19_cod_tran
	  AND r20_num_tran      = a.r19_num_tran
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8;
