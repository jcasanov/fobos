SELECT n30_nombres AS empleados,
	n30_cod_trab AS cod_rol,
	r01_codigo AS cod_vend,
	CASE WHEN r01_tipo = "I" THEN "INTERNO"
	     WHEN r01_tipo = "E" THEN "EXTERNO"
	END AS tipo,
	CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	     WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	     WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	     WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS"
	END AS localidad
	FROM acero_gm@idsgye01:rept001, acero_gm@idsgye01:rolt030
	WHERE r01_compania  = 1
	  AND r01_estado    = "A"
	  AND r01_tipo     IN ("I", "E")
	  AND r01_codrol   NOT IN (27, 68, 173, 212)
	  AND n30_compania  = r01_compania
	  AND n30_cod_trab  = r01_codrol
UNION
SELECT n30_nombres AS empleados,
	n30_cod_trab AS cod_rol,
	r01_codigo AS cod_vend,
	CASE WHEN r01_tipo = "I" THEN "INTERNO"
	     WHEN r01_tipo = "E" THEN "EXTERNO"
	END AS tipo,
	CASE WHEN n30_sub_activ = "1" THEN "01 ACERO GUAYAQUIL"
	     WHEN n30_sub_activ = "2" THEN "02 ACERO CENTRO GYE"
	     WHEN n30_sub_activ = "3" THEN "03 ACERO MATRIZ QUITO"
	     WHEN n30_sub_activ = "4" THEN "04 ACERO QUITO SUR"
		ELSE "OTROS"
	END AS localidad
	FROM acero_qm@idsuio01:rept001, acero_qm@idsuio01:rolt030
	WHERE r01_compania  = 1
	  AND r01_estado    = "A"
	  AND r01_tipo     IN ("I", "E")
	  AND n30_compania  = r01_compania
	  AND n30_cod_trab  = r01_codrol
	ORDER BY 5, 4, 1;
