select r10_codigo item, r10_filtro filtro
	from rept010
	where r10_compania = 999
	into temp t1;

load from "filtros_gc.unl" insert into t1;

update rept010
	set r10_filtro = (select unique filtro from t1 where item = r10_codigo)
	where r10_compania = 1
	  and r10_codigo in (select unique item from t1);

drop table t1;
