SELECT n30_cod_trab AS codigo,
	n30_nombres AS empleados,
	CASE WHEN n30_tipo_doc_id = "P"
		THEN "3"
		ELSE "2"
	END AS tipo,
	n30_num_doc_id AS cedula,
	"009" AS establ
	FROM rolt032, rolt030
	WHERE n32_compania     = 1
	  AND n32_cod_liqrol  IN ('Q1', 'Q2')
	  AND n32_ano_proceso  = 2012
	  AND n30_compania     = n32_compania
	  AND n30_cod_trab     = n32_cod_trab
UNION
	SELECT n30_cod_trab AS codigo,
		n30_nombres AS empleados,
		CASE WHEN n30_tipo_doc_id = "P"
			THEN "3"
			ELSE "2"
		END AS tipo,
		n30_num_doc_id cedula,
		"009" AS establ
		FROM rolt042, rolt041, rolt030
		WHERE n42_compania = 1
		  AND n42_proceso  = 'UT'
		  AND n42_ano      = 2011
		  AND n41_compania = n42_compania
		  AND n41_proceso  = n42_proceso
		  AND n41_ano      = n42_ano
		  AND n30_compania = n42_compania
		  AND n30_cod_trab = n42_cod_trab
	ORDER BY 2 ASC;
