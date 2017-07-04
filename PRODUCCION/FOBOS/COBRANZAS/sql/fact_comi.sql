SELECT r19_codcli AS codcli, r19_nomcli AS cliente, r19_cod_tran AS cod_tran,
	r19_num_tran AS num_tran, r19_localidad AS local, r19_vendedor AS
	cod_ven, r01_nombres AS vendedor, DATE(r19_fecing) AS fecha,
	CASE WHEN r19_cod_tran = 'FA' THEN
		NVL(SUM((r20_cant_ven * r20_precio) - r20_val_descto),0)
	ELSE
		NVL(SUM((r20_cant_ven * r20_precio) - r20_val_descto),0) * (-1)
	END valor_doc--,
	{
	NVL((SELECT SUM(z23_valor_cap + z23_valor_int)
		FROM cxct020, cxct023, cxct022
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
		  AND z23_div_doc   = z20_dividendo
		  AND z22_compania  = z23_compania
		  AND z22_localidad = z23_localidad
		  AND z22_codcli    = z22_codcli
		  AND z22_tipo_trn  = z23_tipo_trn
		  AND z22_num_trn   = z23_num_trn
		  AND EXTEND(z22_fecing, YEAR TO MONTH) =
			EXTEND(r19_fecing, YEAR TO MONTH)), 0) valor_mov,
	NVL((SELECT SUM(z23_valor_cap + z23_valor_int)
		FROM cxct020, cxct023, cxct022
		WHERE z20_compania      = r19_compania
		  AND z20_localidad     = r19_localidad
		  AND z20_cod_tran      = r19_cod_tran
		  AND z20_num_tran      = r19_num_tran
		  AND z20_codcli        = r19_codcli
		  AND z20_areaneg       = 1
		  AND z23_compania      = z20_compania
		  AND z23_localidad     = z20_localidad
		  AND z23_codcli        = z20_codcli
		  AND z23_tipo_doc      = z20_tipo_doc
		  AND z23_num_doc       = z20_num_doc
		  AND z23_div_doc       = z20_dividendo
		  AND z22_compania      = z23_compania
		  AND z22_localidad     = z23_localidad
		  AND z22_codcli        = z22_codcli
		  AND z22_tipo_trn      = z23_tipo_trn
		  AND z22_num_trn       = z23_num_trn
		  AND z22_tipo_trn     <> "AJ"
		  AND DATE(z22_fecing) <= MDY(10, 31, 2010)), 0) valor_pago
	}
	FROM rept019, rept020, rept001
	WHERE r19_compania     = 1
	  AND r19_localidad    = 1
	  AND r19_cod_tran     IN ("FA", "DF", "AF")
	  AND DATE(r19_fecing) BETWEEN MDY(10, 01, 2010)
				   AND MDY(10, 31, 2010)
	  AND r20_compania     = r19_compania
	  AND r20_localidad    = r19_localidad
	  AND r20_cod_tran     = r19_cod_tran
	  AND r20_num_tran     = r19_num_tran
	  AND r01_compania     = r19_compania
	  AND r01_codigo       = r19_vendedor
	--GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 10, 11
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
	ORDER BY 2;
