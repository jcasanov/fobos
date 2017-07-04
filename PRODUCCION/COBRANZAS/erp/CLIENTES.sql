SELECT "ACERO GYE" AS loc,
	z01_codcli AS codigo,
	CASE WHEN z01_personeria = "N"
		THEN "PERSONA"
		ELSE "ORGANIZACION"
	END AS tipo_reg,
	z01_nomcli AS cliente,
	z01_nomcli AS nom_busq,
	"01" AS conjunto,
	"" AS seccion,
	z01_nomcli AS nom_descrip,
	z01_direccion1 || " " || TRIM(z01_direccion2) AS proposito,
	"ECU" AS pais,
	z01_direccion1 AS calle,
	g31_nombre AS ciudad,
	"" AS estado,
	"" AS canton,
	"" AS parroquia,
	z01_telefono1 AS telefono,
	z01_telefono1 AS extension,
	z01_telefono2 AS celular,
	"" AS correo,
	"" AS segmento,
	g32_nombre AS zona_vta,
	g32_nombre AS empl_resp,
	z02_contacto AS contacto,
	"USD" AS moneda,
	1 AS lim_cred,
	z02_cupocred_mb AS limite_cred,
	z01_tipo_doc_id	AS tipo_ident,
	z01_num_doc_id AS num_ident,
	z01_nomcli AS razon_social,
	CASE WHEN z01_personeria = "J"
		THEN 1
		ELSE 0
	END AS llev_cont,
	z02_credit_dias	AS condic_pago,
	"" AS for_pago,
	"" AS grupo_impto,
	z01_personeria AS clase_suj,
	"" AS sexo,
	"" AS est_civil,
	"" AS origen_ing
	FROM cxct001,
		gent031,
		cxct002,
		gent032
	WHERE   g31_ciudad     = z01_ciudad
	  AND   z02_compania   = 1
	  AND   z02_localidad  = 1
	  AND   z02_codcli     = z01_codcli
	  AND   g32_compania   = z02_compania
	  AND   g32_zona_venta = z02_zona_venta
	  AND ((SELECT SUM(z20_saldo_cap + z20_saldo_int)
			FROM cxct020
			WHERE z20_compania  = z02_compania
			  AND z20_localidad = z02_localidad
			  AND z20_codcli    = z02_codcli) > 0
	   OR  (SELECT SUM(z21_saldo)
			FROM cxct021
			WHERE z21_compania  = z02_compania
			  AND z21_localidad = z02_localidad
			  AND z21_codcli    = z02_codcli) > 0)
UNION
SELECT "ACERO GYE" AS loc,
	z01_codcli AS codigo,
	CASE WHEN z01_personeria = "N"
		THEN "PERSONA"
		ELSE "ORGANIZACION"
	END AS tipo_reg,
	z01_nomcli AS cliente,
	z01_nomcli AS nom_busq,
	"01" AS conjunto,
	"" AS seccion,
	z01_nomcli AS nom_descrip,
	z01_direccion1 || " " || TRIM(z01_direccion2) AS proposito,
	"ECU" AS pais,
	z01_direccion1 AS calle,
	g31_nombre AS ciudad,
	"" AS estado,
	"" AS canton,
	"" AS parroquia,
	z01_telefono1 AS telefono,
	z01_telefono1 AS extension,
	z01_telefono2 AS celular,
	"" AS correo,
	"" AS segmento,
	g32_nombre AS zona_vta,
	g32_nombre AS empl_resp,
	z02_contacto AS contacto,
	"USD" AS moneda,
	1 AS lim_cred,
	z02_cupocred_mb AS limite_cred,
	z01_tipo_doc_id	AS tipo_ident,
	z01_num_doc_id AS num_ident,
	z01_nomcli AS razon_social,
	CASE WHEN z01_personeria = "J"
		THEN 1
		ELSE 0
	END AS llev_cont,
	z02_credit_dias	AS condic_pago,
	"" AS for_pago,
	"" AS grupo_impto,
	z01_personeria AS clase_suj,
	"" AS sexo,
	"" AS est_civil,
	"" AS origen_ing
	FROM cxct001,
		gent031,
		cxct002,
		gent032
	WHERE   g31_ciudad     = z01_ciudad
	  AND   z02_compania   = 1
	  AND   z02_localidad  = 1
	  AND   z02_codcli     = z01_codcli
	  AND   g32_compania   = z02_compania
	  AND   g32_zona_venta = z02_zona_venta
	  AND ((SELECT SUM(z20_saldo_cap + z20_saldo_int)
			FROM cxct020
			WHERE z20_compania  = z02_compania
			  AND z20_localidad = z02_localidad
			  AND z20_codcli    = z02_codcli) +
		(SELECT SUM(z21_saldo)
			FROM cxct021
			WHERE z21_compania  = z02_compania
			  AND z21_localidad = z02_localidad
			  AND z21_codcli    = z02_codcli)) = 0
	  AND  (EXISTS
		(SELECT 1 FROM rept019
			WHERE r19_compania      = z02_compania
			  AND r19_localidad     = z02_localidad
			  AND r19_cod_tran     IN ("FA", "DF", "AF")
			  AND r19_codcli        = z02_codcli
			  AND DATE(r19_fecing) BETWEEN TODAY - 180 UNITS DAY
						   AND TODAY)
	   OR   EXISTS
		(SELECT 1 FROM talt023
			WHERE  t23_compania      = z02_compania
			  AND  t23_localidad     = z02_localidad
			  AND  t23_estado       IN ("C", "F", "D")
			  AND  t23_cod_cliente   = z02_codcli
			  AND (DATE(t23_fec_factura)
					BETWEEN TODAY - 180 UNITS DAY
					    AND TODAY
			   OR  DATE(t23_fec_cierre)
					BETWEEN TODAY - 180 UNITS DAY
					    AND TODAY)))
UNION
SELECT CASE WHEN z02_localidad = 3
		THEN "ACERO UIO"
		ELSE "ACERO SUR"
	END AS loc,
	z01_codcli AS codigo,
	CASE WHEN z01_personeria = "N"
		THEN "PERSONA"
		ELSE "ORGANIZACION"
	END AS tipo_reg,
	z01_nomcli AS cliente,
	z01_nomcli AS nom_busq,
	"01" AS conjunto,
	"" AS seccion,
	z01_nomcli AS nom_descrip,
	z01_direccion1 || " " || TRIM(z01_direccion2) AS proposito,
	"ECU" AS pais,
	z01_direccion1 AS calle,
	g31_nombre AS ciudad,
	"" AS estado,
	"" AS canton,
	"" AS parroquia,
	z01_telefono1 AS telefono,
	z01_telefono1 AS extension,
	z01_telefono2 AS celular,
	"" AS correo,
	"" AS segmento,
	g32_nombre AS zona_vta,
	g32_nombre AS empl_resp,
	z02_contacto AS contacto,
	"USD" AS moneda,
	1 AS lim_cred,
	z02_cupocred_mb AS limite_cred,
	z01_tipo_doc_id	AS tipo_ident,
	z01_num_doc_id AS num_ident,
	z01_nomcli AS razon_social,
	CASE WHEN z01_personeria = "J"
		THEN 1
		ELSE 0
	END AS llev_cont,
	z02_credit_dias	AS condic_pago,
	"" AS for_pago,
	"" AS grupo_impto,
	z01_personeria AS clase_suj,
	"" AS sexo,
	"" AS est_civil,
	"" AS origen_ing
	FROM acero_qm:cxct001,
		acero_qm:gent031,
		acero_qm:cxct002,
		acero_qm:gent032
	WHERE   g31_ciudad      = z01_ciudad
	  AND   z02_compania    = 1
	  AND   z02_localidad  IN (3, 4)
	  AND   z02_codcli      = z01_codcli
	  AND   g32_compania    = z02_compania
	  AND   g32_zona_venta  = z02_zona_venta
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
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18,
		19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34,
		35, 36, 37
UNION
SELECT CASE WHEN z02_localidad = 3
		THEN "ACERO UIO"
		ELSE "ACERO SUR"
	END AS loc,
	z01_codcli AS codigo,
	CASE WHEN z01_personeria = "N"
		THEN "PERSONA"
		ELSE "ORGANIZACION"
	END AS tipo_reg,
	z01_nomcli AS cliente,
	z01_nomcli AS nom_busq,
	"01" AS conjunto,
	"" AS seccion,
	z01_nomcli AS nom_descrip,
	z01_direccion1 || " " || TRIM(z01_direccion2) AS proposito,
	"ECU" AS pais,
	z01_direccion1 AS calle,
	g31_nombre AS ciudad,
	"" AS estado,
	"" AS canton,
	"" AS parroquia,
	z01_telefono1 AS telefono,
	z01_telefono1 AS extension,
	z01_telefono2 AS celular,
	"" AS correo,
	"" AS segmento,
	g32_nombre AS zona_vta,
	g32_nombre AS empl_resp,
	z02_contacto AS contacto,
	"USD" AS moneda,
	1 AS lim_cred,
	z02_cupocred_mb AS limite_cred,
	z01_tipo_doc_id	AS tipo_ident,
	z01_num_doc_id AS num_ident,
	z01_nomcli AS razon_social,
	CASE WHEN z01_personeria = "J"
		THEN 1
		ELSE 0
	END AS llev_cont,
	z02_credit_dias	AS condic_pago,
	"" AS for_pago,
	"" AS grupo_impto,
	z01_personeria AS clase_suj,
	"" AS sexo,
	"" AS est_civil,
	"" AS origen_ing
	FROM acero_qm:cxct001,
		acero_qm:gent031,
		acero_qm:cxct002,
		acero_qm:gent032
	WHERE   g31_ciudad      = z01_ciudad
	  AND   z02_compania    = 1
	  AND   z02_localidad  IN (3, 4)
	  AND   z02_codcli      = z01_codcli
	  AND   g32_compania    = z02_compania
	  AND   g32_zona_venta  = z02_zona_venta
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
	  AND  (EXISTS
		(SELECT 1 FROM acero_qm:rept019
			WHERE r19_compania      = z02_compania
			  AND r19_localidad     = 3
			  AND r19_cod_tran     IN ("FA", "DF", "AF")
			  AND r19_codcli        = z02_codcli
			  AND DATE(r19_fecing) BETWEEN TODAY - 180 UNITS DAY
						   AND TODAY)
	   OR   EXISTS
		(SELECT 1 FROM acero_qm:talt023
			WHERE  t23_compania      = z02_compania
			  AND  t23_localidad     = 3
			  AND  t23_estado       IN ("C", "F", "D")
			  AND  t23_cod_cliente   = z02_codcli
			  AND (DATE(t23_fec_factura)
					BETWEEN TODAY - 180 UNITS DAY
					    AND TODAY
			   OR  DATE(t23_fec_cierre)
					BETWEEN TODAY - 180 UNITS DAY
					    AND TODAY))
	   OR   EXISTS
		(SELECT 1 FROM acero_qs:rept019
			WHERE r19_compania      = z02_compania
			  AND r19_localidad     = 4
			  AND r19_cod_tran     IN ("FA", "DF", "AF")
			  AND r19_codcli        = z02_codcli
			  AND DATE(r19_fecing) BETWEEN TODAY - 180 UNITS DAY
						   AND TODAY))
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18,
		19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34,
		35, 36, 37;
