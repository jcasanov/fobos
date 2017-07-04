select b12_tipo_comp tp, b12_num_comp num, b13_cuenta cta,
	b10_descripcion[1,15] nom_cta, b13_valor_base val, b12_estado est
	from ctbt012, ctbt013, ctbt010
	where b12_compania  = 1
	  and year(b12_fec_proceso) = 2009
	  and b12_fec_proceso < mdy(12,01,2009)
	  and (date(b12_fec_modifi) >= today - 4
	   or  date(b12_fecing)     >= today - 4)
	  and b13_compania           = b12_compania
	  and b13_tipo_comp          = b12_tipo_comp
	  and b13_num_comp           = b12_num_comp
	  and b10_compania           = b13_compania
	  and b10_cuenta             = b13_cuenta
	  and (b10_cuenta matches '114*' or b10_cuenta matches '6*')
	order by 3, 1, 2;
