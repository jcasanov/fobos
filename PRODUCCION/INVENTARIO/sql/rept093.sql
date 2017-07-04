begin work;

--drop table "fobos".rept093;

create table "fobos".rept093
	(
		r93_compania		integer			not null,
		r93_item		char(15)		not null,
		r93_cod_pedido		char(20)		not null,
		r93_stock_max		integer			not null,
		r93_stock_min		integer			not null,
		r93_stock_act		decimal(8,2)		not null,
		r93_cantpend		decimal(8,2)		not null,
		r93_cantpedir		decimal(8,2)		not null,
		r93_usuario		varchar(10,5)		not null,
		r93_fecing		datetime year to second	not null
	);

create unique index "fobos".i01_pk_rept093 on "fobos".rept093
	(r93_compania, r93_item);

create index "fobos".i01_fk_rept093 on "fobos".rept093 (r93_cod_pedido);

create index "fobos".i02_fk_rept093 on "fobos".rept093 (r93_usuario);

alter table "fobos".rept093
	add constraint
		primary key (r93_compania, r93_item)
			constraint "fobos".pk_rept093;

alter table "fobos".rept093
	add constraint (foreign key (r93_usuario) references "fobos".gent005);

commit work;
