select b13_cuenta[1, 8] as cta,
	b10_descripcion as nom,
	sum(b13_valor_base) as saldo
	from ctbt012, ctbt013, ctbt010
	where b12_compania   = 1
	  and b12_tipo_comp  = "DN"
	  and b12_num_comp  in ("14090003", "14090004")
	  and b13_compania   = b12_compania
	  and b13_tipo_comp  = b12_tipo_comp
	  and b13_num_comp   = b12_num_comp
	  and b10_compania   = b13_compania
	  and b10_cuenta     = b13_cuenta[1, 8]
	group by 1, 2
	order by 1;
