--drop table rolt020;

begin work;

create table "fobos".rolt020
	(

		n20_compania		integer			not null,
		n20_ano_proceso		integer			not null,
		n20_mes_proceso		smallint		not null,
		n20_proceso		char(2)			not null,
		n20_cod_trab		integer			not null,
		n20_horario		char(2)			not null,
		n20_tipo_trab		char(1)			not null,
		n20_min_dia		smallint		not null,
		n20_min_hor		smallint		not null,
		n20_min_esp_ent		smallint		not null,
		n20_min_almuerzo	smallint		not null,
		n20_usuario		varchar(10,5)		not null,
		n20_fecing		datetime year to second	not null,

		check	(n20_tipo_trab	in	('G', 'J', 'E'))
			constraint "fobos".ck_01_rolt020

	) in datadbs lock mode row;


revoke all on "fobos".rolt020 from "public";


create unique index "fobos".i01_pk_rolt020
	on "fobos".rolt020
		(n20_compania, n20_ano_proceso, n20_mes_proceso, n20_proceso,
		 n20_cod_trab, n20_horario)
	in idxdbs;

create index "fobos".i01_fk_rolt020
	on "fobos".rolt020
		(n20_compania)
	in idxdbs;

create index "fobos".i02_fk_rolt020
	on "fobos".rolt020
		(n20_proceso)
	in idxdbs;

create index "fobos".i03_fk_rolt020
	on "fobos".rolt020
		(n20_compania, n20_cod_trab)
	in idxdbs;

create index "fobos".i04_fk_rolt020
	on "fobos".rolt020
		(n20_compania, n20_horario)
	in idxdbs;

create index "fobos".i05_fk_rolt020
	on "fobos".rolt020
		(n20_usuario)
	in idxdbs;


alter table "fobos".rolt020
	add constraint
		primary key (n20_compania, n20_ano_proceso, n20_mes_proceso,
				n20_proceso, n20_cod_trab, n20_horario)
			constraint "fobos".pk_rolt020;

alter table "fobos".rolt020
	add constraint
		(foreign key (n20_compania)
			references "fobos".rolt001
			constraint "fobos".fk_01_rolt020);

alter table "fobos".rolt020
	add constraint
		(foreign key (n20_proceso)
			references "fobos".rolt003
			constraint "fobos".fk_02_rolt020);

alter table "fobos".rolt020
	add constraint
		(foreign key (n20_compania, n20_cod_trab)
			references "fobos".rolt030
			constraint "fobos".fk_03_rolt020);

alter table "fobos".rolt020
	add constraint
		(foreign key (n20_compania, n20_horario)
			references "fobos".rolt019
			constraint "fobos".fk_04_rolt020);

alter table "fobos".rolt020
	add constraint
		(foreign key (n20_usuario)
			references "fobos".gent005
			constraint "fobos".fk_05_rolt020);


commit work;
