select r20_item[1,6] item, r20_cant_ven cant, r20_cant_ven sto_mes,
	r19_tot_neto val_bru, r19_tot_neto val_des, r19_tot_neto val_neto
	from rept019, rept020
	where r19_compania  = 100
	  and r19_localidad = 100
	  and r19_cod_tran  = 'FA'
	  and r20_compania  = r19_compania
	  and r20_localidad = r19_localidad
	  and r20_cod_tran  = r19_cod_tran
	  and r20_num_tran  = r19_num_tran
	into temp t1;
insert into t1
	select r20_item, sum(r20_cant_ven) cantidad, 0 sto_mes,
		sum(r20_precio * r20_cant_ven) valor_bruto,
		sum(r20_val_descto * r20_cant_ven) descto, 0 valor_neto
		from rept019, rept020
		where r19_compania      = 1
		  and r19_localidad     = 1
		  and r19_cod_tran      = 'FA'
		  and r19_tipo_dev is null
		  and year(r19_fecing)  = 2004
		  and month(r19_fecing) = 3
		  and r20_compania      = r19_compania
		  and r20_localidad     = r19_localidad
		  and r20_cod_tran      = r19_cod_tran
		  and r20_num_tran      = r19_num_tran
		group by 1;
insert into t1
	select r20_item, sum(r20_cant_ven) cantidad, 0 sto_mes,
		(sum(r20_precio * r20_cant_ven) * (-1)) valor_bruto,
		(sum(r20_val_descto * r20_cant_ven) * (-1)) descto,
		0 valor_neto
		from rept019, rept020
		where r19_compania      = 1
		  and r19_localidad     = 1
		  and r19_cod_tran      in ('DF', 'AF')
		  and year(r19_fecing)  = 2004
		  and month(r19_fecing) = 3
		  and r20_compania      = r19_compania
		  and r20_localidad     = r19_localidad
		  and r20_cod_tran      = r19_cod_tran
		  and r20_num_tran      = r19_num_tran
		group by 1;
select item, sum(cant) cant, sum(sto_mes) sto_mes,
	sum(val_bru) val_bru, sum(val_des) val_des,
	sum(val_neto) val_neto
	from t1
	group by 1
	into temp t2;
update t2 set val_neto = val_bru - val_des
	where item in (select unique item from t1);
select r31_item, nvl(sum(r31_stock), 0) stock
	from rept031
	where r31_compania = 1
	  and r31_ano      = 2004
	  and r31_mes      = 3
	  and r31_item     in (select unique item from t1)
	group by 1
	into temp t3;
update t2 set sto_mes = (select stock from t3 where r31_item = item)
	where item in (select unique item from t1);
drop table t1;
drop table t3;
select count(*) cuantos from t2;
--delete from t2 where sto_mes is not null;
select * from t2 order by item;
drop table t2;
