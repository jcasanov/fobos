drop table rept103;

begin work;

create table "fobos".rept103

	(
		r103_compania		integer			not null,
		r103_localidad		smallint		not null,
		r103_pre_lin_anio	smallint		not null,
		r103_pre_lin_mes	smallint		not null,
		r103_pre_lin_sem	smallint		not null,
		r103_vendedor		smallint		not null,
		r103_cod_linea		smallint		not null,
		r103_cod_filtro		char(15)		not null,
		r103_pre_lin_val	decimal(12,2)		not null,
		r103_usuario		varchar(10,5)		not null,
		r103_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".rept103 from "public";

create unique index "fobos".i01_pk_rept103
	on "fobos".rept103
		(r103_compania, r103_localidad, r103_pre_lin_anio,
		 r103_pre_lin_mes, r103_pre_lin_sem, r103_vendedor,
		 r103_cod_linea, r103_cod_filtro)
	in idxdbs;

create index "fobos".i01_fk_rept103
	on "fobos".rept103
		(r103_compania, r103_vendedor)
	in idxdbs;

create index "fobos".i02_fk_rept103
	on "fobos".rept103
		(r103_compania, r103_cod_linea)
	in idxdbs;

create index "fobos".i03_fk_rept103
	on "fobos".rept103
		(r103_compania, r103_cod_filtro)
	in idxdbs;

create index "fobos".i04_fk_rept103
	on "fobos".rept103
		(r103_usuario)
	in idxdbs;

alter table "fobos".rept103
	add constraint
		primary key (r103_compania, r103_localidad, r103_pre_lin_anio,
			     r103_pre_lin_mes, r103_pre_lin_sem, r103_vendedor,
			     r103_cod_linea, r103_cod_filtro)
			constraint "fobos".pk_rept103;

alter table "fobos".rept103
	add constraint
		(foreign key (r103_compania, r103_vendedor)
			references "fobos".rept001
			constraint "fobos".fk_01_rept103);

alter table "fobos".rept103
	add constraint
		(foreign key (r103_compania, r103_cod_linea)
			references "fobos".rept100
			constraint "fobos".fk_02_rept103);

alter table "fobos".rept103
	add constraint
		(foreign key (r103_compania, r103_cod_filtro)
			references "fobos".rept101
			constraint "fobos".fk_03_rept103);

alter table "fobos".rept103
	add constraint
		(foreign key (r103_usuario)
			references "fobos".gent005
			constraint "fobos".fk_04_rept103);

commit work;
