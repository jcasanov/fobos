begin work;

alter table "fobos".rept109 drop r109_pais;

alter table "fobos".rept109 drop r109_divi_poli;

alter table "fobos".rept109 drop r109_ciudad;

alter table "fobos".rept109
	add (r109_pais		integer		before r109_usuario);

alter table "fobos".rept109
	add (r109_divi_poli	integer		before r109_usuario);

alter table "fobos".rept109
	add (r109_ciudad	integer		before r109_usuario);

update rept109
	set r109_pais = 1
	where 1 = 1;

alter table "fobos".rept109
	modify (r109_pais	integer		not null);

create index "fobos".i04_fk_rept109
	on "fobos".rept109
		(r109_pais, r109_divi_poli)
	in idxdbs;

create index "fobos".i05_fk_rept109
	on "fobos".rept109
		(r109_ciudad)
	in idxdbs;

alter table "fobos".rept109
	add constraint
		(foreign key (r109_pais, r109_divi_poli)
			references "fobos".gent025
			constraint "fobos".fk_04_rept109);

alter table "fobos".rept109
	add constraint
		(foreign key (r109_ciudad)
			references "fobos".gent031
			constraint "fobos".fk_05_rept109);

commit work;
