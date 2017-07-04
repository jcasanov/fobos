create table "fobos".srit016
	(

		s16_compania		integer			not null,
		s16_codigo		char(3)			not null,
		s16_descripcion		varchar(30,15)		not null,
		s16_usuario		varchar(10,5)		not null,
		s16_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".srit016 from "public";


create unique index "fobos".i16_pk_srit016
	on "fobos".srit016 (s16_compania, s16_codigo) in idxdbs;

create index "fobos".i16_fk_srit016
	on "fobos".srit016 (s16_compania) in idxdbs;

create index "fobos".i02_fk_srit016 on "fobos".srit016 (s16_usuario) in idxdbs;


alter table "fobos".srit016
	add constraint
		primary key (s16_compania, s16_codigo)
			constraint pk_srit016;

alter table "fobos".srit016
	add constraint (foreign key (s16_compania)
			references "fobos".srit000
			constraint fk_16_srit016);

alter table "fobos".srit016
	add constraint (foreign key (s16_usuario)
			references "fobos".gent005
			constraint fk_02_srit016);
