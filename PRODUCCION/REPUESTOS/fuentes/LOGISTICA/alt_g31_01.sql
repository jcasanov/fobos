begin work;

alter table "fobos".gent031 drop g31_divi_poli;

alter table "fobos".gent031
	add (g31_divi_poli	integer		before g31_nombre);

create index "fobos".i03_fk_gent031
	on "fobos".gent031
		(g31_pais, g31_divi_poli)
	in idxdbs;

alter table "fobos".gent031
	add constraint
		(foreign key (g31_pais, g31_divi_poli)
			references "fobos".gent025
			constraint "fobos".fk_03_gent031);

commit work;
