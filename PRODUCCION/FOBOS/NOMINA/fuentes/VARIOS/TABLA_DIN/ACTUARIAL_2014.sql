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
	g01_razonsocial AS razonsoc,
	g02_direccion AS domicil,
	g02_telefono1 AS telf,
	g02_numruc AS n_ruc,
	n30_nombres AS empleado,
	n30_fecha_nacim AS fecha_nac,
	NVL(n30_fecha_reing, n30_fecha_ing) AS fec_ing,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est,
	CASE WHEN n30_tipo_trab = "N"
		THEN "NORMAL"
		ELSE "EJECUTIVO"
	END AS tip_emp,
	n30_sueldo_mes AS sueld,
	NVL(SUM(n32_tot_gan), 0.00) AS tot_gan
	FROM acero_gm@idsgye01:rolt030,
		acero_gm@idsgye01:rolt032,
		acero_gm@idsgye01:gent001,
		acero_gm@idsgye01:gent002
	WHERE n30_compania     = 1
	  AND n30_estado       = "A"
	  AND n32_compania     = n30_compania
	  AND n32_cod_liqrol  IN ("Q1", "Q2")
	  AND n32_cod_trab     = n30_cod_trab
	  AND n32_ano_proceso  > 2009
	  AND g01_compania     = n32_compania
	  AND g02_compania     = g01_compania
	  AND g02_localidad    = 1
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
UNION ALL
SELECT n48_ano_proceso AS anio,
	CASE WHEN n48_mes_proceso = 01 THEN "ENERO"
	     WHEN n48_mes_proceso = 02 THEN "FEBRERO"
	     WHEN n48_mes_proceso = 03 THEN "MARZO"
	     WHEN n48_mes_proceso = 04 THEN "ABRIL"
	     WHEN n48_mes_proceso = 05 THEN "MAYO"
	     WHEN n48_mes_proceso = 06 THEN "JUNIO"
	     WHEN n48_mes_proceso = 07 THEN "JULIO"
	     WHEN n48_mes_proceso = 08 THEN "AGOSTO"
	     WHEN n48_mes_proceso = 09 THEN "SEPTIEMBRE"
	     WHEN n48_mes_proceso = 10 THEN "OCTUBRE"
	     WHEN n48_mes_proceso = 11 THEN "NOVIEMBRE"
	     WHEN n48_mes_proceso = 12 THEN "DICIEMBRE"
	END AS mes,
	g01_razonsocial AS razonsoc,
	g02_direccion AS domicil,
	g02_telefono1 AS telf,
	g02_numruc AS n_ruc,
	n30_nombres AS empleado,
	n30_fecha_nacim AS fecha_nac,
	NVL(n30_fecha_reing, n30_fecha_ing) AS fec_ing,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est,
	CASE WHEN n30_tipo_trab = "N"
		THEN "NORMAL"
		ELSE "EJECUTIVO"
	END AS tip_emp,
	n30_val_jub_pat AS sueld,
	NVL(SUM(n48_tot_gan), 0.00) AS tot_gan
	FROM acero_gm@idsgye01:rolt030,
		acero_gm@idsgye01:rolt048,
		acero_gm@idsgye01:gent001,
		acero_gm@idsgye01:gent002
	WHERE n30_compania    = 1
	  AND n30_estado      = "J"
	  AND n48_compania    = n30_compania
	  AND n48_cod_liqrol  = "ME"
	  AND n48_cod_trab    = n30_cod_trab
	  AND n48_ano_proceso > 2009
	  AND g01_compania    = n48_compania
	  AND g02_compania    = g01_compania
	  AND g02_localidad   = 1
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
UNION ALL
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
	g01_razonsocial AS razonsoc,
	g02_direccion AS domicil,
	g02_telefono1 AS telf,
	g02_numruc AS n_ruc,
	n30_nombres AS empleado,
	n30_fecha_nacim AS fecha_nac,
	NVL(n30_fecha_reing, n30_fecha_ing) AS fec_ing,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est,
	CASE WHEN n30_tipo_trab = "N"
		THEN "NORMAL"
		ELSE "EJECUTIVO"
	END AS tip_emp,
	n30_sueldo_mes AS sueld,
	NVL(SUM(n32_tot_gan), 0.00) AS tot_gan
	FROM acero_qm@idsuio01:rolt030,
		acero_qm@idsuio01:rolt032,
		acero_qm@idsuio01:gent001,
		acero_qm@idsuio01:gent002
	WHERE n30_compania     = 1
	  AND n30_estado       = "A"
	  AND n32_compania     = n30_compania
	  AND n32_cod_liqrol  IN ("Q1", "Q2")
	  AND n32_cod_trab     = n30_cod_trab
	  AND n32_ano_proceso  > 2009
	  AND g01_compania     = n32_compania
	  AND g02_compania     = g01_compania
	  AND g02_localidad    = 3
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12
UNION ALL
SELECT n48_ano_proceso AS anio,
	CASE WHEN n48_mes_proceso = 01 THEN "ENERO"
	     WHEN n48_mes_proceso = 02 THEN "FEBRERO"
	     WHEN n48_mes_proceso = 03 THEN "MARZO"
	     WHEN n48_mes_proceso = 04 THEN "ABRIL"
	     WHEN n48_mes_proceso = 05 THEN "MAYO"
	     WHEN n48_mes_proceso = 06 THEN "JUNIO"
	     WHEN n48_mes_proceso = 07 THEN "JULIO"
	     WHEN n48_mes_proceso = 08 THEN "AGOSTO"
	     WHEN n48_mes_proceso = 09 THEN "SEPTIEMBRE"
	     WHEN n48_mes_proceso = 10 THEN "OCTUBRE"
	     WHEN n48_mes_proceso = 11 THEN "NOVIEMBRE"
	     WHEN n48_mes_proceso = 12 THEN "DICIEMBRE"
	END AS mes,
	g01_razonsocial AS razonsoc,
	g02_direccion AS domicil,
	g02_telefono1 AS telf,
	g02_numruc AS n_ruc,
	n30_nombres AS empleado,
	n30_fecha_nacim AS fecha_nac,
	NVL(n30_fecha_reing, n30_fecha_ing) AS fec_ing,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est,
	CASE WHEN n30_tipo_trab = "N"
		THEN "NORMAL"
		ELSE "EJECUTIVO"
	END AS tip_emp,
	n30_val_jub_pat AS sueld,
	NVL(SUM(n48_tot_gan), 0.00) AS tot_gan
	FROM acero_qm@idsuio01:rolt030,
		acero_qm@idsuio01:rolt048,
		acero_qm@idsuio01:gent001,
		acero_qm@idsuio01:gent002
	WHERE n30_compania    = 1
	  AND n30_estado      = "J"
	  AND n48_compania    = n30_compania
	  AND n48_cod_liqrol  = "ME"
	  AND n48_cod_trab    = n30_cod_trab
	  AND n48_ano_proceso > 2009
	  AND g01_compania    = n48_compania
	  AND g02_compania    = g01_compania
	  AND g02_localidad   = 3
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12;
