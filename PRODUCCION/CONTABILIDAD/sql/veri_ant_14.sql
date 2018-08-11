select b12_fec_proceso as fec,
	b12_tipo_comp as tp,
	b12_num_comp as num,
	b13_cuenta as cta,
	b10_descripcion[1, 23] as nom_cta,
	round(sum(b13_valor_base), 2) as saldo
	from ctbt012, ctbt013, ctbt010
	where b12_compania           = 1
	  and b12_tipo_comp         <> "DN"
	  and b12_estado             = "M"
	  and year(b12_fec_proceso)  = 2014
	  and b13_compania           = b12_compania
	  and b13_tipo_comp          = b12_tipo_comp
	  and b13_num_comp           = b12_num_comp
	  and b13_cuenta[1, 8]       = "11210103"
	  and b13_valor_base         < 0
	  and b10_compania           = b12_compania
	  and b10_cuenta             = b13_cuenta
	group by 1, 2, 3, 4, 5
	order by 1, 2, 3, 5;
