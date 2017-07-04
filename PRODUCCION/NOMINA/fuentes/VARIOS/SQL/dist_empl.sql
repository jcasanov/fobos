SELECT "J T M" AS loc,
	n30_cod_trab AS cod,
	n30_nombres AS empl,
	g34_nombre AS depto,
	g35_nombre AS carg,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADOS"
	END AS est,
	CASE WHEN n30_sexo = "F"
		THEN "MUJER"
		ELSE "HOMBRE"
	END AS gener
	FROM rolt030, gent034, gent035
	WHERE n30_compania  = 1
	  AND g34_compania  = n30_compania
	  AND g34_cod_depto = n30_cod_depto
	  AND g35_compania  = n30_compania
	  AND g35_cod_cargo = n30_cod_cargo
UNION
SELECT "QUITO" AS loc,
	n30_cod_trab AS cod,
	n30_nombres AS empl,
	g34_nombre AS depto,
	g35_nombre AS carg,
	CASE WHEN n30_estado = "A" THEN "ACTIVO"
	     WHEN n30_estado = "I" THEN "INACTIVO"
	     WHEN n30_estado = "J" THEN "JUBILADOS"
	END AS est,
	CASE WHEN n30_sexo = "F"
		THEN "MUJER"
		ELSE "HOMBRE"
	END AS gener
	FROM acero_qm@idsuio01:rolt030, acero_qm@idsuio01:gent034,
		acero_qm@idsuio01:gent035
	WHERE n30_compania  = 1
	  AND g34_compania  = n30_compania
	  AND g34_cod_depto = n30_cod_depto
	  AND g35_compania  = n30_compania
	  AND g35_cod_cargo = n30_cod_cargo
	ORDER BY 3 ASC;
