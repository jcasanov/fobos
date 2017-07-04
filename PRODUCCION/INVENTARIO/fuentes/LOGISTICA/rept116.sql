drop table rept116;

begin work;

create table "fobos".rept116

	(
		r116_compania		integer			not null,
		r116_localidad		smallint		not null,
		r116_cia_trans		smallint		not null,
		r116_estado		char(1)			not null,
		r116_razon_soc		varchar(60,30)		not null,
		r116_tipo		char(1)			not null,
		r116_usuario		varchar(10,5)		not null,
		r116_fecing		datetime year to second	not null,

		check (r116_estado in ("A", "B"))
			constraint "fobos".ck_01_rept116,
		check (r116_tipo   in ("I", "E"))
			constraint "fobos".ck_02_rept116

	) in datadbs lock mode row;

revoke all on "fobos".rept116 from "public";

create unique index "fobos".i01_pk_rept116
	on "fobos".rept116
		(r116_compania, r116_localidad, r116_cia_trans)
	in idxdbs;

create index "fobos".i01_fk_rept116
	on "fobos".rept116
		(r116_usuario)
	in idxdbs;

alter table "fobos".rept116
	add constraint
		primary key (r116_compania, r116_localidad, r116_cia_trans)
			constraint "fobos".pk_rept116;

alter table "fobos".rept116
	add constraint
		(foreign key (r116_usuario)
			references "fobos".gent005
			constraint "fobos".fk_01_rept116);

commit work;
