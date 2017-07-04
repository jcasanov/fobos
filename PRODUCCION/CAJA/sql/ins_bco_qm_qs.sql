select * from acero_qm@idsuio01:gent008
	into temp t1;

select * from acero_qm@idsuio01:gent009
	where g09_estado = 'A'
	into temp t2;

update t1
	set g08_usuario = 'FOBOS'
	where 1 = 1;

update t2
	set g09_usuario = 'FOBOS'
	where 1 = 1;

begin work;

	insert into gent008
		select a.* from t1 a
			where not exists
			(select 1 from gent008 b
				where b.g08_banco = a.g08_banco);

	insert into gent009
		select a.* from t2 a
			where not exists
			(select 1 from gent009 b
				where b.g09_compania   = a.g09_compania
				  and b.g09_banco      = a.g09_banco
				  and b.g09_numero_cta = a.g09_numero_cta);

--rollback work;
commit work;

drop table t1;
drop table t2;
