select r19_cod_tran ct, r19_num_tran num, b12_tipo_comp tc, b12_num_comp n_c,
	b12_estado est
	from rept019, rept040, ctbt012
	where r19_compania      = 1
	  and r19_cod_tran      = 'AF'
	  and date(r19_fecing) >= mdy(01,01,2009)
	  and r40_compania      = r19_compania
	  and r40_localidad     = r19_localidad
	  and r40_cod_tran      = r19_tipo_dev
	  and r40_num_tran      = r19_num_dev
	  and b12_compania      = r40_compania
	  and b12_tipo_comp     = r40_tipo_comp
	  and b12_num_comp      = r40_num_comp
	  and b12_estado       <> 'E'
	order by 5, 1, 2;
