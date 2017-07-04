select r19_cod_tran, count(*)
	from rept019
	where r19_bodega_ori  = 79
	group by 1;
select r19_cod_tran, count(*)
	from rept019
	where r19_bodega_dest = 79
	group by 1;
select r20_cod_tran, r20_item, count(*) cuantos
	from rept020
	where r20_compania     = 1
	  and r20_bodega       = 79
	  and date(r20_fecing) < TODAY
	group by 1, 2
	into temp t1;
select count(*) total_item from t1;
select * from t1 order by 3 desc;
drop table t1;
-- Items descuadrados:
select r11_item item_gm, r11_stock_act sto_act_gm
	from rept011
	where r11_compania = 1
	  and r11_bodega   = 79
	into temp t2;
select r11_item item_gc, r11_stock_act sto_act_gc
	from acero_gc:rept011
	where r11_compania = 1
	  and r11_bodega   = 79
	into temp t3;
select t2.*, t3.* from t2, t3
	where item_gm     = item_gc
	  and sto_act_gm <> sto_act_gc
	into temp t4;
select count(*) item_dif from t4;
drop table t4;
select t2.*, t3.* from t2, t3
	where item_gm     = item_gc
	  and sto_act_gm <> sto_act_gc;
drop table t2;
drop table t3;
