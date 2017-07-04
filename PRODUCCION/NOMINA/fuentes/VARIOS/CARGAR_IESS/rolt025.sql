--drop table rolt025;

{-- TABLA: TIPO EMPLEADOR Y RELACION DE TRABAJO EN LOS ARCHIVOS BATCH - IESS --}

begin work;

create table "fobos".rolt025

	(

		n25_compania		integer			not null,
		n25_codigo_arch		smallint		not null,
		n25_tipo_arch		char(3)			not null,
		n25_tipo_emp_rel	char(2)			not null,
		n25_tipo		char(3)			not null,
		n25_descripcion		varchar(200,100)	not null,
		n25_tipo_codigo		char(2),
		n25_sub_tipo		char(3),
		n25_usuario		varchar(10,5)		not null,
		n25_fecing		datetime year to second	not null,

		check	(n25_tipo	in	('PRI', 'PUB'))
			constraint "fobos".ck_01_rolt025,

		check	(n25_sub_tipo	in	('PRI', 'PUB'))
			constraint "fobos".ck_02_rolt025

	) in datadbs lock mode row;


revoke all on "fobos".rolt025 from "public";


create unique index "fobos".i01_pk_rolt025
	on "fobos".rolt025
		(n25_compania, n25_codigo_arch, n25_tipo_arch, n25_tipo_emp_rel,
		 n25_tipo)
	in idxdbs;

create index "fobos".i01_fk_rolt025
	on "fobos".rolt025
		(n25_compania, n25_codigo_arch, n25_tipo_arch)
	in idxdbs;

create index "fobos".i02_fk_rolt025
	on "fobos".rolt025
		(n25_compania)
	in idxdbs;

create index "fobos".i03_fk_rolt025
	on "fobos".rolt025
		(n25_usuario)
	in idxdbs;

create index "fobos".i04_fk_rolt025
	on "fobos".rolt025
		(n25_compania, n25_codigo_arch, n25_tipo_arch, n25_tipo_codigo,
		 n25_sub_tipo)
	in idxdbs;


alter table "fobos".rolt025
	add constraint
		primary key (n25_compania, n25_codigo_arch, n25_tipo_arch,
				n25_tipo_emp_rel, n25_tipo)
			constraint "fobos".pk_rolt025;

alter table "fobos".rolt025
	add constraint
		(foreign key (n25_compania, n25_codigo_arch, n25_tipo_arch)
			references "fobos".rolt022
			constraint "fobos".fk_01_rolt025);

alter table "fobos".rolt025
	add constraint
		(foreign key (n25_compania)
			references "fobos".rolt001
			constraint "fobos".fk_02_rolt025);

alter table "fobos".rolt025
	add constraint
		(foreign key (n25_usuario)
			references "fobos".gent005
			constraint "fobos".fk_03_rolt025);

alter table "fobos".rolt025
	add constraint
		(foreign key (n25_compania, n25_codigo_arch, n25_tipo_arch,
				n25_tipo_codigo, n25_sub_tipo)
			references "fobos".rolt025
			constraint "fobos".fk_04_rolt025);


insert into rolt025
	values (1, 4, 'ENT', '2', 'PRI',
		'EMPRESA PRIVADA - SOCIEDADES / COMPANIAS', null, null,
		'FOBOS', current);

insert into rolt025
	values (1, 4, 'ENT', '06', 'PRI', 'CODIGO DEL TRABAJO - CT', '2', 'PRI',
		'FOBOS', current);


commit work;
