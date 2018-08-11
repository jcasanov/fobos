SELECT CASE WHEN 1 = 1 THEN "2" END tipo,
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
	WHERE n32_compania    IN (1, 2)
	  AND n32_cod_liqrol  IN ('Q1', 'Q2')
	  AND n32_ano_proceso  = 2010
	  AND n30_compania     = n32_compania
	  AND n30_cod_trab     = n32_cod_trab
UNION
	SELECT CASE WHEN 1 = 1 THEN "2" END tipo,
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
		WHERE n42_compania      IN (1, 2)
		  AND n42_proceso        = 'UT'
		  AND n42_ano            = 2009
		  AND n41_compania       = n42_compania
		  AND n41_proceso        = n42_proceso
		  AND n41_ano            = n42_ano
		  AND n30_compania       = n42_compania
		  AND n30_cod_trab       = n42_cod_trab
	ORDER BY 3 ASC;
