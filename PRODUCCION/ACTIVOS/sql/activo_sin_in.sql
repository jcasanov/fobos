select a10_codigo_bien activo, a10_descripcion nombre, a10_fecha_comp fecha
	from actt010
	where a10_compania   = 1
	  and a10_estado     in('S', 'D', 'E', 'V')
	  and a10_val_dep_mb > 0
	  and a10_fecha_comp is not null
	  and not exists (select * from actt012
				where a12_compania    = a10_compania
				  and a12_codigo_tran = 'IN'
				  and a12_codigo_bien = a10_codigo_bien)
	into temp t1;
select count(*) tot_act from t1;
select * from t1 order by fecha, activo;
drop table t1;
