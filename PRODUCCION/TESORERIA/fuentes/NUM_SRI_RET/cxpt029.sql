--drop table cxpt029;

begin work;


create table "fobos".cxpt029
	(

		p29_compania		integer			not null,
		p29_localidad		smallint		not null,
		p29_num_ret		integer			not null,
		p29_num_sri		char(16)		not null

	) in datadbs lock mode row;

revoke all on "fobos".cxpt029 from "public";


create unique index "fobos".i01_pk_cxpt029 on "fobos".cxpt029
	(p29_compania, p29_localidad, p29_num_ret, p29_num_sri) in idxdbs;

create index "fobos".i01_fk_cxpt029 on "fobos".cxpt029
	(p29_compania, p29_localidad, p29_num_ret) in idxdbs;


alter table "fobos".cxpt029
	add constraint
		primary key (p29_compania, p29_localidad, p29_num_ret,
				p29_num_sri)
			constraint "fobos".pk_cxpt029;

alter table "fobos".cxpt029
	add constraint (foreign key (p29_compania, p29_localidad, p29_num_ret)
			references "fobos".cxpt027
			constraint "fobos".fk_01_cxpt029);

commit work;
