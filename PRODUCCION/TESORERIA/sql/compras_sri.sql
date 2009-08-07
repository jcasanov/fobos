SELECT p01_nomprov, p01_num_doc, SUBSTR(p01_direccion1,1,15),
		 p28_valor_base, p01_num_aut, p28_num_doc,
		 p20_fecha_emi, "FECHA VALIDEZ",
-- p27_tip_contable, p27_num_contable,
		 b12_fec_proceso,
		 p28_num_ret,
                 p28_tipo_ret, p27_moneda,
                 p28_porcentaje, p28_valor_ret
                 FROM cxpt027, cxpt028, cxpt020, cxpt001, ordt013, ordt040,
		      ctbt012
                 WHERE p27_compania =   1
                 AND p27_localidad =    1
                 AND p27_moneda = "DO"
                 AND p28_compania = p27_compania
                 AND p28_localidad = p27_localidad
                 AND p28_num_ret = p27_num_ret
                 AND p28_codprov = p27_codprov
                 AND p01_codprov = p27_codprov
                 AND p20_compania = p28_compania
                 AND p20_localidad = p28_localidad
                 AND p20_codprov = p28_codprov
                 AND p20_tipo_doc = p28_tipo_doc
                 AND p20_num_doc = p28_num_doc
                 AND p20_fecha_emi BETWEEN "11-01-2003" AND "11-30-2003"
		 AND c13_compania = p27_compania
		 AND c13_localidad = p27_localidad
		 AND c13_num_ret = p27_num_ret
		 AND c40_compania = c13_compania
		 AND c40_localidad = c13_localidad
		 AND c40_numero_oc = c13_numero_oc
		 AND c40_num_recep = c13_num_recep
		 AND b12_compania  = c40_compania
		 AND b12_tipo_comp  = c40_tipo_comp
		 AND b12_num_comp  = c40_num_comp
                 AND 1 = 1
--	 AND p01_codprov = 27
                 ORDER BY 1, 2
