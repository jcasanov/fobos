select r10_codigo, r10_estado
	from rept010
	where r10_compania = 1
	into temp t1;
select r10_codigo item, r10_estado estado
	from rept010
	where r10_compania = 10
	into temp t2;
load from "items.txt" insert into t2;
select * from t1, outer t2 where r10_codigo = item into temp t3;
drop table t1;
drop table t2;
delete from t3 where item is not null;
select count(*) cuantos from t3;
select * from t3;
select unique r20_cod_tran, r20_num_tran, r20_item
        from rept020
        where r20_compania  = 1
          and r20_localidad = 1
          and r20_item in (select r10_codigo from t3)
        order by 3;
select r11_bodega, r11_item, r11_stock_act
        from rept011
        where r11_compania  = 1
          and r11_item in (select r10_codigo from t3)
          and r11_stock_act > 0
        order by 2;
drop table t3;
