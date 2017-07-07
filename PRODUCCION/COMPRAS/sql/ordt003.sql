begin work;

create table "fobos".ordt003
	(

		c03_compania		integer			not null,
		c03_tipo_ret		char(1)			not null,
		c03_porcentaje		decimal(5,2)		not null,
		c03_codigo_sri		varchar(15,6)		not null,
		c03_estado		char(1)			not null,
		c03_descripcion		varchar(150, 70)	not null,
		c03_usuario_modifi	varchar(10,5),
		c03_fecha_modifi	datetime year to second,
		c03_usuario_elimin	varchar(10,5),
		c03_fecha_elimin	datetime year to second,
		c03_usuario		varchar(10,5)		not null,
		c03_fecing		datetime year to second	not null,

		check (c03_estado in ('A', 'E'))

	) lock mode row;

revoke all on "fobos".ordt003 from public;


create unique index "fobos".i01_pk_ordt003 on "fobos".ordt003
	(c03_compania, c03_tipo_ret, c03_porcentaje, c03_codigo_sri) in idxdbs;

create index "fobos".i01_fk_ordt003 on "fobos".ordt003
	(c03_compania, c03_tipo_ret, c03_porcentaje) in idxdbs;

create index "fobos".i02_fk_ordt003 on "fobos".ordt003
	(c03_codigo_sri) in idxdbs;

create index "fobos".i03_fk_ordt003 on "fobos".ordt003
	(c03_usuario_modifi) in idxdbs;

create index "fobos".i04_fk_ordt003 on "fobos".ordt003
	(c03_usuario_elimin) in idxdbs;

create index "fobos".i05_fk_ordt003 on "fobos".ordt003 (c03_usuario) in idxdbs;


alter table "fobos".ordt003
	add constraint
		primary key (c03_compania, c03_tipo_ret, c03_porcentaje,
				c03_codigo_sri)
			constraint "fobos".pk_ordt003;

alter table "fobos".ordt003
	add constraint
		(foreign key (c03_compania, c03_tipo_ret, c03_porcentaje)
			references "fobos".ordt002);

alter table "fobos".ordt003
	add constraint (foreign key (c03_usuario_modifi)
			references "fobos".gent005);

alter table "fobos".ordt003
	add constraint (foreign key (c03_usuario_elimin)
			references "fobos".gent005);

alter table "fobos".ordt003
	add constraint (foreign key (c03_usuario) references "fobos".gent005);

commit work;