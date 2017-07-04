select r19_comito, count(*) tot from rept019_res group by 1;
select r20_comito, count(*) tot from rept020_res group by 1;
select r10_comito, count(*) tot from rept010_res group by 1;
select b13_comito, count(*) tot from ctbt013_res group by 1;
select r19_localidad, r19_cod_tran, r19_num_tran
	from rept019_res
	where r19_comito = 'N'
	order by 3;
select r20_localidad, r20_cod_tran, r20_num_tran
	from rept020_res
	where r20_comito = 'N'
	order by 3;
select r10_codigo item
	from rept010_res
	where r10_comito = 'N'
	order by 1;
select unique r40_localidad loc, r40_cod_tran tp, r40_num_tran num,
	b13_tipo_comp tc, b13_num_comp num_d
	from ctbt013_res, rept040
	where b13_comito    = 'N'
	  and r40_compania  = b13_compania
	  and r40_tipo_comp = b13_tipo_comp
	  and r40_num_comp  = b13_num_comp
	order by b13_num_comp;
