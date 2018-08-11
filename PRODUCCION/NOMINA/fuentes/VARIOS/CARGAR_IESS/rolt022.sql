--drop table rolt022;

{-- TABLA: TIPO DE ARCHIVO BATCH - IESS --}

begin work;

create table "fobos".rolt022

	(

		n22_compania		integer			not null,
		n22_codigo_arch		smallint		not null,
		n22_tipo_arch		char(3)			not null,
		n22_proceso		char(2),
		n22_descripcion		varchar(60,40)		not null,
		n22_nombre_arch		varchar(30,10)		not null,
		n22_usuario		varchar(10,5)		not null,
		n22_fecing		datetime year to second	not null

	) in datadbs lock mode row;


revoke all on "fobos".rolt022 from "public";


create unique index "fobos".i01_pk_rolt022
	on "fobos".rolt022
		(n22_compania, n22_codigo_arch, n22_tipo_arch)
	in idxdbs;

create index "fobos".i01_fk_rolt022
	on "fobos".rolt022
		(n22_compania)
	in idxdbs;

create index "fobos".i02_fk_rolt022
	on "fobos".rolt022
		(n22_proceso)
	in idxdbs;

create index "fobos".i03_fk_rolt022
	on "fobos".rolt022
		(n22_usuario)
	in idxdbs;


alter table "fobos".rolt022
	add constraint
		primary key (n22_compania, n22_codigo_arch, n22_tipo_arch)
			constraint "fobos".pk_rolt022;

alter table "fobos".rolt022
	add constraint
		(foreign key (n22_compania)
			references "fobos".rolt001
			constraint "fobos".fk_01_rolt022);

alter table "fobos".rolt022
	add constraint
		(foreign key (n22_proceso)
			references "fobos".rolt003
			constraint "fobos".fk_02_rolt022);

alter table "fobos".rolt022
	add constraint
		(foreign key (n22_usuario)
			references "fobos".gent005
			constraint "fobos".fk_03_rolt022);


insert into rolt022
	values (1, 1, 'MSU', null, 'AVISO DE NUEVO SUELDO', 'nuevosue.txt',
		'FOBOS', current);

insert into rolt022
	values (1, 2, 'INS', null,'AVISO DE SUELDO POR EXTRAS', 'extras.txt',
		'FOBOS',current);

insert into rolt022
	values (1, 3, 'MSU', null, 'AVISO DE SUELDO POR VACACIONES',
		'nuevosuevac.txt', 'FOBOS', current);

insert into rolt022
	values (1, 4, 'ENT', null, 'AVISO DE ENTRADA DE EMPLEADOS',
		'avisoent.txt', 'FOBOS', current);

insert into rolt022
	values (1, 5, 'SAL', null, 'AVISO DE SALIDA DE EMPLEADOS',
		'avisosal.txt', 'FOBOS', current);

insert into rolt022
	values (1, 6, 'PFR', 'FR', 'PLANILLA FONDO DE RESERVA', 'plani_fr.txt',
		'FOBOS', current);

insert into rolt022
	values (1, 7, 'PPR', null, 'AJUSTES FONDO DE RESERVA PUBLICOS',
		'plani_aj_fr.txt', 'FOBOS', current);

insert into rolt022
	values (1, 8, 'PFN','FR','AJUSTES FONDO DE RESERVA PUBLICOS Y PRIVADOS',
		'plani_aj_fr.txt', 'FOBOS', current);

insert into rolt022
	values (1, 9, 'MND', null, 'AVISO DE DIAS NO LABORADOS',
		'avisodian.txt', 'FOBOS', current);

insert into rolt022
	values (1, 10, 'RHT', null, 'AVISO DE HORAS LABORADAS', 'avisohorn.txt',
		'FOBOS', current);

insert into rolt022
	values (1, 11, 'PRA', null,
		'AVISO DE NOVEDADES RETROACTIVOS Y DIFERENCIAS',
		'novretdif.txt', 'FOBOS', current);

insert into rolt022
	values (1, 12, 'RRT', null, 'AVISO DE INTERMEDIADOS Y/O TERCERIZADOS',
		'avisointter.txt', 'FOBOS', current);

commit work;
--rollback work;
