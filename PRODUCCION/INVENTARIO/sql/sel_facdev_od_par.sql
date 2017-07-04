select r19_cod_tran, r19_num_tran, r20_bodega, r20_item[1,6] r20_item,
	round(nvl(r20_cant_ven -
		(select sum(b.r20_cant_ven)
		from rept019 a, rept020 b
		where a.r19_compania  = r19_compania
		  and a.r19_localidad = r19_localidad
		  and a.r19_tipo_dev  = r19_cod_tran
		  and a.r19_num_dev   = r19_num_tran
		  and b.r20_compania  = a.r19_compania
		  and b.r20_localidad = a.r19_localidad
		  and b.r20_cod_tran  = a.r19_cod_tran
		  and b.r20_num_tran  = a.r19_num_tran
		  and b.r20_bodega    = r20_bodega
		  and b.r20_item      = r20_item), 0), 2) cant_real
	from rept019, rept020
	where r19_compania  = 1
	  and r19_cod_tran  = 'FA'
	  and r19_tipo_dev  in ('DF', 'AF')
	  and r20_compania  = r19_compania
	  and r20_localidad = r19_localidad
	  and r20_cod_tran  = r19_cod_tran
	  and r20_num_tran  = r19_num_tran
	into temp t1;
--delete from t1 where cant_real = 0;
select count(*) total_item from t1;
select r19_cod_tran tp, r19_num_tran fact, r35_bodega bd,
	r35_num_ord_des orddes, r20_item, cant_real,
	nvl(r35_cant_des - r35_cant_ent, 0) cant_pend
	from t1, rept034, rept035
	where r34_compania    = 1
	  and r34_estado      in ('A', 'P')
	  and r34_cod_tran    = r19_cod_tran
	  and r34_num_tran    = r19_num_tran
	  and r35_compania    = r34_compania
	  and r35_localidad   = r34_localidad
	  and r35_bodega      = r20_bodega
	  and r35_num_ord_des = r34_num_ord_des
	  and r35_item        = r20_item
	  and cant_real       <> r35_cant_des - r35_cant_ent
	into temp t2;
drop table t1;
select count(*) total_item_pend from t2;
select * from t2 order by 2, 3, 5;
drop table t2;
