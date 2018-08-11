begin work;

alter table "fobos".rept110
	drop constraint "fobos".ck_01_rept110;

alter table "fobos".rept110
	add constraint
		check (r110_estado in ('A', 'B'))
		constraint "fobos".ck_01_rept110;

commit work;
