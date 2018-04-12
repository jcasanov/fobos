begin work;

	insert into cxpt000
		select * from jadesa:cxpt000;

	select * from jadesa:cxpt004
		into temp t1;

	update t1
		set p04_usuario = 'FOBOS'
		where 1 = 1;

	insert into cxpt004
		select * from t1;

	drop table t1;

--rollback work;
commit work;
