select b12_tipo_comp, b12_num_comp, b13_glosa, b13_valor_base, b13_fec_proceso,
	b12_usuario, b12_fecing
	from ctbt013, ctbt012
	where b13_compania      = 1
	  and b13_cuenta        = "15010101001"
	  and extend(b13_fec_proceso,year to month) = '2013-04'
	  and b12_compania      = b13_compania
	  and b12_tipo_comp     = b13_tipo_comp
 	  and b12_num_comp      = b13_num_comp
	  and b12_estado        = 'M'
	  and date(b12_fecing) >= MDY(04,01,2013)
	order by b12_fecing desc;
