select r10_codigo, r10_nombre, r10_marca from rept010
	where r10_compania = 10
	into temp t1;
load from "desc_item_uio_mar.txt" insert into t1;
update rept010
	set r10_nombre = (select r10_nombre from t1
				where t1.r10_codigo = rept010.r10_codigo)
	where r10_codigo in (select r10_codigo from t1);
select count(*) from t1;
