begin work;

drop table actt015;

create table "fobos".actt015

	(

		a15_compania		integer			not null,
		a15_codigo_tran		char(2)			not null,
		a15_numero_tran		integer			not null,
		a15_tipo_comp		char(2)			not null,
		a15_num_comp		char(8)			not null,
		a15_usuario		varchar(10,5)		not null,
		a15_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".actt015 from "public";

create unique index "fobos".i01_pk_actt015
	on "fobos".actt015
		(a15_compania, a15_codigo_tran, a15_numero_tran, a15_tipo_comp,
		 a15_num_comp)
	in idxdbs;

create index "fobos".i01_fk_actt015
	on "fobos".actt015
		(a15_compania, a15_codigo_tran, a15_numero_tran)
	in idxdbs;

create index "fobos".i02_fk_actt015
	on "fobos".actt015
		(a15_compania, a15_tipo_comp, a15_num_comp)
	in idxdbs;

create index "fobos".i03_fk_actt015
	on "fobos".actt015
		(a15_usuario)
	in idxdbs;

alter table "fobos".actt015
	add constraint
		primary key (a15_compania, a15_codigo_tran, a15_numero_tran,
				a15_tipo_comp, a15_num_comp)
			constraint "fobos".pk_actt015;

alter table "fobos".actt015
	add constraint
		(foreign key (a15_compania, a15_codigo_tran, a15_numero_tran)
			references "fobos".actt012
			constraint "fobos".fk_01_actt015);

alter table "fobos".actt015
	add constraint
		(foreign key (a15_compania, a15_tipo_comp, a15_num_comp)
			references "fobos".ctbt012
			constraint "fobos".fk_02_actt015);

alter table "fobos".actt015
	add constraint
		(foreign key (a15_usuario)
			references "fobos".gent005
			constraint "fobos".fk_03_actt015);

commit work;
