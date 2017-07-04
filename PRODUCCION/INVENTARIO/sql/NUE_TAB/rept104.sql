drop table rept104;

begin work;

create table "fobos".rept104

	(
		r104_compania		integer			not null,
		r104_localidad		smallint		not null,
		r104_pre_ven_anio	smallint		not null,
		r104_pre_ven_mes	smallint		not null,
		r104_pre_ven_sem	smallint		not null,
		r104_vendedor		smallint		not null,
		r104_cod_linea		smallint		not null,
		r104_pre_ven_val	decimal(16,6)		not null,
		r104_usuario		varchar(10,5)		not null,
		r104_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".rept104 from "public";

create unique index "fobos".i01_pk_rept104
	on "fobos".rept104
		(r104_compania, r104_localidad, r104_pre_ven_anio,
		 r104_pre_ven_mes, r104_pre_ven_sem, r104_vendedor,
		 r104_cod_linea)
	in idxdbs;

create index "fobos".i01_fk_rept104
	on "fobos".rept104
		(r104_compania, r104_vendedor)
	in idxdbs;

create index "fobos".i02_fk_rept104
	on "fobos".rept104
		(r104_compania, r104_cod_linea)
	in idxdbs;

create index "fobos".i03_fk_rept104
	on "fobos".rept104
		(r104_usuario)
	in idxdbs;

alter table "fobos".rept104
	add constraint
		primary key (r104_compania, r104_localidad, r104_pre_ven_anio,
			     r104_pre_ven_mes, r104_pre_ven_sem, r104_vendedor,
			     r104_cod_linea)
			constraint "fobos".pk_rept104;

alter table "fobos".rept104
	add constraint
		(foreign key (r104_compania, r104_vendedor)
			references "fobos".rept001
			constraint "fobos".fk_01_rept104);

alter table "fobos".rept104
	add constraint
		(foreign key (r104_compania, r104_cod_linea)
			references "fobos".rept100
			constraint "fobos".fk_02_rept104);

alter table "fobos".rept104
	add constraint
		(foreign key (r104_usuario)
			references "fobos".gent005
			constraint "fobos".fk_03_rept104);

commit work;
