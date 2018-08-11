SELECT j14_localidad AS localidad, j10_tipo_destino AS tip_des,
	j10_num_destino AS num_des, j10_codcli AS codigo,
	z01_nomcli AS clientes, j14_cod_tran AS cod_tran,
	j14_num_tran AS num_tran, j14_fec_emi_fact AS fecha_fact,
	j14_fecha_emi AS fecha_ret, b12_tipo_comp AS tip_com,
	b12_num_comp AS num_comp, b12_fec_proceso AS fecha_comp,
	CASE WHEN j10_areaneg = 1 THEN "INVENTARIO"
	     WHEN j10_areaneg = 2 THEN "TALLER"
	END AS area,
	CASE WHEN b12_estado = 'A' THEN "ACTIVO"
	     WHEN b12_estado = 'M' THEN "MAYORIAZADO"
	     WHEN b12_estado = 'E' THEN "ELIMINADO"
	END AS estado,
	j14_fecing AS fecha_ing
	FROM cajt014, cajt010, cxct040, cxct001, ctbt012
	WHERE j14_compania      = 1
	  AND j14_tipo_fuente   = 'SC'
	  AND DATE(j14_fecing) >= MDY(02, 09, 2011)
	  AND j10_compania      = j14_compania
	  AND j10_localidad     = j14_localidad
	  AND j10_tipo_fuente   = j14_tipo_fuente
	  AND j10_num_fuente    = j14_num_fuente
	  AND z40_compania      = j10_compania
	  AND z40_localidad     = j10_localidad
	  AND z40_codcli        = j10_codcli
	  AND z40_tipo_doc      = j10_tipo_destino
	  AND z40_num_doc       = j10_num_destino
	  AND z01_codcli        = j10_codcli
	  AND b12_compania      = z40_compania
	  AND b12_tipo_comp     = z40_tipo_comp
	  AND b12_num_comp      = z40_num_comp
	  AND b12_tipo_comp     = z40_tipo_comp
	  AND b12_fec_proceso  <> j14_fecha_emi
	ORDER BY j14_fecing ASC;
