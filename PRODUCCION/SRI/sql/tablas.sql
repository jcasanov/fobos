begin work;


-- srit001	(codigos de perido informado)

create table "fobos".srit001 (
	s01_codigo			smallint 		not null, 
	s01_anio			smallint 		not null 
		constraint chk_s01_anio check (s01_anio >= 1995 and s01_anio <= 3000),
	s01_mes				smallint		not null 
	    constraint chk_s01_mes  check (s01_mes >= 1 and s01_mes <= 12)
) lock mode row;

create unique index "fobos".i01_pk_srit001 on "fobos".srit001 (s01_codigo)
in idxdbs;
alter table "fobos".srit001 add constraint primary key (s01_codigo);


-- srit002	(transacciones)

create table "fobos".srit002 (
	s02_codigo			smallint		not null,
	s02_descripcion		varchar(45,25) 	not null 
) lock mode row;

create unique index "fobos".i01_pk_srit002 on "fobos".srit002 (s02_codigo)
in idxdbs;
alter table "fobos".srit002 add constraint primary key (s02_codigo);


-- srit003	(tipo de comprobantes)

create table "fobos".srit003 (
	s03_codigo			smallint		not null,
	s03_descripcion		varchar(45,25) 	not null
) lock mode row;

create unique index "fobos".i01_pk_srit003 on "fobos".srit003 (s03_codigo)
in idxdbs;
alter table "fobos".srit003 add constraint primary key (s03_codigo);


-- srit004	(tipo credito tributario)

create table "fobos".srit004 (
	s04_codigo			smallint		not null,
	s04_descripcion		varchar(45,25) 	not null
) lock mode row;

create unique index "fobos".i01_pk_srit004 on "fobos".srit004 (s04_codigo)
in idxdbs;
alter table "fobos".srit004 add constraint primary key (s04_codigo);


-- srit005	(porcentajes de iva)

create table "fobos".srit005 (
	s05_codigo			smallint		not null,
	s05_porcentaje		numeric(5,2) 	not null 
		constraint chk_s05_porcentaje check (s05_porcentaje >= 0 and s05_porcentaje <= 100)
) lock mode row;

create unique index "fobos".i01_pk_srit005 on "fobos".srit005 (s05_codigo)
in idxdbs;
alter table "fobos".srit005 add constraint primary key (s05_codigo);


-- srit006	(porcentajes de retenciones de iva)

create table "fobos".srit006 (
	s06_codigo			smallint		not null,
	s06_porcentaje		numeric(5,2) 	not null 
		constraint chk_s06_porcentaje check (s06_porcentaje >= 0 and s06_porcentaje <= 100)
) lock mode row;

create unique index "fobos".i01_pk_srit006 on "fobos".srit006 (s06_codigo)
in idxdbs;
alter table "fobos".srit006 add constraint primary key (s06_codigo);


-- srit007	(porcentajes de ice)

create table "fobos".srit007 (
	s07_codigo			smallint		not null,
	s07_descripcion		varchar(30,10)	not null,
	s07_porcentaje		numeric(5,2) 	not null
		constraint chk_s07_porcentaje check (s07_porcentaje >= 0 and s07_porcentaje <= 100)
) lock mode row;

create unique index "fobos".i01_pk_srit007 on "fobos".srit007 (s07_codigo)
in idxdbs;
alter table "fobos".srit007 add constraint primary key (s07_codigo);


-- srit010	(Cabecera de declaracion)

create table "fobos".srit010 (
	s10_ruc				char(13)		not null,
	s10_periodo			char(3)			not null,
	s10_razonsocial		char(60)		not null,	
	s10_telefono		char(9)			not null,	
	s10_fax				char(9)			        ,	
	s10_email			char(60)		         
) lock mode row;

create index "fobos"

rollback work;
