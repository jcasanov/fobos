create table "fobos".cajt090
	(
		j90_localidad		smallint		not null,
		j90_codigo_caja		smallint		not null,
		j90_usua_caja		varchar(10,5)		not null
	);

create unique index "fobos".i01_pk_cajt090 on "fobos".cajt090
	(j90_localidad, j90_codigo_caja);

create index "fobos".i01_fk_cajt090 on "fobos".cajt090 (j90_usua_caja);

alter table "fobos".cajt090
	add constraint
		primary key (j90_localidad, j90_codigo_caja)
			constraint "fobos".pk_cajt090;

alter table "fobos".cajt090 lock mode (row);
