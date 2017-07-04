SELECT DATE(r19_fecing) AS fecha_emi,
	"SANITARIOS Y COMPLEMENTOS" AS descripcion,
	r19_nomcli AS razon_social,
	r19_cedruc AS ruc,
	LPAD(CASE WHEN r19_cod_tran = "FA"
		THEN 18
		ELSE 4
	END, 2, 0) AS tipo_comp,
	(SELECT r38_num_sri
		FROM rept038
		WHERE r38_compania    = r19_compania
		  AND r38_localidad   = r19_localidad
		  AND r38_tipo_fuente = 'PR'
		  AND r38_cod_tran    = r19_cod_tran
		  AND r38_num_tran    = r19_num_tran) AS num_sri,
	(SELECT g37_autorizacion
		FROM rept038, gent039, gent037
		WHERE r38_compania     = r19_compania
		  AND r38_localidad    = r19_localidad
		  AND r38_tipo_fuente  = 'PR'
		  AND r38_cod_tran     = r19_cod_tran
		  AND r38_num_tran     = r19_num_tran
		  AND g39_compania     = r38_compania
		  AND g39_localidad    = r38_localidad
		  AND g39_tipo_doc     = r38_tipo_doc
		  AND g39_num_sri_ini <= ROUND(r38_num_sri[9, 21] + 0, 0)
		  AND g39_num_sri_fin >= ROUND(r38_num_sri[9, 21] + 0, 0)
		  AND g37_compania     = g39_compania
		  AND g37_localidad    = g39_localidad
		  and g37_tipo_doc     = g39_tipo_doc
		  AND g37_secuencia    = g39_secuencia) AS autorizacion_sri,
	CASE WHEN r19_cod_tran = "FA"
		THEN (r19_tot_bruto - r19_tot_dscto)
		ELSE (r19_tot_bruto - r19_tot_dscto) * (-1)
	END AS subtotal,
	CASE WHEN r19_cod_tran = "FA"
		THEN (r19_tot_neto - r19_tot_bruto + r19_tot_dscto - r19_flete)
		ELSE (r19_tot_neto - r19_tot_bruto + r19_tot_dscto
			- r19_flete) * (-1)
	END AS iva,
	CASE WHEN r19_cod_tran = "FA"
		THEN r19_tot_neto
		ELSE r19_tot_neto * (-1)
	END AS total
	FROM rept019
	WHERE  r19_compania     = 1
	  AND  r19_localidad    = 1
	  AND  r19_cod_tran     = "FA"
	  AND (r19_tipo_dev     IS NULL
	   OR  r19_tipo_dev     = "DF")
	  AND  r19_codcli       = 10595
	  AND  YEAR(r19_fecing) = 2010
UNION
SELECT DATE(r19_fecing) AS fecha_emi,
	"SANITARIOS Y COMPLEMENTOS" AS descripcion,
	r19_nomcli AS razon_social,
	r19_cedruc AS ruc,
	LPAD(CASE WHEN r19_cod_tran = "FA"
		THEN 18
		ELSE 4
	END, 2, 0) AS tipo_comp,
	(SELECT z21_num_sri
		FROM cxct021
		WHERE z21_compania    = r19_compania
		  AND z21_localidad   = r19_localidad
		  AND z21_codcli      = r19_codcli
		  AND z21_areaneg     = 1
		  AND z21_cod_tran    = r19_cod_tran
		  AND z21_num_tran    = r19_num_tran) AS num_sri,
	(SELECT g37_autorizacion
		FROM cxct021, gent039, gent037
		WHERE z21_compania     = r19_compania
		  AND z21_localidad    = r19_localidad
		  AND z21_areaneg     = 1
		  AND z21_codcli      = r19_codcli
		  AND z21_cod_tran     = r19_cod_tran
		  AND z21_num_tran     = r19_num_tran
		  AND g39_compania     = z21_compania
		  AND g39_localidad    = z21_localidad
		  AND g39_tipo_doc     = z21_tipo_doc
		  AND g39_num_sri_ini <= ROUND(z21_num_sri[9, 21] + 0, 0)
		  AND g39_num_sri_fin >= ROUND(z21_num_sri[9, 21] + 0, 0)
		  AND g37_compania     = g39_compania
		  AND g37_localidad    = g39_localidad
		  and g37_tipo_doc     = g39_tipo_doc
		  AND g37_secuencia    = g39_secuencia) AS autorizacion_sri,
	CASE WHEN r19_cod_tran = "FA"
		THEN (r19_tot_bruto - r19_tot_dscto)
		ELSE (r19_tot_bruto - r19_tot_dscto) * (-1)
	END AS subtotal,
	CASE WHEN r19_cod_tran = "FA"
		THEN (r19_tot_neto - r19_tot_bruto + r19_tot_dscto - r19_flete)
		ELSE (r19_tot_neto - r19_tot_bruto + r19_tot_dscto
			- r19_flete) * (-1)
	END AS iva,
	CASE WHEN r19_cod_tran = "FA"
		THEN r19_tot_neto
		ELSE r19_tot_neto * (-1)
	END AS total
	FROM rept019
	WHERE  r19_compania     = 1
	  AND  r19_localidad    = 1
	  AND  r19_cod_tran     = "DF"
	  AND  r19_codcli       = 10595
	  AND  YEAR(r19_fecing) = 2010
	ORDER BY 1;
