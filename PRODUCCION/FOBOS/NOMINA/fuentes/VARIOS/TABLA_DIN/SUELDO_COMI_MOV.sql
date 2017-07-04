SELECT n32_ano_proceso AS anio,
	EXTEND(MDY(n32_mes_proceso, 01, n32_ano_proceso), YEAR TO MONTH) AS mes,
	{--
	n32_ano_proceso || "-" ||
	CASE WHEN n32_mes_proceso = 01 THEN "ENE"
	     WHEN n32_mes_proceso = 02 THEN "FEB"
	     WHEN n32_mes_proceso = 03 THEN "MAR"
	     WHEN n32_mes_proceso = 04 THEN "ABR"
	     WHEN n32_mes_proceso = 05 THEN "MAY"
	     WHEN n32_mes_proceso = 06 THEN "JUN"
	     WHEN n32_mes_proceso = 07 THEN "JUL"
	     WHEN n32_mes_proceso = 08 THEN "AGO"
	     WHEN n32_mes_proceso = 09 THEN "SEP"
	     WHEN n32_mes_proceso = 10 THEN "OCT"
	     WHEN n32_mes_proceso = 11 THEN "NOV"
	     WHEN n32_mes_proceso = 12 THEN "DIC"
	END AS mes,
	--}
	n32_cod_trab AS cod_t,
	n30_nombres AS empl,
	(SELECT g34_nombre
		FROM gent034
		WHERE g34_compania  = n32_compania
		  AND g34_cod_depto = n32_cod_depto) AS depto,
	CASE WHEN n06_flag_ident = "VT"
		THEN "SUELDO"
		ELSE n06_nombre_abr
	END AS rub,
	NVL(CASE WHEN n06_flag_ident = "VT"
		THEN (n32_sueldo / 2)
		ELSE n33_valor
	END, 0) AS valor,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADO"
	END AS est
	FROM rolt032, rolt033, rolt006, rolt030
	WHERE n32_compania    = 1
	  AND n32_cod_liqrol IN ("Q1", "Q2")
	  AND n33_compania    = n32_compania
	  AND n33_cod_liqrol  = n32_cod_liqrol
	  AND n33_fecha_ini   = n32_fecha_ini
	  AND n33_fecha_fin   = n32_fecha_fin
	  AND n33_cod_trab    = n32_cod_trab
	  AND n33_valor       > 0
	  AND n06_cod_rubro   = n33_cod_rubro
	  AND n06_flag_ident IN ("VT", "CO", "MO")
	  AND n30_compania    = n33_compania
	  AND n30_cod_trab    = n33_cod_trab;
