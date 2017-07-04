SELECT j14_tipo_fuente tipo, EXTEND(j14_fecha_emi, YEAR TO MONTH) fec_ret,
	EXTEND(j14_fec_emi_fact, YEAR TO MONTH) fec_fac,
	EXTEND(j14_fecing, YEAR TO MONTH) fec_ing,
	EXTEND(b12_fec_proceso, YEAR TO MONTH) fec_ctb, COUNT(*) tot_r
	FROM cajt014, cajt010, cxct022, cxct040, ctbt012
	WHERE j14_compania    IN (1, 2)
	  AND j14_tipo_fuente = 'SC'
	  AND EXTEND(j14_fecha_emi, YEAR TO MONTH)   >= '2009-11'
	  AND EXTEND(j14_fecing, YEAR TO MONTH)      >= '2009-12'
	  AND j10_compania    = j14_compania
	  AND j10_localidad   = j14_localidad
	  AND j10_tipo_fuente = j14_tipo_fuente
	  AND j10_num_fuente  = j14_num_fuente
	  AND z22_compania    = j10_compania
	  AND z22_localidad   = j10_localidad
	  AND z22_codcli      = j10_codcli
	  AND z22_tipo_trn    = j10_tipo_destino
	  AND z22_num_trn     = j10_num_destino
	  AND z40_compania    = z22_compania
	  AND z40_localidad   = z22_localidad
	  AND z40_codcli      = z22_codcli
	  AND z40_tipo_doc    = z22_tipo_trn
	  AND z40_num_doc     = z22_num_trn
	  AND b12_compania    = z40_compania
	  AND b12_tipo_comp   = z40_tipo_comp
	  AND b12_num_comp    = z40_num_comp
	  AND EXTEND(b12_fec_proceso, YEAR TO MONTH) <>
		EXTEND(j14_fec_emi_fact, YEAR TO MONTH)
	  AND EXTEND(b12_fec_proceso, YEAR TO MONTH) <>
		EXTEND(j14_fecha_emi, YEAR TO MONTH)
	GROUP BY 1, 2, 3, 4, 5
	ORDER BY 2, 1;
