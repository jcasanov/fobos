drop table rept112;

begin work;

create table "fobos".rept112

	(
		r112_compania		integer			not null,
		r112_localidad		smallint		not null,
		r112_cod_obser		smallint		not null,
		r112_estado		char(1)			not null,
		r112_descripcion	varchar(45,30)		not null,
		r112_tipo		char(1)			not null,
		r112_usuario		varchar(10,5)		not null,
		r112_fecing		datetime year to second	not null,

		check (r112_estado in ("A", "B"))
			constraint "fobos".ck_01_rept112,
		check (r112_tipo in ("C", "L", "T"))
			constraint "fobos".ck_02_rept112

	) in datadbs lock mode row;

revoke all on "fobos".rept112 from "public";

create unique index "fobos".i01_pk_rept112
	on "fobos".rept112
		(r112_compania, r112_localidad, r112_cod_obser)
	in idxdbs;

create index "fobos".i01_fk_rept112
	on "fobos".rept112
		(r112_compania)
	in idxdbs;

create index "fobos".i02_fk_rept112
	on "fobos".rept112
		(r112_usuario)
	in idxdbs;

alter table "fobos".rept112
	add constraint
		primary key (r112_compania, r112_localidad, r112_cod_obser)
			constraint "fobos".pk_rept112;

alter table "fobos".rept112
	add constraint
		(foreign key (r112_compania)
			references "fobos".rept000
			constraint "fobos".fk_01_rept112);

alter table "fobos".rept112
	add constraint
		(foreign key (r112_usuario)
			references "fobos".gent005
			constraint "fobos".fk_02_rept112);

commit work;
