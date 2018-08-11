begin work;

drop table srit022;

create table "fobos".srit022
	(

		s22_compania		integer			not null,
		s22_localidad		smallint		not null,
		s22_anio		smallint		not null,
		s22_mes			smallint		not null,
		s22_tipo_anexo		char(1)			not null,
		s22_estado		char(1)			not null,
		s22_usu_apert		varchar(10,5),
		s22_fec_apert		datetime year to second,
		s22_usu_cierre		varchar(10,5),
		s22_fec_cierre		datetime year to second,
		s22_usuario		varchar(10,5)		not null,
		s22_fecing		datetime year to second	not null,

		check (s22_tipo_anexo	in ('V', 'C'))
			constraint "fobos".ck_01_srit022,

		check (s22_estado	in ('P', 'C'))
			constraint "fobos".ck_02_srit022

	) in datadbs lock mode row;

revoke all on "fobos".srit022 from "public";


create unique index "fobos".i01_pk_srit022
	on "fobos".srit022
		(s22_compania, s22_localidad, s22_anio, s22_mes, s22_tipo_anexo)
	in idxdbs;

create index "fobos".i01_fk_srit022
	on "fobos".srit022
		(s22_usu_apert)
	in idxdbs;

create index "fobos".i02_fk_srit022
	on "fobos".srit022
		(s22_usu_cierre)
	in idxdbs;

create index "fobos".i03_fk_srit022
	on "fobos".srit022
		(s22_usuario)
	in idxdbs;


alter table "fobos".srit022
	add constraint
		primary key (s22_compania, s22_localidad, s22_anio, s22_mes,
				s22_tipo_anexo)
			constraint "fobos".pk_srit022;

alter table "fobos".srit022
	add constraint
		(foreign key (s22_usu_apert)
			references "fobos".gent005
			constraint "fobos".fk_01_srit022);

alter table "fobos".srit022
	add constraint
		(foreign key (s22_usu_cierre)
			references "fobos".gent005
			constraint "fobos".fk_02_srit022);

alter table "fobos".srit022
	add constraint
		(foreign key (s22_usuario)
			references "fobos".gent005
			constraint "fobos".fk_03_srit022);

commit work;
