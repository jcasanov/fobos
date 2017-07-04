SELECT CASE WHEN n30_tipo_doc_id = "P"
		THEN "3"
		ELSE "2"
	END tipo,
	n30_num_doc_id cedula,
	REPLACE(REPLACE(n30_nombres, "Ñ", "N"), "ñ", "N") nombre,
	CASE WHEN n30_telef_domic IS NOT NULL AND LENGTH(n30_telef_domic) = 9
		THEN n30_telef_domic
		ELSE "042683060"
	END telefono,
	REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
		REPLACE(REPLACE(n30_domicilio[1, 20], "ñ", "N"),
			"Ñ", "N"), "/", ""), "-", " "), ",", ""),
			":", ""), "#", "No.") direccion,
	"109" prov,
	"10901" ciudad
	FROM rolt032, rolt030
	WHERE n32_compania         = 1
	  AND n32_cod_liqrol      IN ('Q1', 'Q2')
	  AND n32_ano_proceso      = 2011
	  AND n30_compania         = n32_compania
	  AND n30_cod_trab         = n32_cod_trab
	  AND YEAR(n30_fecha_ing)  = n32_ano_proceso
UNION
	SELECT CASE WHEN n30_tipo_doc_id = "P"
			THEN "3"
			ELSE "2"
		END tipo,
		n30_num_doc_id cedula,
		REPLACE(REPLACE(n30_nombres, "Ñ", "N"), "ñ", "N") nombre,
		CASE WHEN n30_telef_domic IS NOT NULL AND
				LENGTH(n30_telef_domic) = 9
			THEN n30_telef_domic
			ELSE "042683060"
		END telefono,
		REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
			REPLACE(REPLACE(n30_domicilio[1, 20],"ñ", "N"),
				"Ñ", "N"), "/", ""), "-", " "), ",", ""),
				":", ""), "#", "No.") direccion,
		"109" prov,
		"10901" ciudad
		FROM rolt042, rolt041, rolt030
		WHERE n42_compania        = 1
		  AND n42_proceso         = 'UT'
		  AND n42_ano             = 2010
		  AND n41_compania        = n42_compania
		  AND n41_proceso         = n42_proceso
		  AND n41_ano             = n42_ano
		  AND n30_compania        = n42_compania
		  AND n30_cod_trab        = n42_cod_trab
		  AND YEAR(n30_fecha_ing) = n41_ano + 1
	ORDER BY 3 ASC;
