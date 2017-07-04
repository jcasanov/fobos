select unique b13_cuenta, b10_descripcion, b12_tipo_comp
	from ctbt012, ctbt013, ctbt010
	where b12_compania    = 1
	  and b12_subtipo     = 14		-- subtipo del taller
	  and b13_compania    = b12_compania
	  and b13_tipo_comp   = b12_tipo_comp
	  and b13_num_comp    = b12_num_comp
	  and b13_valor_base <= 0		-- ctas. q' juegan al credito
	  and b10_compania    = b13_compania
	  and b10_cuenta      = b13_cuenta
	order by 1, 3
