select r20_item, r20_cod_tran, count(*) cuantos
	from rept020
	where r20_compania  = 1
	  and r20_localidad = 2
	  and r20_bodega    = '79'
	group by 1, 2
	into temp t1;
select count(*) hay from t1;
select * from t1 order by 3 desc;
drop table t1;
