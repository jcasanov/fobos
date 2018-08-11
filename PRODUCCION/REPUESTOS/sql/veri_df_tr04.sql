select r02_codigo from rept002
	where r02_compania  = 1
	  and r02_localidad = 4
	  and r02_estado    = 'A'
	  and r02_tipo      = 'S'
	into temp t_bd;
select r20_cod_tran, r20_num_tran, r20_item, r20_cant_ven,
	date(r20_fecing) fecha_dev
	from rept020
	where r20_compania  = 1
	  and r20_localidad = 4
	  and r20_cod_tran  = 'DF'
	  and r20_bodega    = (select r02_codigo from t_bd)
	into temp t1;
select r19_tipo_dev, r19_num_dev, r20_cod_tran cod_tran, r20_num_tran num_tran,
	r20_item item, r20_cant_ven cant_ven
	from rept019, rept020
	where r19_compania   = 1
	  and r19_localidad  = 4
	  and r19_cod_tran   = 'TR'
	  and r19_tipo_dev  in ('FA', 'DF')
	  and r20_compania   = r19_compania
	  and r20_localidad  = r19_localidad
	  and r20_cod_tran   = r19_cod_tran
	  and r20_num_tran   = r19_num_tran
	into temp t2;
drop table t_bd;
select r19_tipo_dev, r19_num_dev, cod_tran, item,nvl(sum(cant_ven), 0) cant_ven
	from t2
	group by 1, 2, 3, 4
	into temp t3;
select r20_cod_tran, r20_num_tran, r20_item, r20_cant_ven, cod_tran, 
	r19_tipo_dev, r19_num_dev, item, cant_ven, fecha_dev
	from t1, t3
	where r20_cod_tran  = r19_tipo_dev
	  and r20_num_tran  = r19_num_dev
	  and r20_item      = item
	  and r20_cant_ven <> cant_ven
	into temp t4;
select unique r20_cod_tran, r20_num_tran from t4 into temp t_dev;
select r19_cod_tran, r19_num_tran, r19_tipo_dev tip_dev, r19_num_dev num_dev
	from rept019, t_dev
	where r19_compania  = 1
	  and r19_localidad = 4
	  and r19_cod_tran  = r20_cod_tran
	  and r19_num_tran  = r20_num_tran
	into temp t_fac;
drop table t_dev;
drop table t1;
drop table t2;
select r19_cod_tran, r19_num_tran, item item_fac, cant_ven cant_fac
	from t_fac, t3
	where r19_tipo_dev = tip_dev
	  and r19_num_dev  = num_dev
	into temp t5;
drop table t3;
drop table t_fac;
select r20_cod_tran, r20_num_tran, r20_item, r20_cant_ven, cod_tran, 
	r19_tipo_dev, r19_num_dev, item, cant_ven, fecha_dev
	from t4, t5
	where r20_cod_tran  = r19_cod_tran
	  and r20_num_tran  = r19_num_tran
	  and r20_item      = item_fac
	  and cant_ven     <> cant_fac
	into temp t6;
drop table t4;
drop table t5;
select unique r20_num_tran, count(*) tot_df from t6 group by 1 into temp t_tot;
select nvl(sum(tot_df), 0) total_df from t_tot;
drop table t_tot;
select count(*) tot_item from t6;
select * from t6 order by fecha_dev desc, r20_num_tran desc;
drop table t6;
