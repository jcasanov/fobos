select b12_tipo_comp, b12_num_comp, b12_estado,
	nvl(sum(b13_valor_base), 0) valor
	from ctbt012, ctbt013
	where b12_compania   = 1
	  and b12_estado    <> 'E'
	  and b12_fec_proceso between mdy(01,01,2003) and mdy(12,31,2003)
	  and b13_compania   = b12_compania
	  and b13_tipo_comp  = b12_tipo_comp
	  and b13_num_comp   = b12_num_comp
	group by 1, 2, 3
	into temp t1;
delete from t1 where valor = 0;
select * from t1 order by 1, 2;
drop table t1;
