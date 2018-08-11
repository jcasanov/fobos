--drop table rolt023;

{-- TABLA: CAUSAS PARA NOVEDADES EN LOS ARCHIVOS BATCH - IESS --}

begin work;

create table "fobos".rolt023

	(

		n23_compania		integer			not null,
		n23_codigo_arch		smallint		not null,
		n23_tipo_arch		char(3)			not null,
		n23_tipo_causa		char(1)			not null,
		n23_secuencia		smallint		not null,
		n23_flag_ident		char(2),
		n23_descripcion		varchar(100,60)		not null,
		n23_usuario		varchar(10,5)		not null,
		n23_fecing		datetime year to second	not null

	) in datadbs lock mode row;


revoke all on "fobos".rolt023 from "public";


create unique index "fobos".i01_pk_rolt023
	on "fobos".rolt023
		(n23_compania, n23_codigo_arch, n23_tipo_arch, n23_tipo_causa,
		 n23_secuencia)
	in idxdbs;

create index "fobos".i01_fk_rolt023
	on "fobos".rolt023
		(n23_compania, n23_codigo_arch, n23_tipo_arch)
	in idxdbs;

create index "fobos".i02_fk_rolt023
	on "fobos".rolt023
		(n23_compania)
	in idxdbs;

create index "fobos".i03_fk_rolt023
	on "fobos".rolt023
		(n23_flag_ident)
	in idxdbs;

create index "fobos".i04_fk_rolt023
	on "fobos".rolt023
		(n23_usuario)
	in idxdbs;


alter table "fobos".rolt023
	add constraint
		primary key (n23_compania, n23_codigo_arch, n23_tipo_arch,
				n23_tipo_causa, n23_secuencia)
			constraint "fobos".pk_rolt023;

alter table "fobos".rolt023
	add constraint
		(foreign key (n23_compania, n23_codigo_arch, n23_tipo_arch)
			references "fobos".rolt022
			constraint "fobos".fk_01_rolt023);

alter table "fobos".rolt023
	add constraint
		(foreign key (n23_compania)
			references "fobos".rolt001
			constraint "fobos".fk_02_rolt023);

alter table "fobos".rolt023
	add constraint
		(foreign key (n23_flag_ident)
			references "fobos".rolt016
			constraint "fobos".fk_03_rolt023);

alter table "fobos".rolt023
	add constraint
		(foreign key (n23_usuario)
			references "fobos".gent005
			constraint "fobos".fk_04_rolt023);


insert into rolt023
	values (1, 2, 'INS', 'O', 1, 'AP', 'OTROS INGRESOS', 'FOBOS', current);

insert into rolt023
	values (1, 2, 'INS', 'C', 1, 'CO', 'COMISIONES VENTAS','FOBOS',current);

insert into rolt023
	values (1, 2, 'INS', 'C', 2, 'C1', 'COMISIONES POR COBRANZAS', 'FOBOS',
		current);

insert into rolt023
	values (1, 2, 'INS', 'H', 1, 'V1', 'VALOR HORAS EXTRAS 100 %', 'FOBOS',
		current);

insert into rolt023
	values (1, 2, 'INS', 'H', 2, 'V5', 'VALOR HORAS EXTRAS 50 %', 'FOBOS',
		current);

insert into rolt023
	values (1, 4, 'ENT', '1', 1, null, 'JORNADA NORMAL', 'FOBOS', current);

insert into rolt023
	values (1, 5, 'SAL', 'T', 1, null, 'TERMINACION DEL CONTRATO', 'FOBOS',
		current);

insert into rolt023
	values (1, 5, 'SAL', 'V', 1, null, 'RENUNCIA VOLUNTARIA', 'FOBOS',
		current);

insert into rolt023
	values (1, 5, 'SAL', 'B', 1, null, 'VISTO BUENO', 'FOBOS', current);

insert into rolt023
	values (1, 5, 'SAL', 'R', 1, null,
		'DESPIDO UNILATERAL POR PARTE DEL EMPLEADOR',
		'FOBOS', current);

insert into rolt023
	values (1, 5, 'SAL', 'S', 1, null, 'SUPRESION DE PARTIDA', 'FOBOS',
		current);

insert into rolt023
	values (1, 5, 'SAL', 'D', 1, null,
		'DESAPARICION DEL PUESTO DENTRO DE LA ESTRUCTURA DE LA EMPRESA',
		'FOBOS', current);

insert into rolt023
	values (1, 5, 'SAL', 'I', 1, null,
		'INCAPACIDAD PERMANENTE DEL TRABAJADOR',
		'FOBOS', current);

insert into rolt023
	values (1, 5, 'SAL', 'F', 1, null,'MUERTE DEL TRABAJADOR','FOBOS',
		current);

insert into rolt023
	values (1, 5, 'SAL', 'A', 1, null, 'ABANDONO VOLUNTARIO', 'FOBOS',
		current);


commit work;
