select unique lpad(n32_cod_trab,3,0) cod, n30_nombres[1, 35] empleados,
	n32_sueldo sueldo
	from rolt032, rolt030
	where n32_compania    in (1, 2)
	  and n32_cod_liqrol  in('Q1', 'Q2')
	  and n32_ano_proceso  = 2008
	  and n30_compania     = n32_compania
	  and n30_cod_trab     = n32_cod_trab
	  and n30_estado       = 'A'
	into temp t1;
select count(*) tot_emp from t1;
select cod, count(*) tot_emp
	from t1
	group by 1
	having count(*) > 1
	into temp t2;
select count(*) tot_emp_aum from t2;
select * from t2 order by 2 desc;
select * from t1
	where cod in (select cod from t2)
	order by 2, 3;
drop table t1;
drop table t2;
