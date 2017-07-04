drop table rept110;

begin work;

create table "fobos".rept110

	(
		r110_compania		integer			not null,
		r110_localidad		smallint		not null,
		r110_cod_trans		smallint		not null,
		r110_estado		char(1)			not null,
		r110_descripcion	varchar(40,20)		not null,
		r110_placa		varchar(10,6)		not null,
		r110_usuario		varchar(10,5)		not null,
		r110_fecing		datetime year to second	not null,

		check (r110_estado in ("A", "B"))
			constraint "fobos".ck_01_rept110

	) in datadbs lock mode row;

revoke all on "fobos".rept110 from "public";

create unique index "fobos".i01_pk_rept110
	on "fobos".rept110
		(r110_compania, r110_localidad, r110_cod_trans)
	in idxdbs;

create index "fobos".i01_fk_rept110
	on "fobos".rept110
		(r110_compania)
	in idxdbs;

create index "fobos".i02_fk_rept110
	on "fobos".rept110
		(r110_usuario)
	in idxdbs;

alter table "fobos".rept110
	add constraint
		primary key (r110_compania, r110_localidad, r110_cod_trans)
			constraint "fobos".pk_rept110;

alter table "fobos".rept110
	add constraint
		(foreign key (r110_compania)
			references "fobos".rept000
			constraint "fobos".fk_01_rept110);

alter table "fobos".rept110
	add constraint
		(foreign key (r110_usuario)
			references "fobos".gent005
			constraint "fobos".fk_02_rept110);

commit work;
