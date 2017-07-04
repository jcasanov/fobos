select r10_codigo item, r10_precio_mb precio, r10_cod_util util,
	r10_comentarios comen
	from rept010
	where r10_compania = 999
	into temp t1;
load from "items_pro_ago13.unl" delimiter "," insert into t1;
{--
unload to "items_pro_ago13_res.unl"
	select r10_codigo, r10_precio_mb, r10_cod_util, r10_comentarios
		from rept010
		where r10_compania = 1
		  and r10_codigo in (select item from t1);
--}
begin work;
	update rept010
		set r10_precio_mb   = (select precio
					from t1
					where item = r10_codigo),
		    r10_cod_util    = (select util
					from t1
					where item = r10_codigo),
		    r10_comentarios = (select comen
					from t1
					where item = r10_codigo),
		    r10_cantveh     = 1
		where r10_compania = 1
		  and r10_codigo in (select item from t1);
commit work;
drop table t1;
