begin work;

create table "fobos".ctbt050
	(
		b50_compania		integer			not null,
		b50_tipo_comp		char(2)			not null,
		b50_num_comp		char(8)			not null,
		b50_anio		integer			not null,
		b50_usuario		varchar(10,5)		not null,
		b50_fecing		datetime year to second	not null
	);

alter table "fobos".ctbt050 lock mode (row);

create unique index "fobos".i01_pk_ctbt050 on "fobos".ctbt050
	(b50_compania, b50_tipo_comp, b50_num_comp, b50_anio);

create index "fobos".i01_fk_ctbt050 on "fobos".ctbt050
	(b50_compania, b50_tipo_comp, b50_num_comp);

create index "fobos".i02_fk_ctbt050 on "fobos".ctbt050 (b50_usuario);

alter table "fobos".ctbt050
	add constraint
		primary key (b50_compania, b50_tipo_comp, b50_num_comp,
				b50_anio)
			constraint "fobos".pk_ctbt050;

alter table "fobos".ctbt050
	add constraint (foreign key (b50_usuario) references "fobos".gent005);

commit work;
