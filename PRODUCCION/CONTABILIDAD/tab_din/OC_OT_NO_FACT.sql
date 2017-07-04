SELECT c40_tipo_comp AS tc,
	c40_num_comp AS num,
	b13_cuenta AS cuenta,
	b10_descripcion AS nom_cta,
	c10_fecha_fact AS fecha,
	c10_numero_oc AS num_oc,
	c10_ord_trabajo AS num_ot,
	t23_cod_cliente AS codcli,
	t23_nom_cliente AS cliente,
	((c10_tot_repto + c10_tot_mano - c10_tot_dscto
	 - abs(c10_dif_cuadre)) AS valor,
	NVL(SUM(b13_valor_base), 0) AS val_ctb,
	CASE WHEN t23_estado = 'A' THEN "ACTIVA"
	     WHEN t23_estado = 'C' THEN "CERRADA"
	     WHEN t23_estado = 'E' THEN "ELIMINADA"
	     WHEN t23_estado = 'F' THEN "FACTURADA"
	     WHEN t23_estado = 'D' THEN "DEVUELTA"
	END AS estado
	FROM ordt040, ordt013, ordt010, talt023, ctbt012, ctbt013, ctbt010
	WHERE c40_compania      = 1
	  AND c13_compania      = c40_compania
	  AND c13_localidad     = c40_localidad
	  AND c13_numero_oc     = c40_numero_oc
	  AND c13_num_recep     = c40_num_recep
	  AND c13_estado        = 'A'
	  AND c10_compania      = c13_compania
	  AND c10_localidad     = c13_localidad
	  AND c10_numero_oc     = c13_numero_oc
	  AND t23_compania      = c10_compania
	  AND t23_localidad     = c10_localidad
	  AND t23_orden         = c10_ord_trabajo
	  --AND t23_estado       NOT IN ('F', 'D')
	  AND t23_estado       <> 'F'
	  AND b12_compania      = c40_compania
	  AND b12_tipo_comp     = c40_tipo_comp
	  AND b12_num_comp      = c40_num_comp
	  AND b12_estado        = 'M'
	  AND b13_compania      = b12_compania
	  AND b13_tipo_comp     = b12_tipo_comp
	  AND b13_num_comp      = b12_num_comp
	  AND b13_cuenta[1, 8]  = '11400102'
	  --AND b13_cuenta[1, 3]  = '114'
	  AND b10_compania      = b13_compania
	  AND b10_cuenta        = b13_cuenta
	GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12
	ORDER BY 5, 9;
