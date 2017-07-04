create table "fobos".srit002
	(

		s02_compania		integer			not null,
		s02_ano			smallint		not null,
		s02_mes_num		char(2)			not null,
		s02_mes_nom		varchar(11,10)		not null,
		s02_usuario		varchar(10,5)		not null,
		s02_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".srit002 from "public";


create unique index "fobos".i01_pk_srit002
	on "fobos".srit002 (s02_compania, s02_ano, s02_mes_num) in idxdbs;

create index "fobos".i01_fk_srit002
	on "fobos".srit002 (s02_compania) in idxdbs;

create index "fobos".i02_fk_srit002 on "fobos".srit002 (s02_usuario) in idxdbs;


alter table "fobos".srit002
	add constraint primary key (s02_compania, s02_ano, s02_mes_num)
			constraint pk_srit002;

alter table "fobos".srit002
	add constraint (foreign key (s02_compania) references "fobos".srit000
			constraint fk_01_srit002);

alter table "fobos".srit002
	add constraint (foreign key (s02_usuario) references "fobos".gent005
			constraint fk_02_srit002);
