begin work;
select r82_partida, r82_item, r82_sec_item, r82_sec_partida
	from rept082
	where r82_pedido = 'caca'
	into temp t1;
load from 'A-5601.txt' insert into t1;
--select * from t1 order by r82_sec_item;
update rept082
	set rept082.r82_sec_item = (select t1.r82_sec_item from t1
					where t1.r82_item = rept082.r82_item)
	where r82_compania  = 1
	  and r82_localidad = 3
	  and r82_pedido    = 'A-5601';
drop table t1;
select r82_partida, r82_item, r82_sec_item, r82_sec_partida
	from rept082
	where r82_pedido = 'A-5601'
	order by r82_sec_item;
commit work;
