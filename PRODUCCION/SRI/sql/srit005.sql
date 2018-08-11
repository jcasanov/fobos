create table "fobos".srit005
	(

		s05_compania		integer			not null,
		s05_codigo		smallint		not null,
		s05_descripcion		varchar(30,15)		not null,
		s05_usuario		varchar(10,5)		not null,
		s05_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".srit005 from "public";


create unique index "fobos".i01_pk_srit005
	on "fobos".srit005 (s05_compania, s05_codigo) in idxdbs;

create index "fobos".i01_fk_srit005
	on "fobos".srit005 (s05_compania) in idxdbs;

create index "fobos".i02_fk_srit005 on "fobos".srit005 (s05_usuario);


alter table "fobos".srit005
	add constraint
		primary key (s05_compania, s05_codigo) constraint pk_srit005;

alter table "fobos".srit005
	add constraint (foreign key (s05_compania) references "fobos".srit000
			constraint fk_01_srit005);

alter table "fobos".srit005
	add constraint (foreign key (s05_usuario) references "fobos".gent005
			constraint fk_02_srit005);
