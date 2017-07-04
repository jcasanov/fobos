drop table rept046;

begin work;

create table "fobos".rept046

	(

		r46_compania		integer			not null,
		r46_localidad		smallint		not null,
		r46_composicion		integer			not null,
		r46_item_comp		char(15)		not null,
		r46_estado		char(1)			not null,
		r46_cod_ventas		smallint		not null,
		r46_desc_comp		varchar(70,20)		not null,
		r46_division_c		char(5)			not null,
		r46_nom_div_c		varchar(30,15)		not null,
		r46_sub_linea_c		char(2)			not null,
		r46_desc_sub_c		varchar(35,20)		not null,
		r46_cod_grupo_c		char(4)			not null,
		r46_desc_grupo_c	varchar(40,20)		not null,
		r46_cod_clase_c		char(8)			not null,
		r46_desc_clase_c	varchar(50,20)		not null,
		r46_marca_c		char(6)			not null,
		r46_desc_marca_c	varchar(35,20)		not null,
		r46_referencia		varchar(60,40)		not null,
		r46_tiene_oc		char(1)			not null,
		r46_usu_modifi		varchar(10,5),
		r46_fec_modifi		datetime year to second,
		r46_usu_cierre		varchar(10,5),
		r46_fec_cierre		datetime year to second,
		r46_usuario		varchar(10,5)		not null,
		r46_fecing		datetime year to second	not null,

		check (r46_estado	in ('C', 'P'))
			constraint "fobos".ck_01_rept046,
		check (r46_tiene_oc	in ('S', 'N'))
			constraint "fobos".ck_02_rept046

	) in datadbs lock mode row;

revoke all on "fobos".rept046 from "public";

create unique index "fobos".i01_pk_rept046
	on "fobos".rept046
		(r46_compania, r46_localidad, r46_composicion, r46_item_comp)
	in idxdbs;

create index "fobos".i01_fk_rept046
	on "fobos".rept046
		(r46_compania)
	in idxdbs;

create index "fobos".i02_fk_rept046
	on "fobos".rept046
		(r46_compania, r46_localidad)
	in idxdbs;

create index "fobos".i03_fk_rept046
	on "fobos".rept046
		(r46_compania, r46_item_comp)
	in idxdbs;

create index "fobos".i04_fk_rept046
	on "fobos".rept046
		(r46_compania, r46_cod_ventas)
	in idxdbs;

create index "fobos".i05_fk_rept046
	on "fobos".rept046
		(r46_compania, r46_division_c)
	in idxdbs;

create index "fobos".i06_fk_rept046
	on "fobos".rept046
		(r46_compania, r46_division_c, r46_sub_linea_c)
	in idxdbs;

create index "fobos".i07_fk_rept046
	on "fobos".rept046
		(r46_compania, r46_division_c, r46_sub_linea_c, r46_cod_grupo_c)
	in idxdbs;

create index "fobos".i08_fk_rept046
	on "fobos".rept046
		(r46_compania, r46_division_c, r46_sub_linea_c, r46_cod_grupo_c,
		 r46_cod_clase_c)
	in idxdbs;

create index "fobos".i09_fk_rept046
	on "fobos".rept046
		(r46_compania, r46_marca_c)
	in idxdbs;

create index "fobos".i10_fk_rept046
	on "fobos".rept046
		(r46_usu_modifi)
	in idxdbs;

create index "fobos".i11_fk_rept046
	on "fobos".rept046
		(r46_usu_cierre)
	in idxdbs;

create index "fobos".i12_fk_rept046
	on "fobos".rept046
		(r46_usuario)
	in idxdbs;

alter table "fobos".rept046
	add constraint
		primary key (r46_compania, r46_localidad, r46_composicion,
				r46_item_comp)
			constraint "fobos".pk_rept046;

alter table "fobos".rept046
	add constraint
		(foreign key (r46_compania)
			references "fobos".rept000
			constraint "fobos".fk_01_rept046);

alter table "fobos".rept046
	add constraint
		(foreign key (r46_compania, r46_localidad)
			references "fobos".gent002
			constraint "fobos".fk_02_rept046);

alter table "fobos".rept046
	add constraint
		(foreign key (r46_compania, r46_item_comp)
			references "fobos".rept010
			constraint "fobos".fk_03_rept046);

alter table "fobos".rept046
	add constraint
		(foreign key (r46_compania, r46_cod_ventas)
			references "fobos".rept001
			constraint "fobos".fk_04_rept046);

alter table "fobos".rept046
	add constraint
		(foreign key (r46_compania, r46_division_c)
			references "fobos".rept003
			constraint "fobos".fk_05_rept046);

alter table "fobos".rept046
	add constraint
		(foreign key (r46_compania, r46_division_c, r46_sub_linea_c)
			references "fobos".rept070
			constraint "fobos".fk_06_rept046);

alter table "fobos".rept046
	add constraint
		(foreign key (r46_compania, r46_division_c, r46_sub_linea_c,
				r46_cod_grupo_c)
			references "fobos".rept071
			constraint "fobos".fk_07_rept046);

alter table "fobos".rept046
	add constraint
		(foreign key (r46_compania, r46_division_c, r46_sub_linea_c,
				r46_cod_grupo_c, r46_cod_clase_c)
			references "fobos".rept072
			constraint "fobos".fk_08_rept046);

alter table "fobos".rept046
	add constraint
		(foreign key (r46_compania, r46_marca_c)
			references "fobos".rept073
			constraint "fobos".fk_09_rept046);

alter table "fobos".rept046
	add constraint
		(foreign key (r46_usu_modifi)
			references "fobos".gent005
			constraint "fobos".fk_10_rept046);

alter table "fobos".rept046
	add constraint
		(foreign key (r46_usu_cierre)
			references "fobos".gent005
			constraint "fobos".fk_11_rept046);

alter table "fobos".rept046
	add constraint
		(foreign key (r46_usuario)
			references "fobos".gent005
			constraint "fobos".fk_12_rept046);

commit work;
