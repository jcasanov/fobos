drop table rolt075;

begin work;

create table "fobos".rolt075

	(
		n75_compania		integer			not null,
		n75_proceso		char(2)			not null,
		n75_num_acta		integer			not null,
		n75_cod_liqrol		char(2)			not null,
		n75_sec_liqrol		smallint		not null,
		n75_orden_lq		smallint		not null,
		n75_fecha_ini		date			not null,
		n75_fecha_fin		date			not null,
		n75_referencia		varchar(70,40)		not null,
		n75_valor_base		decimal(12,2)		not null,
		n75_valor_pro		decimal(12,2)		not null,
		n75_usuario		varchar(10,5)		not null,
		n75_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".rolt075 from "public";

create unique index "fobos".i01_pk_rolt075
	on "fobos".rolt075
		(n75_compania, n75_proceso, n75_num_acta, n75_cod_liqrol,
		 n75_sec_liqrol)
	in idxdbs;

create index "fobos".i01_fk_rolt075
	on "fobos".rolt075
		(n75_compania, n75_proceso, n75_num_acta)
	in idxdbs;

create index "fobos".i02_fk_rolt075
	on "fobos".rolt075
		(n75_compania, n75_proceso, n75_cod_liqrol)
	in idxdbs;

create index "fobos".i03_fk_rolt075
	on "fobos".rolt075
		(n75_usuario)
	in idxdbs;

alter table "fobos".rolt075
	add constraint
		primary key (n75_compania, n75_proceso, n75_num_acta,
				n75_cod_liqrol, n75_sec_liqrol)
			constraint "fobos".pk_rolt075;

alter table "fobos".rolt075
	add constraint
		(foreign key (n75_compania, n75_proceso, n75_num_acta)
			references "fobos".rolt074
			constraint "fobos".fk_01_rolt075);

alter table "fobos".rolt075
	add constraint
		(foreign key (n75_compania, n75_proceso, n75_cod_liqrol)
			references "fobos".rolt071
			constraint "fobos".fk_02_rolt075);

alter table "fobos".rolt075
	add constraint
		(foreign key (n75_usuario)
			references "fobos".gent005
			constraint "fobos".fk_03_rolt075);

commit work;
