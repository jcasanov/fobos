create table "fobos".srit006
	(

		s06_compania		integer			not null,
		s06_codigo		char(2)			not null,
		s06_descripcion		varchar(100,60)		not null,
		s06_usuario		varchar(10,5)		not null,
		s06_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".srit006 from "public";


create unique index "fobos".i01_pk_srit006
	on "fobos".srit006 (s06_compania, s06_codigo) in idxdbs;

create index "fobos".i01_fk_srit006
	on "fobos".srit006 (s06_compania) in idxdbs;

create index "fobos".i02_fk_srit006 on "fobos".srit006 (s06_usuario) in idxdbs;


alter table "fobos".srit006
	add constraint primary key (s06_compania, s06_codigo)
			constraint pk_srit006;

alter table "fobos".srit006
	add constraint (foreign key (s06_compania) references "fobos".srit000
			constraint fk_01_srit006);

alter table "fobos".srit006
	add constraint (foreign key (s06_usuario) references "fobos".gent005
			constraint fk_02_srit006);
