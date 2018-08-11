create table "fobos".srit009
	(

		s09_compania		integer			not null,
		s09_codigo		smallint		not null,
		s09_tipo_porc		char(1)			not null,
		s09_descripcion		varchar(10,5)		not null,
		s09_usuario		varchar(10,5)		not null,
		s09_fecing		datetime year to second	not null,

		check (s09_tipo_porc in ('S', 'B'))
			constraint "fobos".ck_01_srit009

	) in datadbs lock mode row;

revoke all on "fobos".srit009 from "public";


create unique index "fobos".i01_pk_srit009
	on "fobos".srit009 (s09_compania, s09_codigo, s09_tipo_porc) in idxdbs;

create index "fobos".i01_fk_srit009
	on "fobos".srit009 (s09_compania) in idxdbs;

create index "fobos".i02_fk_srit009 on "fobos".srit009 (s09_usuario) in idxdbs;


alter table "fobos".srit009
	add constraint
		primary key (s09_compania, s09_codigo, s09_tipo_porc)
			constraint "fobos".pk_srit009;

alter table "fobos".srit009
	add constraint
		(foreign key (s09_compania)
			references "fobos".srit000
			constraint "fobos".fk_01_srit009);

alter table "fobos".srit009
	add constraint
		(foreign key (s09_usuario)
			references "fobos".gent005
			constraint "fobos".fk_02_srit009);
