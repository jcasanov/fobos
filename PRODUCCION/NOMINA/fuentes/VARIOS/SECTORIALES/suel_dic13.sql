SELECT "GUAYAQUIL" AS localidad,
	n30_cod_trab AS codigo,
	n30_nombres AS empleado,
	NVL((SELECT SUM(n32_sueldo)
		FROM acero_gm@idsgye01:rolt032
		WHERE n32_compania    = n30_compania
		  AND n32_cod_liqrol IN ("Q1", "Q2")
		  AND n32_fecha_ini  >= MDY(12, 01, 2013)
		  AND n32_fecha_fin  <= MDY(12, 31, 2013)
		  AND n32_cod_trab    = n30_cod_trab) / 2, 0.00) AS sueldo_dic,
	n30_sueldo_mes AS sueldo_nue,
	n30_sueldo_mes -
	NVL((SELECT SUM(n32_sueldo)
		FROM acero_gm@idsgye01:rolt032
		WHERE n32_compania    = n30_compania
		  AND n32_cod_liqrol IN ("Q1", "Q2")
		  AND n32_fecha_ini  >= MDY(12, 01, 2013)
		  AND n32_fecha_fin  <= MDY(12, 31, 2013)
		  AND n32_cod_trab    = n30_cod_trab) / 2, 0.00) AS diferencia,
	NVL((SELECT n10_valor
		FROM acero_gm@idsgye01:rolt010
		WHERE n10_compania  = n30_compania
		  AND n10_cod_trab  = n30_cod_trab
		  AND n10_cod_rubro = 15), 0.00) AS moviliz,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM acero_gm@idsgye01:rolt030
	WHERE n30_compania = 1
	  AND n30_estado   = 'A'
	  AND NVL(n30_fecha_reing, n30_fecha_ing) <= MDY(12, 31, 2013)
UNION
SELECT "QUITO" AS localidad,
	n30_cod_trab AS codigo,
	n30_nombres AS empleado,
	NVL((SELECT SUM(n32_sueldo)
		FROM acero_qm@idsuio01:rolt032
		WHERE n32_compania    = n30_compania
		  AND n32_cod_liqrol IN ("Q1", "Q2")
		  AND n32_fecha_ini  >= MDY(12, 01, 2013)
		  AND n32_fecha_fin  <= MDY(12, 31, 2013)
		  AND n32_cod_trab    = n30_cod_trab) / 2, 0.00) AS sueldo_dic,
	n30_sueldo_mes AS sueldo_nue,
	n30_sueldo_mes -
	NVL((SELECT SUM(n32_sueldo)
		FROM acero_qm@idsuio01:rolt032
		WHERE n32_compania    = n30_compania
		  AND n32_cod_liqrol IN ("Q1", "Q2")
		  AND n32_fecha_ini  >= MDY(12, 01, 2013)
		  AND n32_fecha_fin  <= MDY(12, 31, 2013)
		  AND n32_cod_trab    = n30_cod_trab) / 2, 0.00) AS diferencia,
	NVL((SELECT n10_valor
		FROM acero_qm@idsuio01:rolt010
		WHERE n10_compania  = n30_compania
		  AND n10_cod_trab  = n30_cod_trab
		  AND n10_cod_rubro = 16), 0.00) AS moviliz,
	CASE WHEN n30_estado = 'A'
		THEN "ACTIVO"
		ELSE "INACTIVO"
	END AS estado
	FROM acero_qm@idsuio01:rolt030
	WHERE n30_compania = 1
	  AND n30_estado   = 'A'
	  AND NVL(n30_fecha_reing, n30_fecha_ing) <= MDY(12, 31, 2013)
	ORDER BY 1, 3;
