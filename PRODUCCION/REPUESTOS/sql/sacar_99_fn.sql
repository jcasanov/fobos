select r20_item[1,6], r20_num_tran, r20_fecing, r36_num_entrega, r36_fecing,
	date(r36_fecing) - date(r20_fecing) dias
	from rept020, rept034, rept036
	where r20_compania     = 1
	  and r20_localidad    = 1
	  and r20_cod_tran     = 'FA'
	  and r20_bodega       = '99'
	  and year(r20_fecing) = 2004
	  and r34_compania     = r20_compania
	  and r34_localidad    = r20_localidad
	  and r34_cod_tran     = r20_cod_tran
	  and r34_num_tran     = r20_num_tran
	  and r36_compania     = r34_compania
	  and r36_localidad    = r34_localidad
	  and r36_bodega       = r34_bodega
	  and r36_num_ord_des  = r34_num_ord_des
	--order by 6 desc;
	into temp t1;
select dias, count(*) tot_dias from t1 group by 1 order by 1 asc;
select dias, count(*) tot_dias from t1 group by 1 into temp t2;
select sum(tot_dias) menor from t2 where dias < 10;
select sum(tot_dias) mayor from t2 where dias >= 10;
drop table t1;
drop table t2;
