drop table rolt072;

begin work;

create table "fobos".rolt072

	(
		n72_compania		integer			not null,
		n72_proceso		char(2)			not null,
		n72_cod_rubro		smallint		not null,
		n72_usuario		varchar(10,5)		not null,
		n72_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".rolt072 from "public";

create unique index "fobos".i01_pk_rolt072
	on "fobos".rolt072
		(n72_compania, n72_proceso, n72_cod_rubro)
	in idxdbs;

create index "fobos".i01_fk_rolt072
	on "fobos".rolt072
		(n72_proceso)
	in idxdbs;

create index "fobos".i02_fk_rolt072
	on "fobos".rolt072
		(n72_cod_rubro)
	in idxdbs;

create index "fobos".i03_fk_rolt072
	on "fobos".rolt072
		(n72_usuario)
	in idxdbs;

alter table "fobos".rolt072
	add constraint
		primary key (n72_compania, n72_proceso, n72_cod_rubro)
			constraint "fobos".pk_rolt072;

alter table "fobos".rolt072
	add constraint
		(foreign key (n72_proceso)
			references "fobos".rolt003
			constraint "fobos".fk_01_rolt072);

alter table "fobos".rolt072
	add constraint
		(foreign key (n72_cod_rubro)
			references "fobos".rolt006
			constraint "fobos".fk_02_rolt072);

alter table "fobos".rolt072
	add constraint
		(foreign key (n72_usuario)
			references "fobos".gent005
			constraint "fobos".fk_03_rolt072);

insert into rolt072
	(n72_compania, n72_proceso, n72_cod_rubro, n72_usuario, n72_fecing)
	select 1, "AF", n06_cod_rubro, "FOBOS", current
		from rolt006
		where n06_cod_rubro in (1, 2, 7, 8, 9, 10, 13, 15, 17, 22, 23,
					24, 25, 32, 33, 51, 54, 55, 57, 59, 61,
					62);

insert into rolt072
	(n72_compania, n72_proceso, n72_cod_rubro, n72_usuario, n72_fecing)
	select 1, "AF", n18_cod_rubro, "FOBOS", current
		from rolt018
		where 1 = 1;

commit work;
