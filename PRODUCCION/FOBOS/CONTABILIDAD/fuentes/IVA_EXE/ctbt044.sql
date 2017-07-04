drop table ctbt044;

begin work;

create table "fobos".ctbt044
	(

		b44_compania		integer			not null,
		b44_localidad		smallint		not null,
		b44_modulo		char(2)			not null,
		b44_bodega		char(2)			not null,
		b44_grupo_linea		char(5)			not null,
		b44_porc_impto		decimal(5,2)		not null,
		b44_tipo_cli		smallint		not null,
		b44_venta		char(12)		not null,
		b44_descuento		char(12)		not null,
		b44_dev_venta		char(12)		not null,
		b44_costo_venta		char(12)		not null,
		b44_dev_costo		char(12)		not null,
		b44_inventario		char(12)		not null,
		b44_transito		char(12)		not null,
		b44_ajustes		char(12)		not null,
		b44_flete		char(12)		not null,
		b44_usuario		varchar(10,5)		not null,
		b44_fecing		datetime year to second	not null

	) in datadbs lock mode row;


revoke all on "fobos".ctbt044 from "public";


create unique index "fobos".i01_pk_ctbt044
	on "fobos".ctbt044
		(b44_compania, b44_localidad, b44_modulo, b44_bodega,
		 b44_grupo_linea, b44_porc_impto, b44_tipo_cli)
	in idxdbs;

create index "fobos".i01_fk_ctbt044 on "fobos".ctbt044 (b44_usuario) in idxdbs;


alter table "fobos".ctbt044
	add constraint
		primary key (b44_compania, b44_localidad, b44_modulo,
				b44_bodega, b44_grupo_linea, b44_porc_impto,
				b44_tipo_cli)
			constraint "fobos".pk_ctbt044;

alter table "fobos".ctbt044
	add constraint
		(foreign key (b44_usuario)
			references "fobos".gent005
			constraint "fobos".fk_01_ctbt044);


commit work;
