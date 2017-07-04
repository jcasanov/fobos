select r19_cod_tran cod_tran, r19_num_tran num_tran, r20_item item,
	r20_cant_ven cantidad
	from rept019, rept020
	where r19_compania  = 10
	  and r19_localidad = 1
	  and r19_cod_tran  = 'FA'
	  and r20_compania  = r19_compania
	  and r20_localidad = r19_localidad
	  and r20_cod_tran  = r19_cod_tran
	  and r20_num_tran  = r19_num_tran
	into temp t1;
insert into t1
	select r19_cod_tran cod_tran, r19_num_tran num_tran, r20_item item,
		r20_cant_ven cantidad
		from rept019, rept020
		where r19_compania  = 1
		  and r19_localidad = 1
		  and r19_cod_tran  = 'FA'
		  and r19_tipo_dev  = 'DF'
		  and r20_compania  = r19_compania
		  and r20_localidad = r19_localidad
		  and r20_cod_tran  = r19_cod_tran
		  and r20_num_tran  = r19_num_tran
		  and r20_bodega    = 99;
select r19_cod_tran cod_dev, r19_num_tran num_dev, r20_item item_dev,
	r20_cant_ven cant_dev
	from t1, rept019, rept020
	where r19_compania  = 1
	  and r19_localidad = 1
	  and r19_cod_tran  = 'DF'
	  and r19_tipo_dev  = cod_tran
	  and r19_num_dev   = num_tran
	  and r20_compania  = r19_compania
	  and r20_localidad = r19_localidad
	  and r20_cod_tran  = r19_cod_tran
	  and r20_num_tran  = r19_num_tran
	  and r20_bodega    = 99
	  and r20_cant_dev  <> cantidad
	into temp t2;
drop table t1;
select cod_dev, num_dev, count(*) cuantos from t2 group by 1, 2 into temp t3;
select count(*) from t3;
drop table t3;
select * from t2 order by num_dev;
drop table t2;
