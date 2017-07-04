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
	END AS total,
	NVL(TRIM(j01_nombre) || CASE WHEN j11_codigo_pago <> "EF" THEN
		" No. " || TRIM(j11_num_ch_aut) || " Cta. "
		|| TRIM(j11_num_cta_tarj) || " " || TRIM(g08_nombre)
		ELSE "" END,
		"NO PAGADA") AS for_pago,
	"NO CORRESPONDE A CONSTRUCTORA PEYASA S.A." AS observacion
	FROM rept019, OUTER(cxct023, cajt010, cajt011, cajt001, OUTER(gent008))
	WHERE  r19_compania     = 1
	  AND  r19_localidad    = 1
	  AND  r19_cod_tran     = "FA"
	  AND  r19_cont_cred    = "R"
	  AND (r19_tipo_dev     IS NULL
	   OR  r19_tipo_dev     = "DF")
	  AND  r19_num_tran     IN
		(SELECT r38_num_tran FROM rept038
			WHERE r38_compania       = r19_compania
			  AND r38_localidad      = r19_localidad
			  AND r38_num_sri[9, 21] IN (38232, 38235, 38238,
							38239, 38241, 38244,
							38247))
	  AND  z23_compania     = r19_compania
	  AND  z23_localidad    = r19_localidad
	  AND  z23_codcli       = r19_codcli
	  AND  z23_tipo_doc     = r19_cod_tran
	  AND  z23_num_doc      = r19_num_tran
	  AND  j10_compania     = z23_compania
	  AND  j10_localidad    = z23_localidad
	  AND  j10_tipo_destino = z23_tipo_trn
	  AND  j10_num_destino  = z23_num_trn
	  AND  j11_compania     = j10_compania
	  AND  j11_localidad    = j10_localidad
	  AND  j11_tipo_fuente  = j10_tipo_fuente
	  AND  j11_num_fuente   = j10_num_fuente
	  AND  j11_codigo_pago <> "RT"
	  AND  j01_compania     = j11_compania
	  AND  j01_codigo_pago  = j11_codigo_pago
	  AND  j01_cont_cred    = r19_cont_cred
	  AND  g08_banco        = j11_cod_bco_tarj
UNION
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
	END AS total,
	NVL(TRIM(j01_nombre) || CASE WHEN j11_codigo_pago <> "EF" THEN
		" No. " || TRIM(j11_num_ch_aut) || " Cta. "
		|| TRIM(j11_num_cta_tarj) || " " || TRIM(g08_nombre)
		ELSE "" END,
		"NO PAGADA") AS for_pago,
	"NO CORRESPONDE A CONSTRUCTORA PEYASA S.A." AS observacion
	FROM rept019, OUTER(cajt010, cajt011, cajt001, OUTER(gent008))
	WHERE  r19_compania     = 1
	  AND  r19_localidad    = 1
	  AND  r19_cod_tran     = "FA"
	  AND  r19_cont_cred    = "C"
	  AND (r19_tipo_dev     IS NULL
	   OR  r19_tipo_dev     = "DF")
	  AND  r19_num_tran     IN
		(SELECT r38_num_tran FROM rept038
			WHERE r38_compania       = r19_compania
			  AND r38_localidad      = r19_localidad
			  AND r38_num_sri[9, 21] IN (38232, 38235, 38238,
							38239, 38241, 38244,
							38247))
	  AND  j10_compania     = r19_compania
	  AND  j10_localidad    = r19_localidad
	  AND  j10_tipo_fuente  = "PR"
	  AND  j10_tipo_destino = r19_cod_tran
	  AND  j10_num_destino  = r19_num_tran
	  AND  j11_compania     = j10_compania
	  AND  j11_localidad    = j10_localidad
	  AND  j11_tipo_fuente  = j10_tipo_fuente
	  AND  j11_num_fuente   = j10_num_fuente
	  AND  j11_codigo_pago <> "RT"
	  AND  j01_compania     = j11_compania
	  AND  j01_codigo_pago  = j11_codigo_pago
	  AND  j01_cont_cred    = r19_cont_cred
	  AND  g08_banco        = j11_cod_bco_tarj
	ORDER BY 1 ASC, 5 ASC;
