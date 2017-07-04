drop table rept048;

begin work;

create table "fobos".rept048

	(

		r48_compania		integer			not null,
		r48_localidad		smallint		not null,
		r48_composicion		integer			not null,
		r48_item_comp		char(15)		not null,
		r48_sec_carga		integer			not null,
		r48_estado		char(1)			not null,
		r48_bodega_comp		char(2)			not null,
		r48_carg_stock		decimal(8,2)		not null,
		r48_costo_inv		decimal(11,2)		not null,
		r48_costo_oc		decimal(11,2)		not null,
		r48_costo_mo		decimal(11,2)		not null,
		r48_costo_comp		decimal(11,2)		not null,
		r48_referencia		varchar(60,40)		not null,
		r48_usu_elimin		varchar(10,5),
		r48_fec_elimin		datetime year to second,
		r48_usu_cierre		varchar(10,5),
		r48_fec_cierre		datetime year to second,
		r48_usuario		varchar(10,5)		not null,
		r48_fecing		datetime year to second	not null,

		check (r48_estado	in ('C', 'P', 'E'))
			constraint "fobos".ck_01_rept048

	) in datadbs lock mode row;

revoke all on "fobos".rept048 from "public";

create unique index "fobos".i01_pk_rept048
	on "fobos".rept048
		(r48_compania, r48_localidad, r48_composicion, r48_item_comp,
		 r48_sec_carga)
	in idxdbs;

create index "fobos".i01_fk_rept048
	on "fobos".rept048
		(r48_compania, r48_localidad, r48_composicion, r48_item_comp)
	in idxdbs;

create index "fobos".i02_fk_rept048
	on "fobos".rept048
		(r48_compania, r48_item_comp)
	in idxdbs;

create index "fobos".i03_fk_rept048
	on "fobos".rept048
		(r48_compania, r48_bodega_comp)
	in idxdbs;

create index "fobos".i04_fk_rept048
	on "fobos".rept048
		(r48_usu_elimin)
	in idxdbs;

create index "fobos".i05_fk_rept048
	on "fobos".rept048
		(r48_usu_cierre)
	in idxdbs;

create index "fobos".i06_fk_rept048
	on "fobos".rept048
		(r48_usuario)
	in idxdbs;

alter table "fobos".rept048
	add constraint
		primary key (r48_compania, r48_localidad, r48_composicion,
				r48_item_comp, r48_sec_carga)
			constraint "fobos".pk_rept048;

alter table "fobos".rept048
	add constraint
		(foreign key (r48_compania, r48_localidad, r48_composicion,
				r48_item_comp)
			references "fobos".rept046
			constraint "fobos".fk_01_rept048);

alter table "fobos".rept048
	add constraint
		(foreign key (r48_compania, r48_item_comp)
			references "fobos".rept010
			constraint "fobos".fk_02_rept048);

alter table "fobos".rept048
	add constraint
		(foreign key (r48_compania, r48_bodega_comp)
			references "fobos".rept002
			constraint "fobos".fk_03_rept048);

alter table "fobos".rept048
	add constraint
		(foreign key (r48_usu_elimin)
			references "fobos".gent005
			constraint "fobos".fk_04_rept048);

alter table "fobos".rept048
	add constraint
		(foreign key (r48_usu_cierre)
			references "fobos".gent005
			constraint "fobos".fk_05_rept048);

alter table "fobos".rept048
	add constraint
		(foreign key (r48_usuario)
			references "fobos".gent005
			constraint "fobos".fk_06_rept048);

commit work;
