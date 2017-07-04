alter table "fobos".cxpt002 drop constraint "fobos".fk_10_cxpt002;

drop table cxpt006;

begin work;

create table "fobos".cxpt006
	(

		p06_compania		integer			not null,
		p06_cod_bco_tra		char(2)			not null,
		p06_banco		integer			not null,
		p06_estado		char(1)			not null,
		p06_usuario		varchar(10,5)		not null,
		p06_fecing		datetime year to second	not null,

		check (p06_estado in ("A", "B"))
			constraint "fobos".ck_01_cxpt006

	) in datadbs lock mode row;

revoke all on "fobos".cxpt006 from "public";

create unique index "fobos".i01_pk_cxpt006
	on "fobos".cxpt006
		(p06_compania, p06_cod_bco_tra, p06_banco)
	in idxdbs;

create index "fobos".i01_fk_cxpt006
	on "fobos".cxpt006
		(p06_banco)
	in idxdbs;

create index "fobos".i02_fk_cxpt006
	on "fobos".cxpt006
		(p06_usuario)
	in idxdbs;

alter table "fobos".cxpt006
	add constraint
		primary key (p06_compania, p06_cod_bco_tra, p06_banco)
			constraint "fobos".pk_cxpt006;

alter table "fobos".cxpt006
	add constraint
		(foreign key (p06_banco)
			references "fobos".gent008
			constraint "fobos".fk_01_cxpt006);

alter table "fobos".cxpt006
	add constraint
		(foreign key (p06_usuario)
			references "fobos".gent005
			constraint "fobos".fk_02_cxpt006);

commit work;
