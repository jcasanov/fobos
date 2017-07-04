drop table rept109;

begin work;

create table "fobos".rept109

	(
		r109_compania		integer			not null,
		r109_localidad		smallint		not null,
		r109_cod_zona		smallint		not null,
		r109_cod_subzona	smallint		not null,
		r109_estado		char(1)			not null,
		r109_descripcion	varchar(25,10)		not null,
		r109_horas_entr		datetime hour to second	not null,
		r109_usuario		varchar(10,5)		not null,
		r109_fecing		datetime year to second	not null,

		check (r109_estado in ("A", "B"))
			constraint "fobos".ck_01_rept109

	) in datadbs lock mode row;

revoke all on "fobos".rept109 from "public";

create unique index "fobos".i01_pk_rept109
	on "fobos".rept109
		(r109_compania, r109_localidad, r109_cod_zona, r109_cod_subzona)
	in idxdbs;

create index "fobos".i01_fk_rept109
	on "fobos".rept109
		(r109_compania)
	in idxdbs;

create index "fobos".i02_fk_rept109
	on "fobos".rept109
		(r109_compania, r109_localidad, r109_cod_zona)
	in idxdbs;

create index "fobos".i03_fk_rept109
	on "fobos".rept109
		(r109_usuario)
	in idxdbs;

alter table "fobos".rept109
	add constraint
		primary key (r109_compania, r109_localidad, r109_cod_zona,
				r109_cod_subzona)
			constraint "fobos".pk_rept109;

alter table "fobos".rept109
	add constraint
		(foreign key (r109_compania)
			references "fobos".rept000
			constraint "fobos".fk_01_rept109);

alter table "fobos".rept109
	add constraint
		(foreign key (r109_compania, r109_localidad, r109_cod_zona)
			references "fobos".rept108
			constraint "fobos".fk_02_rept109);

alter table "fobos".rept109
	add constraint
		(foreign key (r109_usuario)
			references "fobos".gent005
			constraint "fobos".fk_03_rept109);

commit work;
