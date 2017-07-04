drop table provincia;

begin work;

create table "fobos".provincia

	(

		codigo		smallint		not null,
		descripcion	varchar(60,30)		not null,
		pais		integer			not null,
		cod_phobos	integer			not null

	) in datadbs lock mode row;

revoke all on "fobos".provincia from "public";

create unique index "fobos".i01_pk_provincia
	on "fobos".provincia
		(codigo)
	in idxdbs;

create index "fobos".i01_fk_provincia
	on "fobos".provincia
		(pais, cod_phobos)
	in idxdbs;

alter table "fobos".provincia
	add constraint
		primary key (codigo)
		constraint "fobos".pk_provincia;

alter table "fobos".provincia
	add constraint
		(foreign key (pais, cod_phobos)
		references "fobos".gent025
		constraint "fobos".fk_01_provincia);

commit work;
