select r20_compania cia, r20_localidad loc, r20_cod_tran cod_tran,
	r20_num_tran num_tran, r20_item item, max(r20_fecing) fecha
	from rept020
	where r20_compania  = 2
	  and r20_localidad = 7
	  and r20_cod_tran  = 'FA'
	group by 1, 2, 3, 4, 5
	into temp t1;

select unique r20_item, r20_precio, r10_precio_mb, r10_marca
	from rept020, rept010
	where exists           (select cia, loc, cod_tran, num_tran, item
				from t1
				where cia      = r20_compania
				  and loc      = r20_localidad
				  and cod_tran = r20_cod_tran
				  and num_tran = r20_num_tran
				  and item     = r20_item)
	  and r20_fecing     = (select fecha from t1
				where cia      = r20_compania
				  and loc      = r20_localidad
				  and cod_tran = r20_cod_tran
				  and num_tran = r20_num_tran
				  and item     = r20_item)
	  and r10_compania   = r20_compania
	  and r10_codigo     = r20_item
	  and r10_precio_mb <> r20_precio
	into temp t2;

drop table t1;

select count(*) total_item from t2;

select * from t2 order by 1;

drop table t2;
