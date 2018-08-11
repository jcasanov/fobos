SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS GYE"
	END AS loc,
	n30_cod_trab AS codi,
	CASE WHEN n30_tipo_doc_id = "C"
		THEN "CEDULA"
		ELSE "PASAPORTE"
	END AS tip,
	n30_num_doc_id AS cedula,
	n30_nombres AS empl,
	n30_sueldo_mes AS sueld,
	(SELECT g34_nombre
		FROM acero_gm@idsgye01:gent034
		WHERE g34_compania  = n30_compania
		  AND g34_cod_depto = n30_cod_depto) AS depto,
	(SELECT g35_nombre
		FROM acero_gm@idsgye01:gent035
		WHERE g35_compania  = n30_compania
		  AND g35_cod_cargo = n30_cod_cargo) AS carg_int,
	(SELECT n17_descripcion
		FROM acero_gm@idsgye01:rolt017
		WHERE n17_compania  = n30_compania
		  AND n17_ano_sect  = n30_ano_sect
		  AND n17_sectorial = n30_sectorial) AS carg_iess,
	NVL(n30_fecha_reing, n30_fecha_ing) AS fec_ing,
	CAST(CASE WHEN TRUNC((((TODAY - NVL(n30_fecha_reing, n30_fecha_ing))
		+ 1) / n90_dias_anio), 0) > 0
		THEN TRUNC((((TODAY - NVL(n30_fecha_reing, n30_fecha_ing))
		         + 1) / n90_dias_anio), 0)
                ELSE 0
        END AS INTEGER) AS anio_ser,
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
                 365), 0) > 0
                THEN TRUNC((((TODAY - n30_fecha_nacim)
                         + 1) / 365), 0)
                ELSE 0
        END AS anio_edad,
	CASE WHEN TRUNC((((TODAY - n30_fecha_nacim) + 1) /
                 365), 0) > 0
                THEN LPAD(TRUNC((((TODAY - n30_fecha_nacim)
                         + 1) / 365), 0), 2, 0)
                ELSE ""
        END ||
        CASE WHEN TRUNC((((TODAY - n30_fecha_nacim) + 1) /
                 365), 0) = 1
                THEN " Año "
             WHEN TRUNC((((TODAY - n30_fecha_nacim) + 1) /
                 365), 0) > 1
                THEN " Años "
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
                THEN " Día"
             WHEN MOD(MOD(((TODAY - n30_fecha_nacim) + 1),
                        365), n00_dias_mes) > 1
                THEN " Días"
                ELSE ""
        END AS tie_eda,
	NVL((SELECT SUM(n32_tot_gan)
		FROM acero_gm@idsgye01:rolt032
		WHERE n32_compania = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
			(SELECT EXTEND(MAX(a.n32_fecha_fin), YEAR TO MONTH)
				FROM acero_gm@idsgye01:rolt032 a
				WHERE a.n32_compania   = n32_compania
				  AND a.n32_cod_liqrol = 'Q2'
				  AND a.n32_cod_trab   = n32_cod_trab)
		  AND n32_cod_trab = n30_cod_trab),
	n30_sueldo_mes) AS ult_sueld,
	TRUNC(CASE WHEN ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1)
		<= 90
		THEN 0.00
		   WHEN ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) > 90
			AND
			((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1)
			< n90_dias_anio
		THEN 3
		   WHEN ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1)
			>= n90_dias_anio
			AND
			((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1)
			<= (n90_dias_anio * 25)
		THEN (((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) /
			n90_dias_anio)
		ELSE 25
	END, 0) +
	CASE WHEN ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1)
			>= n90_dias_anio
			AND
		  ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1)
			<= (n90_dias_anio * 25)
		THEN MOD(((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) /
			n90_dias_anio, 2)
		ELSE 0.00
	END AS anio_liq,
	ROUND((NVL((SELECT SUM(n32_tot_gan)
		FROM acero_gm@idsgye01:rolt032
		WHERE n32_compania = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
			(SELECT EXTEND(MAX(a.n32_fecha_fin), YEAR TO MONTH)
				FROM acero_gm@idsgye01:rolt032 a
				WHERE a.n32_compania   = n32_compania
				  AND a.n32_cod_liqrol = 'Q2'
				  AND a.n32_cod_trab   = n32_cod_trab)
		  AND n32_cod_trab = n30_cod_trab),
	n30_sueldo_mes) * 25 / 100) *
	CAST(CASE WHEN TRUNC((((TODAY - NVL(n30_fecha_reing, n30_fecha_ing))
		+ 1) / n90_dias_anio), 0) > 0
		THEN TRUNC((((TODAY - NVL(n30_fecha_reing, n30_fecha_ing))
		         + 1) / n90_dias_anio), 0)
                ELSE 0
        END AS INTEGER), 2) AS desahuc,
	ROUND(NVL((SELECT SUM(n32_tot_gan)
		FROM acero_gm@idsgye01:rolt032
		WHERE n32_compania = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
			(SELECT EXTEND(MAX(a.n32_fecha_fin), YEAR TO MONTH)
				FROM acero_gm@idsgye01:rolt032 a
				WHERE a.n32_compania   = n32_compania
				  AND a.n32_cod_liqrol = 'Q2'
				  AND a.n32_cod_trab   = n32_cod_trab)
		  AND n32_cod_trab = n30_cod_trab),
	n30_sueldo_mes) *
	(TRUNC(CASE WHEN ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1)
		<= 90
		THEN 0.00
		   WHEN ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) > 90
			AND
			((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1)
			< n90_dias_anio
		THEN 3
		   WHEN ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1)
			>= n90_dias_anio
			AND
			((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1)
			<= (n90_dias_anio * 25)
		THEN (((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) /
			n90_dias_anio)
		ELSE 25
	END, 0) +
	CASE WHEN ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1)
			>= n90_dias_anio
			AND
		  ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1)
			<= (n90_dias_anio * 25)
		THEN MOD(((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) /
			n90_dias_anio, 2)
		ELSE 0.00
	END), 2) AS indemnizac_desp
	FROM acero_gm@idsgye01:rolt030, acero_gm@idsgye01:rolt090,
		acero_gm@idsgye01:rolt000
	WHERE n30_compania = 1
	  AND n30_estado   = "A"
	  AND n90_compania = n30_compania
          AND n00_serial   = n90_compania
UNION
SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS UIO"
	END AS loc,
	n30_cod_trab AS codi,
	CASE WHEN n30_tipo_doc_id = "C"
		THEN "CEDULA"
		ELSE "PASAPORTE"
	END AS tip,
	n30_num_doc_id AS cedula,
	n30_nombres AS empl,
	n30_sueldo_mes AS sueld,
	(SELECT g34_nombre
		FROM acero_qm@idsuio01:gent034
		WHERE g34_compania  = n30_compania
		  AND g34_cod_depto = n30_cod_depto) AS depto,
	(SELECT g35_nombre
		FROM acero_qm@idsuio01:gent035
		WHERE g35_compania  = n30_compania
		  AND g35_cod_cargo = n30_cod_cargo) AS carg_int,
	(SELECT n17_descripcion
		FROM acero_qm@idsuio01:rolt017
		WHERE n17_compania  = n30_compania
		  AND n17_ano_sect  = n30_ano_sect
		  AND n17_sectorial = n30_sectorial) AS carg_iess,
	NVL(n30_fecha_reing, n30_fecha_ing) AS fec_ing,
	CAST(CASE WHEN TRUNC((((TODAY - NVL(n30_fecha_reing, n30_fecha_ing))
		+ 1) / n90_dias_anio), 0) > 0
		THEN TRUNC((((TODAY - NVL(n30_fecha_reing, n30_fecha_ing))
		         + 1) / n90_dias_anio), 0)
                ELSE 0
        END AS INTEGER) AS anio_ser,
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
                 365), 0) > 0
                THEN TRUNC((((TODAY - n30_fecha_nacim)
                         + 1) / 365), 0)
                ELSE 0
        END AS anio_edad,
	CASE WHEN TRUNC((((TODAY - n30_fecha_nacim) + 1) /
                 365), 0) > 0
                THEN LPAD(TRUNC((((TODAY - n30_fecha_nacim)
                         + 1) / 365), 0), 2, 0)
                ELSE ""
        END ||
        CASE WHEN TRUNC((((TODAY - n30_fecha_nacim) + 1) /
                 365), 0) = 1
                THEN " Año "
             WHEN TRUNC((((TODAY - n30_fecha_nacim) + 1) /
                 365), 0) > 1
                THEN " Años "
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
                THEN " Día"
             WHEN MOD(MOD(((TODAY - n30_fecha_nacim) + 1),
                        365), n00_dias_mes) > 1
                THEN " Días"
                ELSE ""
        END AS tie_eda,
	NVL((SELECT SUM(n32_tot_gan)
		FROM acero_qm@idsuio01:rolt032
		WHERE n32_compania = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
			(SELECT EXTEND(MAX(a.n32_fecha_fin), YEAR TO MONTH)
				FROM acero_qm@idsuio01:rolt032 a
				WHERE a.n32_compania   = n32_compania
				  AND a.n32_cod_liqrol = 'Q2'
				  AND a.n32_cod_trab   = n32_cod_trab)
		  AND n32_cod_trab = n30_cod_trab),
	n30_sueldo_mes) AS ult_sueld,
	TRUNC(CASE WHEN ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1)
		<= 90
		THEN 0.00
		   WHEN ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) > 90
			AND
			((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1)
			< n90_dias_anio
		THEN 3
		   WHEN ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1)
			>= n90_dias_anio
			AND
			((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1)
			<= (n90_dias_anio * 25)
		THEN (((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) /
			n90_dias_anio)
		ELSE 25
	END, 0) +
	CASE WHEN ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1)
			>= n90_dias_anio
			AND
		  ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1)
			<= (n90_dias_anio * 25)
		THEN MOD(((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) /
			n90_dias_anio, 2)
		ELSE 0.00
	END AS anio_liq,
	ROUND((NVL((SELECT SUM(n32_tot_gan)
		FROM acero_qm@idsuio01:rolt032
		WHERE n32_compania = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
			(SELECT EXTEND(MAX(a.n32_fecha_fin), YEAR TO MONTH)
				FROM acero_qm@idsuio01:rolt032 a
				WHERE a.n32_compania   = n32_compania
				  AND a.n32_cod_liqrol = 'Q2'
				  AND a.n32_cod_trab   = n32_cod_trab)
		  AND n32_cod_trab = n30_cod_trab),
	n30_sueldo_mes) * 25 / 100) *
	CAST(CASE WHEN TRUNC((((TODAY - NVL(n30_fecha_reing, n30_fecha_ing))
		+ 1) / n90_dias_anio), 0) > 0
		THEN TRUNC((((TODAY - NVL(n30_fecha_reing, n30_fecha_ing))
		         + 1) / n90_dias_anio), 0)
                ELSE 0
        END AS INTEGER), 2) AS desahuc,
	ROUND(NVL((SELECT SUM(n32_tot_gan)
		FROM acero_qm@idsuio01:rolt032
		WHERE n32_compania = n30_compania
		  AND EXTEND(n32_fecha_fin, YEAR TO MONTH) =
			(SELECT EXTEND(MAX(a.n32_fecha_fin), YEAR TO MONTH)
				FROM acero_qm@idsuio01:rolt032 a
				WHERE a.n32_compania   = n32_compania
				  AND a.n32_cod_liqrol = 'Q2'
				  AND a.n32_cod_trab   = n32_cod_trab)
		  AND n32_cod_trab = n30_cod_trab),
	n30_sueldo_mes) *
	(TRUNC(CASE WHEN ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1)
		<= 90
		THEN 0.00
		   WHEN ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) > 90
			AND
			((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1)
			< n90_dias_anio
		THEN 3
		   WHEN ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1)
			>= n90_dias_anio
			AND
			((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1)
			<= (n90_dias_anio * 25)
		THEN (((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) /
			n90_dias_anio)
		ELSE 25
	END, 0) +
	CASE WHEN ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1)
			>= n90_dias_anio
			AND
		  ((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1)
			<= (n90_dias_anio * 25)
		THEN MOD(((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) /
			n90_dias_anio, 2)
		ELSE 0.00
	END), 2) AS indemnizac_desp
	FROM acero_qm@idsuio01:rolt030, acero_qm@idsuio01:rolt090,
		acero_qm@idsuio01:rolt000
	WHERE n30_compania = 1
	  AND n30_estado   = "A"
	  AND n90_compania = n30_compania
          AND n00_serial   = n90_compania;
