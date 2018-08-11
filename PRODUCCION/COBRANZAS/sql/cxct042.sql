begin work;

create table "fobos".cxct042
	(

		z42_compania		integer		not null,
		z42_localidad		smallint	not null,
		z42_codcli		integer		not null,
		z42_tipo_doc		char(2)		not null,
		z42_num_doc		char(15)	not null,
		z42_dividendo		smallint	not null,
		z42_banco		smallint	not null,
		z42_num_cta		char(15)	not null,
		z42_num_cheque		char(15)	not null,
		z42_secuencia		smallint	not null

	) in datadbs lock mode row;

revoke all on "fobos".cxct042 from "public";


create unique index "fobos".i01_pk_cxct042
	on "fobos".cxct042
		(z42_compania, z42_localidad, z42_codcli, z42_tipo_doc,
			z42_num_doc, z42_dividendo, z42_banco, z42_num_cta,
			z42_num_cheque, z42_secuencia)
	in idxdbs;

create index "fobos".i01_fk_cxct042
	on "fobos".cxct042
		(z42_compania, z42_localidad, z42_codcli, z42_tipo_doc,
			z42_num_doc, z42_dividendo)
	in idxdbs;

create index "fobos".i02_fk_cxct042
	on "fobos".cxct042
		(z42_compania, z42_localidad, z42_banco, z42_num_cta,
			z42_num_cheque, z42_secuencia)
	in idxdbs;


alter table "fobos".cxct042
	add constraint
		primary key
			(z42_compania, z42_localidad, z42_codcli, z42_tipo_doc,
				z42_num_doc, z42_dividendo, z42_banco,
				z42_num_cta, z42_num_cheque, z42_secuencia)
		constraint "fobos".pk_cxct042;

alter table "fobos".cxct042
	add constraint
		(foreign key 
			(z42_compania, z42_localidad, z42_codcli, z42_tipo_doc,
				z42_num_doc, z42_dividendo)
		references "fobos".cxct020
		constraint "fobos".fk_01_cxct042);

alter table "fobos".cxct042
	add constraint
		(foreign key 
			(z42_compania, z42_localidad, z42_banco, z42_num_cta,
				z42_num_cheque, z42_secuencia)
		references "fobos".cajt012
		constraint "fobos".fk_02_cxct042);

commit work;
