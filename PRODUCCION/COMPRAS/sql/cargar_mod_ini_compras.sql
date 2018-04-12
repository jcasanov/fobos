begin work;

	insert into ordt000
		select * from jadesa:ordt000;

	select * from jadesa:ordt001
		into temp t1;

	update t1
		set c01_usuario = 'FOBOS'
		where 1 = 1;

	insert into ordt001
		select * from t1;

	drop table t1;

	select * from jadesa:ordt002
		into temp t1;

	update t1
		set c02_usuario = 'FOBOS'
		where 1 = 1;

	insert into ordt002
		select * from t1;

	drop table t1;

	select * from jadesa:ordt003
		into temp t1;

	update t1
		set c03_usuario = 'FOBOS'
		where 1 = 1;

	insert into ordt003
		select * from t1;

	drop table t1;

--rollback work;
commit work;
