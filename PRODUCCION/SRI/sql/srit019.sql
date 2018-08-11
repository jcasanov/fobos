create table "fobos".srit019
	(

		s19_compania		integer			not null,
		s19_sec_tran		char(2)			not null,
		s19_cod_ident		char(1)			not null,
		s19_tipo_comp		smallint		not null,
		s19_tipo_doc		char(2)			not null

	) in datadbs lock mode row;

revoke all on "fobos".srit019 from "public";


create unique index "fobos".i01_pk_srit019
	on "fobos".srit019
		(s19_compania, s19_sec_tran, s19_cod_ident, s19_tipo_comp,
			s19_tipo_doc)
		in idxdbs;

create index "fobos".i01_fk_srit019
	on "fobos".srit019 (s19_compania, s19_sec_tran, s19_cod_ident)
		in idxdbs;

create index "fobos".i02_fk_srit019
	on "fobos".srit019 (s19_compania, s19_tipo_comp) in idxdbs;

create index "fobos".i03_fk_srit019
	on "fobos".srit019 (s19_tipo_doc) in idxdbs;


alter table "fobos".srit019
	add constraint
		primary key
			(s19_compania, s19_sec_tran, s19_cod_ident,
				s19_tipo_comp, s19_tipo_doc)
			constraint pk_srit019;

alter table "fobos".srit019
	add constraint (foreign key (s19_compania, s19_sec_tran, s19_cod_ident)
			references "fobos".srit003
			constraint fk_01_srit019);

alter table "fobos".srit019
	add constraint (foreign key (s19_compania, s19_tipo_comp)
			references "fobos".srit004
			constraint fk_02_srit019);

alter table "fobos".srit019
	add constraint (foreign key (s19_tipo_doc)
			references "fobos".cxct004
			constraint fk_03_srit019);
