begin work;

create table "fobos".talt061
	(
		t61_compania		integer			not null,
		t61_cod_asesor		smallint		not null,
		t61_cod_vendedor	smallint		not null
	);

create unique index "fobos".i01_pk_talt061 on "fobos".talt061
	(t61_compania, t61_cod_asesor, t61_cod_vendedor) in idxdbs;

create index "fobos".i01_fk_talt061 on "fobos".talt061
	(t61_compania, t61_cod_asesor) in idxdbs;

create index "fobos".i02_fk_talt061 on "fobos".talt061
	(t61_compania, t61_cod_vendedor) in idxdbs;

alter table "fobos".talt061
	add constraint
		primary key (t61_compania, t61_cod_asesor, t61_cod_vendedor)
			constraint "fobos".pk_talt061;

commit work;
