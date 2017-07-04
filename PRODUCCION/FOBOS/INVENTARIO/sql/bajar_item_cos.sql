select unique r10_codigo, r20_item, r10_costo_mb, r10_costo_ma, r10_costult_mb,
	r10_costult_ma
	from rept010, outer rept020
	where r10_compania  = 1
	  and r10_estado    = 'A'
	  and r20_compania  = r10_compania
	  and r20_localidad = 1
	  and r20_item      = r10_codigo
	into temp t1;
delete from t1 where r20_item is not null;
select count(*) hay from t1;
select r10_codigo, r10_costo_mb, r10_costo_ma, r10_costult_mb, r10_costult_ma
	from t1
	order by r10_codigo;
drop table t1;
