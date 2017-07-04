--drop table rolt024;

{-- TABLA: CAUSAS SEGURO SOCIAL Y ORIGEN PAGO EN LOS ARCHIVOS BATCH - IESS --}

begin work;

create table "fobos".rolt024

	(

		n24_compania		integer			not null,
		n24_codigo_arch		smallint		not null,
		n24_tipo_arch		char(3)			not null,
		n24_tipo_seg_pag	char(1)			not null,
		n24_tipo		char(1)			not null,
		n24_descripcion		varchar(40,20)		not null,
		n24_usuario		varchar(10,5)		not null,
		n24_fecing		datetime year to second	not null,

		check	(n24_tipo	in	('S', 'N'))
			constraint "fobos".ck_01_rolt024

	) in datadbs lock mode row;


revoke all on "fobos".rolt024 from "public";


create unique index "fobos".i01_pk_rolt024
	on "fobos".rolt024
		(n24_compania, n24_codigo_arch, n24_tipo_arch, n24_tipo_seg_pag,
		 n24_tipo)
	in idxdbs;

create index "fobos".i01_fk_rolt024
	on "fobos".rolt024
		(n24_compania, n24_codigo_arch, n24_tipo_arch)
	in idxdbs;

create index "fobos".i02_fk_rolt024
	on "fobos".rolt024
		(n24_compania)
	in idxdbs;

create index "fobos".i03_fk_rolt024
	on "fobos".rolt024
		(n24_usuario)
	in idxdbs;


alter table "fobos".rolt024
	add constraint
		primary key (n24_compania, n24_codigo_arch, n24_tipo_arch,
				n24_tipo_seg_pag, n24_tipo)
			constraint "fobos".pk_rolt024;

alter table "fobos".rolt024
	add constraint
		(foreign key (n24_compania, n24_codigo_arch, n24_tipo_arch)
			references "fobos".rolt022
			constraint "fobos".fk_01_rolt024);

alter table "fobos".rolt024
	add constraint
		(foreign key (n24_compania)
			references "fobos".rolt001
			constraint "fobos".fk_02_rolt024);

alter table "fobos".rolt024
	add constraint
		(foreign key (n24_usuario)
			references "fobos".gent005
			constraint "fobos".fk_03_rolt024);


insert into rolt024
	values (1, 4, 'ENT', 'R', 'S', 'LEY DE SEGURO SOCIAL VIGENTE - LEY 21',
		'FOBOS', current);

insert into rolt024
	values (1, 4, 'ENT', 'M', 'S', 'SEGURO MIXTO', 'FOBOS', current);

insert into rolt024
	values (1, 4, 'ENT', 'P', 'N', 'FONDOS PROPIOS', 'FOBOS', current);

insert into rolt024
	values (1, 4, 'ENT', 'E', 'N', 'PRESUPUESTO DEL ESTADO', 'FOBOS',
		current);


commit work;
