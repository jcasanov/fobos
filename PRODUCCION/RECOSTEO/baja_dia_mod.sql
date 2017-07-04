unload to "ctbt013_res260110.unl"
	select a.b13_tipo_comp, a.b13_num_comp, a.b13_cuenta, a.b13_valor_base,
		b.b13_valor_base
		from ctbt013_res a, ctbt013 b
		where a.b13_compania  = b.b13_compania
		  and a.b13_tipo_comp = b.b13_tipo_comp
		  and a.b13_num_comp  = b.b13_num_comp
		  and a.b13_cuenta    = b.b13_cuenta
		  and a.b13_valor_base <> b.b13_valor_base;
