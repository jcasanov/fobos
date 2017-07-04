select a.r19_cod_tran, a.r19_num_tran, round(a.r19_tot_neto, 2) tot_neto_fa,
	round((select nvl(sum(b.r19_tot_neto), 0) * -1
		from rept019 b
		where b.r19_compania  =  a.r19_compania
		  and b.r19_localidad =  a.r19_localidad
		  and b.r19_cod_tran  in ('DF', 'AF')
		  and b.r19_tipo_dev  = a.r19_cod_tran
		  and b.r19_num_dev   = a.r19_num_tran
		  and b.r19_fecing    between '2004-01-01 00:00:00'
					  and current), 2) tot_dfaf,
	round(a.r19_tot_neto +
	(select round(nvl(sum(b.r19_tot_neto), 0), 2) * -1
		from rept019 b
		where b.r19_compania  =  a.r19_compania
		  and b.r19_localidad =  a.r19_localidad
		  and b.r19_cod_tran  in ('DF', 'AF')
		  and b.r19_tipo_dev  = a.r19_cod_tran
		  and b.r19_num_dev   = a.r19_num_tran
		  and b.r19_fecing    between '2004-01-01 00:00:00'
					  and current), 2) tot_neto
	from rept019 a
	where a.r19_compania  = 1
	  and a.r19_localidad = 1
	  and a.r19_cod_tran  = 'FA'
	  and a.r19_fecing    between '2005-05-01 00:00:00' and current
	group by 1, 2, 3, 4, 5
	into temp t1;
	--order by 2;
