drop table rept108;

begin work;

create table "fobos".rept108

	(
		r108_compania		integer			not null,
		r108_localidad		smallint		not null,
		r108_cod_zona		smallint		not null,
		r108_estado		char(1)			not null,
		r108_descripcion	varchar(25,10)		not null,
		r108_usuario		varchar(10,5)		not null,
		r108_fecing		datetime year to second	not null,

		check (r108_estado in ("A", "B"))
			constraint "fobos".ck_01_rept108

	) in datadbs lock mode row;

revoke all on "fobos".rept108 from "public";

create unique index "fobos".i01_pk_rept108
	on "fobos".rept108
		(r108_compania, r108_localidad, r108_cod_zona)
	in idxdbs;

create index "fobos".i01_fk_rept108
	on "fobos".rept108
		(r108_compania)
	in idxdbs;

create index "fobos".i02_fk_rept108
	on "fobos".rept108
		(r108_usuario)
	in idxdbs;

alter table "fobos".rept108
	add constraint
		primary key (r108_compania, r108_localidad, r108_cod_zona)
			constraint "fobos".pk_rept108;

alter table "fobos".rept108
	add constraint
		(foreign key (r108_compania)
			references "fobos".rept000
			constraint "fobos".fk_01_rept108);

alter table "fobos".rept108
	add constraint
		(foreign key (r108_usuario)
			references "fobos".gent005
			constraint "fobos".fk_02_rept108);

commit work;
