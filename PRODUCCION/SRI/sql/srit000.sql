create table "fobos".srit000
	(

		s00_compania		integer			not null,
		s00_usuario		varchar(10,5)		not null,
		s00_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".srit000 from "public";


create unique index "fobos".i01_pk_srit000
	on "fobos".srit000 (s00_compania) in idxdbs;

create index "fobos".i01_fk_srit000 on "fobos".srit000 (s00_usuario) in idxdbs;


alter table "fobos".srit000
	add constraint primary key (s00_compania) constraint pk_srit000;

alter table "fobos".srit000
	add constraint (foreign key (s00_compania) references "fobos".gent001
			constraint fk_01_srit000);

alter table "fobos".srit000
	add constraint (foreign key (s00_usuario) references "fobos".gent005
			constraint fk_02_srit000);
