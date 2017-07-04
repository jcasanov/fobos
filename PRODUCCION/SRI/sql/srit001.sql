create table "fobos".srit001
	(

		s01_compania		integer			not null,
		s01_codigo		smallint		not null,
		s01_descripcion		varchar(20,10)		not null,
		s01_usuario		varchar(10,5)		not null,
		s01_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".srit001 from "public";


create unique index "fobos".i01_pk_srit001
	on "fobos".srit001 (s01_compania, s01_codigo) in idxdbs;

create index "fobos".i01_fk_srit001
	on "fobos".srit001 (s01_compania) in idxdbs;

create index "fobos".i02_fk_srit001 on "fobos".srit001 (s01_usuario) in idxdbs;


alter table "fobos".srit001
	add constraint primary key (s01_compania, s01_codigo)
			constraint pk_srit001;

alter table "fobos".srit001
	add constraint (foreign key (s01_compania) references "fobos".srit000
			constraint fk_01_srit001);

alter table "fobos".srit001
	add constraint (foreign key (s01_usuario) references "fobos".gent005
			constraint fk_02_srit001);
