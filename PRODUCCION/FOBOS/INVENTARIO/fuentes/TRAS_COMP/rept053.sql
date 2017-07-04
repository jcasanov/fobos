drop table rept053;

begin work;

create table "fobos".rept053

	(

		r53_compania		integer			not null,
		r53_localidad		smallint		not null,
		r53_composicion		integer			not null,
		r53_item_comp		char(15)		not null,
		r53_sec_carga		integer			not null,
		r53_cod_tran		char(2)			not null,
		r53_num_tran		decimal(15,0)		not null,
		r53_usuario		varchar(10,5)		not null,
		r53_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".rept053 from "public";

create unique index "fobos".i01_pk_rept053
	on "fobos".rept053
		(r53_compania, r53_localidad, r53_composicion, r53_item_comp,
		 r53_sec_carga, r53_cod_tran, r53_num_tran)
	in idxdbs;

create index "fobos".i01_fk_rept053
	on "fobos".rept053
		(r53_compania, r53_localidad, r53_cod_tran, r53_num_tran)
	in idxdbs;

create index "fobos".i02_fk_rept053
	on "fobos".rept053
		(r53_compania, r53_localidad, r53_composicion, r53_item_comp,
		 r53_sec_carga)
	in idxdbs;

create index "fobos".i03_fk_rept053
	on "fobos".rept053
		(r53_compania, r53_item_comp)
	in idxdbs;

create index "fobos".i04_fk_rept053
	on "fobos".rept053
		(r53_usuario)
	in idxdbs;

alter table "fobos".rept053
	add constraint
		primary key (r53_compania, r53_localidad, r53_composicion,
				r53_item_comp, r53_sec_carga, r53_cod_tran,
				r53_num_tran)
			constraint "fobos".pk_rept053;

alter table "fobos".rept053
	add constraint
		(foreign key (r53_compania, r53_localidad, r53_cod_tran,
				r53_num_tran)
			references "fobos".rept019
			constraint "fobos".fk_01_rept053);

alter table "fobos".rept053
	add constraint
		(foreign key (r53_compania, r53_localidad, r53_composicion,
				r53_item_comp, r53_sec_carga)
			references "fobos".rept048
			constraint "fobos".fk_02_rept053);

alter table "fobos".rept053
	add constraint
		(foreign key (r53_compania, r53_item_comp)
			references "fobos".rept010
			constraint "fobos".fk_03_rept053);

alter table "fobos".rept053
	add constraint
		(foreign key (r53_usuario)
			references "fobos".gent005
			constraint "fobos".fk_04_rept053);

commit work;
