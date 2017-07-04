SELECT n30_cod_trab AS codigo,
	2014 AS periodo,
	CASE WHEN n30_tipo_doc_id = "C"
		THEN "C"
		ELSE "P"
	END AS tipo,
	n30_num_doc_id AS cedula,
	n30_nombres AS empleados,
	"009" AS establ,
	NVL((SELECT n36_valor_bruto
		FROM acero_gm@idsgye01:rolt036
		WHERE n36_compania    = n30_compania
		  AND n36_proceso     = "DT"
		  AND n36_cod_trab    = n30_cod_trab
		  AND n36_ano_proceso = 2014
		  AND n36_estado      = "P"), 0.00) AS decimo_13ro,
	NVL((SELECT n36_valor_bruto
		FROM acero_gm@idsgye01:rolt036
		WHERE n36_compania    = n30_compania
		  AND n36_proceso     = "DC"
		  AND n36_cod_trab    = n30_cod_trab
		  AND n36_ano_proceso = 2014
		  AND n36_estado      = "P"), 0.00) AS decimo_14to,
	NVL((SELECT SUM(n38_valor_fondo)
		FROM acero_gm@idsgye01:rolt038
		WHERE n38_compania        = n30_compania
		  AND n38_cod_trab        = n30_cod_trab
		  AND YEAR(n38_fecha_fin) = 2014
		  AND n38_estado          = "P"), 0.00) AS valor_fr
	FROM acero_gm@idsgye01:rolt032,
		acero_gm@idsgye01:rolt030
	WHERE n32_compania     = 1
	  AND n32_cod_liqrol  IN ('Q1', 'Q2')
	  AND n32_ano_proceso  = 2014
	  AND n30_compania     = n32_compania
	  AND n30_cod_trab     = n32_cod_trab
UNION
	SELECT n42_cod_trab AS codigo,
		2014 AS periodo,
		CASE WHEN n30_tipo_doc_id = "C"
			THEN "C"
			ELSE "P"
		END AS tipo,
		n30_num_doc_id AS cedula,
		n30_nombres AS empleados,
		"009" AS establ,
		0.00 AS decimo_13ro,
		0.00 AS decimo_14to,
		0.00 AS valor_fr
		FROM acero_gm@idsgye01:rolt042,
			acero_gm@idsgye01:rolt041,
			acero_gm@idsgye01:rolt030
		WHERE n42_compania         = 1
		  AND n42_proceso          = 'UT'
		  AND n42_ano              = 2013
		  AND n41_compania         = n42_compania
		  AND n41_proceso          = n42_proceso
		  AND n41_ano              = n42_ano
		  AND n30_compania         = n42_compania
		  AND n30_cod_trab         = n42_cod_trab
		  AND n30_estado           = "I"
		  AND YEAR(n30_fecha_sal) <= 2013
	ORDER BY 5 ASC;
