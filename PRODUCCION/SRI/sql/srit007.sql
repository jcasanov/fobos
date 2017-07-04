create table "fobos".srit007
	(

		s07_compania		integer			not null,
		s07_tipo_comp		smallint		not null,
		s07_sustento_tri	char(2)			not null

	) in datadbs lock mode row;

revoke all on "fobos".srit007 from "public";


create unique index "fobos".i01_pk_srit007
	on "fobos".srit007
		(s07_compania, s07_tipo_comp, s07_sustento_tri) in idxdbs;

create index "fobos".i01_fk_srit007
	on "fobos".srit007 (s07_compania, s07_tipo_comp) in idxdbs;

create index "fobos".i02_fk_srit007
	on "fobos".srit007 (s07_compania, s07_sustento_tri) in idxdbs;


alter table "fobos".srit007
	add constraint
		primary key (s07_compania, s07_tipo_comp, s07_sustento_tri)
			constraint pk_srit007;

alter table "fobos".srit007
	add constraint
		(foreign key (s07_compania, s07_tipo_comp)
			references "fobos".srit004
			constraint fk_01_srit007);

alter table "fobos".srit007
	add constraint
		(foreign key (s07_compania, s07_sustento_tri)
			references "fobos".srit006
			constraint fk_02_srit007);
