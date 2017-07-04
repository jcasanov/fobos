begin work;

--drop index "fobos".i04_fk_rept095;

--drop index "fobos".i05_fk_rept095;

--alter table "fobos".rept095 drop constraint "fobos".fk_04_rept095;

--alter table "fobos".rept095 drop constraint "fobos".fk_05_rept095;

alter table "fobos".rept095 drop r95_cod_zona;

alter table "fobos".rept095 drop r95_cod_subzona;

alter table "fobos".rept095
	add (r95_cod_zona	smallint	before r95_usu_elim);

alter table "fobos".rept095
	add (r95_cod_subzona	smallint	before r95_usu_elim);

create index "fobos".i04_fk_rept095
	on "fobos".rept095
		(r95_compania, r95_localidad, r95_cod_zona)
	in idxdbs;

create index "fobos".i05_fk_rept095
	on "fobos".rept095
		(r95_compania, r95_localidad, r95_cod_zona, r95_cod_subzona)
	in idxdbs;

alter table "fobos".rept095
	add constraint
		(foreign key (r95_compania, r95_localidad, r95_cod_zona)
			references "fobos".rept108
			constraint "fobos".fk_04_rept095);

alter table "fobos".rept095
	add constraint
		(foreign key (r95_compania, r95_localidad, r95_cod_zona,
				r95_cod_subzona)
			references "fobos".rept109
			constraint "fobos".fk_05_rept095);

commit work;
