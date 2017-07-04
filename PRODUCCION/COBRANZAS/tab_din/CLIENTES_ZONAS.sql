SELECT z01_codcli AS cod_c,
	z01_num_doc_id AS cedrc,
	z01_nomcli AS nom_c,
	NVL((SELECT z06_nombre
		FROM cxct002, cxct006
		WHERE z02_compania   = r19_compania
		  AND z02_localidad  = r19_localidad
		  AND z02_codcli     = r19_codcli
		  AND z06_zona_cobro = z02_zona_cobro),
	"SIN COBRADOR") AS zon_cob,
	NVL((SELECT g32_nombre
		FROM cxct002, gent032
		WHERE z02_compania   = r19_compania
		  AND z02_localidad  = r19_localidad
		  AND z02_codcli     = r19_codcli
		  AND g32_compania   = z02_compania
		  AND g32_zona_venta = z02_zona_venta),
	"SIN ZONA VENTA") AS zon_vta,
	CASE WHEN z01_estado = "A"
		THEN "ACTIVO"
		ELSE "BLOQUEADO"
	END AS estado,
	r01_nombres AS vendedor
	FROM rept019, rept001, cxct001
	WHERE r19_compania  = 1
	  AND r19_localidad = 1
	  AND r19_cod_tran  = "FA"
	  AND r19_cont_cred = "R"
	  AND r01_compania  = r19_compania
	  AND r01_codigo    = r19_vendedor
	  AND z01_codcli    = r19_codcli
	GROUP BY 1, 2, 3, 4, 5, 6, 7;
