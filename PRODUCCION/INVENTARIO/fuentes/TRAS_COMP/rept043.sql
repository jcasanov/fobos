drop table rept043;

begin work;

create table "fobos".rept043

	(

		r43_compania		integer			not null,
		r43_localidad		smallint		not null,
		r43_traspaso		integer			not null,
		r43_cod_ventas		smallint		not null,
		r43_division		char(5)			not null,
		r43_nom_div		varchar(30,15)		not null,
		r43_sub_linea		char(2)			not null,
		r43_desc_sub		varchar(35,20)		not null,
		r43_cod_grupo		char(4),
		r43_desc_grupo		varchar(40,20),
		r43_cod_clase		char(8),
		r43_desc_clase		varchar(50,20),
		r43_marca		char(6)			not null,
		r43_desc_marca		varchar(35,20)		not null,
		r43_referencia		varchar(60,40)		not null,
		r43_usuario		varchar(10,5)		not null,
		r43_fecing		datetime year to second	not null

	) in datadbs lock mode row;

revoke all on "fobos".rept043 from "public";

create unique index "fobos".i01_pk_rept043
	on "fobos".rept043
		(r43_compania, r43_localidad, r43_traspaso)
	in idxdbs;

create index "fobos".i01_fk_rept043
	on "fobos".rept043
		(r43_compania, r43_cod_ventas)
	in idxdbs;

create index "fobos".i02_fk_rept043
	on "fobos".rept043
		(r43_compania, r43_division)
	in idxdbs;

create index "fobos".i03_fk_rept043
	on "fobos".rept043
		(r43_compania, r43_division, r43_sub_linea)
	in idxdbs;

create index "fobos".i04_fk_rept043
	on "fobos".rept043
		(r43_compania, r43_division, r43_sub_linea, r43_cod_grupo)
	in idxdbs;

create index "fobos".i05_fk_rept043
	on "fobos".rept043
		(r43_compania, r43_division, r43_sub_linea, r43_cod_grupo,
		 r43_cod_clase)
	in idxdbs;

create index "fobos".i06_fk_rept043
	on "fobos".rept043
		(r43_compania, r43_marca)
	in idxdbs;

create index "fobos".i07_fk_rept043
	on "fobos".rept043
		(r43_usuario)
	in idxdbs;

alter table "fobos".rept043
	add constraint
		primary key (r43_compania, r43_localidad, r43_traspaso)
			constraint "fobos".pk_rept043;

alter table "fobos".rept043
	add constraint
		(foreign key (r43_compania, r43_cod_ventas)
			references "fobos".rept001
			constraint "fobos".fk_01_rept043);

alter table "fobos".rept043
	add constraint
		(foreign key (r43_compania, r43_division)
			references "fobos".rept003
			constraint "fobos".fk_02_rept043);

alter table "fobos".rept043
	add constraint
		(foreign key (r43_compania, r43_division, r43_sub_linea)
			references "fobos".rept070
			constraint "fobos".fk_03_rept043);

alter table "fobos".rept043
	add constraint
		(foreign key (r43_compania, r43_division, r43_sub_linea,
				r43_cod_grupo)
			references "fobos".rept071
			constraint "fobos".fk_04_rept043);

alter table "fobos".rept043
	add constraint
		(foreign key (r43_compania, r43_division, r43_sub_linea,
				r43_cod_grupo, r43_cod_clase)
			references "fobos".rept072
			constraint "fobos".fk_05_rept043);

alter table "fobos".rept043
	add constraint
		(foreign key (r43_compania, r43_marca)
			references "fobos".rept073
			constraint "fobos".fk_06_rept043);

alter table "fobos".rept043
	add constraint
		(foreign key (r43_usuario)
			references "fobos".gent005
			constraint "fobos".fk_07_rept043);

commit work;
