create table "fobos".srit017
	(

		s17_compania		integer			not null,
		s17_codigo		smallint		not null,
		s17_descripcion		varchar(30,15)		not null,
		s17_usuario		varchar(10,5)		not null,
		s17_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".srit017 from "public";


create unique index "fobos".i17_pk_srit017
	on "fobos".srit017 (s17_compania, s17_codigo) in idxdbs;

create index "fobos".i17_fk_srit017
	on "fobos".srit017 (s17_compania) in idxdbs;

create index "fobos".i02_fk_srit017 on "fobos".srit017 (s17_usuario) in idxdbs;


alter table "fobos".srit017
	add constraint
		primary key (s17_compania, s17_codigo)
			constraint pk_srit017;

alter table "fobos".srit017
	add constraint (foreign key (s17_compania)
			references "fobos".srit000
			constraint fk_17_srit017);

alter table "fobos".srit017
	add constraint (foreign key (s17_usuario)
			references "fobos".gent005
			constraint fk_02_srit017);
