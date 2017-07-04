drop table cxpt032;

begin work;


create table "fobos".cxpt032
	(

		p32_compania		integer			not null,
		p32_localidad		smallint		not null,
		p32_num_ret		integer			not null,
		p32_tipo_doc		char(2)			not null,
		p32_secuencia		smallint		not null

	) in datadbs lock mode row;

revoke all on "fobos".cxpt032 from "public";


create unique index "fobos".i01_pk_cxpt032 on "fobos".cxpt032
	(p32_compania, p32_localidad, p32_num_ret, p32_tipo_doc, p32_secuencia)
	in idxdbs;

create index "fobos".i01_fk_cxpt032 on "fobos".cxpt032
	(p32_compania, p32_localidad, p32_num_ret) in idxdbs;

create index "fobos".i02_fk_cxpt032 on "fobos".cxpt032
	(p32_compania, p32_localidad, p32_tipo_doc, p32_secuencia) in idxdbs;


alter table "fobos".cxpt032
	add constraint
		primary key (p32_compania, p32_localidad, p32_num_ret,
				p32_tipo_doc, p32_secuencia)
			constraint "fobos".pk_cxpt032;

alter table "fobos".cxpt032
	add constraint (foreign key (p32_compania, p32_localidad, p32_num_ret)
			references "fobos".cxpt027
			constraint "fobos".fk_01_cxpt032);

alter table "fobos".cxpt032
	add constraint (foreign key (p32_compania, p32_localidad, p32_tipo_doc,
					p32_secuencia)
			references "fobos".gent037
			constraint "fobos".fk_02_cxpt032);

commit work;
