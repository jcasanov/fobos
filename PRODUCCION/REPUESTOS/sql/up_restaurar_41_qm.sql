select r10_compania cia, r10_codigo item, r10_peso peso, r10_partida partida
	from rept010
	where r10_compania = 77
	into temp t1;
load from "restaurar_41_mil.unl" insert into t1;
update rept010
	set r10_peso    = (select peso from t1
				where cia   = r10_compania
				  and item  = r10_codigo),
	    r10_partida = (select partida from t1
				where cia   = r10_compania
				  and item  = r10_codigo)
	where r10_compania in (1, 2)
	  and r10_codigo   in (select item from t1 where cia = r10_compania);
drop table t1;
