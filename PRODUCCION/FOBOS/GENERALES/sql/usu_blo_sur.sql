set isolation to dirty read;
select g05_usuario usuar from gent005 where g05_usuario = 'caca' into temp t1;
load from "usu_blo_sur.unl" insert into t1;
begin work;
	update gent005
		set g05_estado = 'B'
		where g05_usuario in (select * from t1);
commit work;
drop table t1;
