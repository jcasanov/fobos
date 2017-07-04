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
        END AS nom_mes,
	CASE WHEN WEEKDAY(r19_fecing) = 01 THEN "LUN"
	     WHEN WEEKDAY(r19_fecing) = 02 THEN "MAR"
	     WHEN WEEKDAY(r19_fecing) = 03 THEN "MIE"
	     WHEN WEEKDAY(r19_fecing) = 04 THEN "JUE"
	     WHEN WEEKDAY(r19_fecing) = 05 THEN "VIE"
	     WHEN WEEKDAY(r19_fecing) = 06 THEN "SAB"
	     WHEN WEEKDAY(r19_fecing) = 07 THEN "DOM"
	END || " " || TO_CHAR(r19_fecing, "%d") || " " ||
        CASE WHEN MONTH(r19_fecing) = 01 THEN "ENE"
             WHEN MONTH(r19_fecing) = 02 THEN "FEB"
             WHEN MONTH(r19_fecing) = 03 THEN "MAR"
             WHEN MONTH(r19_fecing) = 04 THEN "ABR"
             WHEN MONTH(r19_fecing) = 05 THEN "MAY"
             WHEN MONTH(r19_fecing) = 06 THEN "JUN"
             WHEN MONTH(r19_fecing) = 07 THEN "JUL"
             WHEN MONTH(r19_fecing) = 08 THEN "AGO"
             WHEN MONTH(r19_fecing) = 09 THEN "SEP"
             WHEN MONTH(r19_fecing) = 10 THEN "OCT"
             WHEN MONTH(r19_fecing) = 11 THEN "NOV"
             WHEN MONTH(r19_fecing) = 12 THEN "DIC"
        END AS dia,
        r01_nombres AS vend,
	r19_codcli AS cod_c,
	r19_nomcli AS nom_c,
	r20_item AS ite,
	r72_desc_clase AS clas,
	r10_nombre AS nom_ite,
        r10_marca AS marc,
	r10_filtro AS filt,
	r19_cod_tran AS cod_t,
	r19_num_tran AS num_t,
	(SELECT r21_numprof
		FROM rept021
		WHERE r21_compania  = r19_compania
		  AND r21_localidad = r19_localidad
		  AND r21_cod_tran  = r19_cod_tran
		  AND r21_num_tran  = r19_num_tran) AS num_prof,
        SUM(CASE WHEN r19_cod_tran = "FA"
                THEN (r20_cant_ven)
                ELSE (r20_cant_ven) * (-1)
        END) AS cant,
        SUM(CASE WHEN r19_cod_tran = "FA"
                THEN (r20_precio)
                ELSE (r20_precio) * (-1)
        END) AS prec,
        SUM(CASE WHEN r19_cod_tran = "FA"
                THEN (r20_val_descto)
                ELSE (r20_val_descto) * (-1)
        END) AS dscto,
        SUM(CASE WHEN r19_cod_tran = "FA"
                THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
                ELSE ((r20_cant_ven * r20_precio) - r20_val_descto) * (-1)
        END) AS venta
        FROM rept019, rept001, rept020, rept010, rept072
        WHERE r19_compania      = 1
          AND r19_localidad     = 1
          AND r19_cod_tran     IN ("FA", "DF", "AF")
	  AND DATE(r19_fecing) >= MDY(08, 05, 2013)
          AND r01_compania      = r19_compania
          AND r01_codigo        = r19_vendedor
          AND r20_compania      = r19_compania
          AND r20_localidad     = r19_localidad
          AND r20_cod_tran      = r19_cod_tran
          AND r20_num_tran      = r19_num_tran
	  AND r20_item         NOT IN (SELECT * FROM tmp_blitz)
          AND r10_compania      = r20_compania
          AND r10_codigo        = r20_item
	  AND r10_marca         = 'MILWAU'
          AND r72_compania      = r10_compania
          AND r72_linea         = r10_linea
          AND r72_sub_linea     = r10_sub_linea
          AND r72_cod_grupo     = r10_cod_grupo
          AND r72_cod_clase     = r10_cod_clase
        GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14;
