select g05_usuario usuario
	from gent005
	where g05_usuario = 'caca'
	into temp t1;

load from "per_usu_uio.unl" insert into t1;

begin work;

	delete from gent055
		where g55_user     in (select usuario from t1)
		  and g55_compania = 1
		  and g55_modulo   = 'CO'
		  and g55_proceso  in ('cxcp310', 'cxcp314', 'cxcp315');

	insert into gent057
		(g57_user, g57_compania, g57_modulo, g57_proceso, g57_usuario,
		 g57_fecing)
		select usuario, 1, 'CO', 'cxcp310', 'FOBOS', current
			from t1;

rollback work;

drop table t1;
