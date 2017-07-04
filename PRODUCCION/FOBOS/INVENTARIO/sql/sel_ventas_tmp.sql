select a.r19_compania, a.r19_localidad, a.r19_cod_tran, a.r19_num_tran,
	round(a.r19_tot_neto, 2) tot_neto_fa
	from rept019 a
	where a.r19_compania  = 1
	  and a.r19_localidad = 1
	  and a.r19_cod_tran  = 'FA'
	  and a.r19_fecing    between '2004-01-01 00:00:00' and current
	into temp t1;
select r19_tipo_dev, r19_num_dev, tot_neto_fa,
	round(nvl(sum(b.r19_tot_neto), 0), 2) * -1 tot_dfaf
	from t1 a, rept019 b
	where b.r19_compania  =  a.r19_compania
	  and b.r19_localidad =  a.r19_localidad
	  and b.r19_cod_tran  in ('DF', 'AF')
	  and b.r19_tipo_dev  =  a.r19_cod_tran
	  and b.r19_num_dev   =  a.r19_num_tran
	  and b.r19_fecing    between '2004-01-01 00:00:00' and current
	group by 1, 2, 3
	into temp t2;
drop table t1;
drop table t2;
{
select r19_tipo_dev, r19_num_dev, tot_neto_fa, tot_dfaf,
	tot_neto_fa + tot_dfaf tot_neto
	from t2
	order by 2;
drop table t2;
}
