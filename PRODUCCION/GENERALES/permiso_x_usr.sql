select g55_modulo, g55_proceso, g54_modulo, g54_proceso, g54_nombre
	from gent054, outer gent055
	where g55_user    = "PATRMOLI"
	  and g55_modulo  = g54_modulo
	  and g55_proceso = g54_proceso
	into temp t1;
delete from t1
	where g55_modulo  is not null
	  and g55_proceso is not null;
select g54_modulo, g54_proceso, g54_nombre
	from gent053, t1
	where g53_usuario = "PATRMOLI"
	  and g53_modulo  = g54_modulo
	into temp t2;
drop table t1;
select count(*) from t2;
unload to "patrmoli.txt"
	select g54_modulo, g54_proceso, g54_nombre
		from t2
		order by g54_modulo, g54_proceso;
drop table t2;
