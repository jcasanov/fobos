select * from rept081 where r81_pedido = 'SP0011' into temp t1;
select * from rept016 where r16_pedido = 'SP0011' into temp t2;

update t1 set r81_pedido = 'SP0011C' where 1 = 1;
update t2 set r16_pedido = 'SP0011C' where 1 = 1;

begin work;

insert into rept081 select * from t1;
insert into rept016 select * from t2;

update rept082 set r82_pedido = 'SP0011C'
	where r82_compania  = 2
	  and r82_localidad = 7
	  and r82_pedido    = 'SP0011';
update rept017 set r17_pedido = 'SP0011C'
	where r17_compania  = 2
	  and r17_localidad = 7
	  and r17_pedido    = 'SP0011';

update rept081 set r81_pedido = 'SM0011'
	where r81_compania  = 2
	  and r81_localidad = 7
	  and r81_pedido    = 'SP0011';
update rept016 set r16_pedido = 'SM0011'
	where r16_compania  = 2
	  and r16_localidad = 7
	  and r16_pedido    = 'SP0011';

update rept082 set r82_pedido = 'SM0011'
	where r82_compania  = 2
	  and r82_localidad = 7
	  and r82_pedido    = 'SP0011C';
update rept017 set r17_pedido = 'SM0011'
	where r17_compania  = 2
	  and r17_localidad = 7
	  and r17_pedido    = 'SP0011C';

delete from rept081
	where r81_compania  = 2
	  and r81_localidad = 7
	  and r81_pedido    = 'SP0011C';
delete from rept016
	where r16_compania  = 2
	  and r16_localidad = 7
	  and r16_pedido    = 'SP0011C';

commit work;
--rollback work;

drop table t1;
drop table t2;
