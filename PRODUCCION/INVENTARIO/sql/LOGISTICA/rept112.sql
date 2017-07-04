drop table rept112;

begin work;

create table "fobos".rept112

	(
		r112_compania		integer			not null,
		r112_localidad		smallint		not null,
		r112_num_hojrut		smallint		not null,
		r112_estado		char(1)			not null,
		r112_referencia		varchar(30,20)		not null,
		r112_fecha		date			not null,
		r112_cod_trans		smallint		not null,
		r112_cod_chofer		smallint		not null,
		r112_usuario		varchar(10,5)		not null,
		r112_fecing		datetime year to second	not null,

		check (r112_estado in ("A", "C", "E"))
			constraint "fobos".ck_01_rept112

	) in datadbs lock mode row;

revoke all on "fobos".rept112 from "public";

create unique index "fobos".i01_pk_rept112
	on "fobos".rept112
		(r112_compania, r112_localidad, r112_num_hojrut)
	in idxdbs;

create index "fobos".i01_fk_rept112
	on "fobos".rept112
		(r112_compania, r112_localidad, r112_cod_trans)
	in idxdbs;

create index "fobos".i02_fk_rept112
	on "fobos".rept112
		(r112_compania, r112_localidad, r112_cod_trans, r112_cod_chofer)
	in idxdbs;

create index "fobos".i03_fk_rept112
	on "fobos".rept112
		(r112_usuario)
	in idxdbs;

alter table "fobos".rept112
	add constraint
		primary key (r112_compania, r112_localidad, r112_num_hojrut)
			constraint "fobos".pk_rept112;

alter table "fobos".rept112
	add constraint
		(foreign key (r112_compania, r112_localidad, r112_cod_trans)
			references "fobos".rept110
			constraint "fobos".fk_01_rept112);

alter table "fobos".rept112
	add constraint
		(foreign key (r112_compania, r112_localidad, r112_cod_trans,
				r112_cod_chofer)
			references "fobos".rept111
			constraint "fobos".fk_02_rept112);

alter table "fobos".rept112
	add constraint
		(foreign key (r112_usuario)
			references "fobos".gent005
			constraint "fobos".fk_03_rept112);

commit work;
