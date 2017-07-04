set isolation to dirty read;
select r10_codigo item, r10_cod_pedido codped
	from rept010
	where r10_compania = 999
	into temp t1;
load from "items_codped_ede.unl" insert into t1;
begin work;
	update rept010
		set r10_modelo     = (select codped
					from t1
					where item = r10_codigo),
		    r10_cod_pedido = (select codped
					from t1
					where item = r10_codigo)
		where r10_compania = 1
		  and r10_codigo   in (select item from t1);
commit work;
drop table t1;
