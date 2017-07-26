drop table rept102;

begin work;

create table "fobos".rept102

	(
		r102_compania		integer			not null,
		r102_localidad		smallint		not null,
		r102_cod_linea		smallint		not null,
		r102_cod_filtro		char(15)		not null

	) in datadbs lock mode row;

revoke all on "fobos".rept102 from "public";

create unique index "fobos".i01_pk_rept102
	on "fobos".rept102
		(r102_compania, r102_localidad, r102_cod_linea, r102_cod_filtro)
	in idxdbs;

create index "fobos".i01_fk_rept102
	on "fobos".rept102
		(r102_compania, r102_localidad)
	in idxdbs;

create index "fobos".i02_fk_rept102
	on "fobos".rept102
		(r102_compania, r102_cod_linea)
	in idxdbs;

create index "fobos".i03_fk_rept102
	on "fobos".rept102
		(r102_compania, r102_cod_filtro)
	in idxdbs;

alter table "fobos".rept102
	add constraint
		primary key (r102_compania, r102_localidad, r102_cod_linea,
				r102_cod_filtro)
			constraint "fobos".pk_rept102;

alter table "fobos".rept102
	add constraint
		(foreign key (r102_compania, r102_localidad)
			references "fobos".gent002
			constraint "fobos".fk_01_rept102);

alter table "fobos".rept102
	add constraint
		(foreign key (r102_compania, r102_cod_linea)
			references "fobos".rept100
			constraint "fobos".fk_02_rept102);

alter table "fobos".rept102
	add constraint
		(foreign key (r102_compania, r102_cod_filtro)
			references "fobos".rept101
			constraint "fobos".fk_03_rept102);

load from "rept102.csv" delimiter "," insert into rept102;

commit work;
