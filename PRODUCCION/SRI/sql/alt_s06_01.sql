begin work;

alter table "fobos".srit006 add (s06_tributa char(1) before s06_usuario);

update srit006 set s06_tributa = 'S' where 1 = 1;

alter table "fobos".srit006 modify (s06_tributa char(1) not null);

alter table "fobos".srit006
	add constraint
		check (s06_tributa in ('S', 'N'))
			constraint "fobos".ck_01_srit006;

update srit006
	set s06_tributa = 'N'
	where s06_codigo in ('00', '02', '04', '07');

commit work;
