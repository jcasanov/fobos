drop table rolt070;

begin work;

create table "fobos".rolt070

	(
		n70_compania		integer			not null,
		n70_proceso		char(2)			not null,
		n70_ano_proceso		smallint		not null,
		n70_mes_proceso		smallint		not null,
		n70_dias_anio		smallint		not null,
		n70_dias_desah		smallint		not null,
		n70_anio_desp_max	smallint		not null,
		n70_porc_desp		decimal(5,2)		not null,
		n70_fecha_arran		date			not null,
		n70_incluir_rol		char(1)			not null,
		n70_usuario		varchar(10,5)		not null,
		n70_fecing		datetime year to second	not null,

		check (n70_incluir_rol in ("S", "N"))
			constraint "fobos".ck_01_rolt070

	) in datadbs lock mode row;

revoke all on "fobos".rolt070 from "public";

create unique index "fobos".i01_pk_rolt070
	on "fobos".rolt070
		(n70_compania)
	in idxdbs;

create index "fobos".i01_fk_rolt070
	on "fobos".rolt070
		(n70_proceso)
	in idxdbs;

create index "fobos".i02_fk_rolt070
	on "fobos".rolt070
		(n70_usuario)
	in idxdbs;

alter table "fobos".rolt070
	add constraint
		primary key (n70_compania)
			constraint "fobos".pk_rolt070;

alter table "fobos".rolt070
	add constraint
		(foreign key (n70_proceso)
			references "fobos".rolt003
			constraint "fobos".fk_01_rolt070);

alter table "fobos".rolt070
	add constraint
		(foreign key (n70_usuario)
			references "fobos".gent005
			constraint "fobos".fk_02_rolt070);

insert into rolt070
	(n70_compania, n70_proceso, n70_ano_proceso, n70_mes_proceso,
	 n70_dias_anio, n70_dias_desah, n70_anio_desp_max, n70_porc_desp,
	 n70_fecha_arran, n70_incluir_rol, n70_usuario, n70_fecing)
	select n01_compania, "AF", n01_ano_proceso, n01_mes_proceso,
		360, 360, 25, 25, mdy(04, 01, 2013), "S", "FOBOS", current
		from rolt001
		where n01_compania = 1;

commit work;
