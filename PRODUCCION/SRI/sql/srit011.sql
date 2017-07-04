create table "fobos".srit011
	(

		s11_compania		integer			not null,
		s11_codigo		char(4)			not null,
		s11_nombre_emi_tj	varchar(40,15)		not null,
		s11_usuario		varchar(10,5)		not null,
		s11_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".srit011 from "public";


create unique index "fobos".i11_pk_srit011
	on "fobos".srit011 (s11_compania, s11_codigo) in idxdbs;

create index "fobos".i11_fk_srit011
	on "fobos".srit011 (s11_compania) in idxdbs;

create index "fobos".i02_fk_srit011 on "fobos".srit011 (s11_usuario) in idxdbs;


alter table "fobos".srit011
	add constraint
		primary key (s11_compania, s11_codigo)
			constraint pk_srit011;

alter table "fobos".srit011
	add constraint (foreign key (s11_compania)
			references "fobos".srit000
			constraint fk_11_srit011);

alter table "fobos".srit011
	add constraint (foreign key (s11_usuario)
			references "fobos".gent005
			constraint fk_02_srit011);
