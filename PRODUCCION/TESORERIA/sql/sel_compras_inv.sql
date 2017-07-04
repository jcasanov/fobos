SELECT p01_codprov, p01_nomprov, p01_num_doc, day(c10_fecha_fact) || '/' ||
	month(c10_fecha_fact) || '/' || year(c10_fecha_fact) fecha_fact,
	DATE(c10_fecing) fecing,
	LPAD(c10_factura[1, 3], 3, 0) || LPAD(c10_factura[5, 7], 3, 0) serie,
	LPAD(c13_factura[9, 15], 7, 0) secuencia, c13_num_aut,
	NVL((c10_tot_repto + c10_tot_mano) - c10_tot_dscto + c10_dif_cuadre
		+ c10_otros, 0) subtotal,
	c10_flete, c10_tot_impto,
	NVL((SELECT NVL(p28_valor_base, 0)
		FROM cxpt028
		WHERE p28_compania  = c13_compania
		  AND p28_localidad = c13_localidad
		  AND p28_codprov   = c10_codprov
		  AND p28_num_doc   = c13_factura
		  AND p28_tipo_ret  = "I"), 0) valor_base,
	NVL((SELECT NVL(p28_valor_ret, 0)
		FROM cxpt028
		WHERE p28_compania  = c13_compania
		  AND p28_localidad = c13_localidad
		  AND p28_codprov   = c10_codprov
		  AND p28_num_doc   = c13_factura
		  AND p28_tipo_ret  = "I"), 0) valor_iva,
	NVL((SELECT NVL(p28_valor_ret, 0)
		FROM cxpt028, ordt002
		WHERE p28_compania   = c13_compania
		  AND p28_localidad  = c13_localidad
		  AND p28_codprov    = c10_codprov
		  AND p28_num_doc    = c13_factura
		  AND p28_tipo_ret   = "F"
		  AND c02_compania   = p28_compania
		  AND c02_tipo_ret   = p28_tipo_ret
		  AND c02_porcentaje = 1.00), 0) valor_ret
	FROM ordt010, cxpt001, ordt013
	WHERE c10_compania   = 1
	  AND c10_localidad  = 1
	  AND c10_tipo_orden = 1
	  AND c10_estado     = "C"
	  AND c10_moneda     = "DO"
	  AND EXTEND(c10_fecha_fact, YEAR TO MONTH) =
		EXTEND(MDY(12, 01, 2005), YEAR TO MONTH)
	  AND p01_codprov    = c10_codprov
	  AND c13_compania   = c10_compania
	  AND c13_localidad  = c10_localidad
	  AND c13_numero_oc  = c10_numero_oc
	INTO TEMP tmp_fac_pro;
select round(sum(subtotal), 2) total from tmp_fac_pro;
select count(*) total_reg from tmp_fac_pro;
select * from tmp_fac_pro order by fecing, p01_nomprov;
drop table tmp_fac_pro;
