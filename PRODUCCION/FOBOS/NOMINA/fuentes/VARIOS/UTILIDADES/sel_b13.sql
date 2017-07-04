select 1 loc, b12_tipo_comp tc, b12_num_comp num, b13_cuenta cta,
	b10_descripcion nombre, b13_valor_base valor
	from ctbt012, ctbt013, ctbt010
	where b12_compania           = 1
	  and b12_tipo_comp          = 'DC'
	  and b12_estado            <> 'E'
	  and b12_origen             = 'M'
	  and year(b12_fec_proceso)  = year(today) - 1
	  and date(b12_fecing)	    between mdy(01, 01, year(today))
					and mdy(04, 15, year(today))
	  and b13_compania           = b12_compania
	  and b13_tipo_comp          = b12_tipo_comp
	  and b13_num_comp           = b12_num_comp
	  and b13_cuenta[1, 3]       > '3'
	  --and abs(b13_valor_base)    > 10000
	  and b13_valor_base         > 10000
	  and b10_compania           = b13_compania
	  and b10_cuenta             = b13_cuenta
union
select 3 loc, b12_tipo_comp tc, b12_num_comp num, b13_cuenta cta,
	b10_descripcion nombre, b13_valor_base valor
	from acero_qm:ctbt012, acero_qm:ctbt013, acero_qm:ctbt010
	where b12_compania           = 1
	  and b12_tipo_comp          = 'DC'
	  and b12_estado            <> 'E'
	  and b12_origen             = 'M'
	  and year(b12_fec_proceso)  = year(today) - 1
	  and date(b12_fecing)	    between mdy(01, 01, year(today))
					and mdy(04, 15, year(today))
	  and b13_compania           = b12_compania
	  and b13_tipo_comp          = b12_tipo_comp
	  and b13_num_comp           = b12_num_comp
	  and b13_cuenta[1, 3]       > '3'
	  --and abs(b13_valor_base)    > 10000
	  and b13_valor_base         > 10000
	  and b10_compania           = b13_compania
	  and b10_cuenta             = b13_cuenta
	order by 6 desc, 1, 2, 3;
