create table "fobos".srit015
	(

		s15_compania		integer			not null,
		s15_codigo		smallint		not null,
		s15_descrip_fid		varchar(60,40)		not null,
		s15_codigo_ret		char(4)			not null,
		s15_fecha_ini		date			not null,
		s15_fecha_fin		date,
		s15_usuario		varchar(10,5)		not null,
		s15_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".srit015 from "public";


create unique index "fobos".i01_pk_srit015
	on "fobos".srit015 (s15_compania, s15_codigo) in idxdbs;

create index "fobos".i01_fk_srit015
	on "fobos".srit015 (s15_compania) in idxdbs;

create index "fobos".i02_fk_srit015 on "fobos".srit015 (s15_usuario) in idxdbs;


alter table "fobos".srit015
	add constraint
		primary key (s15_compania, s15_codigo)
			constraint pk_srit015;

alter table "fobos".srit015
	add constraint
		(foreign key (s15_compania)
			references "fobos".srit000
			constraint "fobos".fk_01_srit015);

alter table "fobos".srit015
	add constraint
		(foreign key (s15_usuario)
			references "fobos".gent005
			constraint "fobos".fk_03_srit015);
