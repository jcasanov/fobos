create table "fobos".srit018
	(

		s18_compania		integer			not null,
		s18_sec_tran		char(2)			not null,
		s18_cod_ident		char(1)			not null,
		s18_tipo_tran		smallint		not null

	) in datadbs lock mode row;

revoke all on "fobos".srit018 from "public";


create unique index "fobos".i01_pk_srit018
	on "fobos".srit018
		(s18_compania, s18_sec_tran, s18_cod_ident, s18_tipo_tran)
		in idxdbs;

create index "fobos".i01_fk_srit018
	on "fobos".srit018 (s18_compania, s18_sec_tran, s18_cod_ident)
		in idxdbs;

create index "fobos".i02_fk_srit018
	on "fobos".srit018 (s18_compania, s18_tipo_tran) in idxdbs;


alter table "fobos".srit018
	add constraint
		primary key
			(s18_compania, s18_sec_tran, s18_cod_ident,
				s18_tipo_tran)
			constraint pk_srit018;

alter table "fobos".srit018
	add constraint (foreign key (s18_compania, s18_sec_tran, s18_cod_ident)
			references "fobos".srit003
			constraint fk_01_srit018);

alter table "fobos".srit018
	add constraint (foreign key (s18_compania, s18_tipo_tran)
			references "fobos".srit005
			constraint fk_02_srit018);
