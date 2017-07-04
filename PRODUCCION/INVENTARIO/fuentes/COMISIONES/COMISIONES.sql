SELECT r19_localidad AS LOC,
	(SELECT r73_desc_marca
		FROM rept073
		WHERE r73_compania = r10_compania
		  AND r73_marca    = r10_marca) AS MARCA,
	r10_filtro AS FILTRO,
	(SELECT r01_iniciales
		FROM rept001
		WHERE r01_compania = r19_compania
		  AND r01_codigo   = r19_vendedor) AS VENDEDOR,
	r19_cod_tran AS codtran,
	r19_num_tran AS numtran,
	NVL(r19_codcli, 99) AS codcli,
	r19_nomcli AS cliente,  
	DATE(r20_fecing) AS fecha_fact,
	CASE WHEN r19_cont_cred = "C" THEN "CONTADO"
	     WHEN r19_cont_cred = "R" THEN "CREDITO"
	     ELSE ""
	END AS formapago,
	NVL((SELECT MAX(z20_fecha_vcto)
		FROM cxct020
		WHERE z20_compania  = r19_compania
		  AND z20_localidad = r19_localidad
		  AND z20_cod_tran  = r19_cod_tran
		  AND z20_num_tran  = r19_num_tran
		  AND z20_codcli    = r19_codcli
		  AND z20_areaneg   = 1), DATE(r20_fecing)) AS fecha_vcto,
	r10_cod_clase AS clase,
	(SELECT r72_desc_clase
		FROM rept072
		WHERE r72_compania  = r10_compania
		  AND r72_linea     = r10_linea
		  AND r72_sub_linea = r10_sub_linea
		  AND r72_cod_grupo = r10_cod_grupo
		  AND r72_cod_clase = r10_cod_clase) AS nombre_clase,
	r20_item AS ITEMS,
	r10_nombre AS descripcion,
	CASE WHEN r19_cod_tran = 'FA'
		THEN NVL(r20_cant_ven, 0)
		ELSE NVL(r20_cant_ven, 0) * (-1)
        END AS can_vta,
	r20_precio AS PRECIO,
	r20_descuento AS por_dscto,
	CASE WHEN r19_cont_cred = 'R' THEN
		(SELECT MAX(DATE(z22_fecing))
		FROM cxct020, cxct022, cxct023
		WHERE z20_compania  = r19_compania
		  AND z20_localidad = r19_localidad
		  AND z20_cod_tran  = r19_cod_tran
		  AND z20_num_tran  = r19_num_tran
		  AND z20_codcli    = r19_codcli
		  AND z20_areaneg   = 1
		  AND z23_compania  = z20_compania
		  AND z23_localidad = z20_localidad
		  AND z23_codcli    = z20_codcli
		  AND z23_tipo_doc  = z20_tipo_doc
		  AND z23_num_doc   = z20_num_doc
		  AND (z23_valor_cap + z23_valor_int + z23_saldo_cap +
			z23_saldo_int) = 0
		  AND z22_compania  = z23_compania
		  AND z22_localidad = z23_localidad
		  AND z22_codcli    = z23_codcli
		  AND z22_tipo_trn  = z23_tipo_trn
		  AND z22_num_trn   = z23_num_trn
		  AND z22_fecing    =
			(SELECT MAX(z22_fecing)
				FROM cxct023, cxct022
				WHERE z23_compania   = z20_compania
				  AND z23_localidad  = z20_localidad
				  AND z23_codcli     = z20_codcli
				  AND z23_tipo_doc   = z20_tipo_doc
				  AND z23_num_doc    = z20_num_doc
				  AND z22_compania   = z23_compania
				  AND z22_localidad  = z23_localidad
				  AND z22_codcli     = z23_codcli
				  AND z22_tipo_trn   = z23_tipo_trn
				  AND z22_num_trn    = z23_num_trn
		  		  AND z22_fecing    <= CURRENT))
		ELSE DATE(r20_fecing)
	END AS fec_pago,
	CASE WHEN r19_cod_tran = 'FA'
		THEN NVL(r20_val_descto, 0)
		ELSE NVL(r20_val_descto, 0) * (-1)
        END AS val_dscto,
	CASE WHEN r19_cod_tran = 'FA' THEN
		NVL(((r20_cant_ven * r20_precio) - r20_val_descto), 0)
	ELSE
		NVL(((r20_cant_ven * r20_precio) - r20_val_descto), 0) * (-1)
	END AS val_vta,
	NVL((SELECT r88_num_fact
		FROM rept088
		WHERE r88_compania     = r19_compania
		  AND r88_localidad    = r19_localidad
		  AND r88_cod_fact_nue = r19_cod_tran
		  AND r88_num_fact_nue = r19_num_tran), "") AS fac_ant,
	NVL(DATE((SELECT r19_fecing
		FROM rept088, rept019 repm
		WHERE r88_compania       = r19m.r19_compania
		  AND r88_localidad      = r19m.r19_localidad
		  AND r88_cod_fact_nue   = r19m.r19_cod_tran
		  AND r88_num_fact_nue   = r19m.r19_num_tran
		  AND repm.r19_compania  = r88_compania
		  AND repm.r19_localidad = r88_localidad
		  AND repm.r19_cod_tran	 = r88_cod_fact
		  AND repm.r19_num_tran	 = r88_num_fact)), "") AS fech_ant,
	r19_tipo_dev AS tipodev,
	r19_num_dev AS numdev
	FROM rept019 r19m, rept020, rept010
	WHERE  r19_compania                       = 1
	  AND  r19_localidad                      = 1
	  AND (r19_cod_tran                      IN ("DF", "FA")
	  AND (r19_tipo_dev                      IS NULL
	   OR  r19_tipo_dev                       = "DF"))
	  AND  EXTEND(r19_fecing, YEAR TO MONTH)  = "2013-06"
	  AND  r20_compania                       = r19_compania
	  AND  r20_localidad                      = r19_localidad
	  AND  r20_cod_tran                       = r19_cod_tran
	  AND  r20_num_tran                       = r19_num_tran
	  AND  r10_compania                       = r20_compania
	  AND  r10_codigo                         = r20_item
	  AND  NVL((SELECT SUM(z20_saldo_cap + z20_saldo_int)
			FROM cxct020
			WHERE z20_compania  = r19_compania
			  AND z20_localidad = r19_localidad
			  AND z20_cod_tran  = r19_cod_tran
			  AND z20_num_tran  = r19_num_tran
			  AND z20_codcli    = r19_codcli
			  AND z20_areaneg   = 1), 0) = 0
