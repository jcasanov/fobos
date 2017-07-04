select r19_cod_tran tp,
	count(r19_num_tran) tot_reg,
	round(sum(case when r19_cod_tran = "FA"
			then (r19_tot_bruto - r19_tot_dscto)
			else (r19_tot_bruto - r19_tot_dscto) * (-1)
		end), 2) tot_vta
	from rept019
	where r19_compania   = 1
	  and r19_localidad  = 1
	  and r19_cod_tran  in ("FA", "DF", "AF")
	  and extend(r19_fecing, year to month) = "2012-10"
	group by 1;
select r19_cod_tran tp,
	count(r19_num_tran) tot_dia,
	round(sum(case when r19_cod_tran = "FA"
			then b13_valor_base
			else b13_valor_base * (-1)
		end), 2) tot_ctb
	from rept019, rept040, ctbt012, ctbt013
	where r19_compania     = 1
	  and r19_localidad    = 1
	  and r19_cod_tran    in ("FA", "DF", "AF")
	  and extend(r19_fecing, year to month) = "2012-10"
	  and r40_compania     = r19_compania
	  and r40_localidad    = r19_localidad
	  and r40_cod_tran     = r19_cod_tran
	  and r40_num_tran     = r19_num_tran
	  and b12_compania     = r40_compania
	  and b12_tipo_comp    = r40_tipo_comp
	  and b12_num_comp     = r40_num_comp
	  and b12_estado       = "M"
	  and b13_compania     = b12_compania
	  and b13_tipo_comp    = b12_tipo_comp
	  and b13_num_comp     = b12_num_comp
	  and b13_cuenta[1, 1] = "4"
	group by 1;
