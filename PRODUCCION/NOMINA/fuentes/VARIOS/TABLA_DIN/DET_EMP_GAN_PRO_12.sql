SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS GYE"
	END AS loc,
	a.n32_ano_proceso AS anio,
	CASE WHEN a.n32_mes_proceso = 01 THEN "ENERO"
	     WHEN a.n32_mes_proceso = 02 THEN "FEBRERO"
	     WHEN a.n32_mes_proceso = 03 THEN "MARZO"
	     WHEN a.n32_mes_proceso = 04 THEN "ABRIL"
	     WHEN a.n32_mes_proceso = 05 THEN "MAYO"
	     WHEN a.n32_mes_proceso = 06 THEN "JUNIO"
	     WHEN a.n32_mes_proceso = 07 THEN "JULIO"
	     WHEN a.n32_mes_proceso = 08 THEN "AGOSTO"
	     WHEN a.n32_mes_proceso = 09 THEN "SEPTIEMBRE"
	     WHEN a.n32_mes_proceso = 10 THEN "OCTUBRE"
	     WHEN a.n32_mes_proceso = 11 THEN "NOVIEMBRE"
	     WHEN a.n32_mes_proceso = 12 THEN "DICIEMBRE"
	END AS mes,
	n30_cod_trab AS codi,
	n30_nombres AS empl,
	(SELECT g34_nombre
		FROM gent034
		WHERE g34_compania  = a.n32_compania
		  AND g34_cod_depto = a.n32_cod_depto) AS depto,
	(SELECT g35_nombre
		FROM gent035
		WHERE g35_compania  = n30_compania
		  AND g35_cod_cargo = n30_cod_cargo) AS carg,
	n30_domicilio AS direc,
	n30_telef_domic AS telef,
	NVL(n30_fecha_reing, n30_fecha_ing) AS fec_ing,
	CASE WHEN n30_tipo_doc_id = "C"
		THEN "CEDULA"
		ELSE "PASAPORTE"
	END AS tip,
	n30_num_doc_id AS num_d,
	n30_sectorial AS cod_sec,
	(SELECT n17_descripcion
		FROM rolt017
		WHERE n17_compania  = n30_compania
		  AND n17_ano_sect  = n30_ano_sect
		  AND n17_sectorial = n30_sectorial) AS des_sec,
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
                THEN " A�o "
             WHEN TRUNC((((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) /
                 n90_dias_anio), 0) > 1
                THEN " A�os "
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
                THEN " D�a"
             WHEN MOD(MOD(((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1),
                        n90_dias_anio), n00_dias_mes) > 1
                THEN " D�as"
                ELSE ""
        END AS tie_ser,
	CASE WHEN TRUNC((((TODAY - n30_fecha_nacim) + 1) /
                 365), 0) > 0
                THEN TRUNC((((TODAY - n30_fecha_nacim)
                         + 1) / 365), 0)
                ELSE 0
        END AS anio_eda,
	CASE WHEN TRUNC((((TODAY - n30_fecha_nacim) + 1) /
                 365), 0) > 0
                THEN LPAD(TRUNC((((TODAY - n30_fecha_nacim)
                         + 1) / 365), 0), 2, 0)
                ELSE ""
        END ||
        CASE WHEN TRUNC((((TODAY - n30_fecha_nacim) + 1) /
                 365), 0) = 1
                THEN " A�o "
             WHEN TRUNC((((TODAY - n30_fecha_nacim) + 1) /
                 365), 0) > 1
                THEN " A�os "
                ELSE ""
        END ||
        CASE WHEN TRUNC(MOD(((TODAY - n30_fecha_nacim)
                         + 1), 365) / n00_dias_mes, 0) > 0
                THEN CASE WHEN (MOD(MOD(((TODAY - n30_fecha_nacim) + 1),
                        365), n00_dias_mes) = 0)
                     OR NOT ((TRUNC((((TODAY - n30_fecha_nacim) + 1) /
				365), 0) > 0)
                        OR (TRUNC(MOD(((TODAY - n30_fecha_nacim) + 1),
				365) / n00_dias_mes, 0) > 0))
                                THEN "y "
                                ELSE ""
                        END ||
                        LPAD(TRUNC(MOD(((TODAY - n30_fecha_nacim) + 1),
				365) / n00_dias_mes, 0), 2, 0)
                ELSE ""
        END ||
        CASE WHEN TRUNC(MOD(((TODAY - n30_fecha_nacim)
                                + 1), 365) / n00_dias_mes, 0) = 1
                THEN " Mes "
             WHEN TRUNC(MOD(((TODAY - n30_fecha_nacim)
                                + 1), 365) / n00_dias_mes, 0) > 1
                THEN " Meses "
                ELSE ""
        END ||
        CASE WHEN MOD(MOD(((TODAY - n30_fecha_nacim)
                                + 1), 365), n00_dias_mes) > 0
                THEN CASE WHEN (TRUNC((((TODAY - n30_fecha_nacim) + 1) /
				365), 0) > 0)
                        OR (TRUNC(MOD(((TODAY - n30_fecha_nacim) + 1),
				365) / n00_dias_mes, 0) > 0)
                                THEN "y "
                                ELSE ""
                        END ||
                        LPAD(MOD(MOD(((TODAY - n30_fecha_nacim) + 1),
				365), n00_dias_mes), 2, 0)
                ELSE ""
        END ||
        CASE WHEN MOD(MOD(((TODAY - n30_fecha_nacim) + 1),
                        365), n00_dias_mes) = 1
                THEN " D�a"
             WHEN MOD(MOD(((TODAY - n30_fecha_nacim) + 1),
                        365), n00_dias_mes) > 1
                THEN " D�as"
                ELSE ""
        END AS tie_eda,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est,
	n30_sueldo_mes AS sueld_act,
	CASE WHEN c.n06_flag_ident IN ("V5", "V1") THEN "02 SOBRETIEMPOS"
	     WHEN c.n06_flag_ident IN ("CO", "C1", "C2", "C3", "C4")
		THEN "03 COMISIONES"
	     WHEN c.n06_flag_ident = "BO"          THEN "04 BONIFICACIONES"
	     WHEN c.n06_flag_ident = "MO"          THEN "05 MOVILIZACION"
	     WHEN c.n06_flag_ident IN ("VT", "VE", "VM", "VV", "OV", "SX",
					  "SY")    THEN "01 VAL DIAS TRAB"
		ELSE "07 SIN RUBROS"
	END AS nom_r,
	NVL(SUM(b.n33_valor), 0.00) AS valor_r
	FROM rolt032 a, rolt030, rolt090, rolt000, OUTER(rolt033 b, rolt006 c)
	WHERE a.n32_compania    = 1
	  AND a.n32_cod_liqrol IN ("Q1", "Q2")
	  AND a.n32_fecha_ini  >= (SELECT MAX(d.n32_fecha_fin) + 1 UNITS DAY
						- 1 UNITS YEAR
					FROM rolt032 d
					WHERE d.n32_compania   = a.n32_compania
					  AND d.n32_cod_liqrol IN ("Q1", "Q2"))
	  AND n30_compania      = a.n32_compania
	  AND n30_cod_trab      = a.n32_cod_trab
	  AND n90_compania      = n30_compania
          AND n00_serial        = n90_compania
	  AND b.n33_compania    = a.n32_compania
	  AND b.n33_cod_liqrol  = a.n32_cod_liqrol
	  AND b.n33_fecha_ini   = a.n32_fecha_ini
	  AND b.n33_fecha_fin   = a.n32_fecha_fin
	  AND b.n33_cod_trab    = a.n32_cod_trab
	  AND b.n33_valor       > 0
	  AND c.n06_cod_rubro   = b.n33_cod_rubro
	  AND (c.n06_cod_rubro IN
		(SELECT n08_rubro_base
			FROM rolt006 d, rolt008
			WHERE d.n06_flag_ident = "AP"
			  AND n08_cod_rubro    = d.n06_cod_rubro)
	   OR  c.n06_flag_ident IN ("BO", "MO"))
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18,
		19, 20, 21
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS UIO"
	END AS loc,
	a.n32_ano_proceso AS anio,
	CASE WHEN a.n32_mes_proceso = 01 THEN "ENERO"
	     WHEN a.n32_mes_proceso = 02 THEN "FEBRERO"
	     WHEN a.n32_mes_proceso = 03 THEN "MARZO"
	     WHEN a.n32_mes_proceso = 04 THEN "ABRIL"
	     WHEN a.n32_mes_proceso = 05 THEN "MAYO"
	     WHEN a.n32_mes_proceso = 06 THEN "JUNIO"
	     WHEN a.n32_mes_proceso = 07 THEN "JULIO"
	     WHEN a.n32_mes_proceso = 08 THEN "AGOSTO"
	     WHEN a.n32_mes_proceso = 09 THEN "SEPTIEMBRE"
	     WHEN a.n32_mes_proceso = 10 THEN "OCTUBRE"
	     WHEN a.n32_mes_proceso = 11 THEN "NOVIEMBRE"
	     WHEN a.n32_mes_proceso = 12 THEN "DICIEMBRE"
	END AS mes,
	n30_cod_trab AS codi,
	n30_nombres AS empl,
	(SELECT g34_nombre
		FROM acero_qm@acgyede:gent034
		WHERE g34_compania  = a.n32_compania
		  AND g34_cod_depto = a.n32_cod_depto) AS depto,
	(SELECT g35_nombre
		FROM acero_qm@acgyede:gent035
		WHERE g35_compania  = n30_compania
		  AND g35_cod_cargo = n30_cod_cargo) AS carg,
	n30_domicilio AS direc,
	n30_telef_domic AS telef,
	NVL(n30_fecha_reing, n30_fecha_ing) AS fec_ing,
	CASE WHEN n30_tipo_doc_id = "C"
		THEN "CEDULA"
		ELSE "PASAPORTE"
	END AS tip,
	n30_num_doc_id AS num_d,
	n30_sectorial AS cod_sec,
	(SELECT n17_descripcion
		FROM acero_qm@acgyede:rolt017
		WHERE n17_compania  = n30_compania
		  AND n17_ano_sect  = n30_ano_sect
		  AND n17_sectorial = n30_sectorial) AS des_sec,
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
                THEN " A�o "
             WHEN TRUNC((((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) /
                 n90_dias_anio), 0) > 1
                THEN " A�os "
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
                THEN " D�a"
             WHEN MOD(MOD(((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1),
                        n90_dias_anio), n00_dias_mes) > 1
                THEN " D�as"
                ELSE ""
        END AS tie_ser,
	CASE WHEN TRUNC((((TODAY - n30_fecha_nacim) + 1) /
                 365), 0) > 0
                THEN TRUNC((((TODAY - n30_fecha_nacim)
                         + 1) / 365), 0)
                ELSE 0
        END AS anio_eda,
	CASE WHEN TRUNC((((TODAY - n30_fecha_nacim) + 1) /
                 365), 0) > 0
                THEN LPAD(TRUNC((((TODAY - n30_fecha_nacim)
                         + 1) / 365), 0), 2, 0)
                ELSE ""
        END ||
        CASE WHEN TRUNC((((TODAY - n30_fecha_nacim) + 1) /
                 365), 0) = 1
                THEN " A�o "
             WHEN TRUNC((((TODAY - n30_fecha_nacim) + 1) /
                 365), 0) > 1
                THEN " A�os "
                ELSE ""
        END ||
        CASE WHEN TRUNC(MOD(((TODAY - n30_fecha_nacim)
                         + 1), 365) / n00_dias_mes, 0) > 0
                THEN CASE WHEN (MOD(MOD(((TODAY - n30_fecha_nacim) + 1),
                        365), n00_dias_mes) = 0)
                     OR NOT ((TRUNC((((TODAY - n30_fecha_nacim) + 1) /
				365), 0) > 0)
                        OR (TRUNC(MOD(((TODAY - n30_fecha_nacim) + 1),
				365) / n00_dias_mes, 0) > 0))
                                THEN "y "
                                ELSE ""
                        END ||
                        LPAD(TRUNC(MOD(((TODAY - n30_fecha_nacim) + 1),
				365) / n00_dias_mes, 0), 2, 0)
                ELSE ""
        END ||
        CASE WHEN TRUNC(MOD(((TODAY - n30_fecha_nacim)
                                + 1), 365) / n00_dias_mes, 0) = 1
                THEN " Mes "
             WHEN TRUNC(MOD(((TODAY - n30_fecha_nacim)
                                + 1), 365) / n00_dias_mes, 0) > 1
                THEN " Meses "
                ELSE ""
        END ||
        CASE WHEN MOD(MOD(((TODAY - n30_fecha_nacim)
                                + 1), 365), n00_dias_mes) > 0
                THEN CASE WHEN (TRUNC((((TODAY - n30_fecha_nacim) + 1) /
				365), 0) > 0)
                        OR (TRUNC(MOD(((TODAY - n30_fecha_nacim) + 1),
				365) / n00_dias_mes, 0) > 0)
                                THEN "y "
                                ELSE ""
                        END ||
                        LPAD(MOD(MOD(((TODAY - n30_fecha_nacim) + 1),
				365), n00_dias_mes), 2, 0)
                ELSE ""
        END ||
        CASE WHEN MOD(MOD(((TODAY - n30_fecha_nacim) + 1),
                        365), n00_dias_mes) = 1
                THEN " D�a"
             WHEN MOD(MOD(((TODAY - n30_fecha_nacim) + 1),
                        365), n00_dias_mes) > 1
                THEN " D�as"
                ELSE ""
        END AS tie_eda,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est,
	n30_sueldo_mes AS sueld_act,
	CASE WHEN c.n06_flag_ident IN ("V5", "V1") THEN "02 SOBRETIEMPOS"
	     WHEN c.n06_flag_ident IN ("CO", "C1", "C2", "C3", "C4")
		THEN "03 COMISIONES"
	     WHEN c.n06_flag_ident = "BO"          THEN "04 BONIFICACIONES"
	     WHEN c.n06_flag_ident = "MO"          THEN "05 MOVILIZACION"
	     WHEN c.n06_flag_ident IN ("VT", "VE", "VM", "VV", "OV", "SX",
					  "SY")    THEN "01 VAL DIAS TRAB"
		ELSE "07 SIN RUBROS"
	END AS nom_r,
	NVL(SUM(b.n33_valor), 0.00) AS valor_r
	FROM acero_qm@acgyede:rolt032 a, acero_qm@acgyede:rolt030,
		acero_qm@acgyede:rolt090, acero_qm@acgyede:rolt000,
		OUTER(acero_qm@acgyede:rolt033 b, acero_qm@acgyede:rolt006 c)
	WHERE a.n32_compania    = 1
	  AND a.n32_cod_liqrol IN ("Q1", "Q2")
	  AND a.n32_fecha_ini  >= (SELECT MAX(d.n32_fecha_fin) + 1 UNITS DAY
						- 1 UNITS YEAR
					FROM acero_qm@acgyede:rolt032 d
					WHERE d.n32_compania   = a.n32_compania
					  AND d.n32_cod_liqrol IN ("Q1", "Q2"))
	  AND n30_compania      = a.n32_compania
	  AND n30_cod_trab      = a.n32_cod_trab
	  AND n90_compania      = n30_compania
          AND n00_serial        = n90_compania
	  AND b.n33_compania    = a.n32_compania
	  AND b.n33_cod_liqrol  = a.n32_cod_liqrol
	  AND b.n33_fecha_ini   = a.n32_fecha_ini
	  AND b.n33_fecha_fin   = a.n32_fecha_fin
	  AND b.n33_cod_trab    = a.n32_cod_trab
	  AND b.n33_valor       > 0
	  AND c.n06_cod_rubro   = b.n33_cod_rubro
	  AND (c.n06_cod_rubro IN
		(SELECT n08_rubro_base
			FROM acero_qm@acgyede:rolt006 d,
				acero_qm@acgyede:rolt008
			WHERE d.n06_flag_ident = "AP"
			  AND n08_cod_rubro    = d.n06_cod_rubro)
	   OR  c.n06_flag_ident IN ("BO", "MO"))
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18,
		19, 20, 21;