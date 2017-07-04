drop table srit024;

begin work;

create table "fobos".srit024
	(

		s24_compania		integer			not null,
		s24_codigo		smallint		not null,
		s24_porcentaje_ice	decimal(5,2)		not null,
		s24_codigo_impto	varchar(15,6)		not null,
		s24_tipo_orden		integer			not null,
		s24_aux_cont		char(12),
		s24_usuario		varchar(10,5)		not null,
		s24_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".srit024 from "public";


create unique index "fobos".i01_pk_srit024 on "fobos".srit024
	(s24_compania, s24_codigo, s24_porcentaje_ice, s24_codigo_impto,
	 s24_tipo_orden)
	in idxdbs;

create index "fobos".i01_fk_srit024 on "fobos".srit024
	(s24_compania, s24_codigo, s24_porcentaje_ice, s24_codigo_impto)
	in idxdbs;

create index "fobos".i02_fk_srit024 on "fobos".srit024
	(s24_tipo_orden) in idxdbs;

create index "fobos".i03_fk_srit024 on "fobos".srit024 (s24_compania) in idxdbs;

create index "fobos".i04_fk_srit024 on "fobos".srit024
	(s24_compania, s24_aux_cont) in idxdbs;

create index "fobos".i05_fk_srit024 on "fobos".srit024 (s24_usuario) in idxdbs;


alter table "fobos".srit024
	add constraint
		primary key (s24_compania, s24_codigo, s24_porcentaje_ice,
				s24_codigo_impto, s24_tipo_orden)
			constraint "fobos".pk_srit024;

alter table "fobos".srit024
	add constraint
		(foreign key (s24_compania, s24_codigo, s24_porcentaje_ice,
				s24_codigo_impto)
			references "fobos".srit010
			constraint "fobos".fk_01_srit024);

alter table "fobos".srit024
	add constraint
		(foreign key (s24_tipo_orden)
			references "fobos".ordt001
			constraint "fobos".fk_02_srit024);

alter table "fobos".srit024
	add constraint
		(foreign key (s24_compania)
			references "fobos".srit000
			constraint "fobos".fk_03_srit024);

alter table "fobos".srit024
	add constraint
		(foreign key (s24_compania, s24_aux_cont)
			references "fobos".ctbt010
			constraint "fobos".fk_04_srit024);

alter table "fobos".srit024
	add constraint
		(foreign key (s24_usuario)
			references "fobos".gent005
			constraint "fobos".fk_05_srit024);

commit work;
