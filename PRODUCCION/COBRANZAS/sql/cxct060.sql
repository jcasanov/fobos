begin work;

create table "fobos".cxct060
	(
		z60_compania		integer			not null,
		z60_localidad		smallint		not null,
		z60_fecha_carga		date			not null,
		z60_fecha_arran		date			not null,
		z60_usuario		varchar(10,5)		not null,
		z60_fecing		datetime year to second	not null
	);

create unique index "fobos".i01_pk_cxct060 on "fobos".cxct060
	(z60_compania, z60_localidad) in idxdbs;

alter table "fobos".cxct060
	add constraint
		primary key (z60_compania, z60_localidad)
			constraint "fobos".pk_cxct060;

commit work;
