select r20_compania, r20_bodega, r20_item, count(*) total
	from rept020
	where r20_compania  = 1
	  and r20_localidad = 1
	  and r20_cod_tran  = 'DF'
	  and r20_bodega    = '99'
	  and extend(r20_fecing, year to month) <= '2003-08'
	group by 1, 2, 3
	into temp t1;
select sum(total) from t1;
select r20_item, total from t1 order by 2 desc;
select r20_item, r11_stock_act
	from t1, rept011
	where r11_compania  = r20_compania
	  and r11_bodega    = r20_bodega
	  and r11_item      = r20_item
	  and r11_stock_act <> 0
	order by 2 desc;
drop table t1;
select count(*) from rept019
	where r19_compania  = 1
	  and r19_localidad = 1
	  and r19_cod_tran  = 'TR'
	  and r19_referencia like '%*** TRASLADO%'
