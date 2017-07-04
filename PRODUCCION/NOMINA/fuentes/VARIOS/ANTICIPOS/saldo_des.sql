select n45_cod_trab cod, n30_nombres[1, 32] empleados, n45_num_prest ant,
	(n45_val_prest + n45_valor_int + n45_sal_prest_ant) as val_ant,
	nvl((select sum(n46_valor)
		from rolt046
		where n46_compania  = n45_compania
		  and n46_num_prest = n45_num_prest), 0) as val_div
	from rolt045, rolt030
	where n45_compania  in (1, 2)
	  and n45_estado    in ('A', 'R')
	  and n30_compania   = n45_compania
	  and n30_cod_trab   = n45_cod_trab
	into temp t1;
select count(*) tot_emp_desc
	from t1
	where val_ant <> val_div;
select * from t1
	where val_ant <> val_div
	order by 2, 3;
drop table t1;
