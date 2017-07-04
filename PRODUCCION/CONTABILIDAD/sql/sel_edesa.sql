select b12_tipo_comp tc, b12_num_comp num, b13_codcli cli,
   	b13_valor_base valor
	from ctbt012, ctbt013
	where b12_compania   = 1
	  and b12_estado     = "M"
	  and extend(b12_fec_proceso,year to month)
		between "2012-12" and "2013-01"
	  and b13_compania   = b12_compania
	  and b13_tipo_comp  = b12_tipo_comp
	  and b13_num_comp   = b12_num_comp
	  and b13_cuenta     = "11210101002"
	  --and b13_codcli     = 7817
	  and b13_codcli     is null
	into temp t1;
select * from t1
	order by 1, 2;
select sum(valor) from t1;
drop table t1;
