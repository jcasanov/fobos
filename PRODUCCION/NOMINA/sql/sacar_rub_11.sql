select n33_fecha_fin, count(*) tot_emp_vac
	from rolt033
	where n33_compania   = 1
	  and n33_cod_liqrol in('Q1', 'Q2')
	  and n33_cod_rubro  = 11
	  and n33_valor      > 0
	group by 1
	into temp t1;
select count(*) tot_vacaciones from t1;
select * from t1 order by 1 desc;
select sum(tot_emp_vac) tot_valor from t1;
drop table t1;
