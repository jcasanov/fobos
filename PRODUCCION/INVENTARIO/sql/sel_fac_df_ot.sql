select b.r19_cod_tran, b.r19_num_tran, b.r19_referencia, b.r19_ord_trabajo,
	b.r19_fecing
	from rept019 b, rept019 c
	where b.r19_compania  = 1
	  and b.r19_localidad = 1
	  and b.r19_cod_tran  in('DF', 'AF')
	  and b.r19_tipo_dev  = 'FA'
	  and b.r19_num_dev   in(select a.r19_num_tran from rept019 a
				where a.r19_compania  = b.r19_compania
				  and a.r19_localidad = b.r19_localidad
				  and a.r19_cod_tran  = b.r19_tipo_dev
				  and a.r19_num_tran  = b.r19_num_dev
				  and a.r19_ord_trabajo is not null)
	  and c.r19_compania  = b.r19_compania
	  and c.r19_localidad = b.r19_localidad
	  and c.r19_cod_tran  = 'TR'
	  and c.r19_tipo_dev  = b.r19_cod_tran
	  and c.r19_num_dev   = b.r19_num_tran
	into temp t1;
select count(*) hay_total from t1;
select * from t1 order by 4, 2;
drop table t1;
