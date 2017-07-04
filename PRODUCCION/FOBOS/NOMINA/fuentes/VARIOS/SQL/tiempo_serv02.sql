SELECT CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	    WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	    WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	    WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS GYE"
	END AS loc,
	LPAD(n30_cod_trab, 3, 0) AS codi,
	n30_num_doc_id AS identif,
	n30_nombres AS empl,
	(SELECT g34_nombre
		FROM gent034
		WHERE g34_compania  = n30_compania
		  AND g34_cod_depto = n30_cod_depto) AS depto,
	(SELECT g35_nombre
		FROM gent035
		WHERE g35_compania  = n30_compania
		  AND g35_cod_cargo = n30_cod_cargo) AS carg,
	TO_CHAR(NVL(n30_fecha_reing, n30_fecha_ing), "%Y-%m-%d") AS fec_ing,
	TO_CHAR(n30_fecha_nacim, "%Y-%m-%d") AS fec_nac,
	CASE WHEN TRUNC((((TODAY - NVL(n30_fecha_reing, n30_fecha_ing)) + 1) /
		n90_dias_anio), 0) > 0
		THEN TRUNC((((TODAY - NVL(n30_fecha_reing, n30_fecha_ing))
			+ 1) / n90_dias_anio), 0)
		ELSE 0
	END AS anio_ser,
	CASE WHEN TRUNC(MOD(((TODAY - NVL(n30_fecha_reing, n30_fecha_ing))
			+ 1), n90_dias_anio) / n00_dias_mes, 0) > 0
		THEN TRUNC(MOD(((TODAY - NVL(n30_fecha_reing,
				n30_fecha_ing)) + 1), n90_dias_anio) /
				n00_dias_mes, 0)
		ELSE 0
	END AS mes_ser,
	CASE WHEN MOD(MOD(((TODAY - NVL(n30_fecha_reing, n30_fecha_ing))
				+ 1), n90_dias_anio), n00_dias_mes) > 0
		THEN MOD(MOD(((TODAY - NVL(n30_fecha_reing,
				n30_fecha_ing)) + 1), n90_dias_anio),
				n00_dias_mes)
		ELSE 0
	END AS dias_ser,
	CASE WHEN TRUNC((((TODAY - n30_fecha_nacim) + 1) / 365), 0) > 0
		THEN TRUNC((((TODAY - n30_fecha_nacim) + 1) / 365), 0)
		ELSE 0
	END AS anio_edad,
	CASE WHEN TRUNC(MOD(((TODAY - n30_fecha_nacim) + 1), 365) /
				n00_dias_mes, 0) > 0
		THEN TRUNC(MOD(((TODAY - n30_fecha_nacim) + 1), 365) /
				n00_dias_mes, 0)
		ELSE 0
	END AS mes_edad,
	CASE WHEN MOD(MOD(((TODAY - n30_fecha_nacim) + 1), 365),
				n00_dias_mes) > 0
		THEN MOD(MOD(((TODAY - n30_fecha_nacim) + 1), 365),
				n00_dias_mes)
		ELSE 0
	END AS dias_edad,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	END AS est,
	n30_sueldo_mes AS sueld_act
	FROM rolt030, rolt090, rolt000
	WHERE n30_compania = 1
	  AND n30_estado   = "A"
	  AND n90_compania = n30_compania
          AND n00_serial   = n90_compania
	ORDER BY 4 ASC;
