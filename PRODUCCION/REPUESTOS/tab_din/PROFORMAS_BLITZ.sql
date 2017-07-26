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
        END AS nom_mes,
	CASE WHEN WEEKDAY(r21_fecing) = 01 THEN "LUN"
	     WHEN WEEKDAY(r21_fecing) = 02 THEN "MAR"
	     WHEN WEEKDAY(r21_fecing) = 03 THEN "MIE"
	     WHEN WEEKDAY(r21_fecing) = 04 THEN "JUE"
	     WHEN WEEKDAY(r21_fecing) = 05 THEN "VIE"
	     WHEN WEEKDAY(r21_fecing) = 06 THEN "SAB"
	     WHEN WEEKDAY(r21_fecing) = 07 THEN "DOM"
	END || " " || TO_CHAR(r21_fecing, "%d") || " " ||
        CASE WHEN MONTH(r21_fecing) = 01 THEN "ENE"
             WHEN MONTH(r21_fecing) = 02 THEN "FEB"
             WHEN MONTH(r21_fecing) = 03 THEN "MAR"
             WHEN MONTH(r21_fecing) = 04 THEN "ABR"
             WHEN MONTH(r21_fecing) = 05 THEN "MAY"
             WHEN MONTH(r21_fecing) = 06 THEN "JUN"
             WHEN MONTH(r21_fecing) = 07 THEN "JUL"
             WHEN MONTH(r21_fecing) = 08 THEN "AGO"
             WHEN MONTH(r21_fecing) = 09 THEN "SEP"
             WHEN MONTH(r21_fecing) = 10 THEN "OCT"
             WHEN MONTH(r21_fecing) = 11 THEN "NOV"
             WHEN MONTH(r21_fecing) = 12 THEN "DIC"
        END AS dia,
        r01_nombres AS vend,
	r21_codcli AS cod_c,
	r21_nomcli AS nom_c,
	r22_item AS ite,
	r72_desc_clase AS clas,
	r10_nombre AS nom_ite,
        r10_marca AS marc,
	r10_filtro AS filt,
	r21_cod_tran AS cod_t,
	r21_num_tran AS num_t,
	r21_numprof AS num_prof,
        SUM(r22_cantidad) AS cant,
        SUM(r22_precio) AS prec,
        SUM(r22_val_descto) AS dscto,
        SUM((r22_cantidad * r22_precio) - r22_val_descto) AS venta
        FROM rept021, rept001, rept022, rept010, rept072
        WHERE r21_compania      = 1
          AND r21_localidad     = 1
	  AND DATE(r21_fecing) >= MDY(08, 05, 2013)
          AND r01_compania      = r21_compania
          AND r01_codigo        = r21_vendedor
          AND r22_compania      = r21_compania
          AND r22_localidad     = r21_localidad
          AND r22_numprof       = r21_numprof
	  AND r22_item         IN (SELECT * FROM tmp_blitz)
          AND r10_compania      = r22_compania
          AND r10_codigo        = r22_item
          AND r72_compania      = r10_compania
          AND r72_linea         = r10_linea
          AND r72_sub_linea     = r10_sub_linea
          AND r72_cod_grupo     = r10_cod_grupo
          AND r72_cod_clase     = r10_cod_clase
        GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14;
