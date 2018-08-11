create table "fobos".srit013
	(

		s13_compania		integer			not null,
		s13_codigo		char(4)			not null,
		s13_descripcion		varchar(80,40)		not null,
		s13_usuario		varchar(10,5)		not null,
		s13_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".srit013 from "public";


create unique index "fobos".i13_pk_srit013
	on "fobos".srit013 (s13_compania, s13_codigo) in idxdbs;

create index "fobos".i13_fk_srit013
	on "fobos".srit013 (s13_compania) in idxdbs;

create index "fobos".i02_fk_srit013 on "fobos".srit013 (s13_usuario) in idxdbs;


alter table "fobos".srit013
	add constraint
		primary key (s13_compania, s13_codigo)
			constraint pk_srit013;

alter table "fobos".srit013
	add constraint (foreign key (s13_compania)
			references "fobos".srit000
			constraint fk_13_srit013);

alter table "fobos".srit013
	add constraint (foreign key (s13_usuario)
			references "fobos".gent005
			constraint fk_02_srit013);
