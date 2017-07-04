drop table gent025;

begin work;

create table "fobos".gent025

	(
		g25_pais		integer			not null,
		g25_divi_poli		integer			not null,
		g25_region		varchar(14)		not null,
		g25_nombre		varchar(40,20)		not null,
		g25_siglas		char(3)			not null,
		g25_usuario		varchar(10,5)		not null,
		g25_fecing		datetime year to second	not null,

		check (g25_region in ("COSTA", "SIERRA", "ORIENTE",
					"REGION INSULAR"))
			constraint "fobos".ck_01_gent025

	) in datadbs lock mode row;

revoke all on "fobos".gent025 from "public";

create unique index "fobos".i01_pk_gent025
	on "fobos".gent025
		(g25_pais, g25_divi_poli)
	in idxdbs;

create index "fobos".i01_fk_gent025
	on "fobos".gent025
		(g25_pais)
	in idxdbs;

create index "fobos".i02_fk_gent025
	on "fobos".gent025
		(g25_usuario)
	in idxdbs;

alter table "fobos".gent025
	add constraint
		primary key (g25_pais, g25_divi_poli)
			constraint "fobos".pk_gent025;

alter table "fobos".gent025
	add constraint
		(foreign key (g25_pais)
			references "fobos".gent030
			constraint "fobos".fk_01_gent025);

alter table "fobos".gent025
	add constraint
		(foreign key (g25_usuario)
			references "fobos".gent005
			constraint "fobos".fk_02_gent025);

select g25_pais pais, g25_divi_poli divi_poli, g25_region region,
	g25_nombre nombre, g25_siglas siglas, g25_usuario usuario
	from gent025
	where g25_pais = 0
	into temp t1;

load from "divi_poli.csv" delimiter "," insert into t1;

insert into gent025
	(g25_pais, g25_divi_poli, g25_region, g25_nombre, g25_siglas,
	 g25_usuario, g25_fecing)
	select t1.*, current
		from t1;

drop table t1;

commit work;
