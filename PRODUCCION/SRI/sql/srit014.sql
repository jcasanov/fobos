create table "fobos".srit014
	(

		s14_compania		integer			not null,
		s14_codigo		char(6)			not null,
		s14_porcentaje_ret	decimal(5,2)		not null,
		s14_concepto_ret	varchar(200,100)	not null,
		s14_fecha_ini_porc	date			not null,
		s14_fecha_fin_porc	date,
		s14_ingresa_proc	char(1)			not null,
		s14_usuario		varchar(10,5)		not null,
		s14_fecing		datetime year to second	not null,

		check (s14_ingresa_proc in ('S', 'N'))
			constraint "fobos".ck_01_srit014

	) in datadbs lock mode row;

revoke all on "fobos".srit014 from "public";


create unique index "fobos".i01_pk_srit014
	on "fobos".srit014 (s14_compania, s14_codigo, s14_porcentaje_ret)
		in idxdbs;

create index "fobos".i01_fk_srit014
	on "fobos".srit014 (s14_compania) in idxdbs;

create index "fobos".i02_fk_srit014 on "fobos".srit014 (s14_usuario) in idxdbs;


alter table "fobos".srit014
	add constraint
		primary key (s14_compania, s14_codigo, s14_porcentaje_ret)
			constraint pk_srit014;

alter table "fobos".srit014
	add constraint
		(foreign key (s14_compania)
			references "fobos".srit000
			constraint "fobos".fk_01_srit014);

alter table "fobos".srit014
	add constraint
		(foreign key (s14_usuario)
			references "fobos".gent005
			constraint "fobos".fk_02_srit014);
