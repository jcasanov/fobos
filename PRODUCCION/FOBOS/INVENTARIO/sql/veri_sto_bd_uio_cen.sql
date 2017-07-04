select r11_bodega, r11_item, r11_stock_act, r11_stock_ant
	from rept011
	where r11_compania = 71
	into temp t1;
select r11_bodega bodega, r11_item item, r11_stock_act sto_act,
	r11_stock_ant sto_ant
	from rept011
	where r11_compania = 71
	into temp t2;
insert into t1
	select r11_bodega, r11_item, r11_stock_act, r11_stock_ant
		from acero_qm:rept011
		where r11_compania = 1
		  and r11_bodega in
			(select r02_codigo from rept002
				where r02_localidad = 3);
insert into t2
	select r11_bodega, r11_item, r11_stock_act, r11_stock_ant
		from acero_gc:rept011
		where r11_compania = 1
		  and r11_bodega in
			(select r02_codigo from rept002
				where r02_localidad = 3);
select * from t1, t2
	where r11_bodega = bodega
	  and r11_item   = item
	  and r11_stock_act <> sto_act
	into temp t3;
drop table t1;
drop table t2;
select count(*) hay from t3;
select * from t3 order by r11_item;
drop table t3;
