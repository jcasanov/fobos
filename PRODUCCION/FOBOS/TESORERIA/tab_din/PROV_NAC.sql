SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_gm@idsgye01:gent002
		WHERE g02_compania  = p02_compania
		  AND g02_localidad = p02_localidad) AS localidad,
	p01_codprov AS codigo,
	p01_nomprov AS proveedor,
	CASE WHEN p01_tipo_doc = "C" THEN "CEDULA"
	     WHEN p01_tipo_doc = "R" THEN "RUC"
	     WHEN p01_tipo_doc = "P" THEN "PASAPORTE"
	END AS tip_doc,
	p01_num_doc AS cedruc,
	p01_direccion1 AS direccion,
	p01_telefono1 AS telefono,
	p02_cod_bco_tra AS cod_bco,
	(SELECT g08_nombre
		FROM acero_gm@idsgye01:gent008
		WHERE g08_banco = p02_banco_prov) AS banco,
	CASE WHEN p02_tip_cta_prov = "A" THEN "AHORRO"
	     WHEN p02_tip_cta_prov = "C" THEN "CREDITO"
	END AS tip_cta,
	p02_cta_prov AS cta_prov,
	p02_contacto AS contacto,
	p02_email AS correo,
	p02_referencia AS referencia
	FROM acero_gm@idsgye01:cxpt001, acero_gm@idsgye01:cxpt002
	WHERE p01_estado    = "A"
	  AND p02_compania  = 1
	  AND p02_localidad < 3
	  AND p02_codprov   = p01_codprov
UNION
SELECT (SELECT LPAD(g02_localidad, 2, 0) || " " || TRIM(g02_abreviacion)
		FROM acero_qm@idsuio01:gent002
		WHERE g02_compania  = p02_compania
		  AND g02_localidad = p02_localidad) AS localidad,
	p01_codprov AS codigo,
	p01_nomprov AS proveedor,
	CASE WHEN p01_tipo_doc = "C" THEN "CEDULA"
	     WHEN p01_tipo_doc = "R" THEN "RUC"
	     WHEN p01_tipo_doc = "P" THEN "PASAPORTE"
	END AS tip_doc,
	p01_num_doc AS cedruc,
	p01_direccion1 AS direccion,
	p01_telefono1 AS telefono,
	p02_cod_bco_tra AS cod_bco,
	(SELECT g08_nombre
		FROM acero_qm@idsuio01:gent008
		WHERE g08_banco = p02_banco_prov) AS banco,
	CASE WHEN p02_tip_cta_prov = "A" THEN "AHORRO"
	     WHEN p02_tip_cta_prov = "C" THEN "CREDITO"
	END AS tip_cta,
	p02_cta_prov AS cta_prov,
	p02_contacto AS contacto,
	p02_email AS correo,
	p02_referencia AS referencia
	FROM acero_qm@idsuio01:cxpt001, acero_qm@idsuio01:cxpt002
	WHERE p01_estado    = "A"
	  AND p02_compania  = 1
	  AND p02_localidad > 2
	  AND p02_codprov   = p01_codprov
	ORDER BY 1 ASC, 3 ASC;
