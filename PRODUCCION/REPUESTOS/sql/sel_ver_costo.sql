select r20_cod_tran tp, r20_num_tran num, r20_bodega bod, r20_item[1,6] item,
	r20_costant_mb cos_a, r20_costnue_mb cos_n, r20_fecing fec
	from rept020
	where r20_compania  = 1
	  --and r20_localidad = 1
	  and r20_item      = 23874
	  --and year(r20_fecing) = 2004
	order by 7
	into temp t1;
select tp, num, bod, item, cos_a, cos_n from t1; -- order by 5;
select count(*) from t1;
drop table t1;
