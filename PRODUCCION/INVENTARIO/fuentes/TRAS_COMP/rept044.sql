drop table rept044;

begin work;

create table "fobos".rept044

	(

		r44_compania		integer			not null,
		r44_localidad		smallint		not null,
		r44_traspaso		integer			not null,
		r44_secuencia		integer			not null,
		r44_bodega_ori		char(2)			not null,
		r44_item_ori		char(15)		not null,
		r44_desc_ori		varchar(70,20)		not null,
		r44_stock_ori		decimal(8,2)		not null,
		r44_costo_ori		decimal(11,2)		not null,
		r44_bodega_tra		char(2)			not null,
		r44_item_tra		char(15)		not null,
		r44_desc_tra		varchar(70,20)		not null,
		r44_cant_tra		decimal(8,2)		not null,
		r44_stock_tra		decimal(8,2)		not null,
		r44_costo_tra		decimal(11,2)		not null,
		r44_sto_ant_tra		decimal(8,2)		not null,
		r44_cos_ant_tra		decimal(11,2)		not null,
		r44_division_t		char(5)			not null,
		r44_nom_div_t		varchar(30,15)		not null,
		r44_sub_linea_t		char(2)			not null,
		r44_desc_sub_t		varchar(35,20)		not null,
		r44_cod_grupo_t		char(4)			not null,
		r44_desc_grupo_t	varchar(40,20)		not null,
		r44_cod_clase_t		char(8)			not null,
		r44_desc_clase_t	varchar(50,20)		not null,
		r44_marca_t		char(6)			not null,
		r44_desc_marca_t	varchar(35,20)		not null,
		r44_usuario		varchar(10,5)		not null,
		r44_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".rept044 from "public";

create unique index "fobos".i01_pk_rept044
	on "fobos".rept044
		(r44_compania, r44_localidad, r44_traspaso, r44_secuencia)
	in idxdbs;

create index "fobos".i01_fk_rept044
	on "fobos".rept044
		(r44_compania, r44_localidad, r44_traspaso)
	in idxdbs;

create index "fobos".i02_fk_rept044
	on "fobos".rept044
		(r44_compania, r44_bodega_ori)
	in idxdbs;

create index "fobos".i03_fk_rept044
	on "fobos".rept044
		(r44_compania, r44_item_ori)
	in idxdbs;

create index "fobos".i04_fk_rept044
	on "fobos".rept044
		(r44_compania, r44_bodega_tra)
	in idxdbs;

create index "fobos".i05_fk_rept044
	on "fobos".rept044
		(r44_compania, r44_item_tra)
	in idxdbs;

create index "fobos".i06_fk_rept044
	on "fobos".rept044
		(r44_compania, r44_division_t)
	in idxdbs;

create index "fobos".i07_fk_rept044
	on "fobos".rept044
		(r44_compania, r44_division_t, r44_sub_linea_t)
	in idxdbs;

create index "fobos".i08_fk_rept044
	on "fobos".rept044
		(r44_compania, r44_division_t, r44_sub_linea_t, r44_cod_grupo_t)
	in idxdbs;

create index "fobos".i09_fk_rept044
	on "fobos".rept044
		(r44_compania, r44_division_t, r44_sub_linea_t, r44_cod_grupo_t,
		 r44_cod_clase_t)
	in idxdbs;

create index "fobos".i10_fk_rept044
	on "fobos".rept044
		(r44_compania, r44_marca_t)
	in idxdbs;

alter table "fobos".rept044
	add constraint
		primary key (r44_compania, r44_localidad, r44_traspaso,
				r44_secuencia)
			constraint "fobos".pk_rept044;

alter table "fobos".rept044
	add constraint
		(foreign key (r44_compania, r44_localidad, r44_traspaso)
			references "fobos".rept043
			constraint "fobos".fk_01_rept044);

alter table "fobos".rept044
	add constraint
		(foreign key (r44_compania, r44_bodega_ori)
			references "fobos".rept002
			constraint "fobos".fk_02_rept044);

alter table "fobos".rept044
	add constraint
		(foreign key (r44_compania, r44_item_ori)
			references "fobos".rept010
			constraint "fobos".fk_03_rept044);

alter table "fobos".rept044
	add constraint
		(foreign key (r44_compania, r44_bodega_tra)
			references "fobos".rept002
			constraint "fobos".fk_04_rept044);

alter table "fobos".rept044
	add constraint
		(foreign key (r44_compania, r44_item_tra)
			references "fobos".rept010
			constraint "fobos".fk_05_rept044);

alter table "fobos".rept044
	add constraint
		(foreign key (r44_compania, r44_division_t)
			references "fobos".rept003
			constraint "fobos".fk_06_rept044);

alter table "fobos".rept044
	add constraint
		(foreign key (r44_compania, r44_division_t, r44_sub_linea_t)
			references "fobos".rept070
			constraint "fobos".fk_07_rept044);

alter table "fobos".rept044
	add constraint
		(foreign key (r44_compania, r44_division_t, r44_sub_linea_t,
				r44_cod_grupo_t)
			references "fobos".rept071
			constraint "fobos".fk_08_rept044);

alter table "fobos".rept044
	add constraint
		(foreign key (r44_compania, r44_division_t, r44_sub_linea_t,
				r44_cod_grupo_t, r44_cod_clase_t)
			references "fobos".rept072
			constraint "fobos".fk_09_rept044);

alter table "fobos".rept044
	add constraint
		(foreign key (r44_compania, r44_marca_t)
			references "fobos".rept073
			constraint "fobos".fk_10_rept044);

commit work;
