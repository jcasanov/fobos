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
	DATE(r21_fecing) AS fecha,
	LPAD(DAY(r21_fecing), 2, 0) || " " ||
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
	END || " " || YEAR(r21_fecing) AS dia_p,
	(SELECT r01_nombres
		FROM rept001
		WHERE r01_compania = r21_compania
		  AND r01_codigo   = r21_vendedor) AS vend,
	r21_numprof AS profor,
	r21_codcli AS cod_cli,
	r21_nomcli AS nom_cli,
	LPAD(fp_numero_semana(DATE(r21_fecing)), 2, 0) AS num_sem,
	r21_tot_bruto - r21_tot_dscto AS valor
	FROM rept021
	WHERE r21_compania     = 1
	  AND r21_localidad    = 1
	  AND r21_cod_tran     IS NULL
	  AND YEAR(r21_fecing) > 2011;
