drop table rept111;

begin work;

create table "fobos".rept111

	(
		r111_compania		integer			not null,
		r111_localidad		smallint		not null,
		r111_cod_trans		smallint		not null,
		r111_cod_chofer		smallint		not null,
		r111_estado		char(1)			not null,
		r111_nombre		varchar(45,30)		not null,
		r111_cod_trab		integer,
		--r111_tipo		char(1)			not null,
		r111_usuario		varchar(10,5)		not null,
		r111_fecing		datetime year to second	not null,

		check (r111_estado in ("A", "B"))
			constraint "fobos".ck_01_rept111
		--check (r111_tipo   in ("C", "A"))
			--constraint "fobos".ck_02_rept111

	) in datadbs lock mode row;

revoke all on "fobos".rept111 from "public";

create unique index "fobos".i01_pk_rept111
	on "fobos".rept111
		(r111_compania, r111_localidad, r111_cod_trans, r111_cod_chofer)
	in idxdbs;

create index "fobos".i01_fk_rept111
	on "fobos".rept111
		(r111_compania, r111_localidad, r111_cod_trans)
	in idxdbs;

create index "fobos".i02_fk_rept111
	on "fobos".rept111
		(r111_compania, r111_cod_trab)
	in idxdbs;

create index "fobos".i03_fk_rept111
	on "fobos".rept111
		(r111_usuario)
	in idxdbs;

alter table "fobos".rept111
	add constraint
		primary key (r111_compania, r111_localidad, r111_cod_trans,
				r111_cod_chofer)
			constraint "fobos".pk_rept111;

alter table "fobos".rept111
	add constraint
		(foreign key (r111_compania, r111_localidad, r111_cod_trans)
			references "fobos".rept110
			constraint "fobos".fk_01_rept111);

alter table "fobos".rept111
	add constraint
		(foreign key (r111_compania, r111_cod_trab)
			references "fobos".rolt030
			constraint "fobos".fk_02_rept111);

alter table "fobos".rept111
	add constraint
		(foreign key (r111_usuario)
			references "fobos".gent005
			constraint "fobos".fk_03_rept111);

commit work;
