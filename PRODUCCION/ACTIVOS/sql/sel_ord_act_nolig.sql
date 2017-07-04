select a10_codigo_bien, a10_estado, a10_fecha_comp, a10_valor_mb, a10_fecing
	from actt010
	where a10_compania    = 1
	  and a10_fecha_comp >= mdy(01,01,2004)
	  and a10_estado      = 'A'
	  and a10_numero_oc   is null
	  and a10_val_dep_mb  = 0
	into temp t1;
select c11_numero_oc, c11_codigo, c11_descrip, c11_precio, c10_fecha_fact,
	c10_tipo_orden
	from ordt010, ordt011
	where c10_compania     = 1
	  and c10_localidad    = 3
	  and c10_estado       = 'C'
	  and c10_tipo_orden  <> 1
	  and c10_ord_trabajo is null
	  and c10_fecha_fact  between (select min(date(a10_fecha_comp)) from t1)
				  and (select max(date(a10_fecha_comp)) from t1)
	  and c11_compania     = c10_compania
	  and c11_localidad    = c10_localidad
	  and c11_numero_oc    = c10_numero_oc
	into temp t2;
select * from t1 order by 1;
select count(*) from t2 where c11_precio in (select a10_valor_mb from t1);
select * from t2 where c11_precio in (select a10_valor_mb from t1) order by 1;
drop table t1;
drop table t2;
