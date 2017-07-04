create table "fobos".srit004
	(

		s04_compania		integer			not null,
		s04_codigo		smallint		not null,
		s04_descripcion		varchar(30,15)		not null,
		s04_fecha_vig		date,
		s04_usuario		varchar(10,5)		not null,
		s04_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".srit004 from "public";


create unique index "fobos".i01_pk_srit004
	on "fobos".srit004 (s04_compania, s04_codigo) in idxdbs;

create index "fobos".i01_fk_srit004
	on "fobos".srit004 (s04_compania) in idxdbs;

create index "fobos".i02_fk_srit004 on "fobos".srit004 (s04_usuario) in idxdbs;


alter table "fobos".srit004
	add constraint
		primary key (s04_compania, s04_codigo) constraint pk_srit004;

alter table "fobos".srit004
	add constraint (foreign key (s04_compania) references "fobos".srit000
			constraint fk_01_srit004);

alter table "fobos".srit004
	add constraint (foreign key (s04_usuario) references "fobos".gent005
			constraint fk_02_srit004);
