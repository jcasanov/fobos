--alter table "fobos".gent037 drop g37_autorizacion;

begin work;

alter table "fobos".gent037
	add(g37_autorizacion varchar(15,10) before g37_usuario);

update "fobos".gent037 set g37_autorizacion = 'S/A' where 1 = 1;

alter table "fobos".gent037 modify(g37_autorizacion varchar(15,10) not null);

commit work;
