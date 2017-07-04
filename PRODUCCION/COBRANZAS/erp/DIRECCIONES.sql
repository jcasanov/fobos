SELECT "ACERO GYE" AS localidad,
	z01_codcli AS codigo,
	z01_nomcli AS nom_descrip,
	"" AS proposito,
	"ECU" AS pais,
	NVL(r95_punto_lleg, "") AS calle,
	g31_nombre AS ciudad,
	g25_nombre AS estado,
	NVL((SELECT r109_descripcion
		FROM acero_gm@idsgye01:rept109
		WHERE r109_compania  = 1
		  AND r109_localidad = 1
		  AND r109_cod_zona  = 3
		  AND r109_pais      = g31_pais
		  AND r109_divi_poli = g31_divi_poli
		  AND r109_ciudad    = g31_ciudad), "") AS parroquia
	FROM acero_gm@idsgye01:cxct001,
		acero_gm@idsgye01:gent031,
		acero_gm@idsgye01:gent025,
		OUTER (acero_gm@idsgye01:rept019,
		acero_gm@idsgye01:rept097,
		acero_gm@idsgye01:rept095)
	WHERE   g31_ciudad        = z01_ciudad
	  AND   g25_pais          = g31_pais
	  AND   g25_divi_poli     = g31_divi_poli
	  AND ((SELECT SUM(z20_saldo_cap + z20_saldo_int)
			FROM acero_gm@idsgye01:cxct020
			WHERE z20_compania  = 1
			  AND z20_localidad = 1
			  AND z20_codcli    = z01_codcli) > 0
	   OR  (SELECT SUM(z21_saldo)
			FROM acero_gm@idsgye01:cxct021
			WHERE z21_compania  = 1
			  AND z21_localidad = 1
			  AND z21_codcli    = z01_codcli) > 0)
	  AND   r19_compania      = 1
	  AND   r19_cod_tran      = "FA"
	  AND   r19_codcli        = z01_codcli
	  AND   r97_compania      = r19_compania
	  AND   r97_localidad     = r19_localidad
	  AND   r97_cod_tran      = r19_cod_tran
	  AND   r97_num_tran      = r19_num_tran
	  AND   r95_compania      = r97_compania
	  AND   r95_localidad     = r97_localidad
	  AND   r95_guia_remision = r97_guia_remision
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
UNION
SELECT "ACERO GYE" AS localidad,
	z01_codcli AS codigo,
	z01_nomcli AS nom_descrip,
	"" AS proposito,
	"ECU" AS pais,
	NVL(r95_punto_lleg, "") AS calle,
	g31_nombre AS ciudad,
	g25_nombre AS estado,
	NVL((SELECT r109_descripcion
		FROM acero_gm@idsgye01:rept109
		WHERE r109_compania  = 1
		  AND r109_localidad = 1
		  AND r109_cod_zona  = 3
		  AND r109_pais      = g31_pais
		  AND r109_divi_poli = g31_divi_poli
		  AND r109_ciudad    = g31_ciudad), "") AS parroquia
	FROM acero_gm@idsgye01:cxct001,
		acero_gm@idsgye01:gent031,
		acero_gm@idsgye01:gent025,
		acero_gm@idsgye01:rept019,
		OUTER (acero_gm@idsgye01:rept097,
		acero_gm@idsgye01:rept095)
	WHERE   g31_ciudad        = z01_ciudad
	  AND   g25_pais          = g31_pais
	  AND   g25_divi_poli     = g31_divi_poli
	  AND ((SELECT SUM(z20_saldo_cap + z20_saldo_int)
			FROM acero_gm@idsgye01:cxct020
			WHERE z20_compania  = 1
			  AND z20_localidad = 1
			  AND z20_codcli    = z01_codcli) +
		(SELECT SUM(z21_saldo)
			FROM acero_gm@idsgye01:cxct021
			WHERE z21_compania  = 1
			  AND z21_localidad = 1
			  AND z21_codcli    = z01_codcli)) = 0
	  AND   r19_compania      = 1
	  AND   r19_cod_tran     IN ("FA", "DF", "AF")
	  AND   r19_codcli        = z01_codcli
	  AND   DATE(r19_fecing) BETWEEN TODAY - 180 UNITS DAY AND TODAY
	  AND   r97_compania      = r19_compania
	  AND   r97_localidad     = r19_localidad
	  AND   r97_cod_tran      = r19_cod_tran
	  AND   r97_num_tran      = r19_num_tran
	  AND   r95_compania      = r97_compania
	  AND   r95_localidad     = r97_localidad
	  AND   r95_guia_remision = r97_guia_remision
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
UNION
SELECT CASE WHEN z02_localidad = 3
		THEN "ACERO UIO"
		ELSE "ACERO SUR"
	END AS localidad,
	z01_codcli AS codigo,
	z01_nomcli AS nom_descrip,
	"" AS proposito,
	"ECU" AS pais,
	NVL(r95_punto_lleg, "") AS calle,
	g31_nombre AS ciudad,
	g25_nombre AS estado,
	NVL((SELECT r109_descripcion
		FROM acero_qm:rept109
		WHERE r109_compania  = 1
		  AND r109_localidad = 3
		  AND r109_cod_zona  = 4
		  AND r109_pais      = g31_pais
		  AND r109_divi_poli = g31_divi_poli
		  AND r109_ciudad    = g31_ciudad), "") AS parroquia
	FROM acero_qm:cxct001,
		acero_qm:gent031,
		acero_qm:cxct002,
		acero_qm:gent025,
		OUTER (acero_qm:rept019,
		acero_qm:rept097,
		acero_qm:rept095)
	WHERE   g31_ciudad        = z01_ciudad
	  AND   z02_compania      = 1
	  AND   z02_localidad    IN (3, 4)
	  AND   z02_codcli        = z01_codcli
	  AND   g25_pais          = g31_pais
	  AND   g25_divi_poli     = g31_divi_poli
	  AND ((SELECT SUM(z20_saldo_cap + z20_saldo_int)
			FROM acero_qm:cxct020
			WHERE z20_compania  = z02_compania
			  AND z20_localidad = z02_localidad
			  AND z20_codcli    = z02_codcli) > 0
	   OR  (SELECT SUM(z21_saldo)
			FROM acero_qm:cxct021
			WHERE z21_compania  = z02_compania
			  AND z21_localidad = z02_localidad
			  AND z21_codcli    = z02_codcli) > 0)
	  AND   r19_compania      = z02_compania
	  AND   r19_localidad     = z02_localidad
	  AND   r19_cod_tran      = "FA"
	  AND   r19_codcli        = z02_codcli
	  AND   r97_compania      = r19_compania
	  AND   r97_localidad     = r19_localidad
	  AND   r97_cod_tran      = r19_cod_tran
	  AND   r97_num_tran      = r19_num_tran
	  AND   r95_compania      = r97_compania
	  AND   r95_localidad     = r97_localidad
	  AND   r95_guia_remision = r97_guia_remision
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
UNION
SELECT CASE WHEN z02_localidad = 3
		THEN "ACERO UIO"
		ELSE "ACERO SUR"
	END AS localidad,
	z01_codcli AS codigo,
	z01_nomcli AS nom_descrip,
	"" AS proposito,
	"ECU" AS pais,
	NVL(r95_punto_lleg, "") AS calle,
	g31_nombre AS ciudad,
	g25_nombre AS estado,
	NVL((SELECT r109_descripcion
		FROM acero_qm:rept109
		WHERE r109_compania  = 1
		  AND r109_localidad = 3
		  AND r109_cod_zona  = 4
		  AND r109_pais      = g31_pais
		  AND r109_divi_poli = g31_divi_poli
		  AND r109_ciudad    = g31_ciudad), "") AS parroquia
	FROM acero_qm:cxct001,
		acero_qm:gent031,
		acero_qm:cxct002,
		acero_qm:gent025,
		acero_qm:rept019,
		OUTER (acero_qm:rept097,
		acero_qm:rept095)
	WHERE   g31_ciudad        = z01_ciudad
	  AND   z02_compania      = 1
	  AND   z02_localidad    IN (3, 4)
	  AND   z02_codcli        = z01_codcli
	  AND   g25_pais          = g31_pais
	  AND   g25_divi_poli     = g31_divi_poli
	  AND ((SELECT SUM(z20_saldo_cap + z20_saldo_int)
			FROM acero_qm:cxct020
			WHERE z20_compania  = z02_compania
			  AND z20_localidad = z02_localidad
			  AND z20_codcli    = z02_codcli) +
		(SELECT SUM(z21_saldo)
			FROM acero_qm:cxct021
			WHERE z21_compania  = z02_compania
			  AND z21_localidad = z02_localidad
			  AND z21_codcli    = z02_codcli)) = 0
	  AND   r19_compania      = z02_compania
	  AND   r19_localidad     = z02_localidad
	  AND   r19_cod_tran     IN ("FA", "DF", "AF")
	  AND   r19_codcli        = z02_codcli
	  AND   DATE(r19_fecing) BETWEEN TODAY - 180 UNITS DAY AND TODAY
	  AND   r97_compania      = r19_compania
	  AND   r97_localidad     = r19_localidad
	  AND   r97_cod_tran      = r19_cod_tran
	  AND   r97_num_tran      = r19_num_tran
	  AND   r95_compania      = r97_compania
	  AND   r95_localidad     = r97_localidad
	  AND   r95_guia_remision = r97_guia_remision
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
UNION
SELECT CASE WHEN z02_localidad = 3
		THEN "ACERO UIO"
		ELSE "ACERO SUR"
	END AS localidad,
	z01_codcli AS codigo,
	z01_nomcli AS nom_descrip,
	"" AS proposito,
	"ECU" AS pais,
	NVL(r95_punto_lleg, "") AS calle,
	g31_nombre AS ciudad,
	g25_nombre AS estado,
	"" AS parroquia
	FROM acero_qm:cxct001,
		acero_qm:gent031,
		acero_qm:cxct002,
		acero_qm:gent025,
		acero_qs:rept019,
		OUTER (acero_qs:rept097,
		acero_qs:rept095)
	WHERE   g31_ciudad        = z01_ciudad
	  AND   z02_compania      = 1
	  AND   z02_localidad     = 4
	  AND   z02_codcli        = z01_codcli
	  AND   g25_pais          = g31_pais
	  AND   g25_divi_poli     = g31_divi_poli
	  AND ((SELECT SUM(z20_saldo_cap + z20_saldo_int)
			FROM acero_qm:cxct020
			WHERE z20_compania  = z02_compania
			  AND z20_localidad = z02_localidad
			  AND z20_codcli    = z02_codcli) +
		(SELECT SUM(z21_saldo)
			FROM acero_qm:cxct021
			WHERE z21_compania  = z02_compania
			  AND z21_localidad = z02_localidad
			  AND z21_codcli    = z02_codcli)) = 0
	  AND   r19_compania      = z02_compania
	  AND   r19_localidad     = z02_localidad
	  AND   r19_cod_tran     IN ("FA", "DF", "AF")
	  AND   r19_codcli        = z02_codcli
	  AND   DATE(r19_fecing) BETWEEN TODAY - 180 UNITS DAY AND TODAY
	  AND   r97_compania      = r19_compania
	  AND   r97_localidad     = r19_localidad
	  AND   r97_cod_tran      = r19_cod_tran
	  AND   r97_num_tran      = r19_num_tran
	  AND   r95_compania      = r97_compania
	  AND   r95_localidad     = r97_localidad
	  AND   r95_guia_remision = r97_guia_remision
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9;
