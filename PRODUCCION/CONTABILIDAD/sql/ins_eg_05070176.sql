begin work;
select * from ctbt013
	where b13_compania  = 1
	  and b13_tipo_comp = 'EG'
	  and b13_num_comp  = '05080019'
	into temp t1;
delete from t1
	where exists (select * from ctbt013
			where ctbt013.b13_compania  = t1.b13_compania
			  and ctbt013.b13_tipo_comp = 'EG'
			  and ctbt013.b13_num_comp  = '05070176'
			  and ctbt013.b13_secuencia = t1.b13_secuencia
			  and ctbt013.b13_cuenta    = t1.b13_cuenta);
update t1 set b13_tipo_comp = 'EG',
	      b13_num_comp  = '05070176'
	where b13_compania  = 1
	  and b13_tipo_comp = 'EG'
	  and b13_num_comp  = '05080019';
insert into ctbt013 select * from t1;
drop table t1;
commit work;
