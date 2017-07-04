drop table cxct061;

begin work;

create table "fobos".cxct061
	(

		z61_compania		integer			not null,
		z61_localidad		smallint		not null,
		z61_num_pagos		smallint		not null,
		z61_max_pagos		smallint		not null,
		z61_intereses		decimal(5,2)		not null,
		z61_dia_entre_pago	smallint		not null,
		z61_max_entre_pago	smallint		not null,
		z61_credito_max		smallint default 0	not null,
		z61_credito_min		smallint default 0	not null,
		z61_usuario		varchar(10,5)		not null,
		z61_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".cxct061 from "public";


create unique index "fobos".i01_pk_cxct061
	on "fobos".cxct061 (z61_compania, z61_localidad) in idxdbs;

create index "fobos".i01_fk_cxct061
	on "fobos".cxct061 (z61_compania) in idxdbs;

create index "fobos".i02_fk_cxct061
	on "fobos".cxct061 (z61_usuario) in idxdbs;


alter table "fobos".cxct061
	add constraint
		primary key (z61_compania, z61_localidad)
			constraint "fobos".pk_cxct061;

alter table "fobos".cxct061
	add constraint
		(foreign key (z61_compania)
			references "fobos".cxct000
			constraint "fobos".fk_01_cxct061);

alter table "fobos".cxct061
	add constraint
		(foreign key (z61_usuario)
			references "fobos".gent005
			constraint "fobos".fk_02_cxct061);


insert into cxct061
	select z00_compania, g02_localidad, 1, 300, 0, 30, 360, 0, 0, 'FOBOS',
		current
		from cxct000, gent002
		where g02_compania = z00_compania
		  and g02_matriz   = 'S';

commit work;
