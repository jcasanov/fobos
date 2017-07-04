select r20_cod_tran, r20_num_tran, r20_bodega, r20_item[1,7], r20_fecing
	from rept020
	where r20_compania  = 1
	  and r20_localidad = 1
	  and r20_bodega    = '99'
	  and (r20_stock_ant <> 0 or r20_stock_bd <> 0)
	into temp t1;
--select r20_item, count(*) tot_item from t1 group by 1 order by 2 desc;
select * from t1 order by r20_item, r20_fecing;
drop table t1;
