drop table canton;

begin work;

create table "fobos".canton

	(

		cod_prov	smallint		not null,
		codigo		smallint		not null,
		descripcion	varchar(60,30)		not null,
		pais		integer			not null,
		divi_poli	integer			not null,
		cod_phobos	integer			not null

	) in datadbs lock mode row;

revoke all on "fobos".canton from "public";

create unique index "fobos".i01_pk_canton
	on "fobos".canton
		(cod_prov, codigo)
	in idxdbs;

create index "fobos".i01_fk_canton
	on "fobos".canton
		(cod_prov)
	in idxdbs;

create index "fobos".i02_fk_canton
	on "fobos".canton
		(pais, divi_poli)
	in idxdbs;

create index "fobos".i03_fk_canton
	on "fobos".canton
		(cod_phobos)
	in idxdbs;

alter table "fobos".canton
	add constraint
		primary key (cod_prov, codigo)
		constraint "fobos".pk_canton;

alter table "fobos".canton
	add constraint
		(foreign key (cod_prov)
		references "fobos".provincia
		constraint "fobos".fk_01_canton);

alter table "fobos".canton
	add constraint
		(foreign key (pais, divi_poli)
		references "fobos".gent025
		constraint "fobos".fk_02_canton);

alter table "fobos".canton
	add constraint
		(foreign key (cod_phobos)
		references "fobos".gent031
		constraint "fobos".fk_03_canton);

commit work;
