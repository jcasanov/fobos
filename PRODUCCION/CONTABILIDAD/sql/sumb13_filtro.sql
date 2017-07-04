select nvl(sum(b13_valor_base), 0)
	from ctbt012, ctbt013
	where b12_compania    = 1
	  and b12_estado     <> 'E'
	  and b13_compania    = b12_compania
	  and b13_tipo_comp   = b12_tipo_comp
	  and b13_num_comp    = b12_num_comp
	  and b13_cuenta      = '21010101001'
	  and b13_codprov     = 59
	  and b13_fec_proceso between mdy(12, 13, 2002) and today;
