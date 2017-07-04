create table "fobos".srit008
	(

		s08_compania		integer			not null,
		s08_codigo		smallint		not null,
		s08_porcentaje		decimal(5,2)		not null,
		s08_fecha_ini		date			not null,
		s08_fecha_fin		date,
		s08_usuario		varchar(10,5)		not null,
		s08_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".srit008 from "public";


create unique index "fobos".i01_pk_srit008
	on "fobos".srit008 (s08_compania, s08_codigo) in idxdbs;

create index "fobos".i01_fk_srit008
	on "fobos".srit008 (s08_compania) in idxdbs;

create index "fobos".i02_fk_srit008 on "fobos".srit008 (s08_usuario) in idxdbs;


alter table "fobos".srit008
	add constraint
		primary key (s08_compania, s08_codigo)
			constraint "fobos".pk_srit008;

alter table "fobos".srit008
	add constraint
		(foreign key (s08_compania)
			references "fobos".srit000
			constraint "fobos".fk_01_srit008);

alter table "fobos".srit008
	add constraint
		(foreign key (s08_usuario)
			references "fobos".gent005
			constraint "fobos".fk_02_srit008);
