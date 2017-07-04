drop table rolt076;

begin work;

create table "fobos".rolt076

	(
		n76_compania		integer			not null,
		n76_proceso		char(2)			not null,
		n76_num_acta		integer			not null,
		n76_cod_liqrol		char(2)			not null,
		n76_sec_liqrol		smallint		not null,
		n76_cod_rubro		smallint		not null,
		n76_num_prest		integer,
		n76_prest_club		integer,
		n76_referencia		varchar(70,40),
		n76_orden		smallint		not null,
		n76_det_tot		char(2)			not null,
		n76_imprime_0		char(1)			not null,
		n76_cant_valor		char(1)			not null,
		n76_horas_porc		decimal(5,2),
		n76_valor_rub		decimal(12,2)		not null,
		n76_usuario		varchar(10,5)		not null,
		n76_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".rolt076 from "public";

create unique index "fobos".i01_pk_rolt076
	on "fobos".rolt076
		(n76_compania, n76_proceso, n76_num_acta, n76_cod_liqrol,
		 n76_sec_liqrol, n76_cod_rubro)
	in idxdbs;

create index "fobos".i01_fk_rolt076
	on "fobos".rolt076
		(n76_compania, n76_proceso, n76_num_acta, n76_cod_liqrol,
		 n76_sec_liqrol)
	in idxdbs;

create index "fobos".i02_fk_rolt076
	on "fobos".rolt076
		(n76_compania, n76_proceso, n76_cod_rubro)
	in idxdbs;

create index "fobos".i03_fk_rolt076
	on "fobos".rolt076
		(n76_compania, n76_num_prest)
	in idxdbs;

create index "fobos".i04_fk_rolt076
	on "fobos".rolt076
		(n76_compania, n76_prest_club)
	in idxdbs;

create index "fobos".i05_fk_rolt076
	on "fobos".rolt076
		(n76_usuario)
	in idxdbs;

alter table "fobos".rolt076
	add constraint
		primary key (n76_compania, n76_proceso, n76_num_acta,
				n76_cod_liqrol, n76_sec_liqrol, n76_cod_rubro)
			constraint "fobos".pk_rolt076;

alter table "fobos".rolt076
	add constraint
		(foreign key (n76_compania, n76_proceso, n76_num_acta,
				n76_cod_liqrol, n76_sec_liqrol)
			references "fobos".rolt075
			constraint "fobos".fk_01_rolt076);

alter table "fobos".rolt076
	add constraint
		(foreign key (n76_compania, n76_proceso, n76_cod_rubro)
			references "fobos".rolt072
			constraint "fobos".fk_02_rolt076);

alter table "fobos".rolt076
	add constraint
		(foreign key (n76_compania, n76_num_prest)
			references "fobos".rolt045
			constraint "fobos".fk_03_rolt076);

alter table "fobos".rolt076
	add constraint
		(foreign key (n76_compania, n76_prest_club)
			references "fobos".rolt064
			constraint "fobos".fk_04_rolt076);

alter table "fobos".rolt076
	add constraint
		(foreign key (n76_usuario)
			references "fobos".gent005
			constraint "fobos".fk_05_rolt076);

commit work;
