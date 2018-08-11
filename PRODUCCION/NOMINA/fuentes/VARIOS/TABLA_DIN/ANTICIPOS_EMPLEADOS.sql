SELECT YEAR(a.n45_fecing) AS anio,
	CASE WHEN MONTH(a.n45_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(a.n45_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(a.n45_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(a.n45_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(a.n45_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(a.n45_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(a.n45_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(a.n45_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(a.n45_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(a.n45_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(a.n45_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(a.n45_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	n30_cod_trab AS cod_emp,
	n30_nombres AS nom_emp,
	a.n45_num_prest AS num_prest,
	a.n45_estado AS cod_p,
	CASE WHEN a.n45_estado = "A" THEN "ACTIVO"
	     WHEN a.n45_estado = "P" THEN "PROCESADO"
	     WHEN a.n45_estado = "R" THEN "REDISTRIBUIDO"
	     WHEN a.n45_estado = "T" THEN "TRANSFERIDO"
	END AS nom_p,
	DATE(a.n45_fecing) AS fecha,
	CASE WHEN a.n45_estado <> "T"
		THEN (a.n45_val_prest + a.n45_valor_int + a.n45_sal_prest_ant)
		ELSE (a.n45_val_prest + a.n45_valor_int + a.n45_sal_prest_ant) -
			NVL((SELECT b.n45_sal_prest_ant
				FROM rolt045 b
				WHERE b.n45_compania  = a.n45_compania
				  AND b.n45_num_prest = a.n45_prest_tran), 0)
	END AS val_d, 
	0.00 AS val_p, 
	CASE WHEN a.n45_estado <> "T"
		THEN (a.n45_val_prest + a.n45_valor_int + a.n45_sal_prest_ant)
		ELSE (a.n45_val_prest + a.n45_valor_int + a.n45_sal_prest_ant) -
			NVL((SELECT b.n45_sal_prest_ant
				FROM rolt045 b
				WHERE b.n45_compania  = a.n45_compania
				  AND b.n45_num_prest = a.n45_prest_tran), 0)
	END AS sald, 
	LPAD(a.n45_cod_rubro, 2, 0) AS rubro, 
	(SELECT n06_nombre
		FROM rolt006 
		WHERE n06_cod_rubro = a.n45_cod_rubro) AS nom_r,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est,
	(SELECT UNIQUE n16_descripcion
		FROM rolt018, rolt016
		WHERE n18_cod_rubro  = n45_cod_rubro
		  AND n16_flag_ident = n18_flag_ident) AS tip_ant
	FROM rolt030, rolt045 a
	WHERE a.n45_compania  = 1
	  AND a.n45_estado   IN ("A", "R", "P")
	  AND n30_compania    = a.n45_compania
	  AND n30_cod_trab    = a.n45_cod_trab
UNION
SELECT YEAR(a.n45_fecing) AS anio,
	CASE WHEN MONTH(a.n45_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(a.n45_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(a.n45_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(a.n45_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(a.n45_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(a.n45_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(a.n45_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(a.n45_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(a.n45_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(a.n45_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(a.n45_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(a.n45_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	n30_cod_trab AS cod_emp,
	n30_nombres AS nom_emp,
	a.n45_num_prest AS num_prest,
	a.n45_estado AS cod_p,
	CASE WHEN a.n45_estado = "A" THEN "ACTIVO"
	     WHEN a.n45_estado = "P" THEN "PROCESADO"
	     WHEN a.n45_estado = "R" THEN "REDISTRIBUIDO"
	     WHEN a.n45_estado = "T" THEN "TRANSFERIDO"
	END AS nom_p,
	DATE(a.n45_fecing) AS fecha,
	CASE WHEN a.n45_estado <> "T"
		THEN (a.n45_val_prest + a.n45_valor_int + a.n45_sal_prest_ant)
		ELSE (a.n45_val_prest + a.n45_valor_int + a.n45_sal_prest_ant) -
			NVL((SELECT b.n45_sal_prest_ant
				FROM rolt045 b
				WHERE b.n45_compania  = a.n45_compania
				  AND b.n45_num_prest = a.n45_prest_tran), 0)
	END AS val_d, 
	0.00 AS val_p, 
	CASE WHEN a.n45_estado <> "T"
		THEN (a.n45_val_prest + a.n45_valor_int + a.n45_sal_prest_ant)
		ELSE (a.n45_val_prest + a.n45_valor_int + a.n45_sal_prest_ant) -
			NVL((SELECT b.n45_sal_prest_ant
				FROM rolt045 b
				WHERE b.n45_compania  = a.n45_compania
				  AND b.n45_num_prest = a.n45_prest_tran), 0)
	END AS sald, 
	LPAD(a.n45_cod_rubro, 2, 0) AS rubro, 
	(SELECT n06_nombre
		FROM rolt006 
		WHERE n06_cod_rubro = a.n45_cod_rubro) AS nom_r,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est,
	(SELECT UNIQUE n16_descripcion
		FROM rolt018, rolt016
		WHERE n18_cod_rubro  = n45_cod_rubro
		  AND n16_flag_ident = n18_flag_ident) AS tip_ant
	FROM rolt030, rolt045 a
	WHERE  a.n45_compania  = 1
	  AND  a.n45_estado    = "T"
	  AND  n30_compania    = a.n45_compania
	  AND  n30_cod_trab    = a.n45_cod_trab
	  AND (EXISTS
		(SELECT 1 FROM rolt033
			WHERE n33_compania    = a.n45_compania
			  AND n33_cod_liqrol IN ("Q1", "Q2")
			  AND n33_cod_trab    = a.n45_cod_trab
			  AND n33_num_prest   = a.n45_num_prest)
	   OR  EXISTS
		(SELECT 1 FROM rolt092
			WHERE n92_compania  = a.n45_compania
			  AND n92_cod_trab  = a.n45_cod_trab
			  AND n92_num_prest = a.n45_num_prest))
UNION
SELECT n32_ano_proceso AS anio,
	CASE WHEN n32_mes_proceso = 01 THEN "ENERO"
	     WHEN n32_mes_proceso = 02 THEN "FEBRERO"
	     WHEN n32_mes_proceso = 03 THEN "MARZO"
	     WHEN n32_mes_proceso = 04 THEN "ABRIL"
	     WHEN n32_mes_proceso = 05 THEN "MAYO"
	     WHEN n32_mes_proceso = 06 THEN "JUNIO"
	     WHEN n32_mes_proceso = 07 THEN "JULIO"
	     WHEN n32_mes_proceso = 08 THEN "AGOSTO"
	     WHEN n32_mes_proceso = 09 THEN "SEPTIEMBRE"
	     WHEN n32_mes_proceso = 10 THEN "OCTUBRE"
	     WHEN n32_mes_proceso = 11 THEN "NOVIEMBRE"
	     WHEN n32_mes_proceso = 12 THEN "DICIEMBRE"
	END AS mes,
	n30_cod_trab AS cod_emp,
	n30_nombres AS nom_emp,
	n33_num_prest AS num_prest,
	n33_cod_liqrol AS cod_p,
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = n33_cod_liqrol) AS nom_p,
	DATE(n32_fecing) AS fecha,
	0.00 AS val_d, 
	n33_valor * (-1) AS val_p,
	n33_valor * (-1) AS sald,
	LPAD(n33_cod_rubro, 2, 0) AS rubro,
	(SELECT n06_nombre
		FROM rolt006
		WHERE n06_cod_rubro = n33_cod_rubro) AS nom_r,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est,
	(SELECT UNIQUE n16_descripcion
		FROM rolt018, rolt016
		WHERE n18_cod_rubro  = n33_cod_rubro
		  AND n16_flag_ident = n18_flag_ident) AS tip_ant
	FROM rolt033, rolt032, rolt030
	WHERE n33_compania      = 1
	  AND n33_cod_liqrol   IN ("Q1", "Q2")
	  AND n33_valor         > 0
	  AND n33_det_tot       = "DE"
	  AND n33_cant_valor    = "V"
	  AND n33_num_prest    IS NOT NULL
	  AND n33_cod_rubro    IN
		(SELECT n06_cod_rubro
			FROM rolt006
			WHERE n06_flag_ident IN
				(SELECT n18_flag_ident
					FROM rolt018
					WHERE n18_cod_rubro = n06_cod_rubro))
    	  AND n32_compania      = n33_compania
	  AND n32_cod_liqrol    = n33_cod_liqrol
	  AND n32_fecha_ini     = n33_fecha_ini
	  AND n32_fecha_fin     = n33_fecha_fin
	  AND n32_cod_trab      = n33_cod_trab
	  AND DATE(n32_fecing) >= MDY(04, 01, 2007)
	  AND n30_compania      = n32_compania
	  AND n30_cod_trab      = n32_cod_trab
UNION
SELECT YEAR(n36_fecing) AS anio,
	CASE WHEN MONTH(n36_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(n36_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(n36_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(n36_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(n36_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(n36_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(n36_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(n36_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(n36_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(n36_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(n36_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(n36_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	n30_cod_trab AS cod_emp,
	n30_nombres AS nom_emp,
	n37_num_prest AS num_prest,
	n37_proceso AS cod_p,
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = n37_proceso) AS nom_p,
	DATE(n36_fecing) AS fecha,
	0.00 AS val_d,
	n37_valor * (-1) AS val_p,
	n37_valor * (-1) AS sald,
	LPAD(n37_cod_rubro, 2, 0) AS rubro,
	(SELECT n06_nombre
		FROM rolt006
		WHERE n06_cod_rubro = n37_cod_rubro) AS nom_r,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est,
	(SELECT UNIQUE n16_descripcion
		FROM rolt018, rolt016
		WHERE n18_cod_rubro  = n37_cod_rubro
		  AND n16_flag_ident = n18_flag_ident) AS tip_ant
	FROM rolt037, rolt036, rolt030
	WHERE n37_compania      = 1
	  AND n37_proceso      IN ("DT", "DC")
	  AND n37_valor         > 0
	  AND n37_det_tot       = "DE"
	  AND n37_num_prest    IS NOT NULL
	  AND n37_cod_rubro    IN
		(SELECT n06_cod_rubro
			FROM rolt006
			WHERE n06_flag_ident IN
				(SELECT n18_flag_ident
					FROM rolt018
					WHERE n18_cod_rubro = n06_cod_rubro))
	  AND n36_compania      = n37_compania
	  AND n36_proceso       = n37_proceso
	  AND n36_fecha_ini     = n37_fecha_ini
	  AND n36_fecha_fin     = n37_fecha_fin
	  AND n36_cod_trab      = n37_cod_trab
	  AND DATE(n36_fecing) >= MDY(04, 01, 2007)
	  AND n30_compania      = n36_compania
	  AND n30_cod_trab      = n36_cod_trab
UNION
SELECT YEAR(n39_fecing) AS anio,
	CASE WHEN MONTH(n39_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(n39_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(n39_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(n39_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(n39_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(n39_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(n39_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(n39_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(n39_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(n39_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(n39_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(n39_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	n30_cod_trab AS cod_emp,
	n30_nombres AS nom_emp,
	n40_num_prest AS num_prest,
	n40_proceso AS cod_p,
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = n40_proceso) AS nom_p,
	DATE(n39_fecing) AS fecha,
	0.00 AS val_d,
	n40_valor * (-1) AS val_p,
	n40_valor * (-1) AS sald,
	LPAD(n40_cod_rubro, 2, 0) AS rubro,
	(SELECT n06_nombre
		FROM rolt006
		WHERE n06_cod_rubro = n40_cod_rubro) AS nom_r,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est,
	(SELECT UNIQUE n16_descripcion
		FROM rolt018, rolt016
		WHERE n18_cod_rubro  = n40_cod_rubro
		  AND n16_flag_ident = n18_flag_ident) AS tip_ant
	FROM rolt040, rolt039, rolt030
	WHERE n40_compania      = 1
	  AND n40_proceso      IN ("VA", "VP")
	  AND n40_valor         > 0
	  AND n40_det_tot       = "DE"
	  AND n40_num_prest    IS NOT NULL
	  AND n40_cod_rubro    IN
		(SELECT n06_cod_rubro
			FROM rolt006
			WHERE n06_flag_ident IN
				(SELECT n18_flag_ident
					FROM rolt018
					WHERE n18_cod_rubro = n06_cod_rubro))
	  AND n39_compania      = n40_compania
	  AND n39_proceso       = n40_proceso
	  AND n39_periodo_ini   = n40_periodo_ini
	  AND n39_periodo_fin   = n40_periodo_fin
	  AND n39_cod_trab      = n40_cod_trab
	  AND DATE(n39_fecing) >= MDY(04, 01, 2007)
	  AND n30_compania      = n39_compania
	  AND n30_cod_trab      = n39_cod_trab
UNION
SELECT YEAR(n41_fecing) AS anio,
	CASE WHEN MONTH(n41_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(n41_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(n41_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(n41_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(n41_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(n41_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(n41_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(n41_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(n41_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(n41_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(n41_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(n41_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	n30_cod_trab AS cod_emp,
	n30_nombres AS nom_emp,
	n49_num_prest AS num_prest,
	n49_proceso AS cod_p,
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = n49_proceso) AS nom_p,
	DATE(n41_fecing) AS fecha,
	0.00 AS val_d,
	n49_valor * (-1) AS val_p,
	n49_valor * (-1) AS sald,
	LPAD(n49_cod_rubro, 2, 0) AS rubro,
	(SELECT n06_nombre
		FROM rolt006
		WHERE n06_cod_rubro = n49_cod_rubro) AS nom_r,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est,
	(SELECT UNIQUE n16_descripcion
		FROM rolt018, rolt016
		WHERE n18_cod_rubro  = n49_cod_rubro
		  AND n16_flag_ident = n18_flag_ident) AS tip_ant
	FROM rolt049, rolt042, rolt030, rolt041
	WHERE n49_compania      = 1
	  AND n49_proceso       = "UT"
	  AND n49_valor         > 0 
	  AND n49_det_tot       = "DE"
	  AND n49_num_prest    IS NOT NULL
	  AND n49_cod_rubro    IN
		(SELECT n06_cod_rubro
			FROM rolt006
			WHERE n06_flag_ident IN
				(SELECT n18_flag_ident
					FROM rolt018
					WHERE n18_cod_rubro = n06_cod_rubro))
	  AND n42_compania      = n49_compania
	  AND n42_proceso       = n49_proceso
	  AND n42_cod_trab      = n49_cod_trab
	  AND n42_fecha_ini     = n49_fecha_ini
	  AND n42_fecha_fin     = n49_fecha_fin
	  AND n30_compania      = n42_compania
	  AND n30_cod_trab      = n42_cod_trab
	  AND n41_compania      = n42_compania
	  AND n41_proceso       = n42_proceso
	  AND n41_fecha_ini     = n42_fecha_ini
	  AND n41_fecha_fin     = n42_fecha_fin
	  AND DATE(n41_fecing) >= MDY(04, 01, 2007)
UNION
SELECT YEAR(n91_fecing) AS anio,
	CASE WHEN MONTH(n91_fecing) = 01 THEN "ENERO"
	     WHEN MONTH(n91_fecing) = 02 THEN "FEBRERO"
	     WHEN MONTH(n91_fecing) = 03 THEN "MARZO"
	     WHEN MONTH(n91_fecing) = 04 THEN "ABRIL"
	     WHEN MONTH(n91_fecing) = 05 THEN "MAYO"
	     WHEN MONTH(n91_fecing) = 06 THEN "JUNIO"
	     WHEN MONTH(n91_fecing) = 07 THEN "JULIO"
	     WHEN MONTH(n91_fecing) = 08 THEN "AGOSTO"
	     WHEN MONTH(n91_fecing) = 09 THEN "SEPTIEMBRE"
	     WHEN MONTH(n91_fecing) = 10 THEN "OCTUBRE"
	     WHEN MONTH(n91_fecing) = 11 THEN "NOVIEMBRE"
	     WHEN MONTH(n91_fecing) = 12 THEN "DICIEMBRE"
	END AS mes,
	n30_cod_trab AS cod_emp,
	n30_nombres AS nom_emp,
	n92_num_prest AS num_prest,
	n91_proceso AS cod_p,
	(SELECT n03_nombre_abr
		FROM rolt003
		WHERE n03_proceso = n91_proceso) AS nom_p,
	DATE(n91_fecing) AS fecha,
	0.00 AS val_d,
	SUM(n92_valor_pago) AS val_p,
	SUM(n92_valor_pago) AS sald,
	n92_cod_liqrol AS rubro,
	(SELECT n03_nombre
		FROM rolt003
		WHERE n03_proceso = n92_cod_liqrol) AS nom_r,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est,
	(SELECT UNIQUE n16_descripcion
		FROM rolt045, rolt018, rolt016
		WHERE n45_compania   = n92_compania
		  AND n45_num_prest  = n92_num_prest
		  AND n18_cod_rubro  = n45_cod_rubro
		  AND n16_flag_ident = n18_flag_ident) AS tip_ant
	FROM rolt092, rolt091, rolt030
	WHERE n92_compania      = 1
	  AND n92_proceso       = "CA"
	  AND n92_num_prest    IS NOT NULL
	  AND n92_valor_pago   <> 0
	  AND n91_compania      = n92_compania
	  AND n91_proceso       = n92_proceso
	  AND n91_cod_trab      = n92_cod_trab
	  AND n91_num_ant       = n92_num_ant
	  AND n30_compania      = n91_compania
	  AND n30_cod_trab      = n91_cod_trab
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 12, 13, 14, 15;
