drop table rept047;

begin work;

create table "fobos".rept047

	(

		r47_compania		integer			not null,
		r47_localidad		smallint		not null,
		r47_composicion		integer			not null,
		r47_item_comp		char(15)		not null,
		r47_bodega_part		char(2)			not null,
		r47_item_part		char(15)		not null,
		r47_desc_part		varchar(70,20)		not null,
		r47_costo_part		decimal(11,2)		not null,
		r47_cantidad		decimal(8,2)		not null,
		r47_division_p		char(5)			not null,
		r47_nom_div_p		varchar(30,15)		not null,
		r47_sub_linea_p		char(2)			not null,
		r47_desc_sub_p		varchar(35,20)		not null,
		r47_cod_grupo_p		char(4)			not null,
		r47_desc_grupo_p	varchar(40,20)		not null,
		r47_cod_clase_p		char(8)			not null,
		r47_desc_clase_p	varchar(50,20)		not null,
		r47_marca_p		char(6)			not null,
		r47_desc_marca_p	varchar(35,20)		not null

	) in datadbs lock mode row;

revoke all on "fobos".rept047 from "public";

create unique index "fobos".i01_pk_rept047
	on "fobos".rept047
		(r47_compania, r47_localidad, r47_composicion, r47_item_comp,
		 r47_bodega_part, r47_item_part)
	in idxdbs;

create index "fobos".i01_fk_rept047
	on "fobos".rept047
		(r47_compania, r47_localidad, r47_composicion, r47_item_comp)
	in idxdbs;

create index "fobos".i02_fk_rept047
	on "fobos".rept047
		(r47_compania, r47_item_comp)
	in idxdbs;

create index "fobos".i03_fk_rept047
	on "fobos".rept047
		(r47_compania, r47_bodega_part)
	in idxdbs;

create index "fobos".i04_fk_rept047
	on "fobos".rept047
		(r47_compania, r47_item_part)
	in idxdbs;

create index "fobos".i05_fk_rept047
	on "fobos".rept047
		(r47_compania, r47_division_p)
	in idxdbs;

create index "fobos".i06_fk_rept047
	on "fobos".rept047
		(r47_compania, r47_division_p, r47_sub_linea_p)
	in idxdbs;

create index "fobos".i07_fk_rept047
	on "fobos".rept047
		(r47_compania, r47_division_p, r47_sub_linea_p, r47_cod_grupo_p)
	in idxdbs;

create index "fobos".i08_fk_rept047
	on "fobos".rept047
		(r47_compania, r47_division_p, r47_sub_linea_p, r47_cod_grupo_p,
		 r47_cod_clase_p)
	in idxdbs;

create index "fobos".i09_fk_rept047
	on "fobos".rept047
		(r47_compania, r47_marca_p)
	in idxdbs;

alter table "fobos".rept047
	add constraint
		primary key (r47_compania, r47_localidad, r47_composicion,
				r47_item_comp, r47_bodega_part, r47_item_part)
			constraint "fobos".pk_rept047;

alter table "fobos".rept047
	add constraint
		(foreign key (r47_compania, r47_localidad, r47_composicion,
				r47_item_comp)
			references "fobos".rept046
			constraint "fobos".fk_01_rept047);

alter table "fobos".rept047
	add constraint
		(foreign key (r47_compania, r47_item_comp)
			references "fobos".rept010
			constraint "fobos".fk_02_rept047);

alter table "fobos".rept047
	add constraint
		(foreign key (r47_compania, r47_bodega_part)
			references "fobos".rept002
			constraint "fobos".fk_03_rept047);

alter table "fobos".rept047
	add constraint
		(foreign key (r47_compania, r47_item_part)
			references "fobos".rept010
			constraint "fobos".fk_04_rept047);

alter table "fobos".rept047
	add constraint
		(foreign key (r47_compania, r47_division_p)
			references "fobos".rept003
			constraint "fobos".fk_05_rept047);

alter table "fobos".rept047
	add constraint
		(foreign key (r47_compania, r47_division_p, r47_sub_linea_p)
			references "fobos".rept070
			constraint "fobos".fk_06_rept047);

alter table "fobos".rept047
	add constraint
		(foreign key (r47_compania, r47_division_p, r47_sub_linea_p,
				r47_cod_grupo_p)
			references "fobos".rept071
			constraint "fobos".fk_07_rept047);

alter table "fobos".rept047
	add constraint
		(foreign key (r47_compania, r47_division_p, r47_sub_linea_p,
				r47_cod_grupo_p, r47_cod_clase_p)
			references "fobos".rept072
			constraint "fobos".fk_08_rept047);

alter table "fobos".rept047
	add constraint
		(foreign key (r47_compania, r47_marca_p)
			references "fobos".rept073
			constraint "fobos".fk_09_rept047);

commit work;
