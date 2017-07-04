create table "fobos".srit012
	(

		s12_compania		integer			not null,
		s12_codigo		char(1)			not null,
		s12_nombre_ident	varchar(30,15)		not null,
		s12_usuario		varchar(10,5)		not null,
		s12_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".srit012 from "public";


create unique index "fobos".i12_pk_srit012
	on "fobos".srit012 (s12_compania, s12_codigo) in idxdbs;

create index "fobos".i12_fk_srit012
	on "fobos".srit012 (s12_compania) in idxdbs;

create index "fobos".i02_fk_srit012 on "fobos".srit012 (s12_usuario) in idxdbs;


alter table "fobos".srit012
	add constraint
		primary key (s12_compania, s12_codigo)
			constraint pk_srit012;

alter table "fobos".srit012
	add constraint (foreign key (s12_compania)
			references "fobos".srit000
			constraint fk_12_srit012);

alter table "fobos".srit012
	add constraint (foreign key (s12_usuario)
			references "fobos".gent005
			constraint fk_02_srit012);
