select count(*) from gent052;
select count(*) from gent053;
select g52_modulo, g52_usuario, g52_estado, g53_modulo, g53_usuario
	from gent052, outer gent053
	where g53_modulo  = g52_modulo
	  and g53_usuario = g52_usuario
	into temp t1;
delete from t1 where g53_modulo is not null;
select count(*) from t1;
select * from t1 order by 2;
drop table t1;
