select r20_cod_tran, r20_num_tran, r20_fecing, r20_bodega, r20_item
	from rept020, rept019
	where r20_compania     = 1
	  and r20_localidad    = 2
	  and r20_cod_tran     = 'FA'
	  and r20_bodega       = '79'
	  and r19_compania     = r20_compania
	  and r19_localidad    = r20_localidad
	  and r19_cod_tran     = r20_cod_tran
	  and r19_num_tran     = r20_num_tran
	  and r19_tipo_dev     is null
	  and date(r19_fecing) <= mdy(09, 10, 2004)
	into temp t1;
select r20_cod_tran, r20_num_tran, date(r20_fecing) fecha_fact, r20_item,
	r20_bodega, r34_num_ord_des
	from t1, rept034
	where r34_compania  = 1
	  and r34_localidad = 2
	  and r34_cod_tran  = r20_cod_tran
	  and r34_num_tran  = r20_num_tran
	  and r34_estado    in ('A', 'P')
	into temp t2;
drop table t1;
select unique r20_cod_tran, r20_num_tran from t2 into temp caca;
select count(*) num_fact from caca;
drop table caca;
select unique r20_cod_tran, r20_num_tran, fecha_fact
	from t2 order by r20_num_tran desc;
select r20_item, sum(r35_cant_des - r35_cant_ent) cantidad_aju70, r11_stock_act
	from t2, rept035, rept011
	where r35_compania    = 1
	  and r35_localidad   = 2
	  and r35_bodega      = r20_bodega
	  and r35_item        = r20_item
	  and r35_num_ord_des = r34_num_ord_des
	  and r11_compania    = r35_compania
	  and r11_bodega      = r35_bodega
	  and r11_item        = r35_item
	  and r11_stock_act  <> 0
	group by 1, 3
	having sum(r35_cant_des - r35_cant_ent) > 0
	into temp t3;
drop table t2;
select count(*) total_items from t3;
select r20_item, r10_linea division, cantidad_aju70, r11_stock_act
	from t3, rept010
	where (cantidad_aju70 * -1) <> r11_stock_act
	  and r10_compania           = 1
	  and r10_codigo             = r20_item
	order by 2 asc, 3 desc;
select r20_item, r10_linea division, cantidad_aju70, r11_stock_act
	from t3, rept010
	where (cantidad_aju70 * -1) = r11_stock_act
	  and r10_compania          = 1
	  and r10_codigo            = r20_item
	order by 2 asc, 3 desc;
drop table t3;
