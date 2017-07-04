set isolation to dirty read;
select r10_codigo item from rept010 where r10_compania = 999 into temp t1;
load from "ite_blo.unl" insert into t1;
select item
	from t1
	where item  in
		(select r10_codigo
			from rept010
			where r10_compania = 1);
select r11_item, sum(r11_stock_act) tot_sto
	from rept011
	where r11_compania = 1
	  and r11_bodega   in
		(select r02_codigo
			from rept002
			where r02_compania  = r11_compania
			  and r02_localidad = 1)
	  and r11_item     in
		(select * from t1)
	group by 1
	having sum(r11_stock_act) <> 0;
select count(*) tot_t1 from t1;
drop table t1;
