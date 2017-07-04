SELECT n30_cod_trab AS codi,
	n30_nombres AS empl,
	g34_nombre AS depto,
	g35_nombre AS carg,
	n30_domicilio AS direc,
	n30_telef_domic AS telef,
	NVL(n30_fecha_reing, n30_fecha_ing) AS fec_ing,
	n30_num_doc_id AS num_d,
	n30_sectorial AS cod_sec,
	n17_descripcion AS des_sec,
	CASE WHEN n30_tipo_doc_id = "C"
		THEN "CEDULA"
		ELSE "PASAPORTE"
	END AS tip,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est,
	CASE WHEN TRUNC((((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) /
                 n90_dias_anio), 0) > 0
                THEN TRUNC((((TODAY - NVL(n30_fecha_reing, n30_fecha_ing))
                         + 1) / n90_dias_anio), 0)
                ELSE 0
        END AS anio_ser,
	CASE WHEN TRUNC((((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) /
                 n90_dias_anio), 0) > 0
                THEN LPAD(TRUNC((((TODAY - NVL(n30_fecha_reing, n30_fecha_ing))
                         + 1) / n90_dias_anio), 0), 2, 0)
                ELSE ""
        END ||
        CASE WHEN TRUNC((((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) /
                 n90_dias_anio), 0) = 1
                THEN " Año "
             WHEN TRUNC((((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) /
                 n90_dias_anio), 0) > 1
                THEN " Años "
                ELSE ""
        END ||
        CASE WHEN TRUNC(MOD(((TODAY - NVL(n30_fecha_reing, n30_fecha_ing))
                         + 1), n90_dias_anio) / n00_dias_mes, 0) > 0
                THEN CASE WHEN (MOD(MOD(((TODAY - NVL(n30_fecha_reing,
                         n30_fecha_ing)) + 1),
                        n90_dias_anio), n00_dias_mes) = 0)
                     OR NOT ((TRUNC((((TODAY - NVL(n30_fecha_reing,
                                n30_fecha_ing)) + 1) / n90_dias_anio), 0) > 0)
                        OR (TRUNC(MOD(((TODAY - NVL(n30_fecha_reing,
                                n30_fecha_ing)) + 1), n90_dias_anio) /
                                n00_dias_mes, 0) > 0))
                                THEN "y "
                                ELSE ""
                        END ||
                        LPAD(TRUNC(MOD(((TODAY - NVL(n30_fecha_reing,
                                n30_fecha_ing)) + 1), n90_dias_anio) /
                                n00_dias_mes, 0), 2, 0)
                ELSE ""
        END ||
        CASE WHEN TRUNC(MOD(((TODAY - NVL(n30_fecha_reing, n30_fecha_ing))
                                + 1), n90_dias_anio) / n00_dias_mes, 0) = 1
                THEN " Mes "
             WHEN TRUNC(MOD(((TODAY - NVL(n30_fecha_reing, n30_fecha_ing))
                                + 1), n90_dias_anio) / n00_dias_mes, 0) > 1
                THEN " Meses "
                ELSE ""
        END ||
        CASE WHEN MOD(MOD(((TODAY - NVL(n30_fecha_reing, n30_fecha_ing))
                                + 1), n90_dias_anio), n00_dias_mes) > 0
                THEN CASE WHEN (TRUNC((((TODAY - NVL(n30_fecha_reing,
                                n30_fecha_ing)) + 1) / n90_dias_anio), 0) > 0)
                        OR (TRUNC(MOD(((TODAY - NVL(n30_fecha_reing,
                                n30_fecha_ing)) + 1), n90_dias_anio) /
                                n00_dias_mes, 0) > 0)
                                THEN "y "
                                ELSE ""
                        END ||
                        LPAD(MOD(MOD(((TODAY - NVL(n30_fecha_reing,
                                n30_fecha_ing)) + 1), n90_dias_anio),
                                n00_dias_mes), 2, 0)
                ELSE ""
        END ||
        CASE WHEN MOD(MOD(((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1),
                        n90_dias_anio), n00_dias_mes) = 1
                THEN " Día"
             WHEN MOD(MOD(((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1),
                        n90_dias_anio), n00_dias_mes) > 1
                THEN " Días"
                ELSE ""
        END AS tie_ser,
	CASE WHEN TRUNC((((TODAY - n30_fecha_nacim) + 1) /
                 n90_dias_anio), 0) > 0
                THEN LPAD(TRUNC((((TODAY - n30_fecha_nacim)
                         + 1) / n90_dias_anio), 0), 2, 0)
                ELSE ""
        END ||
        CASE WHEN TRUNC((((TODAY - n30_fecha_nacim) + 1) /
                 n90_dias_anio), 0) = 1
                THEN " Año "
             WHEN TRUNC((((TODAY - n30_fecha_nacim) + 1) /
                 n90_dias_anio), 0) > 1
                THEN " Años "
                ELSE ""
        END ||
        CASE WHEN TRUNC(MOD(((TODAY - n30_fecha_nacim)
                         + 1), n90_dias_anio) / n00_dias_mes, 0) > 0
                THEN CASE WHEN (MOD(MOD(((TODAY - n30_fecha_nacim) + 1),
                        n90_dias_anio), n00_dias_mes) = 0)
                     OR NOT ((TRUNC((((TODAY - n30_fecha_nacim) + 1) /
				n90_dias_anio), 0) > 0)
                        OR (TRUNC(MOD(((TODAY - n30_fecha_nacim) + 1),
				n90_dias_anio) / n00_dias_mes, 0) > 0))
                                THEN "y "
                                ELSE ""
                        END ||
                        LPAD(TRUNC(MOD(((TODAY - n30_fecha_nacim) + 1),
				n90_dias_anio) / n00_dias_mes, 0), 2, 0)
                ELSE ""
        END ||
        CASE WHEN TRUNC(MOD(((TODAY - n30_fecha_nacim)
                                + 1), n90_dias_anio) / n00_dias_mes, 0) = 1
                THEN " Mes "
             WHEN TRUNC(MOD(((TODAY - n30_fecha_nacim)
                                + 1), n90_dias_anio) / n00_dias_mes, 0) > 1
                THEN " Meses "
                ELSE ""
        END ||
        CASE WHEN MOD(MOD(((TODAY - n30_fecha_nacim)
                                + 1), n90_dias_anio), n00_dias_mes) > 0
                THEN CASE WHEN (TRUNC((((TODAY - n30_fecha_nacim) + 1) /
				n90_dias_anio), 0) > 0)
                        OR (TRUNC(MOD(((TODAY - n30_fecha_nacim) + 1),
				n90_dias_anio) / n00_dias_mes, 0) > 0)
                                THEN "y "
                                ELSE ""
                        END ||
                        LPAD(MOD(MOD(((TODAY - n30_fecha_nacim) + 1),
				n90_dias_anio), n00_dias_mes), 2, 0)
                ELSE ""
        END ||
        CASE WHEN MOD(MOD(((TODAY - n30_fecha_nacim) + 1),
                        n90_dias_anio), n00_dias_mes) = 1
                THEN " Día"
             WHEN MOD(MOD(((TODAY - n30_fecha_nacim) + 1),
                        n90_dias_anio), n00_dias_mes) > 1
                THEN " Días"
                ELSE ""
        END AS tie_eda
	FROM rolt030, rolt090, rolt000, rolt017, gent034, gent035
	WHERE n30_compania   = 1
	  AND n17_compania   = n30_compania
	  AND n17_ano_sect   = n30_ano_sect
	  AND n17_sectorial  = n30_sectorial
	  AND g34_compania   = n30_compania
	  AND g34_cod_depto  = n30_cod_depto
	  AND g35_compania   = n30_compania
	  AND g35_cod_cargo  = n30_cod_cargo
	  AND n90_compania   = n30_compania
          AND n00_serial     = n90_compania
	ORDER BY 2 ASC;
