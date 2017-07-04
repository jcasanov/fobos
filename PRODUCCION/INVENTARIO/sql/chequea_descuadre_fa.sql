select r19_compania, r19_localidad, r19_cod_tran, r19_num_tran,
	r19_tot_bruto, round(sum(r20_cant_ven * r20_precio), 2) valor
	from rept019, rept020
	where r19_compania  = 1
	  and r19_localidad = 1
	  and r19_cod_tran  = 'FA'
	  and r20_compania  = r19_compania
	  and r20_localidad = r19_localidad
	  and r20_cod_tran  = r19_cod_tran
	  and r20_num_tran  = r19_num_tran
	group by 1, 2, 3, 4, 5
	having sum(r20_cant_ven * r20_precio) <> r19_tot_bruto
	order by 1, 2, 3, 4, 5
	into temp t1;
select count(*) hay from t1;
select * from t1;
drop table t1;
