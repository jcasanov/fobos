create table "fobos".srit010
	(

		s10_compania		integer			not null,
		s10_codigo		smallint		not null,
		s10_porcentaje_ice	decimal(5,2)		not null,
		s10_codigo_impto	varchar(15,6)		not null,
		s10_descripcion		varchar(60,30)		not null,
		s10_fecha_ini		date			not null,
		s10_fecha_fin		date,
		s10_usuario		varchar(10,5)		not null,
		s10_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".srit010 from "public";


create unique index "fobos".i01_pk_srit010
	on "fobos".srit010 (s10_compania, s10_codigo, s10_porcentaje_ice,
				s10_codigo_impto) in idxdbs;

create index "fobos".i01_fk_srit010
	on "fobos".srit010 (s10_compania) in idxdbs;

{--
create index "fobos".i02_fk_srit010
	on "fobos".srit010 (s10_compania, s10_codigo_impto) in idxdbs;
--}

create index "fobos".i03_fk_srit010 on "fobos".srit010 (s10_usuario) in idxdbs;


alter table "fobos".srit010
	add constraint
		primary key (s10_compania, s10_codigo, s10_porcentaje_ice,
				s10_codigo_impto)
			constraint pk_srit010;

alter table "fobos".srit010
	add constraint
		(foreign key (s10_compania)
			references "fobos".srit000
			constraint "fobos".fk_01_srit010);

{--
alter table "fobos".srit010
	add constraint
		(foreign key (s10_compania, s10_codigo_impto)
			references "fobos".ordt003
			constraint "fobos".fk_02_srit010);
--}

alter table "fobos".srit010
	add constraint
		(foreign key (s10_usuario)
			references "fobos".gent005
			constraint "fobos".fk_03_srit010);
