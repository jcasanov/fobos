create table "fobos".srit003
	(
		s03_compania		integer			not null,
		s03_codigo		char(2)			not null,
		s03_cod_ident		char(1)			not null,
		s03_usuario		varchar(10,5)		not null,
		s03_fecing		datetime year to second	not null,

		check (s03_cod_ident in ('R', 'C', 'P', 'F', '0'))
			constraint "fobos".ck_01_srit003

	) in datadbs lock mode row;

revoke all on "fobos".srit003 from "public";


create unique index "fobos".i01_pk_srit003
	on "fobos".srit003 (s03_compania, s03_codigo, s03_cod_ident) in idxdbs;

create index "fobos".i01_fk_srit003
	on "fobos".srit003 (s03_compania) in idxdbs;

create index "fobos".i02_fk_srit003 on "fobos".srit003 (s03_usuario) in idxdbs;


alter table "fobos".srit003
	add constraint
		primary key (s03_compania, s03_codigo, s03_cod_ident)
			constraint pk_srit003;

alter table "fobos".srit003
	add constraint (foreign key (s03_compania) references "fobos".srit000
			constraint fk_01_srit003);

alter table "fobos".srit003
	add constraint (foreign key (s03_usuario) references "fobos".gent005
			constraint fk_02_srit003);
