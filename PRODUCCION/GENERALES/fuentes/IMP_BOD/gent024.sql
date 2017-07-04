begin work;

--------------------------------------------------------------------------------

drop table gent024;

--------------------------------------------------------------------------------

create table "fobos".gent024

	(

		g24_compania		integer			not null,
		g24_bodega		char(2)			not null,
		g24_impresora		varchar(10,5)		not null,
		g24_imprime		char(1)			not null,
		g24_usuario		varchar(10,5)		not null,
		g24_fecing		datetime year to second	not null,

		check (g24_imprime in ('S', 'N'))
			constraint "fobos".ck_01_gent024

	) in datadbs lock mode row;

revoke all on "fobos".gent024 from "public";

--------------------------------------------------------------------------------

create unique index "fobos".i01_pk_gent024
	on "fobos".gent024
		(g24_compania, g24_bodega, g24_impresora)
	in idxdbs;

create index "fobos".i01_fk_gent024
	on "fobos".gent024
		(g24_compania, g24_bodega)
	in idxdbs;

create index "fobos".i02_fk_gent024
	on "fobos".gent024
		(g24_impresora)
	in idxdbs;

create index "fobos".i03_fk_gent024
	on "fobos".gent024
		(g24_usuario)
	in idxdbs;

--------------------------------------------------------------------------------

alter table "fobos".gent024
	add constraint
		primary key (g24_compania, g24_bodega, g24_impresora)
			constraint "fobos".pk_gent024;

alter table "fobos".gent024
	add constraint
		(foreign key (g24_compania, g24_bodega)
			references "fobos".rept002
			constraint "fobos".fk_01_gent024);

alter table "fobos".gent024
	add constraint
		(foreign key (g24_impresora)
			references "fobos".gent006
			constraint "fobos".fk_02_gent024);

alter table "fobos".gent024
	add constraint
		(foreign key (g24_usuario)
			references "fobos".gent005
			constraint "fobos".fk_03_gent024);

--------------------------------------------------------------------------------

commit work;
