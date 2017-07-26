drop table rept115;

begin work;

create table "fobos".rept115

	(
		r115_compania		integer			not null,
		r115_localidad		smallint		not null,
		r115_cod_trans		smallint		not null,
		r115_cod_ayud		smallint		not null,
		r115_estado		char(1)			not null,
		r115_nombre		varchar(45,30)		not null,
		r115_cod_trab		integer,
		r115_usuario		varchar(10,5)		not null,
		r115_fecing		datetime year to second	not null,

		check (r115_estado in ("A", "B"))
			constraint "fobos".ck_01_rept115

	) in datadbs lock mode row;

revoke all on "fobos".rept115 from "public";

create unique index "fobos".i01_pk_rept115
	on "fobos".rept115
		(r115_compania, r115_localidad, r115_cod_trans, r115_cod_ayud)
	in idxdbs;

create index "fobos".i01_fk_rept115
	on "fobos".rept115
		(r115_compania, r115_localidad, r115_cod_trans)
	in idxdbs;

create index "fobos".i02_fk_rept115
	on "fobos".rept115
		(r115_compania, r115_cod_trab)
	in idxdbs;

create index "fobos".i03_fk_rept115
	on "fobos".rept115
		(r115_usuario)
	in idxdbs;

alter table "fobos".rept115
	add constraint
		primary key (r115_compania, r115_localidad, r115_cod_trans,
				r115_cod_ayud)
			constraint "fobos".pk_rept115;

alter table "fobos".rept115
	add constraint
		(foreign key (r115_compania, r115_localidad, r115_cod_trans)
			references "fobos".rept110
			constraint "fobos".fk_01_rept115);

alter table "fobos".rept115
	add constraint
		(foreign key (r115_compania, r115_cod_trab)
			references "fobos".rolt030
			constraint "fobos".fk_02_rept115);

alter table "fobos".rept115
	add constraint
		(foreign key (r115_usuario)
			references "fobos".gent005
			constraint "fobos".fk_03_rept115);

commit work;
