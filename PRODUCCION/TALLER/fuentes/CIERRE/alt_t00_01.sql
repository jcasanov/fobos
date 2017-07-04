begin work;


alter table "fobos".talt000
	add (t00_dias_elim	smallint);

alter table "fobos".talt000
	add (t00_elim_mes	char(1));

alter table "fobos".talt000
	add (t00_dias_pres	smallint);

alter table "fobos".talt000
	add (t00_anopro		integer);

alter table "fobos".talt000
	add (t00_mespro		smallint);


update talt000
	set t00_dias_elim = 120,
	    t00_elim_mes  = 'N',
	    t00_dias_pres = 90,
	    t00_anopro    = 2009,
	    t00_mespro    = 3
	where 1 = 1;


alter table "fobos".talt000
	modify (t00_dias_elim	smallint	not null);

alter table "fobos".talt000
	modify (t00_elim_mes	char(1)		not null);

alter table "fobos".talt000
	modify (t00_dias_pres	smallint	not null);

alter table "fobos".talt000
	modify (t00_anopro	integer		not null);

alter table "fobos".talt000
	modify (t00_mespro	smallint	not null);


alter table "fobos".talt000
        add constraint
		check (t00_elim_mes in ('S', 'N'))
                	constraint "fobos".ck_04_talt000;


commit work;
