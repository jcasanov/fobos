SELECT DATE(r19_fecing) AS fecha_emi,
	CASE WHEN r19_cod_tran = "FA"
		THEN "FACTURA"
		ELSE "NOTA DE CREDITO"
	END AS tipo_comp,
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
		  AND g37_secuencia    = g39_secuencia) AS autorizacion,
	(SELECT TRIM(r38_num_sri[1, 7])
		FROM rept038
		WHERE r38_compania    = r19_compania
		  AND r38_localidad   = r19_localidad
		  AND r38_tipo_fuente = 'PR'
		  AND r38_cod_tran    = r19_cod_tran
		  AND r38_num_tran    = r19_num_tran) AS serie,
	(SELECT CAST(TRIM(r38_num_sri[9, 21]) AS INTEGER)
		FROM rept038
		WHERE r38_compania    = r19_compania
		  AND r38_localidad   = r19_localidad
		  AND r38_tipo_fuente = 'PR'
		  AND r38_cod_tran    = r19_cod_tran
		  AND r38_num_tran    = r19_num_tran) AS num_sri,
	"1790008959001" AS ruc_prov,
	"ACERO COMERCIAL ECUATORIANO S.A." AS razon_soc,
	r20_item AS item,
	TRIM(r72_desc_clase) || " " || TRIM(r10_nombre) AS desrcipcion,
	r10_marca AS marca,
	CASE WHEN r19_cod_tran = "FA"
		THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
		ELSE ((r20_cant_ven * r20_precio) - r20_val_descto) * (-1)
	END AS subtotal,
	CASE WHEN r19_cod_tran = "FA"
		THEN r20_val_impto
		ELSE r20_val_impto * (-1)
	END AS iva,
	CASE WHEN r19_cod_tran = "FA"
		THEN (((r20_cant_ven * r20_precio) - r20_val_descto)
			+ r20_val_impto)
		ELSE (((r20_cant_ven * r20_precio) - r20_val_descto)
			+ r20_val_impto) * (-1)
	END AS total
	FROM rept019, rept020, rept010, rept072
	WHERE  r19_compania     = 1
	  AND  r19_localidad    = 1
	  AND  r19_cod_tran     = "FA"
	  AND (r19_tipo_dev     IS NULL
	   OR  r19_tipo_dev     = "DF")
	  AND  r19_codcli       = 4255
	  AND  YEAR(r19_fecing) = 2007
	  AND  r20_compania     = r19_compania
	  AND  r20_localidad    = r19_localidad
	  AND  r20_cod_tran     = r19_cod_tran
	  AND  r20_num_tran     = r19_num_tran
	  AND  r10_compania     = r20_compania
	  AND  r10_codigo       = r20_item
	  AND  r72_compania     = r10_compania
	  AND  r72_linea        = r10_linea
	  AND  r72_sub_linea    = r10_sub_linea
	  AND  r72_cod_grupo    = r10_cod_grupo
	  AND  r72_cod_clase    = r10_cod_clase
UNION
SELECT DATE(r19_fecing) AS fecha_emi,
	CASE WHEN r19_cod_tran = "FA"
		THEN "FACTURA"
		ELSE "NOTA DE CREDITO"
	END AS tipo_comp,
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
		  AND g37_tipo_doc     = g39_tipo_doc
		  AND g37_secuencia    = g39_secuencia) AS autorizacion,
	(SELECT TRIM(z21_num_sri[1, 7])
		FROM cxct021
		WHERE z21_compania    = r19_compania
		  AND z21_localidad   = r19_localidad
		  AND z21_codcli      = r19_codcli
		  AND z21_areaneg     = 1
		  AND z21_cod_tran    = r19_cod_tran
		  AND z21_num_tran    = r19_num_tran) AS serie,
	(SELECT CAST(TRIM(z21_num_sri[9, 21]) AS INTEGER)
		FROM cxct021
		WHERE z21_compania    = r19_compania
		  AND z21_localidad   = r19_localidad
		  AND z21_codcli      = r19_codcli
		  AND z21_areaneg     = 1
		  AND z21_cod_tran    = r19_cod_tran
		  AND z21_num_tran    = r19_num_tran) AS num_sri,
	"1790008959001" AS ruc_prov,
	"ACERO COMERCIAL ECUATORIANO S.A." AS razon_soc,
	r20_item AS item,
	TRIM(r72_desc_clase) || " " || TRIM(r10_nombre) AS desrcipcion,
	r10_marca AS marca,
	CASE WHEN r19_cod_tran = "FA"
		THEN ((r20_cant_ven * r20_precio) - r20_val_descto)
		ELSE ((r20_cant_ven * r20_precio) - r20_val_descto) * (-1)
	END AS subtotal,
	CASE WHEN r19_cod_tran = "FA"
		THEN r20_val_impto
		ELSE r20_val_impto * (-1)
	END AS iva,
	CASE WHEN r19_cod_tran = "FA"
		THEN (((r20_cant_ven * r20_precio) - r20_val_descto)
			+ r20_val_impto)
		ELSE (((r20_cant_ven * r20_precio) - r20_val_descto)
			+ r20_val_impto) * (-1)
	END AS total
	FROM rept019, rept020, rept010, rept072
	WHERE  r19_compania     = 1
	  AND  r19_localidad    = 1
	  AND  r19_cod_tran     = "DF"
	  AND  r19_codcli       = 4255
	  AND  YEAR(r19_fecing) = 2007
	  AND  r20_compania     = r19_compania
	  AND  r20_localidad    = r19_localidad
	  AND  r20_cod_tran     = r19_cod_tran
	  AND  r20_num_tran     = r19_num_tran
	  AND  r10_compania     = r20_compania
	  AND  r10_codigo       = r20_item
	  AND  r72_compania     = r10_compania
	  AND  r72_linea        = r10_linea
	  AND  r72_sub_linea    = r10_sub_linea
	  AND  r72_cod_grupo    = r10_cod_grupo
	  AND  r72_cod_clase    = r10_cod_clase
	ORDER BY 1 ASC, 5 ASC;
