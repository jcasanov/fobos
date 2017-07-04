drop table rolt071;

begin work;

create table "fobos".rolt071

	(
		n71_compania		integer			not null,
		n71_proceso		char(2)			not null,
		n71_cod_liqrol		char(2)			not null,
		n71_orden_lq		smallint		not null,
		n71_usuario		varchar(10,5)		not null,
		n71_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".rolt071 from "public";

create unique index "fobos".i01_pk_rolt071
	on "fobos".rolt071
		(n71_compania, n71_proceso, n71_cod_liqrol)
	in idxdbs;

create index "fobos".i01_fk_rolt071
	on "fobos".rolt071
		(n71_proceso)
	in idxdbs;

create index "fobos".i02_fk_rolt071
	on "fobos".rolt071
		(n71_cod_liqrol)
	in idxdbs;

create index "fobos".i03_fk_rolt071
	on "fobos".rolt071
		(n71_usuario)
	in idxdbs;

alter table "fobos".rolt071
	add constraint
		primary key (n71_compania, n71_proceso, n71_cod_liqrol)
			constraint "fobos".pk_rolt071;

alter table "fobos".rolt071
	add constraint
		(foreign key (n71_proceso)
			references "fobos".rolt003
			constraint "fobos".fk_01_rolt071);

alter table "fobos".rolt071
	add constraint
		(foreign key (n71_cod_liqrol)
			references "fobos".rolt003
			constraint "fobos".fk_02_rolt071);

alter table "fobos".rolt071
	add constraint
		(foreign key (n71_usuario)
			references "fobos".gent005
			constraint "fobos".fk_03_rolt071);

insert into rolt071
	(n71_compania, n71_proceso, n71_cod_liqrol, n71_orden_lq, n71_usuario,
	 n71_fecing)
	values (1, "AF", "Q1", 1, "FOBOS", current);

insert into rolt071
	(n71_compania, n71_proceso, n71_cod_liqrol, n71_orden_lq, n71_usuario,
	 n71_fecing)
	values (1, "AF", "Q2", 2, "FOBOS", current);

insert into rolt071
	(n71_compania, n71_proceso, n71_cod_liqrol, n71_orden_lq, n71_usuario,
	 n71_fecing)
	values (1, "AF", "FR", 3, "FOBOS", current);

insert into rolt071
	(n71_compania, n71_proceso, n71_cod_liqrol, n71_orden_lq, n71_usuario,
	 n71_fecing)
	values (1, "AF", "DT", 4, "FOBOS", current);

insert into rolt071
	(n71_compania, n71_proceso, n71_cod_liqrol, n71_orden_lq, n71_usuario,
	 n71_fecing)
	values (1, "AF", "DC", 5, "FOBOS", current);

insert into rolt071
	(n71_compania, n71_proceso, n71_cod_liqrol, n71_orden_lq, n71_usuario,
	 n71_fecing)
	values (1, "AF", "VP", 6, "FOBOS", current);

insert into rolt071
	(n71_compania, n71_proceso, n71_cod_liqrol, n71_orden_lq, n71_usuario,
	 n71_fecing)
	values (1, "AF", "AN", 7, "FOBOS", current);

insert into rolt071
	(n71_compania, n71_proceso, n71_cod_liqrol, n71_orden_lq, n71_usuario,
	 n71_fecing)
	values (1, "AF", "IR", 8, "FOBOS", current);

commit work;
