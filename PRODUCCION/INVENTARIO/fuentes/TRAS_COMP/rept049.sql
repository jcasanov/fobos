drop table rept049;

begin work;

create table "fobos".rept049

	(

		r49_compania		integer			not null,
		r49_localidad		smallint		not null,
		r49_composicion		integer			not null,
		r49_item_comp		char(15)		not null,
		r49_sec_carga		integer			not null,
		r49_numero_oc		integer			not null,
		r49_costo_oc		decimal(11,2)		not null,
		r49_cant_unid		integer			not null,
		r49_usuario		varchar(10,5)		not null,
		r49_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".rept049 from "public";

create unique index "fobos".i01_pk_rept049
	on "fobos".rept049
		(r49_compania, r49_localidad, r49_composicion, r49_item_comp,
		 r49_sec_carga, r49_numero_oc)
	in idxdbs;

create index "fobos".i01_fk_rept049
	on "fobos".rept049
		(r49_compania, r49_localidad, r49_numero_oc)
	in idxdbs;

create index "fobos".i02_fk_rept049
	on "fobos".rept049
		(r49_compania, r49_localidad, r49_composicion, r49_item_comp,
		 r49_sec_carga)
	in idxdbs;

create index "fobos".i03_fk_rept049
	on "fobos".rept049
		(r49_compania, r49_item_comp)
	in idxdbs;

create index "fobos".i04_fk_rept049
	on "fobos".rept049
		(r49_usuario)
	in idxdbs;

alter table "fobos".rept049
	add constraint
		primary key (r49_compania, r49_localidad, r49_composicion,
				r49_item_comp, r49_sec_carga, r49_numero_oc)
			constraint "fobos".pk_rept049;

alter table "fobos".rept049
	add constraint
		(foreign key (r49_compania, r49_localidad, r49_numero_oc)
			references "fobos".ordt010
			constraint "fobos".fk_01_rept049);

alter table "fobos".rept049
	add constraint
		(foreign key (r49_compania, r49_localidad, r49_composicion,
				r49_item_comp, r49_sec_carga)
			references "fobos".rept048
			constraint "fobos".fk_02_rept049);

alter table "fobos".rept049
	add constraint
		(foreign key (r49_compania, r49_item_comp)
			references "fobos".rept010
			constraint "fobos".fk_03_rept049);

alter table "fobos".rept049
	add constraint
		(foreign key (r49_usuario)
			references "fobos".gent005
			constraint "fobos".fk_04_rept049);

commit work;
