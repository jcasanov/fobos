select r20_num_tran item, r20_localidad localidad, r20_orden cuantos
	from rept020
	where r20_compania = 23
	into temp t1;
insert into t1
	select r87_item, r87_localidad, count(*) cuantos
		from rept087
		group by 1, 2;
select item item_var, count(*) hay from t1
	group by 1
	having count(*) > 1
	into temp t2;
delete from t1
	where item not in (select item_var from t2);
drop table t2;
select * from t1 order by 1, 2;
drop table t1;
