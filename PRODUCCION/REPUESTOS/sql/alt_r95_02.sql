begin work;

--alter table "fobos".rept095 drop r95_estado;

alter table "fobos".rept095 add (r95_estado char(1) before r95_motivo);

update rept095 set r95_estado = 'C' where 1 = 1;

alter table "fobos".rept095 modify (r95_estado char(1) not null);

alter table "fobos".rept095
	add constraint
		check (r95_estado in ('A', 'C', 'E'))
			constraint "fobos".ck_03_rept095;

commit work;
